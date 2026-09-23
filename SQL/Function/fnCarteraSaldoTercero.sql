-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIÓN SQL: fnCarteraSaldoTercero
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnCarteraSaldoTercero";
END $$;

CREATE OR REPLACE FUNCTION public."fnCarteraSaldoTercero"(
    p_company_id INTEGER,
    p_third_party_id INTEGER DEFAULT NULL
)
RETURNS TABLE (
    "thirdPartyId" INTEGER,
    "documentNumber" VARCHAR(50),
    "fullName" VARCHAR(255),
    "totalInvoiced" NUMERIC(18, 4),
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
        COALESCE(SUM(r."totalAmount"), 0) AS "totalInvoiced",
        COALESCE(SUM(r."paidAmount"), 0) AS "totalPaid",
        COALESCE(SUM(r."balanceAmount"), 0) AS "currentBalance",
        COUNT(r.id) AS "invoicesCount"
    FROM public."ThirdParty" t
    JOIN public."ReceivableInvoice" r ON r."thirdPartyId" = t.id
    WHERE r."companyId" = p_company_id
      AND (p_third_party_id IS NULL OR t.id = p_third_party_id)
      AND r.status IN ('POSTED', 'PARTIAL')
    GROUP BY t.id, t."documentNumber", t."fullName"
    ORDER BY "currentBalance" DESC;
END;
$$;
