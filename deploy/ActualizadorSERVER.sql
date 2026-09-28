-- ============================================================================
-- KOREX_CONTABILIDAD - SCRIPT CONSOLIDADO DE ACTUALIZACION (SQL SERVER)
-- GENERADO AUTOMATICAMENTE: 2026-09-25T12:54:58.724Z
-- ============================================================================

-- --- OBJETO T-SQL: 01_Accounting_Masters_Tables.sql ---
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


-- --- OBJETO T-SQL: 02_Accounting_Seeds.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - SEMILLAS DE MAESTROS CONTABLES (SQL SERVER / T-SQL)
-- Archivo: SQL/SqlServer/02_Accounting_Seeds.sql
-- ============================================================================

-- 1. Roles por Defecto
SET IDENTITY_INSERT [dbo].[Role] ON;
IF NOT EXISTS (SELECT 1 FROM [dbo].[Role] WHERE [id] = 1)
    INSERT INTO [dbo].[Role] ([id], [name], [description], [permissions], [isActive])
    VALUES (1, 'SUPERADMINISTRADOR', 'Acceso total y configuración del sistema contable', '{"modules": {"accounting": true, "masters": true, "periods": true, "reports": true, "treasury": true, "receivables": true, "payables": true, "config": true, "manual": true}}', 1);

IF NOT EXISTS (SELECT 1 FROM [dbo].[Role] WHERE [id] = 2)
    INSERT INTO [dbo].[Role] ([id], [name], [description], [permissions], [isActive])
    VALUES (2, 'CONTADOR_GENERAL', 'Gestión de comprobantes, balances, cierres y reportes contables', '{"modules": {"accounting": true, "masters": true, "periods": true, "reports": true, "treasury": true, "receivables": true, "payables": true, "config": false, "manual": true}}', 1);

IF NOT EXISTS (SELECT 1 FROM [dbo].[Role] WHERE [id] = 3)
    INSERT INTO [dbo].[Role] ([id], [name], [description], [permissions], [isActive])
    VALUES (3, 'AUXILIAR_CONTABLE', 'Elaboración y edición de comprobantes en borrador', '{"modules": {"accounting": true, "masters": false, "periods": false, "reports": true, "treasury": false, "receivables": false, "payables": false, "config": false, "manual": true}}', 1);

IF NOT EXISTS (SELECT 1 FROM [dbo].[Role] WHERE [id] = 4)
    INSERT INTO [dbo].[Role] ([id], [name], [description], [permissions], [isActive])
    VALUES (4, 'AUDITOR_FISCAL', 'Solo consulta y auditoría de libros y comprobantes', '{"modules": {"accounting": true, "masters": false, "periods": false, "reports": true, "treasury": false, "receivables": false, "payables": false, "config": false, "manual": true}}', 1);
SET IDENTITY_INSERT [dbo].[Role] OFF;

-- 2. Empresa Demostrativa por Defecto
SET IDENTITY_INSERT [dbo].[Company] ON;
IF NOT EXISTS (SELECT 1 FROM [dbo].[Company] WHERE [id] = 1)
    INSERT INTO [dbo].[Company] ([id], [code], [businessName], [tradeName], [documentType], [documentNumber], [verificationDigit], [city], [state], [country], [email], [taxRegime], [isActive])
    VALUES (1, 'EMP-01', 'EMPRESA DEMO CONTABLE S.A.S.', 'KOREX CONTABILIDAD DEMO', 'NIT', '900123456', '7', 'Bogotá D.C.', 'Cundinamarca', 'Colombia', 'contabilidad@korex.com.co', 'Régimen Ordinario', 1);
SET IDENTITY_INSERT [dbo].[Company] OFF;

-- 3. Tipos de Documento Contable Estándar en Colombia
SET IDENTITY_INSERT [dbo].[DocumentType] ON;
IF NOT EXISTS (SELECT 1 FROM [dbo].[DocumentType] WHERE [code] = 'CC')
    INSERT INTO [dbo].[DocumentType] ([id], [code], [name], [prefix], [isAutomatic], [isActive]) VALUES (1, 'CC', 'Comprobante de Contabilidad / Diario', 'CC', 1, 1);
IF NOT EXISTS (SELECT 1 FROM [dbo].[DocumentType] WHERE [code] = 'CE')
    INSERT INTO [dbo].[DocumentType] ([id], [code], [name], [prefix], [isAutomatic], [isActive]) VALUES (2, 'CE', 'Comprobante de Egreso / Pago', 'CE', 1, 1);
IF NOT EXISTS (SELECT 1 FROM [dbo].[DocumentType] WHERE [code] = 'CI')
    INSERT INTO [dbo].[DocumentType] ([id], [code], [name], [prefix], [isAutomatic], [isActive]) VALUES (3, 'CI', 'Comprobante de Ingreso / Recibo de Caja', 'CI', 1, 1);
IF NOT EXISTS (SELECT 1 FROM [dbo].[DocumentType] WHERE [code] = 'NC')
    INSERT INTO [dbo].[DocumentType] ([id], [code], [name], [prefix], [isAutomatic], [isActive]) VALUES (4, 'NC', 'Nota Crédito', 'NC', 1, 1);
IF NOT EXISTS (SELECT 1 FROM [dbo].[DocumentType] WHERE [code] = 'ND')
    INSERT INTO [dbo].[DocumentType] ([id], [code], [name], [prefix], [isAutomatic], [isActive]) VALUES (5, 'ND', 'Nota Débito', 'ND', 1, 1);
IF NOT EXISTS (SELECT 1 FROM [dbo].[DocumentType] WHERE [code] = 'FV')
    INSERT INTO [dbo].[DocumentType] ([id], [code], [name], [prefix], [isAutomatic], [isActive]) VALUES (6, 'FV', 'Factura de Venta', 'FV', 1, 1);
IF NOT EXISTS (SELECT 1 FROM [dbo].[DocumentType] WHERE [code] = 'DS')
    INSERT INTO [dbo].[DocumentType] ([id], [code], [name], [prefix], [isAutomatic], [isActive]) VALUES (7, 'DS', 'Documento Soporte en Adquisiciones', 'DS', 1, 1);
IF NOT EXISTS (SELECT 1 FROM [dbo].[DocumentType] WHERE [code] = 'CZ')
    INSERT INTO [dbo].[DocumentType] ([id], [code], [name], [prefix], [isAutomatic], [isActive]) VALUES (8, 'CZ', 'Comprobante de Cierre Contable', 'CZ', 1, 1);
IF NOT EXISTS (SELECT 1 FROM [dbo].[DocumentType] WHERE [code] = 'AJ')
    INSERT INTO [dbo].[DocumentType] ([id], [code], [name], [prefix], [isAutomatic], [isActive]) VALUES (9, 'AJ', 'Comprobante de Ajustes / Reclasificaciones', 'AJ', 1, 1);
SET IDENTITY_INSERT [dbo].[DocumentType] OFF;

-- 4. Plan Único de Cuentas (PUC) Colombiano Base
IF NOT EXISTS (SELECT 1 FROM [dbo].[Account] WHERE [code] = '1')
    INSERT INTO [dbo].[Account] ([code], [name], [level], [nature], [allowsMovement], [requiresThirdParty], [requiresCostCenter], [parentId], [isActive])
    VALUES ('1', 'ACTIVO', 1, 'DEBIT', 0, 0, 0, NULL, 1);
