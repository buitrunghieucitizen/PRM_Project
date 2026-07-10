using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BackendAPI.Models
{
    public class Category
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public string Name { get; set; } = string.Empty;

        [Required]
        public string Type { get; set; } = "Expense"; // "Income" or "Expense"

        public string Emoji { get; set; } = "🏷️";
        
        public string Color { get; set; } = "#808080";
    }
}
