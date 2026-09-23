-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIONES SQL DE LISTADO MAESTROS (POSTGRESQL)
-- Archivo: SQL/Function/fnBankListar.sql
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnBankListar"();
END $$;

CREATE OR REPLACE FUNCTION public."fnBankListar"()
RETURNS TABLE (
    id INT,
    code VARCHAR,
    name VARCHAR,
    nit VARCHAR,
    phone VARCHAR,
    "contactName" VARCHAR,
    "isActive" BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        b.id,
        b.code,
        b.name,
        b.nit,
        b.phone,
        b."contactName",
        b."isActive"
    FROM public."Bank" b
    ORDER BY b.name ASC;
END;
$$ LANGUAGE plpgsql;