IF NOT EXISTS (SELECT 1 FROM [dbo].[Account] WHERE [code] = '2')
    INSERT INTO [dbo].[Account] ([code], [name], [level], [nature], [allowsMovement], [requiresThirdParty], [requiresCostCenter], [parentId], [isActive])
    VALUES ('2', 'PASIVO', 1, 'CREDIT', 0, 0, 0, NULL, 1);
IF NOT EXISTS (SELECT 1 FROM [dbo].[Account] WHERE [code] = '3')
    INSERT INTO [dbo].[Account] ([code], [name], [level], [nature], [allowsMovement], [requiresThirdParty], [requiresCostCenter], [parentId], [isActive])
    VALUES ('3', 'PATRIMONIO', 1, 'CREDIT', 0, 0, 0, NULL, 1);
IF NOT EXISTS (SELECT 1 FROM [dbo].[Account] WHERE [code] = '4')
    INSERT INTO [dbo].[Account] ([code], [name], [level], [nature], [allowsMovement], [requiresThirdParty], [requiresCostCenter], [parentId], [isActive])
    VALUES ('4', 'INGRESOS', 1, 'CREDIT', 0, 0, 0, NULL, 1);
IF NOT EXISTS (SELECT 1 FROM [dbo].[Account] WHERE [code] = '5')
    INSERT INTO [dbo].[Account] ([code], [name], [level], [nature], [allowsMovement], [requiresThirdParty], [requiresCostCenter], [parentId], [isActive])
    VALUES ('5', 'GASTOS', 1, 'DEBIT', 0, 0, 0, NULL, 1);
IF NOT EXISTS (SELECT 1 FROM [dbo].[Account] WHERE [code] = '6')
    INSERT INTO [dbo].[Account] ([code], [name], [level], [nature], [allowsMovement], [requiresThirdParty], [requiresCostCenter], [parentId], [isActive])
    VALUES ('6', 'COSTOS DE VENTAS', 1, 'DEBIT', 0, 0, 0, NULL, 1);

-- Subcuentas
DECLARE @p1 INT = (SELECT [id] FROM [dbo].[Account] WHERE [code] = '1');
IF NOT EXISTS (SELECT 1 FROM [dbo].[Account] WHERE [code] = '11')
    INSERT INTO [dbo].[Account] ([code], [name], [level], [nature], [allowsMovement], [requiresThirdParty], [requiresCostCenter], [parentId], [isActive])
    VALUES ('11', 'DISPONIBLE', 2, 'DEBIT', 0, 0, 0, @p1, 1);

DECLARE @p11 INT = (SELECT [id] FROM [dbo].[Account] WHERE [code] = '11');
IF NOT EXISTS (SELECT 1 FROM [dbo].[Account] WHERE [code] = '1105')
    INSERT INTO [dbo].[Account] ([code], [name], [level], [nature], [allowsMovement], [requiresThirdParty], [requiresCostCenter], [parentId], [isActive])
    VALUES ('1105', 'CAJA', 3, 'DEBIT', 0, 0, 0, @p11, 1);

DECLARE @p1105 INT = (SELECT [id] FROM [dbo].[Account] WHERE [code] = '1105');
IF NOT EXISTS (SELECT 1 FROM [dbo].[Account] WHERE [code] = '110505')
    INSERT INTO [dbo].[Account] ([code], [name], [level], [nature], [allowsMovement], [requiresThirdParty], [requiresCostCenter], [parentId], [isActive])
    VALUES ('110505', 'CAJA GENERAL', 4, 'DEBIT', 1, 1, 0, @p1105, 1);

-- 5. Centros de Costo Iniciales
SET IDENTITY_INSERT [dbo].[CostCenter] ON;
IF NOT EXISTS (SELECT 1 FROM [dbo].[CostCenter] WHERE [code] = '01')
    INSERT INTO [dbo].[CostCenter] ([id], [code], [name], [level], [isActive]) VALUES (1, '01', 'ADMINISTRACION GENERAL', 1, 1);
IF NOT EXISTS (SELECT 1 FROM [dbo].[CostCenter] WHERE [code] = '02')
    INSERT INTO [dbo].[CostCenter] ([id], [code], [name], [level], [isActive]) VALUES (2, '02', 'VENTAS Y COMERCIAL', 1, 1);
IF NOT EXISTS (SELECT 1 FROM [dbo].[CostCenter] WHERE [code] = '03')
    INSERT INTO [dbo].[CostCenter] ([id], [code], [name], [level], [isActive]) VALUES (3, '03', 'OPERACIONES Y SERVICIOS', 1, 1);
SET IDENTITY_INSERT [dbo].[CostCenter] OFF;

-- 6. Bancos Base de Colombia
SET IDENTITY_INSERT [dbo].[Bank] ON;
IF NOT EXISTS (SELECT 1 FROM [dbo].[Bank] WHERE [code] = '007')
    INSERT INTO [dbo].[Bank] ([id], [code], [name], [nit], [isActive]) VALUES (1, '007', 'BANCOLOMBIA S.A.', '890903938-8', 1);
IF NOT EXISTS (SELECT 1 FROM [dbo].[Bank] WHERE [code] = '001')
    INSERT INTO [dbo].[Bank] ([id], [code], [name], [nit], [isActive]) VALUES (2, '001', 'BANCO DE BOGOTA', '860002964-4', 1);
IF NOT EXISTS (SELECT 1 FROM [dbo].[Bank] WHERE [code] = '051')
    INSERT INTO [dbo].[Bank] ([id], [code], [name], [nit], [isActive]) VALUES (3, '051', 'DAVIVIENDA S.A.', '860034313-7', 1);
SET IDENTITY_INSERT [dbo].[Bank] OFF;


-- --- OBJETO T-SQL: 03_Functions_And_SPs.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTOS Y FUNCIONES T-SQL (SQL SERVER)
-- Archivo: SQL/SqlServer/03_Functions_And_SPs.sql
-- ============================================================================

