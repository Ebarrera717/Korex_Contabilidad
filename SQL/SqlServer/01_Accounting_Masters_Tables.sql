-- ============================================================================
-- KOREX_CONTABILIDAD - DDL DE TABLAS MAESTRAS (SQL SERVER / T-SQL)
-- Archivo: SQL/SqlServer/01_Accounting_Masters_Tables.sql
-- ============================================================================

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Company]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Company] (
        [id] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [code] NVARCHAR(50) NOT NULL UNIQUE,
        [businessName] NVARCHAR(255) NOT NULL,
        [tradeName] NVARCHAR(255) NULL,
        [documentType] NVARCHAR(20) NOT NULL CONSTRAINT DF_Company_docType DEFAULT 'NIT',
        [documentNumber] NVARCHAR(50) NOT NULL UNIQUE,
        [verificationDigit] NVARCHAR(2) NULL,
        [address] NVARCHAR(255) NULL,
        [city] NVARCHAR(100) NULL,
        [state] NVARCHAR(100) NULL,
        [country] NVARCHAR(100) NOT NULL CONSTRAINT DF_Company_country DEFAULT 'Colombia',
        [phone] NVARCHAR(50) NULL,
        [email] NVARCHAR(150) NULL,
        [legalRepresentative] NVARCHAR(255) NULL,
        [taxRegime] NVARCHAR(100) NULL,
        [fiscalResponsibilities] NVARCHAR(255) NULL,
        [economicActivityCode] NVARCHAR(20) NULL,
        [logo] VARBINARY(MAX) NULL,
        [isActive] BIT NOT NULL CONSTRAINT DF_Company_isActive DEFAULT 1,
        [createdAt] DATETIME2 NOT NULL CONSTRAINT DF_Company_createdAt DEFAULT GETDATE(),
        [updatedAt] DATETIME2 NOT NULL CONSTRAINT DF_Company_updatedAt DEFAULT GETDATE()
    );
END;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Role]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Role] (
        [id] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [name] NVARCHAR(100) NOT NULL UNIQUE,
        [description] NVARCHAR(255) NULL,
        [permissions] NVARCHAR(MAX) NULL,
        [isActive] BIT NOT NULL CONSTRAINT DF_Role_isActive DEFAULT 1,
        [createdAt] DATETIME2 NOT NULL CONSTRAINT DF_Role_createdAt DEFAULT GETDATE(),
        [updatedAt] DATETIME2 NOT NULL CONSTRAINT DF_Role_updatedAt DEFAULT GETDATE()
    );
END;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[User]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[User] (
        [id] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [name] NVARCHAR(150) NOT NULL,
        [email] NVARCHAR(150) NOT NULL UNIQUE,
        [passwordHash] NVARCHAR(255) NOT NULL,
        [roleId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[Role]([id]),
        [companyId] INT NULL FOREIGN KEY REFERENCES [dbo].[Company]([id]),
        [resetPasswordToken] NVARCHAR(255) NULL UNIQUE,
        [resetPasswordExpires] DATETIME2 NULL,
        [isActive] BIT NOT NULL CONSTRAINT DF_User_isActive DEFAULT 1,
        [createdAt] DATETIME2 NOT NULL CONSTRAINT DF_User_createdAt DEFAULT GETDATE(),
        [updatedAt] DATETIME2 NOT NULL CONSTRAINT DF_User_updatedAt DEFAULT GETDATE()
    );
END;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Account]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Account] (
        [id] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [code] NVARCHAR(30) NOT NULL UNIQUE,
        [name] NVARCHAR(255) NOT NULL,
        [level] INT NOT NULL,
        [nature] NVARCHAR(10) NOT NULL, -- 'DEBIT' o 'CREDIT'
        [allowsMovement] BIT NOT NULL CONSTRAINT DF_Account_allowsMovement DEFAULT 0,
        [requiresThirdParty] BIT NOT NULL CONSTRAINT DF_Account_reqThird DEFAULT 0,
        [requiresCostCenter] BIT NOT NULL CONSTRAINT DF_Account_reqCC DEFAULT 0,
        [parentId] INT NULL FOREIGN KEY REFERENCES [dbo].[Account]([id]),
        [isActive] BIT NOT NULL CONSTRAINT DF_Account_isActive DEFAULT 1,
        [createdAt] DATETIME2 NOT NULL CONSTRAINT DF_Account_createdAt DEFAULT GETDATE(),
        [updatedAt] DATETIME2 NOT NULL CONSTRAINT DF_Account_updatedAt DEFAULT GETDATE()
    );
    CREATE NONCLUSTERED INDEX [IX_Account_code] ON [dbo].[Account]([code]);
    CREATE NONCLUSTERED INDEX [IX_Account_level] ON [dbo].[Account]([level]);
    CREATE NONCLUSTERED INDEX [IX_Account_parentId] ON [dbo].[Account]([parentId]);
