-- ============================================================================
-- PROYECTO: KOREX_CONTABILIDAD
-- MODULO: FASE 8 - PLANTILLAS BASE DE IMPORTACION Y EXPORTACION
-- ============================================================================

INSERT INTO public."DataInterfaceTemplate" ("code", "name", "category", "formatType", "mappingConfig", "isActive", "createdAt", "updatedAt")
VALUES 
(
    'PUC_EXCEL_STANDARD',
    'Plantilla Oficial de Importación de Cuentas PUC (Excel)',
    'PUC',
    'EXCEL',
    '{"codeColumn": "CODIGO_CUENTA", "nameColumn": "NOMBRE_CUENTA", "natureColumn": "NATURALEZA", "levelColumn": "NIVEL", "isMovementColumn": "ES_MOVIMIENTO", "requiresThirdPartyColumn": "REQUIERE_TERCERO", "requiresCostCenterColumn": "REQUIERE_CENTRO_COSTO"}'::jsonb,
    true,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
),
(
    'TERCEROS_EXCEL_STANDARD',
    'Plantilla Oficial de Importación de Terceros y Clientes/Proveedores (Excel)',
    'TERCEROS',
    'EXCEL',
    '{"documentTypeColumn": "TIPO_DOCUMENTO", "documentNumberColumn": "NUMERO_IDENTIFICACION", "businessNameColumn": "RAZON_SOCIAL", "firstNameColumn": "PRIMER_NOMBRE", "lastNameColumn": "PRIMER_APELLIDO", "emailColumn": "CORREO_ELECTRONICO", "phoneColumn": "TELEFONO", "cityColumn": "CIUDAD", "addressColumn": "DIRECCION", "isCustomerColumn": "ES_CLIENTE", "isVendorColumn": "ES_PROVEEDOR"}'::jsonb,
    true,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
),
(
    'COMPROBANTES_EXCEL_STANDARD',
    'Plantilla de Importación de Comprobantes y Asientos Contables (Excel)',
    'COMPROBANTES',
    'EXCEL',
    '{"dateColumn": "FECHA", "docTypeColumn": "TIPO_DOCUMENTO", "consecutiveColumn": "NUMERO_COMPROBANTE", "conceptColumn": "CONCEPTO_CABECERA", "accountColumn": "CODIGO_CUENTA", "thirdPartyDocColumn": "NIT_TERCERO", "costCenterColumn": "CENTRO_COSTO", "debitColumn": "DEBITO", "creditColumn": "CREDITO", "descriptionColumn": "DETALLE_ASIENTO"}'::jsonb,
    true,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
),
(
    'EXOGENA_XML_1001',
    'Formato de Exportación Exógena DIAN 1001 (XML Prevalidador)',
    'EXOGENA',
    'XML',
    '{"formatNumber": "1001", "version": "10", "rootElement": "masiva", "rowElement": "pagos"}'::jsonb,
    true,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
)
ON CONFLICT ("code") DO UPDATE SET 
    "name" = EXCLUDED."name",
    "mappingConfig" = EXCLUDED."mappingConfig",
    "updatedAt" = CURRENT_TIMESTAMP;
