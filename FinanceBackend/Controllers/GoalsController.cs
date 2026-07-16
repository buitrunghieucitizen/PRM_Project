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
    public class GoalsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public GoalsController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet("{userId}")]
        public async Task<IActionResult> GetGoals(int userId)
        {
            var goals = await _context.Goals.Where(t => t.UserId == userId).ToListAsync();
            return Ok(goals);
        }

        [HttpPost]
        public async Task<IActionResult> AddGoal([FromBody] Goal goal)
        {
            _context.Goals.Add(goal);
            await _context.SaveChangesAsync();
            return Ok(goal);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateGoal(int id, [FromBody] Goal goal)
        {
            if (id != goal.Id) return BadRequest();
            var existingGoal = await _context.Goals.FindAsync(id);
            if (existingGoal == null) return NotFound();

            existingGoal.Title = goal.Title;
            existingGoal.TargetAmount = goal.TargetAmount;
            existingGoal.Deadline = goal.Deadline;
            existingGoal.IsCompleted = goal.IsCompleted;

            await _context.SaveChangesAsync();
            return Ok(existingGoal);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteGoal(int id)
        {
            var goal = await _context.Goals.FindAsync(id);
            if (goal == null) return NotFound();

            _context.Goals.Remove(goal);
            await _context.SaveChangesAsync();
            return Ok(new { message = "Deleted" });
        }
    }
}
