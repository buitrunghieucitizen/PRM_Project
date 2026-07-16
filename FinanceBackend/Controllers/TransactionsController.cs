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
    public class TransactionsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public TransactionsController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet("{userId}")]
        public async Task<IActionResult> GetTransactions(int userId, [FromQuery] DateTime? startDate, [FromQuery] DateTime? endDate, [FromQuery] int? limit, [FromQuery] int? offset)
        {
            var query = _context.Transactions.Where(t => t.UserId == userId);

            if (startDate.HasValue)
                query = query.Where(t => t.TransactionDate >= startDate.Value);
            
            if (endDate.HasValue)
                query = query.Where(t => t.TransactionDate <= endDate.Value);

            query = query.OrderByDescending(t => t.TransactionDate);

            if (offset.HasValue)
                query = query.Skip(offset.Value);

            if (limit.HasValue)
                query = query.Take(limit.Value);

            var txs = await query.ToListAsync();
            return Ok(txs);
        }

        [HttpPost]
        public async Task<IActionResult> AddTransaction([FromBody] Transaction transaction)
        {
            _context.Transactions.Add(transaction);
            await _context.SaveChangesAsync();
            return Ok(transaction);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteTransaction(int id)
        {
            var tx = await _context.Transactions.FindAsync(id);
            if (tx == null) return NotFound();

            _context.Transactions.Remove(tx);
            await _context.SaveChangesAsync();
            return Ok(new { message = "Deleted" });
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateTransaction(int id, [FromBody] Transaction transaction)
        {
            if (id != transaction.Id) return BadRequest();
            _context.Entry(transaction).State = EntityState.Modified;
            await _context.SaveChangesAsync();
            return Ok(transaction);
        }
    }
}
