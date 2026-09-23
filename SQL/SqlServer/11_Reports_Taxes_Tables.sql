-- ============================================================================
-- KOREX_CONTABILIDAD - TABLAS DDL PARA REPORTES, IMPUESTOS Y EXÓGENA DIAN (FASE 7)
-- MOTOR: SQL Server (T-SQL)
-- ============================================================================

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ExogenaConcept]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[ExogenaConcept] (
        [id] INT IDENTITY(1,1) PRIMARY KEY,
        [formatNumber] NVARCHAR(20) NOT NULL,
        [code] NVARCHAR(20) NOT NULL,
        [name] NVARCHAR(255) NOT NULL,
        [columnMapping] NVARCHAR(MAX) NULL,
        [isActive] BIT NOT NULL DEFAULT 1,
        [createdAt] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        [updatedAt] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT [UQ_ExogenaConcept_format_code] UNIQUE ([formatNumber], [code])
    );
END;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ExogenaFormatConfig]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[ExogenaFormatConfig] (
        [id] INT IDENTITY(1,1) PRIMARY KEY,
        [companyId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[Company]([id]),
        [formatNumber] NVARCHAR(20) NOT NULL,
        [conceptId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[ExogenaConcept]([id]),
        [accountId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[Account]([id]),
        [columnType] NVARCHAR(50) NOT NULL,
        [isActive] BIT NOT NULL DEFAULT 1,
        [createdAt] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT [UQ_ExogenaFormatConfig_unique] UNIQUE ([companyId], [formatNumber], [conceptId], [accountId], [columnType])
    );
END;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TaxDeclarationPeriod]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[TaxDeclarationPeriod] (
        [id] INT IDENTITY(1,1) PRIMARY KEY,
        [companyId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[Company]([id]),
        [formType] NVARCHAR(30) NOT NULL,
        [year] INT NOT NULL,
        [periodNumber] INT NOT NULL,
        [totalBaseAmount] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [totalTaxAmount] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [totalWithholdingAmount] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [totalPayableAmount] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [breakdown] NVARCHAR(MAX) NULL,
        [status] NVARCHAR(20) NOT NULL DEFAULT 'DRAFT',
        [filedAt] DATETIME2 NULL,
        [createdById] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[User]([id]),
        [createdAt] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        [updatedAt] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT [UQ_TaxDeclarationPeriod_period] UNIQUE ([companyId], [formType], [year], [periodNumber])
    );
END;
