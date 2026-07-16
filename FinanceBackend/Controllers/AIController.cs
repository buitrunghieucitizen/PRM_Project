using Microsoft.AspNetCore.Mvc;
using FinanceBackend.Data;
using FinanceBackend.Models;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;
using System.Text;
using Microsoft.AspNetCore.Authorization;

namespace FinanceBackend.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class AIController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IConfiguration _configuration;
        private readonly HttpClient _httpClient;

        public AIController(AppDbContext context, IConfiguration configuration, IHttpClientFactory httpClientFactory)
        {
            _context = context;
            _configuration = configuration;
            _httpClient = httpClientFactory.CreateClient();
        }

        [HttpPost("consult")]
        public async Task<IActionResult> Consult([FromQuery] int userId, [FromBody] string userQuery)
        {
            var user = await _context.Users
                .Include(u => u.Goals)
                .Include(u => u.MonthlyPlans)
                .FirstOrDefaultAsync(u => u.Id == userId);

            if (user == null) return NotFound("User not found");

            var recentTransactions = await _context.Transactions
                .Where(t => t.UserId == userId)
                .OrderByDescending(t => t.TransactionDate)
                .Take(50)
                .ToListAsync();

            var now = DateTime.Now;
            var monthIncome = await _context.Transactions
                .Where(t => t.UserId == userId && t.TransactionDate.Month == now.Month && t.TransactionDate.Year == now.Year && t.Type.ToLower() == "income")
                .SumAsync(t => t.Amount);

            var monthExpense = await _context.Transactions
                .Where(t => t.UserId == userId && t.TransactionDate.Month == now.Month && t.TransactionDate.Year == now.Year && t.Type.ToLower() == "expense")
                .SumAsync(t => t.Amount);

// Format data for AI
            var prompt = $@"
You are a financial advisor AI. The user has the following data:
Current Month Income: {monthIncome}
Current Month Expense: {monthExpense}
Goals: {JsonSerializer.Serialize(user.Goals.Select(g => new {g.Id, g.Title, g.TargetAmount, g.CurrentAmount, g.Deadline}))}
Monthly Plans: {JsonSerializer.Serialize(user.MonthlyPlans.Select(p => new {p.Category, p.PlannedAmount}))}
Recent Transactions (up to 50): {JsonSerializer.Serialize(recentTransactions.Select(t => new {t.Amount, t.Category, t.Type, t.TransactionDate, t.Note}))}

User Query: {userQuery}

Please provide friendly advice. 
If the user wants to add a new goal, plan, or record a transaction (income/expense), include a JSON block at the very end of your response exactly like this:
```json
[
  {{ ""action"": ""add_goal"", ""title"": ""[Title]"", ""targetAmount"": [Amount], ""currentAmount"": [Initial amount user has, 0 if not specified], ""deadline"": ""[YYYY-MM-DD or null]"" }},
  {{ ""action"": ""add_plan"", ""category"": ""[Category]"", ""amount"": [Amount] }},
  {{ ""action"": ""add_transaction"", ""type"": ""[Income or Expense]"", ""category"": ""[Category]"", ""amount"": [Amount], ""note"": ""[Optional note]"", ""goalId"": [Goal ID or null] }}
]
```
If no actions are needed, do not include the JSON block.
";

            var apiKey = _configuration["GeminiApi:ApiKey"];
            if (string.IsNullOrEmpty(apiKey))
            {
                return Ok(new { aiResponse = "Hệ thống chưa được cấu hình AI Key. Vui lòng liên hệ quản trị viên." });
            }
            var model = _configuration["GeminiApi:Model"] ?? "gemini-2.5-flash";
            var url = $"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={apiKey}";

            var requestBody = new
            {
                contents = new[]
                {
                    new { parts = new[] { new { text = prompt } } }
                }
            };

            var response = await _httpClient.PostAsJsonAsync(url, requestBody);
            if (!response.IsSuccessStatusCode)
            {
                var err = await response.Content.ReadAsStringAsync();
                return StatusCode(500, "AI Error: " + err);
            }

            var resultStr = await response.Content.ReadAsStringAsync();
            using var doc = JsonDocument.Parse(resultStr);
            var aiText = doc.RootElement
                .GetProperty("candidates")[0]
                .GetProperty("content")
                .GetProperty("parts")[0]
                .GetProperty("text").GetString();

            // Extract JSON from AI text
            string? actionsJson = null;
            try
            {
                var jsonStart = aiText!.LastIndexOf("```json");
                if (jsonStart != -1)
                {
                    var jsonEnd = aiText.IndexOf("```", jsonStart + 7);
                    if (jsonEnd != -1)
                    {
                        actionsJson = aiText.Substring(jsonStart + 7, jsonEnd - (jsonStart + 7)).Trim();
                        aiText = aiText.Substring(0, jsonStart).Trim();
                    }
                }
                else if (aiText.Trim().EndsWith("]"))
                {
                    var firstBracket = aiText.IndexOf("[");
                    if (firstBracket != -1)
                    {
                        actionsJson = aiText.Substring(firstBracket).Trim();
                        aiText = aiText.Substring(0, firstBracket).Trim();
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error parsing AI JSON: " + ex.Message);
            }

            var advice = new AIAdvice
            {
                UserId = userId,
                UserQuery = userQuery,
                AIResponse = aiText,
                ProposedActionsJson = actionsJson
            };

            _context.AIAdvice.Add(advice);
            await _context.SaveChangesAsync();

            return Ok(advice);
        }

        [HttpPost("apply/{adviceId}")]
        public async Task<IActionResult> Apply(int adviceId)
        {
            var advice = await _context.AIAdvice.FindAsync(adviceId);
            if (advice == null) return NotFound("Advice not found");
            if (advice.IsApplied) return BadRequest("Already applied");
            if (string.IsNullOrEmpty(advice.ProposedActionsJson)) return BadRequest("No actions to apply");

            try
            {
                var actions = JsonSerializer.Deserialize<List<ActionPayload>>(advice.ProposedActionsJson);
                if (actions != null)
                {
                    foreach (var action in actions)
                    {
                        if (action.action == "add_goal")
                        {
                            DateTime? parsedDeadline = null;
                            if (!string.IsNullOrEmpty(action.deadline) && DateTime.TryParse(action.deadline, out var dt))
                            {
                                parsedDeadline = dt;
                            }

                            _context.Goals.Add(new Goal
                            {
                                UserId = advice.UserId,
                                Title = action.title ?? "New Goal",
                                TargetAmount = action.targetAmount ?? 0,
                                CurrentAmount = action.currentAmount ?? 0,
                                Deadline = parsedDeadline
                            });
                        }
                        else if (action.action == "add_plan")
                        {
                            _context.MonthlyPlans.Add(new MonthlyPlan
                            {
                                UserId = advice.UserId,
                                Month = DateTime.Now.Month,
                                Year = DateTime.Now.Year,
                                Category = action.category ?? "General",
                                PlannedAmount = action.amount ?? 0
                            });
                        }
                        else if (action.action == "add_transaction")
                        {
                            _context.Transactions.Add(new Transaction
                            {
                                UserId = advice.UserId,
                                Amount = action.amount ?? 0,
                                Category = action.category ?? "General",
                                Type = action.type ?? "Expense",
                                TransactionDate = DateTime.Now,
                                Note = action.note,
                                GoalId = action.goalId
                            });
                        }
                    }
                    advice.IsApplied = true;
                    await _context.SaveChangesAsync();
                    return Ok(new { message = "Actions applied successfully" });
                }
            }
            catch (Exception ex)
            {
                return BadRequest("Failed to parse or apply actions: " + ex.Message);
            }

            return BadRequest("Unknown error");
        }
    }

    public class ActionPayload
    {
        public string action { get; set; } = string.Empty;
        public string? title { get; set; }
        public string? category { get; set; }
        public string? type { get; set; }
        public string? note { get; set; }
        public decimal? targetAmount { get; set; }
        public decimal? currentAmount { get; set; }
        public decimal? amount { get; set; }
        public int? goalId { get; set; }
        public string? deadline { get; set; }
    }
}
