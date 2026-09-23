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
