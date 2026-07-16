USE FinanceAI_DB;
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns 
    WHERE object_id = OBJECT_ID('Transactions') AND name = 'GoalId'
)
BEGIN
    ALTER TABLE Transactions ADD GoalId int NULL;
    
    ALTER TABLE Transactions 
    ADD CONSTRAINT FK_Transactions_Goals 
    FOREIGN KEY (GoalId) REFERENCES Goals(Id) 
    ON DELETE SET NULL;
END
GO

IF NOT EXISTS (
    SELECT * FROM sys.indexes WHERE name = 'IX_Txn_UserId_Date' AND object_id = OBJECT_ID('Transactions')
)
BEGIN
    CREATE INDEX IX_Txn_UserId_Date ON Transactions(UserId, TransactionDate DESC);
END
GO