-- 1. spCompanyGuardar
CREATE OR ALTER PROCEDURE [dbo].[spCompanyGuardar]
    @p_id INT = NULL,
    @p_code NVARCHAR(50),
    @p_business_name NVARCHAR(255),
    @p_trade_name NVARCHAR(255) = NULL,
    @p_document_type NVARCHAR(20) = 'NIT',
    @p_document_number NVARCHAR(50),
    @p_verification_digit NVARCHAR(2) = NULL,
    @p_address NVARCHAR(255) = NULL,
    @p_city NVARCHAR(100) = NULL,
    @p_state NVARCHAR(100) = NULL,
    @p_country NVARCHAR(100) = 'Colombia',
    @p_phone NVARCHAR(50) = NULL,
    @p_email NVARCHAR(150) = NULL,
    @p_legal_rep NVARCHAR(255) = NULL,
    @p_tax_regime NVARCHAR(100) = NULL,
    @p_fiscal_resp NVARCHAR(255) = NULL,
    @p_ciiu NVARCHAR(20) = NULL,
    @p_is_active BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    IF @p_id IS NULL OR @p_id = 0
    BEGIN
        INSERT INTO [dbo].[Company] (
            [code], [businessName], [tradeName], [documentType], [documentNumber],
            [verificationDigit], [address], [city], [state], [country], [phone], [email],
            [legalRepresentative], [taxRegime], [fiscalResponsibilities],
            [economicActivityCode], [isActive], [createdAt], [updatedAt]
        ) VALUES (
            @p_code, @p_business_name, @p_trade_name, ISNULL(@p_document_type, 'NIT'), @p_document_number,
            @p_verification_digit, @p_address, @p_city, @p_state, ISNULL(@p_country, 'Colombia'), @p_phone, @p_email,
            @p_legal_rep, @p_tax_regime, @p_fiscal_resp,
            @p_ciiu, ISNULL(@p_is_active, 1), GETDATE(), GETDATE()
        );
    END
    ELSE
    BEGIN
        UPDATE [dbo].[Company]
        SET 
            [code] = @p_code,
            [businessName] = @p_business_name,
            [tradeName] = @p_trade_name,
            [documentType] = ISNULL(@p_document_type, 'NIT'),
            [documentNumber] = @p_document_number,
            [verificationDigit] = @p_verification_digit,
            [address] = @p_address,
            [city] = @p_city,
            [state] = @p_state,
            [country] = ISNULL(@p_country, 'Colombia'),
            [phone] = @p_phone,
            [email] = @p_email,
            [legalRepresentative] = @p_legal_rep,
            [taxRegime] = @p_tax_regime,
            [fiscalResponsibilities] = @p_fiscal_resp,
            [economicActivityCode] = @p_ciiu,
            [isActive] = ISNULL(@p_is_active, [isActive]),
            [updatedAt] = GETDATE()
        WHERE [id] = @p_id;
    END
END;
GO

-- 2. spPucGuardar
CREATE OR ALTER PROCEDURE [dbo].[spPucGuardar]
    @p_id INT = NULL,
    @p_code NVARCHAR(30),
    @p_name NVARCHAR(255),
    @p_level INT,
    @p_nature NVARCHAR(10),
    @p_allows_movement BIT = 0,
    @p_requires_third BIT = 0,
    @p_requires_cc BIT = 0,
    @p_parent_id INT = NULL,
    @p_is_active BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_clean_code NVARCHAR(30) = RTRIM(LTRIM(@p_code));
    DECLARE @v_parent_id INT = @p_parent_id;

    IF @v_parent_id IS NULL AND LEN(@v_clean_code) > 1
    BEGIN
        IF LEN(@v_clean_code) = 2
            SELECT @v_parent_id = [id] FROM [dbo].[Account] WHERE [code] = SUBSTRING(@v_clean_code, 1, 1);
        ELSE IF LEN(@v_clean_code) = 4
            SELECT @v_parent_id = [id] FROM [dbo].[Account] WHERE [code] = SUBSTRING(@v_clean_code, 1, 2);
        ELSE IF LEN(@v_clean_code) = 6
            SELECT @v_parent_id = [id] FROM [dbo].[Account] WHERE [code] = SUBSTRING(@v_clean_code, 1, 4);
        ELSE IF LEN(@v_clean_code) >= 8
            SELECT @v_parent_id = [id] FROM [dbo].[Account] WHERE [code] = SUBSTRING(@v_clean_code, 1, 6);
    END

    IF @v_parent_id IS NOT NULL
        UPDATE [dbo].[Account] SET [allowsMovement] = 0 WHERE [id] = @v_parent_id;

    IF @p_id IS NULL OR @p_id = 0
    BEGIN
        INSERT INTO [dbo].[Account] (
            [code], [name], [level], [nature], [allowsMovement],
            [requiresThirdParty], [requiresCostCenter], [parentId], [isActive],
            [createdAt], [updatedAt]
        ) VALUES (
            @v_clean_code, RTRIM(LTRIM(@p_name)), @p_level, UPPER(RTRIM(LTRIM(@p_nature))), ISNULL(@p_allows_movement, 0),
            ISNULL(@p_requires_third, 0), ISNULL(@p_requires_cc, 0), @v_parent_id, ISNULL(@p_is_active, 1),
            GETDATE(), GETDATE()
        );
    END
    ELSE
    BEGIN
        UPDATE [dbo].[Account]
        SET 
            [code] = @v_clean_code,
            [name] = RTRIM(LTRIM(@p_name)),
            [level] = @p_level,
            [nature] = UPPER(RTRIM(LTRIM(@p_nature))),
            [allowsMovement] = ISNULL(@p_allows_movement, [allowsMovement]),
            [requiresThirdParty] = ISNULL(@p_requires_third, [requiresThirdParty]),
            [requiresCostCenter] = ISNULL(@p_requires_cc, [requiresCostCenter]),
            [parentId] = @v_parent_id,
            [isActive] = ISNULL(@p_is_active, [isActive]),
            [updatedAt] = GETDATE()
        WHERE [id] = @p_id;
    END
END;
GO

-- 3. spThirdPartyGuardar
CREATE OR ALTER PROCEDURE [dbo].[spThirdPartyGuardar]
    @p_id INT = NULL,
    @p_document_type NVARCHAR(20) = 'NIT',
    @p_document_number NVARCHAR(50),
    @p_verification_digit NVARCHAR(2) = NULL,
    @p_business_name NVARCHAR(255) = NULL,
    @p_first_name NVARCHAR(100) = NULL,
    @p_second_name NVARCHAR(100) = NULL,
    @p_first_last_name NVARCHAR(100) = NULL,
    @p_second_last_name NVARCHAR(100) = NULL,
    @p_person_type NVARCHAR(20) = 'JURIDICA',
    @p_address NVARCHAR(255) = NULL,
    @p_city NVARCHAR(100) = NULL,
    @p_state NVARCHAR(100) = NULL,
    @p_country NVARCHAR(100) = 'Colombia',
    @p_phone NVARCHAR(50) = NULL,
    @p_email NVARCHAR(150) = NULL,
    @p_is_customer BIT = 0,
    @p_is_supplier BIT = 0,
    @p_is_employee BIT = 0,
    @p_is_partner BIT = 0,
    @p_is_other BIT = 0,
    @p_tax_regime NVARCHAR(100) = NULL,
    @p_fiscal_resp NVARCHAR(255) = NULL,
    @p_is_active BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_full_name NVARCHAR(255);
    IF UPPER(@p_person_type) = 'JURIDICA' OR (@p_business_name IS NOT NULL AND RTRIM(LTRIM(@p_business_name)) <> '')
        SET @v_full_name = RTRIM(LTRIM(@p_business_name));
    ELSE
        SET @v_full_name = RTRIM(LTRIM(CONCAT(
            ISNULL(@p_first_name, ''), ' ',
            ISNULL(@p_second_name, ''), ' ',
            ISNULL(@p_first_last_name, ''), ' ',
            ISNULL(@p_second_last_name, '')
        )));

    IF @p_id IS NULL OR @p_id = 0
    BEGIN
        INSERT INTO [dbo].[ThirdParty] (
            [documentType], [documentNumber], [verificationDigit], [businessName],
            [firstName], [secondName], [firstLastName], [secondLastName],
            [fullName], [personType], [address], [city], [state], [country], [phone], [email],
            [isCustomer], [isSupplier], [isEmployee], [isPartner], [isOther],
            [taxRegime], [fiscalResponsibilities], [isActive], [createdAt], [updatedAt]
        ) VALUES (
            ISNULL(@p_document_type, 'NIT'), RTRIM(LTRIM(@p_document_number)), @p_verification_digit, @p_business_name,
            @p_first_name, @p_second_name, @p_first_last_name, @p_second_last_name,
            @v_full_name, ISNULL(@p_person_type, 'JURIDICA'), @p_address, @p_city, @p_state, ISNULL(@p_country, 'Colombia'), @p_phone, @p_email,
            ISNULL(@p_is_customer, 0), ISNULL(@p_is_supplier, 0), ISNULL(@p_is_employee, 0),
            ISNULL(@p_is_partner, 0), ISNULL(@p_is_other, 0),
            @p_tax_regime, @p_fiscal_resp, ISNULL(@p_is_active, 1), GETDATE(), GETDATE()
        );
    END
    ELSE
    BEGIN
        UPDATE [dbo].[ThirdParty]
        SET 
            [documentType] = ISNULL(@p_document_type, 'NIT'),
            [documentNumber] = RTRIM(LTRIM(@p_document_number)),
            [verificationDigit] = @p_verification_digit,
            [businessName] = @p_business_name,
            [firstName] = @p_first_name,
            [secondName] = @p_second_name,
            [firstLastName] = @p_first_last_name,
            [secondLastName] = @p_second_last_name,
            [fullName] = @v_full_name,
            [personType] = ISNULL(@p_person_type, 'JURIDICA'),
            [address] = @p_address,
            [city] = @p_city,
            [state] = @p_state,
            [country] = ISNULL(@p_country, 'Colombia'),
            [phone] = @p_phone,
            [email] = @p_email,
            [isCustomer] = ISNULL(@p_is_customer, [isCustomer]),
            [isSupplier] = ISNULL(@p_is_supplier, [isSupplier]),
            [isEmployee] = ISNULL(@p_is_employee, [isEmployee]),
            [isPartner] = ISNULL(@p_is_partner, [isPartner]),
            [isOther] = ISNULL(@p_is_other, [isOther]),
            [taxRegime] = @p_tax_regime,
            [fiscalResponsibilities] = @p_fiscal_resp,
            [isActive] = ISNULL(@p_is_active, [isActive]),
            [updatedAt] = GETDATE()
        WHERE [id] = @p_id;
    END