END;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ThirdParty]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[ThirdParty] (
        [id] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [documentType] NVARCHAR(20) NOT NULL CONSTRAINT DF_TP_docType DEFAULT 'NIT',
        [documentNumber] NVARCHAR(50) NOT NULL UNIQUE,
        [verificationDigit] NVARCHAR(2) NULL,
        [businessName] NVARCHAR(255) NULL,
        [firstName] NVARCHAR(100) NULL,
        [secondName] NVARCHAR(100) NULL,
        [firstLastName] NVARCHAR(100) NULL,
        [secondLastName] NVARCHAR(100) NULL,
        [fullName] NVARCHAR(255) NOT NULL,
        [personType] NVARCHAR(20) NOT NULL CONSTRAINT DF_TP_personType DEFAULT 'JURIDICA',
        [address] NVARCHAR(255) NULL,
        [city] NVARCHAR(100) NULL,
        [state] NVARCHAR(100) NULL,
        [country] NVARCHAR(100) NOT NULL CONSTRAINT DF_TP_country DEFAULT 'Colombia',
        [phone] NVARCHAR(50) NULL,
        [email] NVARCHAR(150) NULL,
        [isCustomer] BIT NOT NULL CONSTRAINT DF_TP_isCustomer DEFAULT 0,
        [isSupplier] BIT NOT NULL CONSTRAINT DF_TP_isSupplier DEFAULT 0,
        [isEmployee] BIT NOT NULL CONSTRAINT DF_TP_isEmployee DEFAULT 0,
        [isPartner] BIT NOT NULL CONSTRAINT DF_TP_isPartner DEFAULT 0,
        [isOther] BIT NOT NULL CONSTRAINT DF_TP_isOther DEFAULT 0,
        [taxRegime] NVARCHAR(100) NULL,
        [fiscalResponsibilities] NVARCHAR(255) NULL,
        [isActive] BIT NOT NULL CONSTRAINT DF_TP_isActive DEFAULT 1,
        [createdAt] DATETIME2 NOT NULL CONSTRAINT DF_TP_createdAt DEFAULT GETDATE(),
        [updatedAt] DATETIME2 NOT NULL CONSTRAINT DF_TP_updatedAt DEFAULT GETDATE()
    );
    CREATE NONCLUSTERED INDEX [IX_ThirdParty_document] ON [dbo].[ThirdParty]([documentNumber]);
    CREATE NONCLUSTERED INDEX [IX_ThirdParty_fullName] ON [dbo].[ThirdParty]([fullName]);
END;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CostCenter]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[CostCenter] (
        [id] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [code] NVARCHAR(30) NOT NULL UNIQUE,
        [name] NVARCHAR(150) NOT NULL,
        [level] INT NOT NULL CONSTRAINT DF_CC_level DEFAULT 1,
        [parentId] INT NULL FOREIGN KEY REFERENCES [dbo].[CostCenter]([id]),
        [isActive] BIT NOT NULL CONSTRAINT DF_CC_isActive DEFAULT 1,
        [createdAt] DATETIME2 NOT NULL CONSTRAINT DF_CC_createdAt DEFAULT GETDATE(),
        [updatedAt] DATETIME2 NOT NULL CONSTRAINT DF_CC_updatedAt DEFAULT GETDATE()
    );
    CREATE NONCLUSTERED INDEX [IX_CostCenter_code] ON [dbo].[CostCenter]([code]);
