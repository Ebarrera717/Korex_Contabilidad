-- ============================================================================
-- KOREX_CONTABILIDAD - SEMILLAS DE MAESTROS CONTABLES (POSTGRESQL)
-- Archivo: SQL/Data/02_Accounting_Seeds.sql
-- ============================================================================

-- 1. Roles por Defecto
INSERT INTO public."Role" (id, name, description, permissions, "isActive")
VALUES 
(1, 'SUPERADMINISTRADOR', 'Acceso total y configuración del sistema contable', '{"modules": {"accounting": true, "masters": true, "periods": true, "reports": true, "treasury": true, "receivables": true, "payables": true, "config": true, "manual": true}}'::jsonb, true),
(2, 'CONTADOR_GENERAL', 'Gestión de comprobantes, balances, cierres y reportes contables', '{"modules": {"accounting": true, "masters": true, "periods": true, "reports": true, "treasury": true, "receivables": true, "payables": true, "config": false, "manual": true}}'::jsonb, true),
(3, 'AUXILIAR_CONTABLE', 'Elaboración y edición de comprobantes en borrador', '{"modules": {"accounting": true, "masters": false, "periods": false, "reports": true, "treasury": false, "receivables": false, "payables": false, "config": false, "manual": true}}'::jsonb, true),
(4, 'AUDITOR_FISCAL', 'Solo consulta y auditoría de libros y comprobantes', '{"modules": {"accounting": true, "masters": false, "periods": false, "reports": true, "treasury": false, "receivables": false, "payables": false, "config": false, "manual": true}}'::jsonb, true)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description;

-- 2. Empresa Demostrativa por Defecto
INSERT INTO public."Company" (id, code, "businessName", "tradeName", "documentType", "documentNumber", "verificationDigit", city, state, country, email, "taxRegime", "isActive")
VALUES 
(1, 'EMP-01', 'EMPRESA DEMO CONTABLE S.A.S.', 'KOREX CONTABILIDAD DEMO', 'NIT', '900123456', '7', 'Bogotá D.C.', 'Cundinamarca', 'Colombia', 'contabilidad@korex.com.co', 'Régimen Ordinario', true)
ON CONFLICT (id) DO UPDATE SET "businessName" = EXCLUDED."businessName";

-- 3. Tipos de Documento Contable Estándar en Colombia
INSERT INTO public."DocumentType" (id, code, name, prefix, "isAutomatic", "isActive")
VALUES
(1, 'CC', 'Comprobante de Contabilidad / Diario', 'CC', true, true),
(2, 'CE', 'Comprobante de Egreso / Pago', 'CE', true, true),
(3, 'CI', 'Comprobante de Ingreso / Recibo de Caja', 'CI', true, true),
(4, 'NC', 'Nota Crédito', 'NC', true, true),
(5, 'ND', 'Nota Débito', 'ND', true, true),
(6, 'FV', 'Factura de Venta', 'FV', true, true),
(7, 'DS', 'Documento Soporte en Adquisiciones', 'DS', true, true),
(8, 'CZ', 'Comprobante de Cierre Contable', 'CZ', true, true),
(9, 'AJ', 'Comprobante de Ajustes / Reclasificaciones', 'AJ', true, true)
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name, prefix = EXCLUDED.prefix;

-- 4. Consecutivos Iniciales Año Actual
INSERT INTO public."Consecutive" ("documentTypeId", prefix, "currentNumber", "initialNumber", "fiscalYear", "isActive")
VALUES
(1, 'CC', 1, 1, EXTRACT(YEAR FROM CURRENT_DATE)::INT, true),
(2, 'CE', 1, 1, EXTRACT(YEAR FROM CURRENT_DATE)::INT, true),
(3, 'CI', 1, 1, EXTRACT(YEAR FROM CURRENT_DATE)::INT, true),
(4, 'NC', 1, 1, EXTRACT(YEAR FROM CURRENT_DATE)::INT, true),
(5, 'ND', 1, 1, EXTRACT(YEAR FROM CURRENT_DATE)::INT, true),
(6, 'FV', 1, 1, EXTRACT(YEAR FROM CURRENT_DATE)::INT, true),
(7, 'DS', 1, 1, EXTRACT(YEAR FROM CURRENT_DATE)::INT, true),
(8, 'CZ', 1, 1, EXTRACT(YEAR FROM CURRENT_DATE)::INT, true),
(9, 'AJ', 1, 1, EXTRACT(YEAR FROM CURRENT_DATE)::INT, true)
ON CONFLICT ("documentTypeId", "fiscalYear", prefix) DO NOTHING;