END;
GO

-- 4. spTraceabilityLog
CREATE OR ALTER PROCEDURE [dbo].[spTraceabilityLog]
    @p_code NVARCHAR(100),
    @p_user_id INT = NULL,
    @p_origin NVARCHAR(50) = 'WEB',
    @p_module NVARCHAR(100),
    @p_screen NVARCHAR(100) = NULL,
    @p_action NVARCHAR(100),
    @p_process NVARCHAR(150) = NULL,
    @p_event_type NVARCHAR(50),
    @p_step_name NVARCHAR(150),
    @p_sp_name NVARCHAR(150) = NULL,
    @p_endpoint NVARCHAR(255) = NULL,
    @p_duration_ms INT = 0,
    @p_status NVARCHAR(50) = 'SUCCESS',
    @p_input_data NVARCHAR(MAX) = NULL,
    @p_output_data NVARCHAR(MAX) = NULL,
    @p_tech_message NVARCHAR(MAX) = NULL,
    @p_functional_message NVARCHAR(MAX) = NULL,
    @p_stack_trace NVARCHAR(MAX) = NULL,
    @p_affected_id NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO [dbo].[TraceabilityLog] (
        [code], [userId], [origin], [module], [screen], [action], [process],
        [eventType], [stepName], [spName], [endpoint], [durationMs],
        [status], [inputData], [outputData], [techMessage], [functionalMessage],
        [stackTrace], [affectedId], [createdAt]
    ) VALUES (
        @p_code, @p_user_id, ISNULL(@p_origin, 'WEB'), @p_module, @p_screen, @p_action, @p_process,
        @p_event_type, @p_step_name, @p_sp_name, @p_endpoint, ISNULL(@p_duration_ms, 0),
        ISNULL(@p_status, 'SUCCESS'), @p_input_data, @p_output_data, @p_tech_message, @p_functional_message,
        @p_stack_trace, @p_affected_id, GETDATE()
    );
END;
GO


-- --- OBJETO T-SQL: 04_Accounting_Core_SPs.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTOS Y FUNCIONES T-SQL DE CONTABILIDAD (SQL SERVER)
-- Archivo: SQL/SqlServer/04_Accounting_Core_SPs.sql
-- ============================================================================

-- 1. spComprobanteGuardar
CREATE OR ALTER PROCEDURE [dbo].[spComprobanteGuardar]
    @p_id INT = NULL,
    @p_company_id INT,
    @p_document_type_id INT,
    @p_entry_number NVARCHAR(50) = NULL,
    @p_entry_date DATETIME2,
    @p_third_party_id INT = NULL,
    @p_concept NVARCHAR(255),
    @p_observation NVARCHAR(MAX) = NULL,
    @p_items NVARCHAR(MAX) = NULL, -- JSON
    @p_user_id INT = 1,
    @p_created_id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_journal_id INT;
    DECLARE @v_fiscal_year INT = YEAR(@p_entry_date);
    DECLARE @v_doc_prefix NVARCHAR(10);
    DECLARE @v_curr_number INT;
    DECLARE @v_final_entry_number NVARCHAR(50);
    DECLARE @v_status NVARCHAR(20) = 'DRAFT';
    DECLARE @v_total_debit DECIMAL(18,4) = 0;
    DECLARE @v_total_credit DECIMAL(18,4) = 0;

    -- Calcular totales del JSON
    IF @p_items IS NOT NULL AND ISJSON(@p_items) = 1
    BEGIN
        SELECT 
            @v_total_debit = ISNULL(SUM(CAST(JSON_VALUE(value, '$.debit') AS DECIMAL(18,4))), 0),
            @v_total_credit = ISNULL(SUM(CAST(JSON_VALUE(value, '$.credit') AS DECIMAL(18,4))), 0)
        FROM OPENJSON(@p_items);
    END

    IF @p_id IS NULL OR @p_id = 0
    BEGIN
        SELECT @v_doc_prefix = [prefix] FROM [dbo].[DocumentType] WHERE [id] = @p_document_type_id;

        SELECT @v_curr_number = [currentNumber] 
        FROM [dbo].[Consecutive] 
        WHERE [documentTypeId] = @p_document_type_id AND [fiscalYear] = @v_fiscal_year;

        IF @v_curr_number IS NULL
        BEGIN
            SET @v_curr_number = 1;
            INSERT INTO [dbo].[Consecutive] ([documentTypeId], [prefix], [currentNumber], [initialNumber], [fiscalYear], [isActive])
            VALUES (@p_document_type_id, @v_doc_prefix, 2, 1, @v_fiscal_year, 1);
        END
        ELSE
        BEGIN
            UPDATE [dbo].[Consecutive] 
            SET [currentNumber] = [currentNumber] + 1 
            WHERE [documentTypeId] = @p_document_type_id AND [fiscalYear] = @v_fiscal_year;
        END

        SET @v_final_entry_number = ISNULL(@p_entry_number, CONCAT(ISNULL(@v_doc_prefix, 'DOC'), '-', @v_fiscal_year, '-', RIGHT('000000' + CAST(@v_curr_number AS VARCHAR(6)), 6)));

        INSERT INTO [dbo].[JournalEntry] (
            [companyId], [documentTypeId], [consecutiveNumber], [entryNumber],
            [entryDate], [thirdPartyId], [concept], [observation],
            [totalDebit], [totalCredit], [status], [createdById],
            [createdAt], [updatedAt]
        ) VALUES (
            @p_company_id, @p_document_type_id, @v_curr_number, @v_final_entry_number,
            @p_entry_date, @p_third_party_id, @p_concept, @p_observation,
            @v_total_debit, @v_total_credit, @v_status, @p_user_id,
            GETDATE(), GETDATE()
        );

        SET @v_journal_id = SCOPE_IDENTITY();
        SET @p_created_id = @v_journal_id;
    END
    ELSE
    BEGIN
        SET @v_journal_id = @p_id;
        SET @p_created_id = @p_id;

        SELECT @v_status = [status] FROM [dbo].[JournalEntry] WHERE [id] = @v_journal_id;
        IF @v_status = 'POSTED'
        BEGIN
            RAISERROR('❌ Comprobante ya Contabilizado: No se puede editar un comprobante en estado POSTED.', 16, 1);
            RETURN;
        END

        UPDATE [dbo].[JournalEntry]
        SET 
            [companyId] = @p_company_id,
            [documentTypeId] = @p_document_type_id,
            [entryDate] = @p_entry_date,
            [thirdPartyId] = @p_third_party_id,
            [concept] = @p_concept,
            [observation] = @p_observation,
            [totalDebit] = @v_total_debit,
            [totalCredit] = @v_total_credit,
            [updatedAt] = GETDATE()
        WHERE [id] = @v_journal_id;

        DELETE FROM [dbo].[JournalEntryItem] WHERE [journalEntryId] = @v_journal_id;
    END

    -- Insertar líneas del JSON
    IF @p_items IS NOT NULL AND ISJSON(@p_items) = 1
    BEGIN
        INSERT INTO [dbo].[JournalEntryItem] (
            [journalEntryId], [accountId], [thirdPartyId], [costCenterId],
            [debit], [credit], [baseAmount], [description], [documentReference],
            [createdAt], [updatedAt]
        )
        SELECT 
            @v_journal_id,
            CAST(JSON_VALUE(value, '$.accountId') AS INT),
            NULLIF(CAST(JSON_VALUE(value, '$.thirdPartyId') AS INT), 0),
            NULLIF(CAST(JSON_VALUE(value, '$.costCenterId') AS INT), 0),
            ISNULL(CAST(JSON_VALUE(value, '$.debit') AS DECIMAL(18,4)), 0),
            ISNULL(CAST(JSON_VALUE(value, '$.credit') AS DECIMAL(18,4)), 0),
            ISNULL(CAST(JSON_VALUE(value, '$.baseAmount') AS DECIMAL(18,4)), 0),
            JSON_VALUE(value, '$.description'),
            JSON_VALUE(value, '$.documentReference'),
            GETDATE(),
            GETDATE()
        FROM OPENJSON(@p_items);
    END
