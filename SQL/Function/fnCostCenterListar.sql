-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIONES SQL DE LISTADO MAESTROS (POSTGRESQL)
-- Archivo: SQL/Function/fnCostCenterListar.sql
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnCostCenterListar"();
END $$;

CREATE OR REPLACE FUNCTION public."fnCostCenterListar"()
RETURNS TABLE (
    id INT,
    code VARCHAR,
    name VARCHAR,
    level INT,
    "parentId" INT,
    "parentName" VARCHAR,
    "isActive" BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cc.id,
        cc.code,
        cc.name,
        cc.level,
        cc."parentId",
        p.name AS "parentName",
        cc."isActive"
    FROM public."CostCenter" cc
    LEFT JOIN public."CostCenter" p ON cc."parentId" = p.id
    ORDER BY cc.code ASC;
END;
$$ LANGUAGE plpgsql;
