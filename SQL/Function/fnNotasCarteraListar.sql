-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIÓN SQL: fnNotasCarteraListar
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnNotasCarteraListar";
END $$;

CREATE OR REPLACE FUNCTION public."fnNotasCarteraListar"(
    p_company_id INTEGER,
    p_note_type VARCHAR(30) DEFAULT NULL,
    p_third_party_id INTEGER DEFAULT NULL,
    p_limit INTEGER DEFAULT 100,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id INTEGER,
    "noteType" VARCHAR(30),
    "noteNumber" VARCHAR(50),
    "noteDate" TIMESTAMP WITH TIME ZONE,
    "thirdPartyId" INTEGER,
    "thirdPartyName" VARCHAR(255),
    "thirdPartyNit" VARCHAR(50),
    concept TEXT,
    subtotal NUMERIC(18, 4),
    "taxAmount" NUMERIC(18, 4),
    "totalAmount" NUMERIC(18, 4),
    "appliedAmount" NUMERIC(18, 4),
    "balanceAmount" NUMERIC(18, 4),
    status VARCHAR(20),
    "receivableInvoiceId" INTEGER,
    "payableInvoiceId" INTEGER,
    "journalEntryId" INTEGER,
    "journalNumber" VARCHAR(50)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        n.id,
        n."noteType",
        n."noteNumber",
        n."noteDate",
        n."thirdPartyId",
        t."fullName" AS "thirdPartyName",
        t."documentNumber" AS "thirdPartyNit",
        n.concept,
        n.subtotal,
        n."taxAmount",
        n."totalAmount",
        n."appliedAmount",
        n."balanceAmount",
        n.status,
        n."receivableInvoiceId",
        n."payableInvoiceId",
        n."journalEntryId",
        j."entryNumber" AS "journalNumber"
    FROM public."CreditDebitNote" n
    JOIN public."ThirdParty" t ON t.id = n."thirdPartyId"
    LEFT JOIN public."JournalEntry" j ON j.id = n."journalEntryId"
    WHERE n."companyId" = p_company_id
      AND (p_note_type IS NULL OR n."noteType" = p_note_type)
      AND (p_third_party_id IS NULL OR n."thirdPartyId" = p_third_party_id)
    ORDER BY n."noteDate" DESC, n.id DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;
