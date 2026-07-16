using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using FinanceBackend.Data;
using FinanceBackend.Models;
using Microsoft.AspNetCore.Authorization;

namespace FinanceBackend.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class MonthlyPlansController : ControllerBase
    {
        private readonly AppDbContext _context;

        public MonthlyPlansController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet("{userId}")]
        public async Task<IActionResult> GetPlans(int userId, [FromQuery] int? month, [FromQuery] int? year)
        {
            var query = _context.MonthlyPlans.Where(t => t.UserId == userId);
            if (month.HasValue) query = query.Where(t => t.Month == month.Value);
            if (year.HasValue) query = query.Where(t => t.Year == year.Value);

            var plans = await query.ToListAsync();
            return Ok(plans);
        }

        [HttpPost]
        public async Task<IActionResult> AddPlan([FromBody] MonthlyPlan plan)
        {
            _context.MonthlyPlans.Add(plan);
            await _context.SaveChangesAsync();
            return Ok(plan);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdatePlan(int id, [FromBody] MonthlyPlan plan)
        {
            if (id != plan.Id) return BadRequest();
            _context.Entry(plan).State = EntityState.Modified;
            await _context.SaveChangesAsync();
            return Ok(plan);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeletePlan(int id)
        {
            var plan = await _context.MonthlyPlans.FindAsync(id);
            if (plan == null) return NotFound();

            _context.MonthlyPlans.Remove(plan);
            await _context.SaveChangesAsync();
            return Ok(new { message = "Deleted" });
        }
    }
}
