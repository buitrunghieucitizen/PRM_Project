using Microsoft.AspNetCore.Mvc;
using FinanceBackend.Data;
using FinanceBackend.Models;
using Microsoft.EntityFrameworkCore;

namespace FinanceBackend.Controllers
{
    [ApiController]
    [Route("api")]
    public class FinanceController : ControllerBase
    {
        private readonly AppDbContext _context;

        public FinanceController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet("users/{userId}/goals")]
        public async Task<IActionResult> GetGoals(int userId)
        {
            var goals = await _context.Goals.Where(g => g.UserId == userId).ToListAsync();
            return Ok(goals);
        }

        [HttpGet("users/{userId}/plans")]
        public async Task<IActionResult> GetPlans(int userId)
        {
            var plans = await _context.MonthlyPlans.Where(p => p.UserId == userId).ToListAsync();
            return Ok(plans);
        }

        [HttpGet("users/{userId}/transactions")]
        public async Task<IActionResult> GetTransactions(int userId)
        {
            var txs = await _context.Transactions.Where(t => t.UserId == userId).ToListAsync();
            return Ok(txs);
        }

        [HttpGet("users/{userId}/advice")]
        public async Task<IActionResult> GetAdvice(int userId)
        {
            var advice = await _context.AIAdvice.Where(a => a.UserId == userId).OrderByDescending(a => a.CreatedAt).ToListAsync();
            return Ok(advice);
        }
    }
}