END;
GO

-- 2. spComprobanteContabilizar
CREATE OR ALTER PROCEDURE [dbo].[spComprobanteContabilizar]
    @p_journal_id INT,
    @p_user_id INT = 1
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_status NVARCHAR(20);
    DECLARE @v_entry_number NVARCHAR(50);
    DECLARE @v_entry_date DATETIME2;
    DECLARE @v_year INT;
    DECLARE @v_month INT;
    DECLARE @v_total_debit DECIMAL(18,4);
    DECLARE @v_total_credit DECIMAL(18,4);
    DECLARE @v_line_count INT;
    DECLARE @v_period_status NVARCHAR(20);

    SELECT 
        @v_status = [status],
        @v_entry_number = [entryNumber],
        @v_entry_date = [entryDate]
    FROM [dbo].[JournalEntry] WHERE [id] = @p_journal_id;

    IF @v_status IS NULL
    BEGIN
        RAISERROR('❌ Error: El comprobante no existe.', 16, 1);
        RETURN;
    END

    IF @v_status = 'POSTED'
    BEGIN
        RAISERROR('⚠️ Advertencia: El comprobante ya se encuentra contabilizado.', 16, 1);
        RETURN;
    END

    -- Validar período
    SET @v_year = YEAR(@v_entry_date);
    SET @v_month = MONTH(@v_entry_date);
    SELECT @v_period_status = [status] FROM [dbo].[FiscalPeriod] WHERE [year] = @v_year AND [month] = @v_month;
    IF @v_period_status = 'CLOSED'
    BEGIN
        RAISERROR('❌ Período Cerrado: El período contable se encuentra cerrado.', 16, 1);
        RETURN;
    END

    -- Calcular totales
    SELECT 
        @v_line_count = COUNT(*),
        @v_total_debit = ISNULL(SUM([debit]), 0),
        @v_total_credit = ISNULL(SUM([credit]), 0)
    FROM [dbo].[JournalEntryItem]
    WHERE [journalEntryId] = @p_journal_id;

    IF @v_line_count < 2
    BEGIN
        RAISERROR('❌ Asientos Insuficientes: Se requieren al menos 2 asientos para cumplir partida doble.', 16, 1);
        RETURN;
    END

    -- Validar Partida Doble
    IF ABS(@v_total_debit - @v_total_credit) > 0.0001
    BEGIN
        DECLARE @errMsg NVARCHAR(255) = CONCAT('❌ Descuadre Contable: Total Débitos (', @v_total_debit, ') != Total Créditos (', @v_total_credit, ')');
        RAISERROR(@errMsg, 16, 1);
        RETURN;
    END

    -- Validar cuentas de movimiento
    IF EXISTS (
        SELECT 1 FROM [dbo].[JournalEntryItem] ji
        INNER JOIN [dbo].[Account] a ON ji.[accountId] = a.[id]
        WHERE ji.[journalEntryId] = @p_journal_id AND a.[allowsMovement] = 0
    )
    BEGIN
        RAISERROR('❌ Cuenta Inválida: Una o más cuentas no permiten movimiento directo por ser cuentas padre.', 16, 1);
        RETURN;
    END

    -- Validar exigencia de tercero
    IF EXISTS (
        SELECT 1 FROM [dbo].[JournalEntryItem] ji
        INNER JOIN [dbo].[Account] a ON ji.[accountId] = a.[id]
        WHERE ji.[journalEntryId] = @p_journal_id AND a.[requiresThirdParty] = 1 AND (ji.[thirdPartyId] IS NULL OR ji.[thirdPartyId] = 0)
    )
    BEGIN
        RAISERROR('❌ Exigencia de Tercero: Una o más cuentas requieren obligatoriamente un Tercero.', 16, 1);
        RETURN;
    END

    -- Asentar
    UPDATE [dbo].[JournalEntry]
    SET 
        [status] = 'POSTED',
        [totalDebit] = @v_total_debit,
        [totalCredit] = @v_total_credit,
        [postedAt] = GETDATE(),
        [updatedAt] = GETDATE()
    WHERE [id] = @p_journal_id;
END;
GO


-- --- OBJETO T-SQL: 05_Treasury_Tables.sql ---
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


-- --- OBJETO T-SQL: 06_Treasury_SPs.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTOS Y FUNCIONES T-SQL DE TESORERÍA (SQL SERVER)
-- Archivo: SQL/SqlServer/06_Treasury_SPs.sql
-- ============================================================================

