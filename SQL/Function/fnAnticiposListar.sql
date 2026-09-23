-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIÓN SQL: fnAnticiposListar
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnAnticiposListar";
END $$;

CREATE OR REPLACE FUNCTION public."fnAnticiposListar"(
    p_company_id INTEGER,
    p_advance_type VARCHAR(20) DEFAULT NULL,
    p_third_party_id INTEGER DEFAULT NULL,
    p_status VARCHAR(20) DEFAULT NULL,
    p_limit INTEGER DEFAULT 100,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id INTEGER,
    "advanceType" VARCHAR(20),
    "advanceDate" TIMESTAMP WITH TIME ZONE,
    "thirdPartyId" INTEGER,
    "thirdPartyName" VARCHAR(255),
    "thirdPartyNit" VARCHAR(50),
    amount NUMERIC(18, 4),
    "usedAmount" NUMERIC(18, 4),
    "balanceAmount" NUMERIC(18, 4),
    status VARCHAR(20),
    concept TEXT,
    "treasuryMovementId" INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.id,
        a."advanceType",
        a."advanceDate",
        a."thirdPartyId",
        t."fullName" AS "thirdPartyName",
        t."documentNumber" AS "thirdPartyNit",
        a.amount,
        a."usedAmount",
        a."balanceAmount",
        a.status,
        a.concept,
        a."treasuryMovementId"
    FROM public."AdvancePayment" a
    JOIN public."ThirdParty" t ON t.id = a."thirdPartyId"
    WHERE a."companyId" = p_company_id
      AND (p_advance_type IS NULL OR a."advanceType" = p_advance_type)
      AND (p_third_party_id IS NULL OR a."thirdPartyId" = p_third_party_id)
      AND (p_status IS NULL OR a.status = p_status)
    ORDER BY a."advanceDate" DESC, a.id DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;
