-- ============================================================================
-- KOREX_CONTABILIDAD - TABLAS DDL PARA CARTERA Y PROVEEDORES (FASE 5)
-- MOTOR: SQL Server (T-SQL)
-- ============================================================================

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ReceivableInvoice]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[ReceivableInvoice] (
        [id] INT IDENTITY(1,1) PRIMARY KEY,
        [companyId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[Company]([id]),
        [thirdPartyId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[ThirdParty]([id]),
        [documentTypeId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[DocumentType]([id]),
        [consecutiveNumber] INT NOT NULL,
        [invoiceNumber] NVARCHAR(50) NOT NULL,
        [issueDate] DATETIME2 NOT NULL,
        [dueDate] DATETIME2 NOT NULL,
        [paymentTermDays] INT NOT NULL DEFAULT 0,
        [subtotal] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [taxAmount] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [retentionAmount] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [totalAmount] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [paidAmount] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [balanceAmount] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [status] NVARCHAR(20) NOT NULL DEFAULT 'POSTED',
        [journalEntryId] INT NULL FOREIGN KEY REFERENCES [dbo].[JournalEntry]([id]),
        [createdById] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[User]([id]),
        [observations] NVARCHAR(MAX) NULL,
        [createdAt] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        [updatedAt] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT [UQ_ReceivableInvoice_doc_num] UNIQUE ([documentTypeId], [invoiceNumber])
    );
    CREATE INDEX [IX_ReceivableInvoice_thirdPartyId] ON [dbo].[ReceivableInvoice]([thirdPartyId]);
    CREATE INDEX [IX_ReceivableInvoice_issueDate] ON [dbo].[ReceivableInvoice]([issueDate]);
    CREATE INDEX [IX_ReceivableInvoice_dueDate] ON [dbo].[ReceivableInvoice]([dueDate]);
END;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ReceivableInstallment]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[ReceivableInstallment] (
        [id] INT IDENTITY(1,1) PRIMARY KEY,
        [receivableInvoiceId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[ReceivableInvoice]([id]) ON DELETE CASCADE,
        [installmentNumber] INT NOT NULL DEFAULT 1,
        [dueDate] DATETIME2 NOT NULL,
        [amount] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [paidAmount] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [balanceAmount] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [status] NVARCHAR(20) NOT NULL DEFAULT 'PENDING',
        [createdAt] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        [updatedAt] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
    CREATE INDEX [IX_ReceivableInstallment_invoice] ON [dbo].[ReceivableInstallment]([receivableInvoiceId]);
END;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PayableInvoice]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[PayableInvoice] (
        [id] INT IDENTITY(1,1) PRIMARY KEY,
        [companyId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[Company]([id]),
        [thirdPartyId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[ThirdParty]([id]),
        [documentTypeId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[DocumentType]([id]),
        [consecutiveNumber] INT NOT NULL,
        [invoiceNumber] NVARCHAR(50) NOT NULL,
        [internalNumber] NVARCHAR(50) NOT NULL,
        [issueDate] DATETIME2 NOT NULL,
        [dueDate] DATETIME2 NOT NULL,
        [paymentTermDays] INT NOT NULL DEFAULT 0,
        [subtotal] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [taxAmount] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [retentionAmount] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [totalAmount] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [paidAmount] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [balanceAmount] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [status] NVARCHAR(20) NOT NULL DEFAULT 'POSTED',
        [journalEntryId] INT NULL FOREIGN KEY REFERENCES [dbo].[JournalEntry]([id]),
        [createdById] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[User]([id]),
        [observations] NVARCHAR(MAX) NULL,
        [createdAt] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        [updatedAt] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT [UQ_PayableInvoice_doc_internal] UNIQUE ([documentTypeId], [internalNumber])
    );
    CREATE INDEX [IX_PayableInvoice_thirdPartyId] ON [dbo].[PayableInvoice]([thirdPartyId]);
    CREATE INDEX [IX_PayableInvoice_dueDate] ON [dbo].[PayableInvoice]([dueDate]);
END;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PayableInstallment]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[PayableInstallment] (
        [id] INT IDENTITY(1,1) PRIMARY KEY,
        [payableInvoiceId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[PayableInvoice]([id]) ON DELETE CASCADE,
        [installmentNumber] INT NOT NULL DEFAULT 1,
        [dueDate] DATETIME2 NOT NULL,
        [amount] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [paidAmount] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [balanceAmount] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [status] NVARCHAR(20) NOT NULL DEFAULT 'PENDING',
        [createdAt] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        [updatedAt] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
    CREATE INDEX [IX_PayableInstallment_invoice] ON [dbo].[PayableInstallment]([payableInvoiceId]);
END;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CreditDebitNote]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[CreditDebitNote] (
        [id] INT IDENTITY(1,1) PRIMARY KEY,
        [companyId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[Company]([id]),
        [noteType] NVARCHAR(30) NOT NULL,
        [documentTypeId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[DocumentType]([id]),
        [consecutiveNumber] INT NOT NULL,
        [noteNumber] NVARCHAR(50) NOT NULL,
        [noteDate] DATETIME2 NOT NULL,
        [thirdPartyId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[ThirdParty]([id]),
        [receivableInvoiceId] INT NULL FOREIGN KEY REFERENCES [dbo].[ReceivableInvoice]([id]),
        [payableInvoiceId] INT NULL FOREIGN KEY REFERENCES [dbo].[PayableInvoice]([id]),
        [concept] NVARCHAR(MAX) NOT NULL,
        [subtotal] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [taxAmount] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [totalAmount] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [appliedAmount] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [balanceAmount] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [status] NVARCHAR(20) NOT NULL DEFAULT 'POSTED',
        [journalEntryId] INT NULL FOREIGN KEY REFERENCES [dbo].[JournalEntry]([id]),
        [createdById] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[User]([id]),
        [observations] NVARCHAR(MAX) NULL,
        [createdAt] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        [updatedAt] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT [UQ_CreditDebitNote_doc_num] UNIQUE ([documentTypeId], [noteNumber])
    );
    CREATE INDEX [IX_CreditDebitNote_noteType] ON [dbo].[CreditDebitNote]([noteType]);
END;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AdvancePayment]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[AdvancePayment] (
        [id] INT IDENTITY(1,1) PRIMARY KEY,
        [companyId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[Company]([id]),
        [advanceType] NVARCHAR(20) NOT NULL,
        [thirdPartyId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[ThirdParty]([id]),
        [treasuryMovementId] INT NULL FOREIGN KEY REFERENCES [dbo].[TreasuryMovement]([id]),
        [advanceDate] DATETIME2 NOT NULL,
        [amount] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [usedAmount] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [balanceAmount] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [status] NVARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
        [concept] NVARCHAR(MAX) NOT NULL,
        [createdById] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[User]([id]),
        [createdAt] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        [updatedAt] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
END;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ReceivablePaymentAllocation]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[ReceivablePaymentAllocation] (
        [id] INT IDENTITY(1,1) PRIMARY KEY,
        [receivableInvoiceId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[ReceivableInvoice]([id]),
        [receivableInstallmentId] INT NULL FOREIGN KEY REFERENCES [dbo].[ReceivableInstallment]([id]),
        [treasuryMovementId] INT NULL FOREIGN KEY REFERENCES [dbo].[TreasuryMovement]([id]),
        [advancePaymentId] INT NULL FOREIGN KEY REFERENCES [dbo].[AdvancePayment]([id]),
        [creditDebitNoteId] INT NULL FOREIGN KEY REFERENCES [dbo].[CreditDebitNote]([id]),
        [allocationDate] DATETIME2 NOT NULL,
        [amount] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [discountAmount] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [withholdingAdjustment] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [observations] NVARCHAR(MAX) NULL,
        [createdAt] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
END;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PayablePaymentAllocation]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[PayablePaymentAllocation] (
        [id] INT IDENTITY(1,1) PRIMARY KEY,
        [payableInvoiceId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[PayableInvoice]([id]),
        [payableInstallmentId] INT NULL FOREIGN KEY REFERENCES [dbo].[PayableInstallment]([id]),
        [treasuryMovementId] INT NULL FOREIGN KEY REFERENCES [dbo].[TreasuryMovement]([id]),
        [advancePaymentId] INT NULL FOREIGN KEY REFERENCES [dbo].[AdvancePayment]([id]),
        [creditDebitNoteId] INT NULL FOREIGN KEY REFERENCES [dbo].[CreditDebitNote]([id]),
        [allocationDate] DATETIME2 NOT NULL,
        [amount] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [discountAmount] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [observations] NVARCHAR(MAX) NULL,
        [createdAt] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
END;