-- 5. Plan Único de Cuentas (PUC) Colombiano Base
-- Nivel 1: Clases
INSERT INTO public."Account" (code, name, level, nature, "allowsMovement", "requiresThirdParty", "requiresCostCenter", "parentId", "isActive") VALUES
('1', 'ACTIVO', 1, 'DEBIT', false, false, false, NULL, true),
('2', 'PASIVO', 1, 'CREDIT', false, false, false, NULL, true),
('3', 'PATRIMONIO', 1, 'CREDIT', false, false, false, NULL, true),
('4', 'INGRESOS', 1, 'CREDIT', false, false, false, NULL, true),
('5', 'GASTOS', 1, 'DEBIT', false, false, false, NULL, true),
('6', 'COSTOS DE VENTAS', 1, 'DEBIT', false, false, false, NULL, true),
('7', 'COSTOS DE PRODUCCION O DE OPERACION', 1, 'DEBIT', false, false, false, NULL, true),
('8', 'CUENTAS DE ORDEN DEUDORAS', 1, 'DEBIT', false, false, false, NULL, true),
('9', 'CUENTAS DE ORDEN ACREEDORAS', 1, 'CREDIT', false, false, false, NULL, true)
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name, nature = EXCLUDED.nature;

-- Nivel 2: Grupos Principales
INSERT INTO public."Account" (code, name, level, nature, "allowsMovement", "requiresThirdParty", "requiresCostCenter", "parentId", "isActive") VALUES
('11', 'DISPONIBLE', 2, 'DEBIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '1'), true),
('12', 'INVERSIONES', 2, 'DEBIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '1'), true),
('13', 'DEUDORES (CLIENTES)', 2, 'DEBIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '1'), true),
('14', 'INVENTARIOS', 2, 'DEBIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '1'), true),
('15', 'PROPIEDAD, PLANTA Y EQUIPO', 2, 'DEBIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '1'), true),
('21', 'OBLIGACIONES FINANCIERAS', 2, 'CREDIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '2'), true),
('22', 'PROVEEDORES', 2, 'CREDIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '2'), true),
('23', 'CUENTAS POR PAGAR', 2, 'CREDIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '2'), true),
('24', 'IMPUESTOS, GRAVAMENES Y TASAS', 2, 'CREDIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '2'), true),
('31', 'CAPITAL SOCIAL', 2, 'CREDIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '3'), true),
('36', 'RESULTADOS DEL EJERCICIO', 2, 'CREDIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '3'), true),
('41', 'OPERACIONALES', 2, 'CREDIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '4'), true),
('51', 'OPERACIONALES DE ADMINISTRACION', 2, 'DEBIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '5'), true),
('52', 'OPERACIONALES DE VENTAS', 2, 'DEBIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '5'), true)
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name;

-- Nivel 3 y 4: Cuentas y Subcuentas Operacionales
INSERT INTO public."Account" (code, name, level, nature, "allowsMovement", "requiresThirdParty", "requiresCostCenter", "parentId", "isActive") VALUES
('1105', 'CAJA', 3, 'DEBIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '11'), true),
('110505', 'CAJA GENERAL', 4, 'DEBIT', true, true, false, (SELECT id FROM public."Account" WHERE code = '1105'), true),
('1110', 'BANCOS', 3, 'DEBIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '11'), true),
('111005', 'MONEDA NACIONAL', 4, 'DEBIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '1110'), true),
('11100501', 'BANCOLOMBIA CTA CTE #1', 5, 'DEBIT', true, true, false, (SELECT id FROM public."Account" WHERE code = '111005'), true),
('1305', 'CLIENTES NACIONALES', 3, 'DEBIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '13'), true),
('130505', 'CLIENTES NACIONALES - CARTERA', 4, 'DEBIT', true, true, false, (SELECT id FROM public."Account" WHERE code = '1305'), true),
('2205', 'PROVEEDORES NACIONALES', 3, 'CREDIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '22'), true),
('220505', 'PROVEEDORES NACIONALES - CUENTAS POR PAGAR', 4, 'CREDIT', true, true, false, (SELECT id FROM public."Account" WHERE code = '2205'), true),
('2365', 'RETENCION EN LA FUENTE', 3, 'CREDIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '23'), true),
('236540', 'RETEFUENTE POR COMPRAS', 4, 'CREDIT', true, true, false, (SELECT id FROM public."Account" WHERE code = '2365'), true),
('236525', 'RETEFUENTE POR SERVICIOS', 4, 'CREDIT', true, true, false, (SELECT id FROM public."Account" WHERE code = '2365'), true),
('2408', 'IMPUESTO SOBRE LAS VENTAS POR PAGAR (IVA)', 3, 'CREDIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '24'), true),
('240801', 'IVA GENERADO EN VENTAS 19%', 4, 'CREDIT', true, true, false, (SELECT id FROM public."Account" WHERE code = '2408'), true),
('240802', 'IVA DESCONTABLE EN COMPRAS 19%', 4, 'DEBIT', true, true, false, (SELECT id FROM public."Account" WHERE code = '2408'), true),
('4135', 'COMERCIO AL POR MAYOR Y AL POR MENOR', 3, 'CREDIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '41'), true),
('413501', 'INGRESOS POR VENTAS GRAVADAS 19%', 4, 'CREDIT', true, true, true, (SELECT id FROM public."Account" WHERE code = '4135'), true),
('5105', 'GASTOS DE PERSONAL', 3, 'DEBIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '51'), true),
('510506', 'SUELDOS', 4, 'DEBIT', true, true, true, (SELECT id FROM public."Account" WHERE code = '5105'), true),
('5135', 'SERVICIOS', 3, 'DEBIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '51'), true),
('513505', 'ASEO Y VIGILANCIA', 4, 'DEBIT', true, true, true, (SELECT id FROM public."Account" WHERE code = '5135'), true)
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name, "allowsMovement" = EXCLUDED."allowsMovement";

-- 6. Centros de Costo Iniciales
INSERT INTO public."CostCenter" (id, code, name, level, "isActive") VALUES
(1, '01', 'ADMINISTRACION GENERAL', 1, true),
(2, '02', 'VENTAS Y COMERCIAL', 1, true),
(3, '03', 'OPERACIONES Y SERVICIOS', 1, true)
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name;

-- 7. Bancos Base de Colombia
INSERT INTO public."Bank" (id, code, name, nit, "isActive") VALUES
(1, '007', 'BANCOLOMBIA S.A.', '890903938-8', true),
(2, '001', 'BANCO DE BOGOTA', '860002964-4', true),
(3, '051', 'DAVIVIENDA S.A.', '860034313-7', true),
(4, '002', 'BANCO POPULAR', '860007738-9', true),
(5, '013', 'BBVA COLOMBIA', '860003020-1', true)
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name;

-- 8. Impuestos y Retenciones Base
INSERT INTO public."TaxConcept" (code, name, type, "ratePercentage", "minimumBaseAmount", "accountDebitId", "accountCreditId", "isActive") VALUES
('IVA19_GEN', 'IVA Generado en Ventas 19%', 'IVA', 19.0000, 0, NULL, (SELECT id FROM public."Account" WHERE code = '240801'), true),
('IVA19_DESC', 'IVA Descontable en Compras 19%', 'IVA', 19.0000, 0, (SELECT id FROM public."Account" WHERE code = '240802'), NULL, true),
('RF_COMPRAS_25', 'Retefuente por Compras Generales 2.5%', 'RETEFUENTE', 2.5000, 1150000.0000, NULL, (SELECT id FROM public."Account" WHERE code = '236540'), true),
('RF_SERVICIOS_4', 'Retefuente por Servicios Declarantes 4%', 'RETEFUENTE', 4.0000, 190000.0000, NULL, (SELECT id FROM public."Account" WHERE code = '236525'), true)
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name, "ratePercentage" = EXCLUDED."ratePercentage";
