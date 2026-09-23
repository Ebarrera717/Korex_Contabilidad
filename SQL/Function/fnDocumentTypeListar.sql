-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIONES SQL DE LISTADO MAESTROS (POSTGRESQL)
-- Archivo: SQL/Function/fnDocumentTypeListar.sql
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnDocumentTypeListar"();
END $$;

CREATE OR REPLACE FUNCTION public."fnDocumentTypeListar"()
RETURNS TABLE (
    id INT,
    code VARCHAR,
    name VARCHAR,
    prefix VARCHAR,
    "isAutomatic" BOOLEAN,
    "isActive" BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        d.id,
        d.code,
        d.name,
        d.prefix,
        d."isAutomatic",
        d."isActive"
    FROM public."DocumentType" d
    ORDER BY d.id ASC;
END;
$$ LANGUAGE plpgsql;
