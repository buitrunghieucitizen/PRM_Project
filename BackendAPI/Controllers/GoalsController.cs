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
    public class GoalsController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public GoalsController(ApplicationDbContext context)
        {
            _context = context;
        }

        private int GetUserId() => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        [HttpGet]
        public async Task<IActionResult> GetGoals()
        {
            var userId = GetUserId();
            var goals = await _context.Goals.Where(g => g.UserId == userId).ToListAsync();
            return Ok(goals);
        }

        [HttpPost]
        public async Task<IActionResult> CreateGoal([FromBody] Goal goal)
        {
            goal.UserId = GetUserId();
            goal.CreatedAt = DateTime.UtcNow;

            _context.Goals.Add(goal);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetGoals), new { id = goal.Id }, goal);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateGoal(int id, [FromBody] Goal goalUpdate)
        {
            var userId = GetUserId();
            var goal = await _context.Goals.FirstOrDefaultAsync(g => g.Id == id && g.UserId == userId);

            if (goal == null) return NotFound();

            goal.Name = goalUpdate.Name;
            goal.Emoji = goalUpdate.Emoji;
            goal.ColorHex = goalUpdate.ColorHex;
            goal.TargetAmount = goalUpdate.TargetAmount;
            goal.CurrentAmount = goalUpdate.CurrentAmount;
            goal.MonthlySaving = goalUpdate.MonthlySaving;
            goal.TargetDate = goalUpdate.TargetDate;

            await _context.SaveChangesAsync();
            return Ok(goal);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteGoal(int id)
        {
            var userId = GetUserId();
            var goal = await _context.Goals.FirstOrDefaultAsync(g => g.Id == id && g.UserId == userId);

            if (goal == null) return NotFound();

            _context.Goals.Remove(goal);
            await _context.SaveChangesAsync();
            return NoContent();
        }
    }
}