END;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Bank]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Bank] (
        [id] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [code] NVARCHAR(30) NOT NULL UNIQUE,
        [name] NVARCHAR(150) NOT NULL,
        [nit] NVARCHAR(50) NULL,
        [phone] NVARCHAR(50) NULL,
        [contactName] NVARCHAR(150) NULL,
        [isActive] BIT NOT NULL CONSTRAINT DF_Bank_isActive DEFAULT 1,
        [createdAt] DATETIME2 NOT NULL CONSTRAINT DF_Bank_createdAt DEFAULT GETDATE(),
        [updatedAt] DATETIME2 NOT NULL CONSTRAINT DF_Bank_updatedAt DEFAULT GETDATE()
    );
END;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BankAccount]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[BankAccount] (
        [id] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [companyId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[Company]([id]),
        [bankId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[Bank]([id]),
        [accountId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[Account]([id]),
        [accountNumber] NVARCHAR(50) NOT NULL,
        [accountType] NVARCHAR(30) NOT NULL CONSTRAINT DF_BA_type DEFAULT 'AHORROS',
        [currency] NVARCHAR(10) NOT NULL CONSTRAINT DF_BA_curr DEFAULT 'COP',
        [description] NVARCHAR(255) NULL,
        [isActive] BIT NOT NULL CONSTRAINT DF_BA_isActive DEFAULT 1,
        [createdAt] DATETIME2 NOT NULL CONSTRAINT DF_BA_createdAt DEFAULT GETDATE(),
        [updatedAt] DATETIME2 NOT NULL CONSTRAINT DF_BA_updatedAt DEFAULT GETDATE(),
        CONSTRAINT [UQ_BankAccount_num] UNIQUE ([bankId], [accountNumber])
    );
END;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DocumentType]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[DocumentType] (
        [id] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [code] NVARCHAR(20) NOT NULL UNIQUE,
        [name] NVARCHAR(150) NOT NULL,
        [prefix] NVARCHAR(10) NULL,
        [isAutomatic] BIT NOT NULL CONSTRAINT DF_DocType_isAuto DEFAULT 1,
        [isActive] BIT NOT NULL CONSTRAINT DF_DocType_isActive DEFAULT 1,
        [createdAt] DATETIME2 NOT NULL CONSTRAINT DF_DocType_createdAt DEFAULT GETDATE(),
        [updatedAt] DATETIME2 NOT NULL CONSTRAINT DF_DocType_updatedAt DEFAULT GETDATE()
    );
END;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Consecutive]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Consecutive] (
        [id] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [documentTypeId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[DocumentType]([id]),
        [prefix] NVARCHAR(10) NULL,
        [currentNumber] INT NOT NULL CONSTRAINT DF_Consec_curr DEFAULT 1,
        [initialNumber] INT NOT NULL CONSTRAINT DF_Consec_init DEFAULT 1,
        [finalNumber] INT NULL,
        [fiscalYear] INT NOT NULL,
        [isActive] BIT NOT NULL CONSTRAINT DF_Consec_isActive DEFAULT 1,
        [createdAt] DATETIME2 NOT NULL CONSTRAINT DF_Consec_createdAt DEFAULT GETDATE(),
        [updatedAt] DATETIME2 NOT NULL CONSTRAINT DF_Consec_updatedAt DEFAULT GETDATE(),
        CONSTRAINT [UQ_Consecutive_doc_year] UNIQUE ([documentTypeId], [fiscalYear], [prefix])
    );
END;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FiscalPeriod]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[FiscalPeriod] (
        [id] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [year] INT NOT NULL,
        [month] INT NOT NULL,
        [startDate] DATETIME2 NOT NULL,
        [endDate] DATETIME2 NOT NULL,
        [status] NVARCHAR(20) NOT NULL CONSTRAINT DF_FP_status DEFAULT 'OPEN',
        [closedAt] DATETIME2 NULL,
        [closedBy] INT NULL,
        [createdAt] DATETIME2 NOT NULL CONSTRAINT DF_FP_createdAt DEFAULT GETDATE(),
        [updatedAt] DATETIME2 NOT NULL CONSTRAINT DF_FP_updatedAt DEFAULT GETDATE(),
        CONSTRAINT [UQ_FiscalPeriod_ym] UNIQUE ([year], [month])
    );
