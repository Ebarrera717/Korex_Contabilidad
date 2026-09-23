-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIÓN SQL: fnFacturasCompraListar
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnFacturasCompraListar";
END $$;

CREATE OR REPLACE FUNCTION public."fnFacturasCompraListar"(
    p_company_id INTEGER,
    p_third_party_id INTEGER DEFAULT NULL,
    p_status VARCHAR(20) DEFAULT NULL,
    p_limit INTEGER DEFAULT 100,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id INTEGER,
    "invoiceNumber" VARCHAR(50),
    "internalNumber" VARCHAR(50),
    "issueDate" TIMESTAMP WITH TIME ZONE,
    "dueDate" TIMESTAMP WITH TIME ZONE,
    "thirdPartyId" INTEGER,
    "supplierName" VARCHAR(255),
    "supplierNit" VARCHAR(50),
    subtotal NUMERIC(18, 4),
    "taxAmount" NUMERIC(18, 4),
    "retentionAmount" NUMERIC(18, 4),
    "totalAmount" NUMERIC(18, 4),
    "paidAmount" NUMERIC(18, 4),
    "balanceAmount" NUMERIC(18, 4),
    status VARCHAR(20),
    "journalEntryId" INTEGER,
    "journalNumber" VARCHAR(50)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p."invoiceNumber",
        p."internalNumber",
        p."issueDate",
        p."dueDate",
        p."thirdPartyId",
        t."fullName" AS "supplierName",
        t."documentNumber" AS "supplierNit",
        p.subtotal,
        p."taxAmount",
        p."retentionAmount",
        p."totalAmount",
        p."paidAmount",
        p."balanceAmount",
        p.status,
        p."journalEntryId",
        j."entryNumber" AS "journalNumber"
    FROM public."PayableInvoice" p
    JOIN public."ThirdParty" t ON t.id = p."thirdPartyId"
    LEFT JOIN public."JournalEntry" j ON j.id = p."journalEntryId"
    WHERE p."companyId" = p_company_id
      AND (p_third_party_id IS NULL OR p."thirdPartyId" = p_third_party_id)
      AND (p_status IS NULL OR p.status = p_status)
    ORDER BY p."issueDate" DESC, p.id DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;
