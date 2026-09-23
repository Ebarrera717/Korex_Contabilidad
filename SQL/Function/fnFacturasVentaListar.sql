-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIÓN SQL: fnFacturasVentaListar
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnFacturasVentaListar";
END $$;

CREATE OR REPLACE FUNCTION public."fnFacturasVentaListar"(
    p_company_id INTEGER,
    p_third_party_id INTEGER DEFAULT NULL,
    p_status VARCHAR(20) DEFAULT NULL,
    p_limit INTEGER DEFAULT 100,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id INTEGER,
    "invoiceNumber" VARCHAR(50),
    "issueDate" TIMESTAMP WITH TIME ZONE,
    "dueDate" TIMESTAMP WITH TIME ZONE,
    "thirdPartyId" INTEGER,
    "customerName" VARCHAR(255),
    "customerNit" VARCHAR(50),
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
        r.id,
        r."invoiceNumber",
        r."issueDate",
        r."dueDate",
        r."thirdPartyId",
        t."fullName" AS "customerName",
        t."documentNumber" AS "customerNit",
        r.subtotal,
        r."taxAmount",
        r."retentionAmount",
        r."totalAmount",
        r."paidAmount",
        r."balanceAmount",
        r.status,
        r."journalEntryId",
        j."entryNumber" AS "journalNumber"
    FROM public."ReceivableInvoice" r
    JOIN public."ThirdParty" t ON t.id = r."thirdPartyId"
    LEFT JOIN public."JournalEntry" j ON j.id = r."journalEntryId"
    WHERE r."companyId" = p_company_id
      AND (p_third_party_id IS NULL OR r."thirdPartyId" = p_third_party_id)
      AND (p_status IS NULL OR r.status = p_status)
    ORDER BY r."issueDate" DESC, r.id DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;
