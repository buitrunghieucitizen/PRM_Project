using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using System.Text.Json;
using System.Text;
using BackendAPI.Data;

namespace BackendAPI.Controllers
{
    [Authorize]
    [Route("api/[controller]")]
    [ApiController]
    public class AIController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly IConfiguration _configuration;

        public AIController(ApplicationDbContext context, IHttpClientFactory httpClientFactory, IConfiguration configuration)
        {
            _context = context;
            _httpClientFactory = httpClientFactory;
            _configuration = configuration;
        }

        private int GetUserId() => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        [HttpPost("chat")]
        public async Task<IActionResult> Chat([FromBody] ChatRequest request)
        {
            var userId = GetUserId();
            var user = await _context.Users.FindAsync(userId);
            
            // Gather financial context for the AI
            var transactions = await _context.Transactions.Where(t => t.UserId == userId).ToListAsync();
            var goals = await _context.Goals.Where(g => g.UserId == userId).ToListAsync();
            
            var totalIncome = transactions.Where(t => t.Type == "Income").Sum(t => t.Amount);
            var totalExpense = transactions.Where(t => t.Type == "Expense").Sum(t => t.Amount);
            var balance = totalIncome - totalExpense;

            // Prepare prompt context
            var contextPrompt = $"Bạn là trợ lý tài chính thông minh (FinanceAI). Tên người dùng là {user?.FullName}. " +
                $"Số dư hiện tại: {balance:N0} VNĐ. Tổng thu: {totalIncome:N0} VNĐ, Tổng chi: {totalExpense:N0} VNĐ. " +
                $"Họ đang có {goals.Count} mục tiêu tài chính. Hãy tư vấn ngắn gọn gọn gàng (dưới 100 chữ), thân thiện và tập trung vào câu hỏi sau đây của người dùng: '{request.Message}'.";

            var apiKey = _configuration["Gemini:ApiKey"];
            
            if (string.IsNullOrEmpty(apiKey) || apiKey == "YOUR_GEMINI_API_KEY_HERE")
            {
                return Ok(new
                {
                    Role = "assistant",
                    Text = "[Chưa cấu hình API Key] " + request.Message + ". Vui lòng điền Gemini API Key trong file appsettings.json để nhận tư vấn thực."
                });
            }

            // Call Gemini API
            var url = $"https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key={apiKey}";
            
            var payload = new
            {
                contents = new[]
                {
                    new
                    {
                        parts = new[]
                        {
                            new { text = contextPrompt }
                        }
                    }
                }
            };

            var jsonPayload = JsonSerializer.Serialize(payload);
            var httpContent = new StringContent(jsonPayload, Encoding.UTF8, "application/json");

            var client = _httpClientFactory.CreateClient();
            var response = await client.PostAsync(url, httpContent);

            if (!response.IsSuccessStatusCode)
            {
                return StatusCode(500, new { message = "Lỗi khi kết nối với AI." });
            }

            var jsonResponse = await response.Content.ReadAsStringAsync();
            using var document = JsonDocument.Parse(jsonResponse);
            
            try
            {
                var textResponse = document.RootElement
                    .GetProperty("candidates")[0]
                    .GetProperty("content")
                    .GetProperty("parts")[0]
                    .GetProperty("text")
                    .GetString();

                return Ok(new
                {
                    Role = "assistant",
                    Text = textResponse
                });
            }
            catch
            {
                return StatusCode(500, new { message = "Lỗi định dạng từ AI." });
            }
        }
        [HttpPost("suggest-budget")]
        public async Task<IActionResult> SuggestBudget([FromBody] SuggestBudgetRequest request)
        {
            var apiKey = _configuration["Gemini:ApiKey"];
            if (string.IsNullOrEmpty(apiKey) || apiKey == "YOUR_GEMINI_API_KEY_HERE")
            {
                return BadRequest(new { message = "Chưa cấu hình Gemini API Key." });
            }

            var lockedSum = request.LockedCategories.Sum(c => c.Amount);
            var remainingBudget = request.TotalBudget - lockedSum;

            if (remainingBudget <= 0 || request.TargetCategories.Count == 0)
            {
                return BadRequest(new { message = "Ngân sách không đủ hoặc không có danh mục cần phân bổ." });
            }

            var lockedStr = string.Join(", ", request.LockedCategories.Select(c => $"{c.Name}: {c.Amount}"));
            var targetStr = string.Join(", ", request.TargetCategories);

            var contextPrompt = $"Bạn là chuyên gia tài chính. Tổng ngân sách tháng là {request.TotalBudget}. " +
                $"Người dùng đã cố định các khoản sau: [{lockedStr}]. Số tiền còn lại là: {remainingBudget}. " +
                $"Hãy phân bổ số tiền còn lại vào các danh mục sau một cách hợp lý: [{targetStr}]. " +
                "Chỉ trả về định dạng JSON thuần túy (không có markdown ```json, không có text dư thừa), với key là tên danh mục, value là số tiền (số nguyên). " +
                "Ví dụ: {\"Ăn uống\": 2000000, \"Đi lại\": 500000}";

            var url = $"https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key={apiKey}";
            
            var payload = new
            {
                contents = new[]
                {
                    new
                    {
                        parts = new[] { new { text = contextPrompt } }
                    }
                }
            };

            var jsonPayload = JsonSerializer.Serialize(payload);
            var httpContent = new StringContent(jsonPayload, Encoding.UTF8, "application/json");

            var client = _httpClientFactory.CreateClient();
            var response = await client.PostAsync(url, httpContent);

            if (!response.IsSuccessStatusCode)
            {
                return StatusCode(500, new { message = "Lỗi khi kết nối với AI." });
            }

            var jsonResponse = await response.Content.ReadAsStringAsync();
            using var document = JsonDocument.Parse(jsonResponse);
            
            try
            {
                var textResponse = document.RootElement
                    .GetProperty("candidates")[0]
                    .GetProperty("content")
                    .GetProperty("parts")[0]
                    .GetProperty("text")
                    .GetString();

                textResponse = textResponse?.Replace("```json", "").Replace("```", "").Trim();

                return Ok(new
                {
                    Suggestion = textResponse
                });
            }
            catch
            {
                return StatusCode(500, new { message = "Lỗi định dạng từ AI." });
            }
        }
    }

    public class ChatRequest
    {
        public string Message { get; set; } = string.Empty;
    }

    public class SuggestBudgetRequest
    {
        public decimal TotalBudget { get; set; }
        public List<LockedCategory> LockedCategories { get; set; } = new();
        public List<string> TargetCategories { get; set; } = new();
    }

    public class LockedCategory
    {
        public string Name { get; set; } = string.Empty;
        public decimal Amount { get; set; }
    }
}
