using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using BackendAPI.Data;
using BackendAPI.Models;

namespace BackendAPI.Controllers
{
    [Authorize]
    [Route("api/[controller]")]
    [ApiController]
    public class BudgetsController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public BudgetsController(ApplicationDbContext context)
        {
            _context = context;
        }

        private int GetUserId() => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        [HttpGet("current")]
        public async Task<IActionResult> GetCurrentBudget()
        {
            var userId = GetUserId();
            var now = DateTime.UtcNow;
            var plan = await _context.BudgetPlans
                .FirstOrDefaultAsync(b => b.UserId == userId && b.Month == now.Month && b.Year == now.Year);

            if (plan == null)
            {
                return Ok(new { Month = now.Month, Year = now.Year, TotalBudget = 0, CategoryAllocations = "[]" });
            }

            return Ok(plan);
        }

        [HttpPost]
        public async Task<IActionResult> SetBudget([FromBody] BudgetPlan plan)
        {
            var userId = GetUserId();
            plan.UserId = userId;
            plan.CreatedAt = DateTime.UtcNow;
            plan.UpdatedAt = DateTime.UtcNow;

            var existingPlan = await _context.BudgetPlans
                .FirstOrDefaultAsync(b => b.UserId == userId && b.Month == plan.Month && b.Year == plan.Year);

            if (existingPlan != null)
            {
                existingPlan.TotalBudget = plan.TotalBudget;
                existingPlan.CategoryAllocations = plan.CategoryAllocations;
                existingPlan.UpdatedAt = DateTime.UtcNow;
            }
            else
            {
                _context.BudgetPlans.Add(plan);
            }

            await _context.SaveChangesAsync();
            return Ok(existingPlan ?? plan);
        }
    }
}
