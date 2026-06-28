using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using FinanceBackend.Data;
using FinanceBackend.Models;

namespace FinanceBackend.Controllers
{
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
        public async Task<IActionResult> GetTransactions(int userId)
        {
            var txs = await _context.Transactions.Where(t => t.UserId == userId).OrderByDescending(t => t.TransactionDate).ToListAsync();
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
    }
}
