-- ============================================================================
-- KOREX_CONTABILIDAD - TABLAS DDL PARA ACTIVOS FIJOS Y DEPRECIACIONES (FASE 6)
-- MOTOR: SQL Server (T-SQL)
-- ============================================================================

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FixedAssetCategory]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[FixedAssetCategory] (
        [id] INT IDENTITY(1,1) PRIMARY KEY,
        [code] NVARCHAR(50) NOT NULL UNIQUE,
        [name] NVARCHAR(100) NOT NULL,
        [defaultUsefulLifeMonths] INT NOT NULL DEFAULT 60,
        [accountAssetId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[Account]([id]),
        [accountAccumDeprId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[Account]([id]),
        [accountExpenseDeprId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[Account]([id]),
        [isActive] BIT NOT NULL DEFAULT 1,
        [createdAt] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        [updatedAt] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
END;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FixedAsset]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[FixedAsset] (
        [id] INT IDENTITY(1,1) PRIMARY KEY,
        [companyId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[Company]([id]),
        [categoryId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[FixedAssetCategory]([id]),
        [code] NVARCHAR(50) NOT NULL UNIQUE,
        [name] NVARCHAR(150) NOT NULL,
        [description] NVARCHAR(MAX) NULL,
        [serialNumber] NVARCHAR(100) NULL,
        [purchaseDate] DATETIME2 NOT NULL,
        [activationDate] DATETIME2 NOT NULL,
        [acquisitionCost] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [residualValue] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [usefulLifeMonths] INT NOT NULL DEFAULT 60,
        [depreciatedMonths] INT NOT NULL DEFAULT 0,
        [accumulatedDepreciation] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [netBookValue] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [monthlyDepreciation] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [costCenterId] INT NULL FOREIGN KEY REFERENCES [dbo].[CostCenter]([id]),
        [responsibleThirdPartyId] INT NULL FOREIGN KEY REFERENCES [dbo].[ThirdParty]([id]),
        [location] NVARCHAR(150) NULL,
        [status] NVARCHAR(30) NOT NULL DEFAULT 'ACTIVE',
        [createdById] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[User]([id]),
        [createdAt] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        [updatedAt] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
    CREATE INDEX [IX_FixedAsset_categoryId] ON [dbo].[FixedAsset]([categoryId]);
END;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FixedAssetDepreciation]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[FixedAssetDepreciation] (
        [id] INT IDENTITY(1,1) PRIMARY KEY,
        [fixedAssetId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[FixedAsset]([id]) ON DELETE CASCADE,
        [year] INT NOT NULL,
        [month] INT NOT NULL,
        [amount] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [accumulatedAmount] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [netBookValue] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [journalEntryId] INT NULL FOREIGN KEY REFERENCES [dbo].[JournalEntry]([id]),
        [createdAt] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT [UQ_FixedAssetDepreciation_period] UNIQUE ([fixedAssetId], [year], [month])
    );
END;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FixedAssetImprovement]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[FixedAssetImprovement] (
        [id] INT IDENTITY(1,1) PRIMARY KEY,
        [fixedAssetId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[FixedAsset]([id]) ON DELETE CASCADE,
        [improvementDate] DATETIME2 NOT NULL,
        [description] NVARCHAR(MAX) NOT NULL,
        [amount] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [additionalMonths] INT NOT NULL DEFAULT 0,
        [journalEntryId] INT NULL FOREIGN KEY REFERENCES [dbo].[JournalEntry]([id]),
        [createdById] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[User]([id]),
        [createdAt] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
END;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FixedAssetDisposal]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[FixedAssetDisposal] (
        [id] INT IDENTITY(1,1) PRIMARY KEY,
        [fixedAssetId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[FixedAsset]([id]) ON DELETE CASCADE,
        [disposalDate] DATETIME2 NOT NULL,
        [disposalType] NVARCHAR(30) NOT NULL,
        [salePrice] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [acquisitionCostAtDisposal] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [accumulatedDeprAtDisposal] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [netGainLoss] DECIMAL(18, 4) NOT NULL DEFAULT 0,
        [journalEntryId] INT NULL FOREIGN KEY REFERENCES [dbo].[JournalEntry]([id]),
        [reason] NVARCHAR(MAX) NOT NULL,
        [createdById] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[User]([id]),
        [createdAt] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
END;
