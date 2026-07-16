using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using FinanceBackend.Data;
using FinanceBackend.Models;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Google.Apis.Auth;
using Microsoft.AspNetCore.Authorization;
using System.Text.Json;

namespace FinanceBackend.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class UsersController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IConfiguration _config;

        public UsersController(AppDbContext context, IConfiguration config)
        {
            _context = context;
            _config = config;
        }

        private string GenerateJwtToken(User user)
        {
            var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["Jwt:Key"] ?? "ThisIsASecretKeyForJwtAuthenticationMakeItLonger123!@#"));
            var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

            var claims = new[]
            {
                new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
                new Claim(JwtRegisteredClaimNames.Email, user.Email),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
            };

            var token = new JwtSecurityToken(_config["Jwt:Issuer"],
                _config["Jwt:Audience"],
                claims,
                expires: DateTime.Now.AddDays(30),
                signingCredentials: credentials);

            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetUser(int id)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null) return NotFound();
            var userDto = new { user.Id, user.Email, user.FullName, user.Username, user.MonthlySalary, user.IsProfileComplete };
            return Ok(userDto);
        }

        public class UpdateUserRequest
        {
            public string? FullName { get; set; }
            public string? PhoneNumber { get; set; }
            public string? JobTitle { get; set; }
            public decimal? MonthlySalary { get; set; }
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateUser(int id, [FromBody] UpdateUserRequest request)
        {
            var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userIdStr) || !int.TryParse(userIdStr, out int tokenUserId) || tokenUserId != id)
                return Unauthorized();

            var user = await _context.Users.FindAsync(id);
            if (user == null) return NotFound("User not found");

            if (request.FullName != null)
            {
                user.FullName = request.FullName;
            }
            if (request.PhoneNumber != null)
            {
                user.PhoneNumber = request.PhoneNumber;
            }
            if (request.JobTitle != null)
            {
                user.JobTitle = request.JobTitle;
            }
            if (request.MonthlySalary.HasValue)
            {
                user.MonthlySalary = request.MonthlySalary.Value;
            }
            
            await _context.SaveChangesAsync();
            return Ok(new { message = "Profile updated successfully", user = new { user.Id, user.Email, user.FullName, user.Username, user.PhoneNumber, user.JobTitle, user.MonthlySalary } });
        }

        public class ChangePasswordRequest
        {
            public string CurrentPassword { get; set; } = string.Empty;
            public string NewPassword { get; set; } = string.Empty;
        }

        [HttpPost("{id}/change-password")]
        public async Task<IActionResult> ChangePassword(int id, [FromBody] ChangePasswordRequest request)
        {
            var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userIdStr) || !int.TryParse(userIdStr, out int tokenUserId) || tokenUserId != id)
                return Unauthorized();

            var user = await _context.Users.FindAsync(id);
            if (user == null) return NotFound("User not found");

            if (string.IsNullOrEmpty(user.PasswordHash)) 
                return BadRequest("User logged in via Google SSO. Password change not supported.");

            try
            {
                if (!BCrypt.Net.BCrypt.Verify(request.CurrentPassword, user.PasswordHash))
                {
                    return BadRequest("Incorrect current password.");
                }
            }
            catch (Exception)
            {
                if (user.PasswordHash != request.CurrentPassword)
                    return BadRequest("Incorrect current password.");
            }

            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Password changed successfully" });
        }

        [AllowAnonymous]
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] User loginUser)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == loginUser.Email);
            if (user == null) return Unauthorized("Invalid credentials");
            
            // Verify password using BCrypt
            bool isPasswordValid = false;
            if (!string.IsNullOrEmpty(user.PasswordHash))
            {
                try
                {
                    isPasswordValid = BCrypt.Net.BCrypt.Verify(loginUser.PasswordHash, user.PasswordHash);
                }
                catch (Exception)
                {
                    // Fallback for legacy plain text passwords
                    if (user.PasswordHash == loginUser.PasswordHash)
                    {
                        isPasswordValid = true;
                        // Upgrade the hash
                        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(loginUser.PasswordHash);
                        await _context.SaveChangesAsync();
                    }
                }
            }

            if (!isPasswordValid)
            {
                return Unauthorized("Invalid credentials");
            }

            var token = GenerateJwtToken(user);
            var userDto = new { user.Id, user.Email, user.FullName, user.Username, user.MonthlySalary, user.IsProfileComplete };
            return Ok(new { token, user = userDto, isNewUser = !user.IsProfileComplete });
        }

        [AllowAnonymous]
        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] User newUser)
        {
            if (await _context.Users.AnyAsync(u => u.Email == newUser.Email))
                return BadRequest("Email already exists");

            newUser.PasswordHash = BCrypt.Net.BCrypt.HashPassword(newUser.PasswordHash);
            _context.Users.Add(newUser);
            await _context.SaveChangesAsync();
            
            var token = GenerateJwtToken(newUser);
            var userDto = new { newUser.Id, newUser.Email, newUser.FullName, newUser.Username, newUser.MonthlySalary, newUser.IsProfileComplete };
            return Ok(new { token, user = userDto, isNewUser = !newUser.IsProfileComplete });
        }

        public class GoogleLoginRequest
        {
            public string IdToken { get; set; } = string.Empty;
        }

        [AllowAnonymous]
        [HttpPost("google-login")]
        public async Task<IActionResult> GoogleLogin([FromBody] GoogleLoginRequest request)
        {
            try
            {
                var settings = new GoogleJsonWebSignature.ValidationSettings
                {
                    Audience = new List<string> { _config["GoogleAuth:ClientId"] }
                };
                var payload = await GoogleJsonWebSignature.ValidateAsync(request.IdToken, settings);
                
                var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == payload.Email);
                if (user == null)
                {
                    // Create a new user if one doesn't exist
                    user = new User
                    {
                        Email = payload.Email,
                        Username = payload.Name,
                        GoogleId = payload.Subject,
                        PasswordHash = "" // No password for Google SSO users
                    };
                    _context.Users.Add(user);
                    await _context.SaveChangesAsync();
                }
                else if (string.IsNullOrEmpty(user.GoogleId))
                {
                    // Link existing account with Google ID
                    user.GoogleId = payload.Subject;
                    await _context.SaveChangesAsync();
                }

                var token = GenerateJwtToken(user);
                var userDto = new { user.Id, user.Email, user.FullName, user.Username, user.MonthlySalary, user.IsProfileComplete };
                return Ok(new { token, user = userDto, isNewUser = !user.IsProfileComplete });
            }
            catch (InvalidJwtException ex)
            {
                return Unauthorized($"Invalid Google Token: {ex.Message}");
            }
            catch (Exception ex)
            {
                return BadRequest($"Google Login Error: {ex.Message}");
            }
        }

        public class OnboardRequest
        {
            public string? FullName { get; set; }
            public string PhoneNumber { get; set; } = string.Empty;
            public string JobTitle { get; set; } = string.Empty;
            public decimal MonthlySalary { get; set; }
            public decimal? IncomeGoal { get; set; }
            public string ExpensesDescription { get; set; } = string.Empty;
        }

        [HttpPost("onboard")]
        public async Task<IActionResult> Onboard([FromBody] OnboardRequest request)
        {
            var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userIdStr) || !int.TryParse(userIdStr, out int userId))
                return Unauthorized();

            var user = await _context.Users.FindAsync(userId);
            if (user == null) return NotFound("User not found");

            if (!string.IsNullOrEmpty(request.FullName))
            {
                user.FullName = request.FullName;
            }
            user.PhoneNumber = request.PhoneNumber;
            user.JobTitle = request.JobTitle;
            user.MonthlySalary = request.MonthlySalary;
            user.IsProfileComplete = true;

            // Add initial income transaction
            if (request.MonthlySalary > 0)
            {
                _context.Transactions.Add(new Transaction
                {
                    UserId = userId,
                    Amount = request.MonthlySalary,
                    Category = "Lương",
                    Type = "Income",
                    Note = "Thu nhập ban đầu",
                    TransactionDate = DateTime.Now
                });
            }

            // Generate initial goals/plans from AI if user provided expenses description
            if (!string.IsNullOrEmpty(request.ExpensesDescription) || request.IncomeGoal.HasValue)
            {
                var prompt = $@"
You are a financial advisor AI. The user is setting up their profile.
Monthly Salary: {request.MonthlySalary}
Income Goal: {request.IncomeGoal}
Expenses Description: {request.ExpensesDescription}

Please parse their expenses and goals and return a JSON array of actions to set up their initial monthly plans and goals.
Return ONLY a JSON block like this:
```json
[
  {{ ""action"": ""add_goal"", ""title"": ""[Title]"", ""targetAmount"": [Amount] }},
  {{ ""action"": ""add_plan"", ""category"": ""[Category]"", ""amount"": [Amount] }}
]
```
Do not include any other text outside the JSON block.
";
                try
                {
                    var httpClient = new HttpClient();
                    var apiKey = _config["GeminiApi:ApiKey"];
                    var model = _config["GeminiApi:Model"] ?? "gemini-1.5-pro-latest";
                    var url = $"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={apiKey}";

                    var requestBody = new
                    {
                        contents = new[]
                        {
                            new { parts = new[] { new { text = prompt } } }
                        }
                    };

                    var response = await httpClient.PostAsJsonAsync(url, requestBody);
                    if (response.IsSuccessStatusCode)
                    {
                        var resultStr = await response.Content.ReadAsStringAsync();
                        using var doc = JsonDocument.Parse(resultStr);
                        var aiText = doc.RootElement
                            .GetProperty("candidates")[0]
                            .GetProperty("content")
                            .GetProperty("parts")[0]
                            .GetProperty("text").GetString();

                        string? actionsJson = null;
                        var jsonStart = aiText!.LastIndexOf("```json");
                        if (jsonStart != -1)
                        {
                            var jsonEnd = aiText.IndexOf("```", jsonStart + 7);
                            if (jsonEnd != -1)
                            {
                                actionsJson = aiText.Substring(jsonStart + 7, jsonEnd - (jsonStart + 7)).Trim();
                            }
                        }
                        else if (aiText.Trim().StartsWith("[")) 
                        {
                            actionsJson = aiText.Trim();
                        }

                        if (!string.IsNullOrEmpty(actionsJson))
                        {
                            var actions = System.Text.Json.JsonSerializer.Deserialize<List<ActionPayload>>(actionsJson);
                            if (actions != null)
                            {
                                foreach (var action in actions)
                                {
                                    if (action.action == "add_goal")
                                    {
                                        _context.Goals.Add(new Goal
                                        {
                                            UserId = userId,
                                            Title = action.title ?? "Mục tiêu mới",
                                            TargetAmount = action.targetAmount ?? 0,
                                            CurrentAmount = action.currentAmount ?? 0,
                                            Deadline = !string.IsNullOrEmpty(action.deadline) && DateTime.TryParse(action.deadline, out var d) ? d : DateTime.Now.AddMonths(1)
                                        });
                                    }
                                    else if (action.action == "add_plan")
                                    {
                                        _context.MonthlyPlans.Add(new MonthlyPlan
                                        {
                                            UserId = userId,
                                            Month = DateTime.Now.Month,
                                            Year = DateTime.Now.Year,
                                            Category = action.category ?? "General",
                                            PlannedAmount = action.amount ?? 0
                                        });
                                    }
                                }
                            }
                        }
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine("AI parsing failed during onboard: " + ex.Message);
                }
            }

            await _context.SaveChangesAsync();
            var userDto = new { user.Id, user.Email, user.FullName, user.Username, user.MonthlySalary, user.IsProfileComplete };
            return Ok(userDto);
        }

        private class ActionPayload
        {
            public string action { get; set; } = string.Empty;
            public string? title { get; set; }
            public string? category { get; set; }
            public decimal? targetAmount { get; set; }
            public decimal? currentAmount { get; set; }
            public decimal? amount { get; set; }
            public string? deadline { get; set; }
            public int? goalId { get; set; }
        }
    }
}