-- 1. spCajaGuardar
CREATE OR ALTER PROCEDURE [dbo].[spCajaGuardar]
    @p_id INT = NULL,
    @p_company_id INT,
    @p_code NVARCHAR(30),
    @p_name NVARCHAR(150),
    @p_account_id INT,
    @p_responsible_user_id INT = NULL,
    @p_currency NVARCHAR(10) = 'COP',
    @p_max_amount DECIMAL(18, 4) = 0,
    @p_is_active BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    IF @p_id IS NULL OR @p_id = 0
    BEGIN
        INSERT INTO [dbo].[CashBox] (
            [companyId], [code], [name], [accountId], [responsibleUserId],
            [currency], [maxAmount], [isActive], [createdAt], [updatedAt]
        ) VALUES (
            @p_company_id, RTRIM(LTRIM(@p_code)), RTRIM(LTRIM(@p_name)), @p_account_id, @p_responsible_user_id,
            ISNULL(@p_currency, 'COP'), ISNULL(@p_max_amount, 0), ISNULL(@p_is_active, 1),
            GETDATE(), GETDATE()
        );
    END
    ELSE
    BEGIN
        UPDATE [dbo].[CashBox]
        SET 
            [companyId] = @p_company_id,
            [code] = RTRIM(LTRIM(@p_code)),
            [name] = RTRIM(LTRIM(@p_name)),
            [accountId] = @p_account_id,
            [responsibleUserId] = @p_responsible_user_id,
            [currency] = ISNULL(@p_currency, [currency]),
            [maxAmount] = ISNULL(@p_max_amount, [maxAmount]),
            [isActive] = ISNULL(@p_is_active, [isActive]),
            [updatedAt] = GETDATE()
        WHERE [id] = @p_id;
    END
END;
GO

-- 2. spTesoreriaIngresoCrear
CREATE OR ALTER PROCEDURE [dbo].[spTesoreriaIngresoCrear]
    @p_company_id INT,
    @p_movement_date DATETIME2,
    @p_bank_account_id INT = NULL,
    @p_cash_box_id INT = NULL,
    @p_third_party_id INT = NULL,
    @p_concept NVARCHAR(255),
    @p_payment_method NVARCHAR(50) = 'TRANSFERENCIA',
    @p_check_number NVARCHAR(50) = NULL,
    @p_total_amount DECIMAL(18, 4),
    @p_counterpart_account_id INT,
    @p_cost_center_id INT = NULL,
    @p_user_id INT = 1,
    @p_movement_id INT OUTPUT,
    @p_journal_id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_ci_doc_type_id INT;
    DECLARE @v_doc_prefix NVARCHAR(10);
    DECLARE @v_fiscal_year INT = YEAR(@p_movement_date);
    DECLARE @v_curr_number INT;
    DECLARE @v_entry_number NVARCHAR(50);
    DECLARE @v_debit_account_id INT;
    DECLARE @v_journal_id INT;
    DECLARE @v_mov_id INT;

    IF @p_total_amount <= 0
    BEGIN
        RAISERROR('❌ Error: El monto del ingreso debe ser mayor a cero.', 16, 1);
        RETURN;
    END

    -- Determinar cuenta Débito
    IF @p_bank_account_id IS NOT NULL AND @p_bank_account_id > 0
        SELECT @v_debit_account_id = [accountId] FROM [dbo].[BankAccount] WHERE [id] = @p_bank_account_id;
    ELSE IF @p_cash_box_id IS NOT NULL AND @p_cash_box_id > 0
        SELECT @v_debit_account_id = [accountId] FROM [dbo].[CashBox] WHERE [id] = @p_cash_box_id;

    IF @v_debit_account_id IS NULL
        SELECT TOP 1 @v_debit_account_id = [id] FROM [dbo].[Account] WHERE [code] = '110505';

    -- Consecutivo CI
    SELECT TOP 1 @v_ci_doc_type_id = [id], @v_doc_prefix = [prefix] FROM [dbo].[DocumentType] WHERE [code] = 'CI';
    IF @v_ci_doc_type_id IS NULL
        SELECT TOP 1 @v_ci_doc_type_id = [id], @v_doc_prefix = [prefix] FROM [dbo].[DocumentType] WHERE [code] = 'CC';

    SELECT @v_curr_number = [currentNumber] 
    FROM [dbo].[Consecutive] 
    WHERE [documentTypeId] = @v_ci_doc_type_id AND [fiscalYear] = @v_fiscal_year;

    IF @v_curr_number IS NULL
    BEGIN
        SET @v_curr_number = 1;
        INSERT INTO [dbo].[Consecutive] ([documentTypeId], [prefix], [currentNumber], [initialNumber], [fiscalYear], [isActive])
        VALUES (@v_ci_doc_type_id, @v_doc_prefix, 2, 1, @v_fiscal_year, 1);
    END
    ELSE
    BEGIN
        UPDATE [dbo].[Consecutive] 
        SET [currentNumber] = [currentNumber] + 1 
        WHERE [documentTypeId] = @v_ci_doc_type_id AND [fiscalYear] = @v_fiscal_year;
    END

    SET @v_entry_number = CONCAT(ISNULL(@v_doc_prefix, 'CI'), '-', @v_fiscal_year, '-', RIGHT('000000' + CAST(@v_curr_number AS VARCHAR(6)), 6));

    -- Comprobante Contable
    INSERT INTO [dbo].[JournalEntry] (
        [companyId], [documentTypeId], [consecutiveNumber], [entryNumber],
        [entryDate], [thirdPartyId], [concept], [observation],
        [totalDebit], [totalCredit], [status], [createdById],
        [postedAt], [createdAt], [updatedAt]
    ) VALUES (
        @p_company_id, @v_ci_doc_type_id, @v_curr_number, @v_entry_number,
        @p_movement_date, @p_third_party_id, @p_concept,
        CONCAT('Recibo de Caja / Ingreso de Tesorería #', @v_entry_number),
        @p_total_amount, @p_total_amount, 'POSTED', @p_user_id,
        GETDATE(), GETDATE(), GETDATE()
    );
    SET @v_journal_id = SCOPE_IDENTITY();

    -- Débito Caja/Banco
    INSERT INTO [dbo].[JournalEntryItem] ([journalEntryId], [accountId], [thirdPartyId], [costCenterId], [debit], [credit], [baseAmount], [description], [documentReference], [createdAt], [updatedAt])
    VALUES (@v_journal_id, @v_debit_account_id, @p_third_party_id, @p_cost_center_id, @p_total_amount, 0, 0, CONCAT('Ingreso Tesorería - ', @p_concept), @v_entry_number, GETDATE(), GETDATE());

    -- Crédito Contrapartida
    INSERT INTO [dbo].[JournalEntryItem] ([journalEntryId], [accountId], [thirdPartyId], [costCenterId], [debit], [credit], [baseAmount], [description], [documentReference], [createdAt], [updatedAt])
    VALUES (@v_journal_id, @p_counterpart_account_id, @p_third_party_id, @p_cost_center_id, 0, @p_total_amount, 0, CONCAT('Contrapartida Ingreso - ', @p_concept), @v_entry_number, GETDATE(), GETDATE());

    -- Movimiento de Tesorería
    INSERT INTO [dbo].[TreasuryMovement] (
        [companyId], [movementType], [documentTypeId], [consecutiveNumber], [entryNumber],
        [movementDate], [bankAccountId], [cashBoxId], [thirdPartyId],
        [concept], [paymentMethod], [checkNumber], [totalAmount], [status],
        [journalEntryId], [createdById], [createdAt], [updatedAt]
    ) VALUES (
        @p_company_id, 'INGRESO', @v_ci_doc_type_id, @v_curr_number, @v_entry_number,
        @p_movement_date, @p_bank_account_id, @p_cash_box_id, @p_third_party_id,
        @p_concept, ISNULL(@p_payment_method, 'TRANSFERENCIA'), @p_check_number,
        @p_total_amount, 'POSTED', @v_journal_id, @p_user_id,
        GETDATE(), GETDATE()
    );
    SET @v_mov_id = SCOPE_IDENTITY();

    SET @p_movement_id = @v_mov_id;
    SET @p_journal_id = @v_journal_id;
