using System;
using System.Collections.Generic;

namespace FinanceBackend.Models
{
    public class User
    {
        public int Id { get; set; }
        public string Username { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string PasswordHash { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; } = DateTime.Now;

        public ICollection<Transaction> Transactions { get; set; } = new List<Transaction>();
        public ICollection<Goal> Goals { get; set; } = new List<Goal>();
        public ICollection<MonthlyPlan> MonthlyPlans { get; set; } = new List<MonthlyPlan>();
    }

    public class Transaction
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public decimal Amount { get; set; }
        public string Category { get; set; } = string.Empty;
        public string Type { get; set; } = string.Empty; // 'Income' or 'Expense'
        public DateTime TransactionDate { get; set; } = DateTime.Now;
        public string? Note { get; set; }
        public int? GoalId { get; set; }

        public User? User { get; set; }
        public Goal? Goal { get; set; }
    }

    public class Goal
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string Title { get; set; } = string.Empty;
        public decimal TargetAmount { get; set; }
        public decimal CurrentAmount { get; set; } = 0;
        public DateTime? Deadline { get; set; }
        public bool IsCompleted { get; set; } = false;
        public DateTime CreatedAt { get; set; } = DateTime.Now;

        public User? User { get; set; }
        public ICollection<Transaction> Transactions { get; set; } = new List<Transaction>();
    }

    public class MonthlyPlan
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int Month { get; set; }
        public int Year { get; set; }
        public string Category { get; set; } = string.Empty;
        public decimal PlannedAmount { get; set; }

        public User? User { get; set; }
    }

    public class AIAdvice
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string UserQuery { get; set; } = string.Empty;
        public string AIResponse { get; set; } = string.Empty;
        public string? ProposedActionsJson { get; set; } // JSON list of actions
        public bool IsApplied { get; set; } = false;
        public DateTime CreatedAt { get; set; } = DateTime.Now;

        public User? User { get; set; }
    }
}
