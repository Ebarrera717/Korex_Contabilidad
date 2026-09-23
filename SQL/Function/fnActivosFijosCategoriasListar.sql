-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIÓN SQL: fnActivosFijosCategoriasListar
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnActivosFijosCategoriasListar";
END $$;

CREATE OR REPLACE FUNCTION public."fnActivosFijosCategoriasListar"()
RETURNS TABLE (
    id INTEGER,
    code VARCHAR(50),
    name VARCHAR(100),
    "defaultUsefulLifeMonths" INTEGER,
    "accountAssetId" INTEGER,
    "assetAccountCode" VARCHAR(50),
    "assetAccountName" VARCHAR(255),
    "accountAccumDeprId" INTEGER,
    "accumDeprAccountCode" VARCHAR(50),
    "accumDeprAccountName" VARCHAR(255),
    "accountExpenseDeprId" INTEGER,
    "expenseDeprAccountCode" VARCHAR(50),
    "expenseDeprAccountName" VARCHAR(255),
    "isActive" BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.code,
        c.name,
        c."defaultUsefulLifeMonths",
        c."accountAssetId",
        aa.code AS "assetAccountCode",
        aa.name AS "assetAccountName",
        c."accountAccumDeprId",
        ad.code AS "accumDeprAccountCode",
        ad.name AS "accumDeprAccountName",
        c."accountExpenseDeprId",
        ed.code AS "expenseDeprAccountCode",
        ed.name AS "expenseDeprAccountName",
        c."isActive"
    FROM public."FixedAssetCategory" c
    JOIN public."Account" aa ON aa.id = c."accountAssetId"
    JOIN public."Account" ad ON ad.id = c."accountAccumDeprId"
    JOIN public."Account" ed ON ed.id = c."accountExpenseDeprId"
    ORDER BY c.code ASC;
END;
$$;
