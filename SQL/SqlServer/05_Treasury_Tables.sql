-- ============================================================================
-- KOREX_CONTABILIDAD - DDL DE TABLAS DE TESORERÍA (SQL SERVER / T-SQL)
-- Archivo: SQL/SqlServer/05_Treasury_Tables.sql
-- ============================================================================

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CashBox]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[CashBox] (
        [id] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [companyId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[Company]([id]),
        [code] NVARCHAR(30) NOT NULL UNIQUE,
        [name] NVARCHAR(150) NOT NULL,
        [accountId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[Account]([id]),
        [responsibleUserId] INT NULL FOREIGN KEY REFERENCES [dbo].[User]([id]),
        [currency] NVARCHAR(10) NOT NULL CONSTRAINT DF_CashBox_curr DEFAULT 'COP',
        [maxAmount] DECIMAL(18, 4) NULL CONSTRAINT DF_CashBox_max DEFAULT 0,
        [isActive] BIT NOT NULL CONSTRAINT DF_CashBox_isActive DEFAULT 1,
        [createdAt] DATETIME2 NOT NULL CONSTRAINT DF_CashBox_createdAt DEFAULT GETDATE(),
        [updatedAt] DATETIME2 NOT NULL CONSTRAINT DF_CashBox_updatedAt DEFAULT GETDATE()
    );
END;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TreasuryMovement]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[TreasuryMovement] (
        [id] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [companyId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[Company]([id]),
        [movementType] NVARCHAR(30) NOT NULL,
        [documentTypeId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[DocumentType]([id]),
        [consecutiveNumber] INT NOT NULL,
        [entryNumber] NVARCHAR(50) NOT NULL,
        [movementDate] DATETIME2 NOT NULL,
        [bankAccountId] INT NULL FOREIGN KEY REFERENCES [dbo].[BankAccount]([id]),
        [cashBoxId] INT NULL FOREIGN KEY REFERENCES [dbo].[CashBox]([id]),
        [targetBankAccountId] INT NULL FOREIGN KEY REFERENCES [dbo].[BankAccount]([id]),
        [targetCashBoxId] INT NULL FOREIGN KEY REFERENCES [dbo].[CashBox]([id]),
        [thirdPartyId] INT NULL FOREIGN KEY REFERENCES [dbo].[ThirdParty]([id]),
        [concept] NVARCHAR(255) NOT NULL,
        [paymentMethod] NVARCHAR(50) NOT NULL CONSTRAINT DF_TM_payMethod DEFAULT 'TRANSFERENCIA',
        [checkNumber] NVARCHAR(50) NULL,
        [totalAmount] DECIMAL(18, 4) NOT NULL CONSTRAINT DF_TM_amount DEFAULT 0,
        [status] NVARCHAR(20) NOT NULL CONSTRAINT DF_TM_status DEFAULT 'POSTED',
        [journalEntryId] INT NULL FOREIGN KEY REFERENCES [dbo].[JournalEntry]([id]),
        [createdById] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[User]([id]),
        [createdAt] DATETIME2 NOT NULL CONSTRAINT DF_TM_createdAt DEFAULT GETDATE(),
        [updatedAt] DATETIME2 NOT NULL CONSTRAINT DF_TM_updatedAt DEFAULT GETDATE()
    );
    CREATE NONCLUSTERED INDEX [IX_TreasuryMovement_date] ON [dbo].[TreasuryMovement]([movementDate]);
    CREATE NONCLUSTERED INDEX [IX_TreasuryMovement_type] ON [dbo].[TreasuryMovement]([movementType]);
END;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BankReconciliation]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[BankReconciliation] (
        [id] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [companyId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[Company]([id]),
        [bankAccountId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[BankAccount]([id]),
        [year] INT NOT NULL,
        [month] INT NOT NULL,
        [initialBalance] DECIMAL(18, 4) NOT NULL CONSTRAINT DF_BR_initBal DEFAULT 0,
        [finalBankStatementBalance] DECIMAL(18, 4) NOT NULL CONSTRAINT DF_BR_stmtBal DEFAULT 0,
        [bookBalance] DECIMAL(18, 4) NOT NULL CONSTRAINT DF_BR_bookBal DEFAULT 0,
        [difference] DECIMAL(18, 4) NOT NULL CONSTRAINT DF_BR_diff DEFAULT 0,
        [status] NVARCHAR(20) NOT NULL CONSTRAINT DF_BR_status DEFAULT 'DRAFT',
        [closedAt] DATETIME2 NULL,
        [closedById] INT NULL FOREIGN KEY REFERENCES [dbo].[User]([id]),
        [observations] NVARCHAR(MAX) NULL,
        [createdAt] DATETIME2 NOT NULL CONSTRAINT DF_BR_createdAt DEFAULT GETDATE(),
        [updatedAt] DATETIME2 NOT NULL CONSTRAINT DF_BR_updatedAt DEFAULT GETDATE(),
        CONSTRAINT [UQ_BankReconciliation_acct_ym] UNIQUE ([bankAccountId], [year], [month])
    );
END;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BankReconciliationItem]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[BankReconciliationItem] (
        [id] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [bankReconciliationId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[BankReconciliation]([id]) ON DELETE CASCADE,
        [itemType] NVARCHAR(50) NOT NULL,
        [itemDate] DATETIME2 NOT NULL,
        [documentNumber] NVARCHAR(50) NULL,
        [description] NVARCHAR(255) NOT NULL,
        [amount] DECIMAL(18, 4) NOT NULL CONSTRAINT DF_BRI_amount DEFAULT 0,
        [status] NVARCHAR(20) NOT NULL CONSTRAINT DF_BRI_status DEFAULT 'PENDING',
        [journalEntryItemId] INT NULL FOREIGN KEY REFERENCES [dbo].[JournalEntryItem]([id]),
        [createdAt] DATETIME2 NOT NULL CONSTRAINT DF_BRI_createdAt DEFAULT GETDATE(),
        [updatedAt] DATETIME2 NOT NULL CONSTRAINT DF_BRI_updatedAt DEFAULT GETDATE()
    );
END;