END;
GO


-- --- OBJETO T-SQL: 07_Receivables_Payables_Tables.sql ---
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


-- --- OBJETO T-SQL: 08_Receivables_Payables_SPs.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTOS ALMACENADOS: CARTERA Y PROVEEDORES (FASE 5)
-- MOTOR: SQL Server (T-SQL)
-- ============================================================================

IF OBJECT_ID('dbo.spFacturaVentaCrear', 'P') IS NOT NULL DROP PROCEDURE dbo.spFacturaVentaCrear;
GO
CREATE PROCEDURE dbo.spFacturaVentaCrear
    @companyId INT,
    @thirdPartyId INT,
    @documentTypeId INT,
    @issueDate DATETIME2,
    @paymentTermDays INT = 0,
    @subtotal DECIMAL(18, 4),
    @taxAmount DECIMAL(18, 4) = 0,
    @retentionAmount DECIMAL(18, 4) = 0,
    @accountIncomeId INT,
    @accountReceivableId INT,
    @accountTaxId INT = NULL,
    @costCenterId INT = NULL,
    @createdById INT,
    @observations NVARCHAR(MAX) = NULL,
    @installmentsCount INT = 1,
    @invoiceId INT OUTPUT,
    @invoiceNumber NVARCHAR(50) OUTPUT,
    @journalEntryId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @year INT = YEAR(@issueDate);
    DECLARE @month INT = MONTH(@issueDate);
    DECLARE @periodStatus NVARCHAR(20);

    SELECT @periodStatus = [status] FROM dbo.[FiscalPeriod] WHERE [year] = @year AND [month] = @month;
    IF @periodStatus = 'CLOSED'
    BEGIN
        RAISERROR('No se puede emitir factura en un periodo fiscal cerrado', 16, 1);
        RETURN;
    END

    DECLARE @prefix NVARCHAR(10);
    DECLARE @consecutive INT;

    SELECT @prefix = [prefix], @consecutive = [currentNumber]
    FROM dbo.[Consecutive] WITH (UPDLOCK, HOLDLOCK)
    WHERE [documentTypeId] = @documentTypeId AND [fiscalYear] = @year;

    IF @consecutive IS NULL
    BEGIN
        SET @prefix = 'FV';
        SET @consecutive = 1;
        INSERT INTO dbo.[Consecutive]([documentTypeId], [prefix], [currentNumber], [initialNumber], [fiscalYear], [isActive])
        VALUES (@documentTypeId, @prefix, 2, 1, @year, 1);
    END
    ELSE
    BEGIN
        UPDATE dbo.[Consecutive] SET [currentNumber] = @consecutive + 1
        WHERE [documentTypeId] = @documentTypeId AND [fiscalYear] = @year;
    END

    SET @invoiceNumber = ISNULL(@prefix, 'FV') + '-' + CAST(@year AS NVARCHAR(10)) + '-' + RIGHT('000000' + CAST(@consecutive AS NVARCHAR(10)), 6);
    DECLARE @total DECIMAL(18, 4) = ISNULL(@subtotal, 0) + ISNULL(@taxAmount, 0) - ISNULL(@retentionAmount, 0);
    DECLARE @dueDate DATETIME2 = DATEADD(DAY, ISNULL(@paymentTermDays, 0), @issueDate);

    INSERT INTO dbo.[ReceivableInvoice](
        [companyId], [thirdPartyId], [documentTypeId], [consecutiveNumber], [invoiceNumber],
        [issueDate], [dueDate], [paymentTermDays], [subtotal], [taxAmount], [retentionAmount],
        [totalAmount], [paidAmount], [balanceAmount], [status], [createdById], [observations]
    ) VALUES (
        @companyId, @thirdPartyId, @documentTypeId, @consecutive, @invoiceNumber,
        @issueDate, @dueDate, ISNULL(@paymentTermDays, 0), @subtotal, ISNULL(@taxAmount, 0),
        ISNULL(@retentionAmount, 0), @total, 0, @total, 'POSTED', @createdById, @observations
    );
    SET @invoiceId = SCOPE_IDENTITY();

    -- Cuota
    INSERT INTO dbo.[ReceivableInstallment]([receivableInvoiceId], [installmentNumber], [dueDate], [amount], [paidAmount], [balanceAmount], [status])
    VALUES (@invoiceId, 1, @dueDate, @total, 0, @total, 'PENDING');

    -- Comprobante Contable FV
    INSERT INTO dbo.[JournalEntry](
        [companyId], [documentTypeId], [consecutiveNumber], [entryNumber], [entryDate],
        [thirdPartyId], [concept], [observation], [totalDebit], [totalCredit], [status], [createdById], [postedAt]
    ) VALUES (
        @companyId, @documentTypeId, @consecutive, @invoiceNumber, @issueDate,
        @thirdPartyId, 'Factura de Venta ' + @invoiceNumber, @observations,
        @total + ISNULL(@retentionAmount, 0), ISNULL(@subtotal, 0) + ISNULL(@taxAmount, 0),
        'POSTED', @createdById, SYSUTCDATETIME()
    );
    SET @journalEntryId = SCOPE_IDENTITY();

    -- Débito: Clientes
    INSERT INTO dbo.[JournalEntryItem]([journalEntryId], [accountId], [thirdPartyId], [costCenterId], [debit], [credit], [description], [documentReference])
    VALUES (@journalEntryId, @accountReceivableId, @thirdPartyId, @costCenterId, @total, 0, 'CxC Cliente Factura ' + @invoiceNumber, @invoiceNumber);

    -- Crédito: Ingreso
    INSERT INTO dbo.[JournalEntryItem]([journalEntryId], [accountId], [thirdPartyId], [costCenterId], [debit], [credit], [description], [documentReference])
    VALUES (@journalEntryId, @accountIncomeId, @thirdPartyId, @costCenterId, 0, @subtotal, 'Ingreso Factura ' + @invoiceNumber, @invoiceNumber);

    IF ISNULL(@taxAmount, 0) > 0 AND @accountTaxId IS NOT NULL
    BEGIN
        INSERT INTO dbo.[JournalEntryItem]([journalEntryId], [accountId], [thirdPartyId], [costCenterId], [debit], [credit], [description], [documentReference])
        VALUES (@journalEntryId, @accountTaxId, @thirdPartyId, @costCenterId, 0, @taxAmount, 'IVA Generado ' + @invoiceNumber, @invoiceNumber);
    END

    UPDATE dbo.[ReceivableInvoice] SET [journalEntryId] = @journalEntryId WHERE [id] = @invoiceId;
END;
GO

