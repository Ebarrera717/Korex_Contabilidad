-- ============================================================================
-- PROYECTO: KOREX_CONTABILIDAD
-- MODULO: FASE 8 - INTEGRACIONES E INTERFACES DE DATOS (TABLAS DDL)
-- MOTOR: Microsoft SQL Server (Korex_Contabilidad_sql)
-- ============================================================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DataInterfaceTemplate' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.[DataInterfaceTemplate] (
        [id] INT IDENTITY(1,1) PRIMARY KEY,
        [code] NVARCHAR(50) NOT NULL UNIQUE,
        [name] NVARCHAR(150) NOT NULL,
        [category] NVARCHAR(50) NOT NULL,
        [formatType] NVARCHAR(20) NOT NULL,
        [mappingConfig] NVARCHAR(MAX) NULL,
        [sampleFile] VARBINARY(MAX) NULL,
        [isActive] BIT NOT NULL CONSTRAINT DF_DataInterfaceTemplate_isActive DEFAULT 1,
        [createdAt] DATETIME2 NOT NULL CONSTRAINT DF_DataInterfaceTemplate_createdAt DEFAULT SYSUTCDATETIME(),
        [updatedAt] DATETIME2 NOT NULL CONSTRAINT DF_DataInterfaceTemplate_updatedAt DEFAULT SYSUTCDATETIME()
    );
END;

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'BatchImportJob' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.[BatchImportJob] (
        [id] INT IDENTITY(1,1) PRIMARY KEY,
        [jobCode] NVARCHAR(50) NOT NULL UNIQUE,
        [companyId] INT NOT NULL,
        [templateCode] NVARCHAR(50) NOT NULL,
        [interfaceType] NVARCHAR(50) NOT NULL,
        [fileName] NVARCHAR(255) NULL,
        [fileSizeBytes] INT NULL,
        [status] NVARCHAR(20) NOT NULL CONSTRAINT DF_BatchImportJob_status DEFAULT 'PENDING',
        [totalRows] INT NOT NULL CONSTRAINT DF_BatchImportJob_totalRows DEFAULT 0,
        [processedRows] INT NOT NULL CONSTRAINT DF_BatchImportJob_processedRows DEFAULT 0,
        [successRows] INT NOT NULL CONSTRAINT DF_BatchImportJob_successRows DEFAULT 0,
        [failedRows] INT NOT NULL CONSTRAINT DF_BatchImportJob_failedRows DEFAULT 0,
        [errorsSummary] NVARCHAR(MAX) NULL,
        [startedAt] DATETIME2 NULL,
        [completedAt] DATETIME2 NULL,
        [userId] INT NULL,
        [createdAt] DATETIME2 NOT NULL CONSTRAINT DF_BatchImportJob_createdAt DEFAULT SYSUTCDATETIME(),
        [updatedAt] DATETIME2 NOT NULL CONSTRAINT DF_BatchImportJob_updatedAt DEFAULT SYSUTCDATETIME()
    );

    CREATE INDEX IX_BatchImportJob_companyId ON dbo.[BatchImportJob]([companyId]);
    CREATE INDEX IX_BatchImportJob_status ON dbo.[BatchImportJob]([status]);
    CREATE INDEX IX_BatchImportJob_createdAt ON dbo.[BatchImportJob]([createdAt]);
END;

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ExternalIntegrationEndpoint' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.[ExternalIntegrationEndpoint] (
        [id] INT IDENTITY(1,1) PRIMARY KEY,
        [code] NVARCHAR(50) NOT NULL UNIQUE,
        [systemName] NVARCHAR(150) NOT NULL,
        [adapterType] NVARCHAR(50) NOT NULL CONSTRAINT DF_ExtEndpoint_adapterType DEFAULT 'API_REST',
        [endpointUrl] NVARCHAR(500) NULL,
        [authType] NVARCHAR(50) NOT NULL CONSTRAINT DF_ExtEndpoint_authType DEFAULT 'BEARER_TOKEN',
        [credentialsEnc] NVARCHAR(MAX) NULL,
        [subscribedEvents] NVARCHAR(MAX) NULL,
        [isActive] BIT NOT NULL CONSTRAINT DF_ExtEndpoint_isActive DEFAULT 1,
        [createdAt] DATETIME2 NOT NULL CONSTRAINT DF_ExtEndpoint_createdAt DEFAULT SYSUTCDATETIME(),
        [updatedAt] DATETIME2 NOT NULL CONSTRAINT DF_ExtEndpoint_updatedAt DEFAULT SYSUTCDATETIME()
    );
END;

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'IntegrationTransaction' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.[IntegrationTransaction] (
        [id] INT IDENTITY(1,1) PRIMARY KEY,
        [txCode] NVARCHAR(50) NOT NULL UNIQUE,
        [endpointCode] NVARCHAR(50) NOT NULL,
        [direction] NVARCHAR(20) NOT NULL,
        [eventType] NVARCHAR(50) NOT NULL,
        [requestPayload] NVARCHAR(MAX) NULL,
        [responsePayload] NVARCHAR(MAX) NULL,
        [httpStatus] INT NULL,
        [durationMs] INT NOT NULL CONSTRAINT DF_IntTx_durationMs DEFAULT 0,
        [status] NVARCHAR(20) NOT NULL CONSTRAINT DF_IntTx_status DEFAULT 'SUCCESS',
        [errorMessage] NVARCHAR(MAX) NULL,
        [createdAt] DATETIME2 NOT NULL CONSTRAINT DF_IntTx_createdAt DEFAULT SYSUTCDATETIME()
    );

    CREATE INDEX IX_IntegrationTransaction_endpointCode ON dbo.[IntegrationTransaction]([endpointCode]);
    CREATE INDEX IX_IntegrationTransaction_direction ON dbo.[IntegrationTransaction]([direction]);
    CREATE INDEX IX_IntegrationTransaction_status ON dbo.[IntegrationTransaction]([status]);
    CREATE INDEX IX_IntegrationTransaction_createdAt ON dbo.[IntegrationTransaction]([createdAt]);
END;
