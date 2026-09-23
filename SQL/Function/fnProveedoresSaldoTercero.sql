-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIÓN SQL: fnProveedoresSaldoTercero
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnProveedoresSaldoTercero";
END $$;

CREATE OR REPLACE FUNCTION public."fnProveedoresSaldoTercero"(
    p_company_id INTEGER,
    p_third_party_id INTEGER DEFAULT NULL
)
RETURNS TABLE (
    "thirdPartyId" INTEGER,
    "documentNumber" VARCHAR(50),
    "fullName" VARCHAR(255),
    "totalPurchased" NUMERIC(18, 4),
    "totalPaid" NUMERIC(18, 4),
    "currentBalance" NUMERIC(18, 4),
    "invoicesCount" BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id AS "thirdPartyId",
        t."documentNumber",
        t."fullName",
        COALESCE(SUM(p."totalAmount"), 0) AS "totalPurchased",
        COALESCE(SUM(p."paidAmount"), 0) AS "totalPaid",
        COALESCE(SUM(p."balanceAmount"), 0) AS "currentBalance",
        COUNT(p.id) AS "invoicesCount"
    FROM public."ThirdParty" t
    JOIN public."PayableInvoice" p ON p."thirdPartyId" = t.id
    WHERE p."companyId" = p_company_id
      AND (p_third_party_id IS NULL OR t.id = p_third_party_id)
      AND p.status IN ('POSTED', 'PARTIAL')
    GROUP BY t.id, t."documentNumber", t."fullName"
    ORDER BY "currentBalance" DESC;
END;
$$;