IF OBJECT_ID('dbo.spCarteraReciboCruzar', 'P') IS NOT NULL DROP PROCEDURE dbo.spCarteraReciboCruzar;
GO
CREATE PROCEDURE dbo.spCarteraReciboCruzar
    @receivableInvoiceId INT,
    @receivableInstallmentId INT = NULL,
    @treasuryMovementId INT = NULL,
    @advancePaymentId INT = NULL,
    @creditNoteId INT = NULL,
    @amount DECIMAL(18, 4),
    @discountAmount DECIMAL(18, 4) = 0,
    @withholdingAdjustment DECIMAL(18, 4) = 0,
    @observations NVARCHAR(MAX) = NULL,
    @allocationId INT OUTPUT,
    @newBalance DECIMAL(18, 4) OUTPUT,
    @invoiceStatus NVARCHAR(20) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @invBalance DECIMAL(18, 4);
    SELECT @invBalance = [balanceAmount] FROM dbo.[ReceivableInvoice] WITH (UPDLOCK) WHERE [id] = @receivableInvoiceId;

    DECLARE @totalApplied DECIMAL(18, 4) = ISNULL(@amount, 0) + ISNULL(@discountAmount, 0) + ISNULL(@withholdingAdjustment, 0);

    INSERT INTO dbo.[ReceivablePaymentAllocation](
        [receivableInvoiceId], [receivableInstallmentId], [treasuryMovementId],
        [advancePaymentId], [creditDebitNoteId], [allocationDate],
        [amount], [discountAmount], [withholdingAdjustment], [observations]
    ) VALUES (
        @receivableInvoiceId, @receivableInstallmentId, @treasuryMovementId,
        @advancePaymentId, @creditNoteId, SYSUTCDATETIME(),
        @amount, ISNULL(@discountAmount, 0), ISNULL(@withholdingAdjustment, 0), @observations
    );
    SET @allocationId = SCOPE_IDENTITY();

    SET @newBalance = @invBalance - @totalApplied;
    SET @invoiceStatus = CASE WHEN @newBalance <= 0 THEN 'PAID' ELSE 'PARTIAL' END;

    UPDATE dbo.[ReceivableInvoice]
    SET [paidAmount] = [paidAmount] + @totalApplied,
        [balanceAmount] = @newBalance,
        [status] = @invoiceStatus,
        [updatedAt] = SYSUTCDATETIME()
    WHERE [id] = @receivableInvoiceId;
END;
GO


-- --- OBJETO T-SQL: 09_Fixed_Assets_Tables.sql ---
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


-- --- OBJETO T-SQL: 10_Fixed_Assets_SPs.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTOS ALMACENADOS: ACTIVOS FIJOS (FASE 6)
-- MOTOR: SQL Server (T-SQL)
-- ============================================================================

IF OBJECT_ID('dbo.spActivoFijoCategoriaGuardar', 'P') IS NOT NULL DROP PROCEDURE dbo.spActivoFijoCategoriaGuardar;
GO
CREATE PROCEDURE dbo.spActivoFijoCategoriaGuardar
    @id INT = NULL,
    @code NVARCHAR(50),
    @name NVARCHAR(100),
    @defaultUsefulLifeMonths INT = 60,
    @accountAssetId INT,
    @accountAccumDeprId INT,
    @accountExpenseDeprId INT,
    @isActive BIT = 1,
    @outId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    IF @id IS NULL OR @id = 0
    BEGIN
        INSERT INTO dbo.[FixedAssetCategory]([code], [name], [defaultUsefulLifeMonths], [accountAssetId], [accountAccumDeprId], [accountExpenseDeprId], [isActive])
        VALUES (@code, @name, ISNULL(@defaultUsefulLifeMonths, 60), @accountAssetId, @accountAccumDeprId, @accountExpenseDeprId, ISNULL(@isActive, 1));
        SET @outId = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE dbo.[FixedAssetCategory]
        SET [code] = @code, [name] = @name, [defaultUsefulLifeMonths] = ISNULL(@defaultUsefulLifeMonths, 60),
            [accountAssetId] = @accountAssetId, [accountAccumDeprId] = @accountAccumDeprId, [accountExpenseDeprId] = @accountExpenseDeprId,
            [isActive] = ISNULL(@isActive, 1), [updatedAt] = SYSUTCDATETIME()
        WHERE [id] = @id;
        SET @outId = @id;
    END
END;
GO

IF OBJECT_ID('dbo.spActivoFijoGuardar', 'P') IS NOT NULL DROP PROCEDURE dbo.spActivoFijoGuardar;
GO
CREATE PROCEDURE dbo.spActivoFijoGuardar
    @id INT = NULL,
    @companyId INT,
    @categoryId INT,
    @code NVARCHAR(50),
    @name NVARCHAR(150),
    @description NVARCHAR(MAX) = NULL,
    @serialNumber NVARCHAR(100) = NULL,
    @purchaseDate DATETIME2,
    @activationDate DATETIME2,
    @acquisitionCost DECIMAL(18, 4),
    @residualValue DECIMAL(18, 4) = 0,
    @usefulLifeMonths INT = 60,
    @costCenterId INT = NULL,
    @responsibleThirdPartyId INT = NULL,
    @location NVARCHAR(150) = NULL,
    @createdById INT,
    @outId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @monthlyDepr DECIMAL(18, 4) = ROUND((ISNULL(@acquisitionCost, 0) - ISNULL(@residualValue, 0)) / @usefulLifeMonths, 4);

    IF @id IS NULL OR @id = 0
    BEGIN
        INSERT INTO dbo.[FixedAsset](
            [companyId], [categoryId], [code], [name], [description], [serialNumber],
            [purchaseDate], [activationDate], [acquisitionCost], [residualValue],
            [usefulLifeMonths], [depreciatedMonths], [accumulatedDepreciation],
            [netBookValue], [monthlyDepreciation], [costCenterId],
            [responsibleThirdPartyId], [location], [status], [createdById]
        ) VALUES (
            @companyId, @categoryId, @code, @name, @description, @serialNumber,
            @purchaseDate, @activationDate, @acquisitionCost, ISNULL(@residualValue, 0),
            @usefulLifeMonths, 0, 0,
            @acquisitionCost, @monthlyDepr, @costCenterId,
            @responsibleThirdPartyId, @location, 'ACTIVE', @createdById
        );
        SET @outId = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE dbo.[FixedAsset]
        SET [categoryId] = @categoryId, [code] = @code, [name] = @name, [description] = @description,
            [serialNumber] = @serialNumber, [purchaseDate] = @purchaseDate, [activationDate] = @activationDate,
            [acquisitionCost] = @acquisitionCost, [residualValue] = ISNULL(@residualValue, 0),
            [usefulLifeMonths] = @usefulLifeMonths, [monthlyDepreciation] = @monthlyDepr,
            [netBookValue] = @acquisitionCost - [accumulatedDepreciation],
            [costCenterId] = @costCenterId, [responsibleThirdPartyId] = @responsibleThirdPartyId,
            [location] = @location, [updatedAt] = SYSUTCDATETIME()
        WHERE [id] = @id;
        SET @outId = @id;
    END
END;
GO


-- --- OBJETO T-SQL: 11_Reports_Taxes_Tables.sql ---
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


-- --- OBJETO T-SQL: 12_Integrations_Tables.sql ---
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


