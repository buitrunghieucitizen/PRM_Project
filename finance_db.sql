CREATE DATABASE FinanceAI_DB;
GO

USE FinanceAI_DB;
GO

CREATE TABLE Users (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Username NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(MAX) NOT NULL,
    CreatedAt DATETIME2 DEFAULT GETDATE()
);

CREATE TABLE Transactions (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    UserId INT NOT NULL FOREIGN KEY REFERENCES Users(Id),
    Amount DECIMAL(18,2) NOT NULL,
    Category NVARCHAR(50) NOT NULL,
    Type NVARCHAR(20) NOT NULL, -- 'Income' or 'Expense'
    TransactionDate DATETIME2 NOT NULL,
    Note NVARCHAR(MAX)
);

CREATE TABLE Goals (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    UserId INT NOT NULL FOREIGN KEY REFERENCES Users(Id),
    Title NVARCHAR(100) NOT NULL,
    TargetAmount DECIMAL(18,2) NOT NULL,
    CurrentAmount DECIMAL(18,2) DEFAULT 0,
    Deadline DATETIME2,
    IsCompleted BIT DEFAULT 0,
    CreatedAt DATETIME2 DEFAULT GETDATE()
);

CREATE TABLE MonthlyPlans (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    UserId INT NOT NULL FOREIGN KEY REFERENCES Users(Id),
    Month INT NOT NULL,
    Year INT NOT NULL,
    Category NVARCHAR(50) NOT NULL,
    PlannedAmount DECIMAL(18,2) NOT NULL
);

CREATE TABLE AIAdvice (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    UserId INT NOT NULL FOREIGN KEY REFERENCES Users(Id),
    UserQuery NVARCHAR(MAX) NOT NULL,
    AIResponse NVARCHAR(MAX) NOT NULL,
    ProposedActionsJson NVARCHAR(MAX), -- JSON array of actions like {"action": "create_goal", "data": {...}}
    IsApplied BIT DEFAULT 0,
    CreatedAt DATETIME2 DEFAULT GETDATE()
);

-- Insert dummy user
INSERT INTO Users (Username, Email, PasswordHash) VALUES ('testuser', 'test@example.com', 'dummyhash');
