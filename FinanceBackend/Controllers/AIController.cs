using Microsoft.AspNetCore.Mvc;
using FinanceBackend.Data;
using FinanceBackend.Models;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;
using System.Text;

namespace FinanceBackend.Controllers
{
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

            // Format data for AI
            var prompt = $@"
You are a financial advisor AI. The user has the following data:
Goals: {JsonSerializer.Serialize(user.Goals.Select(g => new {g.Title, g.TargetAmount, g.CurrentAmount}))}
Monthly Plans: {JsonSerializer.Serialize(user.MonthlyPlans.Select(p => new {p.Category, p.PlannedAmount}))}

User Query: {userQuery}

Please provide friendly advice. 
If the user wants to add a new goal or plan, include a JSON block at the very end of your response exactly like this:
```json
[
  {{ ""action"": ""add_goal"", ""title"": ""[Title]"", ""targetAmount"": [Amount] }},
  {{ ""action"": ""add_plan"", ""category"": ""[Category]"", ""amount"": [Amount] }}
]
```
If no actions are needed, do not include the JSON block.
";

            var apiKey = _configuration["GeminiApi:ApiKey"];
            var model = _configuration["GeminiApi:Model"] ?? "gemini-1.5-pro";
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
                            _context.Goals.Add(new Goal
                            {
                                UserId = advice.UserId,
                                Title = action.title ?? "New Goal",
                                TargetAmount = action.targetAmount ?? 0
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
        public decimal? targetAmount { get; set; }
        public decimal? amount { get; set; }
    }
}
