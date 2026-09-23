-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIONES SQL DE LISTADO MAESTROS (POSTGRESQL)
-- Archivo: SQL/Function/fnConsecutiveListar.sql
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnConsecutiveListar"(INT);
END $$;

CREATE OR REPLACE FUNCTION public."fnConsecutiveListar"(
    p_year INT DEFAULT NULL
)
RETURNS TABLE (
    id INT,
    "documentTypeId" INT,
    "documentTypeCode" VARCHAR,
    "documentTypeName" VARCHAR,
    prefix VARCHAR,
    "currentNumber" INT,
    "initialNumber" INT,
    "finalNumber" INT,
    "fiscalYear" INT,
    "isActive" BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c."documentTypeId",
        d.code AS "documentTypeCode",
        d.name AS "documentTypeName",
        c.prefix,
        c."currentNumber",
        c."initialNumber",
        c."finalNumber",
        c."fiscalYear",
        c."isActive"
    FROM public."Consecutive" c
    INNER JOIN public."DocumentType" d ON c."documentTypeId" = d.id
    WHERE (p_year IS NULL OR c."fiscalYear" = p_year)
    ORDER BY d.code ASC, c.prefix ASC;
END;
$$ LANGUAGE plpgsql;