END;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TaxConcept]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[TaxConcept] (
        [id] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [code] NVARCHAR(30) NOT NULL UNIQUE,
        [name] NVARCHAR(150) NOT NULL,
        [type] NVARCHAR(30) NOT NULL,
        [ratePercentage] DECIMAL(6, 4) NOT NULL,
        [minimumBaseAmount] DECIMAL(18, 4) NOT NULL CONSTRAINT DF_Tax_minBase DEFAULT 0,
        [accountDebitId] INT NULL FOREIGN KEY REFERENCES [dbo].[Account]([id]),
        [accountCreditId] INT NULL FOREIGN KEY REFERENCES [dbo].[Account]([id]),
        [isActive] BIT NOT NULL CONSTRAINT DF_Tax_isActive DEFAULT 1,
        [createdAt] DATETIME2 NOT NULL CONSTRAINT DF_Tax_createdAt DEFAULT GETDATE(),
        [updatedAt] DATETIME2 NOT NULL CONSTRAINT DF_Tax_updatedAt DEFAULT GETDATE()
    );
END;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SystemParameter]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[SystemParameter] (
        [id] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [code] NVARCHAR(100) NOT NULL UNIQUE,
        [name] NVARCHAR(150) NOT NULL,
        [value] NVARCHAR(MAX) NULL,
        [description] NVARCHAR(255) NULL,
        [category] NVARCHAR(50) NOT NULL CONSTRAINT DF_SysParam_cat DEFAULT 'GENERAL',
        [isEditable] BIT NOT NULL CONSTRAINT DF_SysParam_edit DEFAULT 1,
        [isEncrypted] BIT NOT NULL CONSTRAINT DF_SysParam_enc DEFAULT 0,
        [createdAt] DATETIME2 NOT NULL CONSTRAINT DF_SysParam_createdAt DEFAULT GETDATE(),
        [updatedAt] DATETIME2 NOT NULL CONSTRAINT DF_SysParam_updatedAt DEFAULT GETDATE()
    );
END;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TraceabilityLog]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[TraceabilityLog] (
        [id] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [code] NVARCHAR(100) NOT NULL,
        [userId] INT NULL,
        [origin] NVARCHAR(50) NOT NULL CONSTRAINT DF_Trace_origin DEFAULT 'WEB',
        [module] NVARCHAR(100) NOT NULL,
        [screen] NVARCHAR(100) NULL,
        [action] NVARCHAR(100) NOT NULL,
        [process] NVARCHAR(150) NULL,
        [eventType] NVARCHAR(50) NOT NULL,
        [stepName] NVARCHAR(150) NOT NULL,
        [spName] NVARCHAR(150) NULL,
        [endpoint] NVARCHAR(255) NULL,
        [durationMs] INT NOT NULL CONSTRAINT DF_Trace_dur DEFAULT 0,
        [status] NVARCHAR(50) NOT NULL CONSTRAINT DF_Trace_stat DEFAULT 'SUCCESS',
        [inputData] NVARCHAR(MAX) NULL,
        [outputData] NVARCHAR(MAX) NULL,
        [techMessage] NVARCHAR(MAX) NULL,
        [functionalMessage] NVARCHAR(MAX) NULL,
        [stackTrace] NVARCHAR(MAX) NULL,
        [affectedId] NVARCHAR(100) NULL,
        [createdAt] DATETIME2 NOT NULL CONSTRAINT DF_Trace_createdAt DEFAULT GETDATE()
    );
    CREATE NONCLUSTERED INDEX [IX_Traceability_code] ON [dbo].[TraceabilityLog]([code]);
    CREATE NONCLUSTERED INDEX [IX_Traceability_module] ON [dbo].[TraceabilityLog]([module]);
END;
