-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIONES SQL DE LISTADO MAESTROS (POSTGRESQL)
-- Archivo: SQL/Function/fnPucListar.sql
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnPucListar"(VARCHAR, INT, BOOLEAN);
END $$;

CREATE OR REPLACE FUNCTION public."fnPucListar"(
    p_search VARCHAR DEFAULT NULL,
    p_level INT DEFAULT NULL,
    p_movement_only BOOLEAN DEFAULT NULL
)
RETURNS TABLE (
    id INT,
    code VARCHAR,
    name VARCHAR,
    level INT,
    nature VARCHAR,
    "allowsMovement" BOOLEAN,
    "requiresThirdParty" BOOLEAN,
    "requiresCostCenter" BOOLEAN,
    "parentId" INT,
    "parentCode" VARCHAR,
    "parentName" VARCHAR,
    "isActive" BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.id,
        a.code,
        a.name,
        a.level,
        a.nature,
        a."allowsMovement",
        a."requiresThirdParty",
        a."requiresCostCenter",
        a."parentId",
        p.code AS "parentCode",
        p.name AS "parentName",
        a."isActive"
    FROM public."Account" a
    LEFT JOIN public."Account" p ON a."parentId" = p.id
    WHERE 
        (p_search IS NULL OR TRIM(p_search) = '' OR (a.code ILIKE '%' || TRIM(p_search) || '%' OR a.name ILIKE '%' || TRIM(p_search) || '%'))
        AND (p_level IS NULL OR a.level = p_level)
        AND (p_movement_only IS NULL OR a."allowsMovement" = p_movement_only)
    ORDER BY a.code ASC;
END;
$$ LANGUAGE plpgsql;
