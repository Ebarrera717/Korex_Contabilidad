-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIÓN SQL: fnActivosFijosListar
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnActivosFijosListar";
END $$;

CREATE OR REPLACE FUNCTION public."fnActivosFijosListar"(
    p_company_id INTEGER,
    p_category_id INTEGER DEFAULT NULL,
    p_status VARCHAR(30) DEFAULT NULL,
    p_limit INTEGER DEFAULT 100,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id INTEGER,
    code VARCHAR(50),
    name VARCHAR(150),
    "categoryId" INTEGER,
    "categoryName" VARCHAR(100),
    "purchaseDate" TIMESTAMP WITH TIME ZONE,
    "activationDate" TIMESTAMP WITH TIME ZONE,
    "acquisitionCost" NUMERIC(18, 4),
    "residualValue" NUMERIC(18, 4),
    "usefulLifeMonths" INTEGER,
    "depreciatedMonths" INTEGER,
    "accumulatedDepreciation" NUMERIC(18, 4),
    "netBookValue" NUMERIC(18, 4),
    "monthlyDepreciation" NUMERIC(18, 4),
    "costCenterId" INTEGER,
    "costCenterName" VARCHAR(100),
    "responsibleThirdPartyId" INTEGER,
    "responsibleName" VARCHAR(255),
    location VARCHAR(150),
    status VARCHAR(30)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.id,
        a.code,
        a.name,
        a."categoryId",
        c.name AS "categoryName",
        a."purchaseDate",
        a."activationDate",
        a."acquisitionCost",
        a."residualValue",
        a."usefulLifeMonths",
        a."depreciatedMonths",
        a."accumulatedDepreciation",
        a."netBookValue",
        a."monthlyDepreciation",
        a."costCenterId",
        cc.name AS "costCenterName",
        a."responsibleThirdPartyId",
        t."fullName" AS "responsibleName",
        a.location,
        a.status
    FROM public."FixedAsset" a
    JOIN public."FixedAssetCategory" c ON c.id = a."categoryId"
    LEFT JOIN public."CostCenter" cc ON cc.id = a."costCenterId"
    LEFT JOIN public."ThirdParty" t ON t.id = a."responsibleThirdPartyId"
    WHERE a."companyId" = p_company_id
      AND (p_category_id IS NULL OR a."categoryId" = p_category_id)
      AND (p_status IS NULL OR a.status = p_status)
    ORDER BY a.code ASC
    LIMIT p_limit OFFSET p_offset;
END;
$$;
