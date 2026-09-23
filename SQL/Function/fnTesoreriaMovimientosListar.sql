-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIONES DE CONSULTA DE TESORERÍA (POSTGRESQL)
-- Archivo: SQL/Function/fnTesoreriaMovimientosListar.sql
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnTesoreriaMovimientosListar"(INT, VARCHAR, TIMESTAMP(3), TIMESTAMP(3), INT, INT, VARCHAR, VARCHAR);
END $$;

CREATE OR REPLACE FUNCTION public."fnTesoreriaMovimientosListar"(
    p_company_id INT DEFAULT NULL,
    p_type VARCHAR DEFAULT NULL, -- 'INGRESO', 'EGRESO', 'TRANSFERENCIA'
    p_start_date TIMESTAMP(3) DEFAULT NULL,
    p_end_date TIMESTAMP(3) DEFAULT NULL,
    p_bank_account_id INT DEFAULT NULL,
    p_cash_box_id INT DEFAULT NULL,
    p_status VARCHAR DEFAULT NULL,
    p_search VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    id INT,
    "companyId" INT,
    "movementType" VARCHAR,
    "documentTypeId" INT,
    "documentTypeCode" VARCHAR,
    "documentTypeName" VARCHAR,
    "consecutiveNumber" INT,
    "entryNumber" VARCHAR,
    "movementDate" TIMESTAMP(3),
    "bankAccountId" INT,
    "bankName" VARCHAR,
    "bankAccountNumber" VARCHAR,
    "cashBoxId" INT,
    "cashBoxName" VARCHAR,
    "thirdPartyId" INT,
    "thirdPartyDoc" VARCHAR,
    "thirdPartyName" VARCHAR,
    concept VARCHAR,
    "paymentMethod" VARCHAR,
    "checkNumber" VARCHAR,
    "totalAmount" NUMERIC,
    status VARCHAR,
    "journalEntryId" INT,
    "createdById" INT,
    "createdByName" VARCHAR,
    "createdAt" TIMESTAMP(3)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        tm.id,
        tm."companyId",
        tm."movementType",
        tm."documentTypeId",
        dt.code AS "documentTypeCode",
        dt.name AS "documentTypeName",
        tm."consecutiveNumber",
        tm."entryNumber",
        tm."movementDate",
        tm."bankAccountId",
        b.name AS "bankName",
        ba."accountNumber" AS "bankAccountNumber",
        tm."cashBoxId",
        cb.name AS "cashBoxName",
        tm."thirdPartyId",
        tp."documentNumber" AS "thirdPartyDoc",
        tp."fullName" AS "thirdPartyName",
        tm.concept,
        tm."paymentMethod",
        tm."checkNumber",
        tm."totalAmount",
        tm.status,
        tm."journalEntryId",
        tm."createdById",
        u.name AS "createdByName",
        tm."createdAt"
    FROM public."TreasuryMovement" tm
    INNER JOIN public."DocumentType" dt ON tm."documentTypeId" = dt.id
    LEFT JOIN public."BankAccount" ba ON tm."bankAccountId" = ba.id
    LEFT JOIN public."Bank" b ON ba."bankId" = b.id
    LEFT JOIN public."CashBox" cb ON tm."cashBoxId" = cb.id
    LEFT JOIN public."ThirdParty" tp ON tm."thirdPartyId" = tp.id
    LEFT JOIN public."User" u ON tm."createdById" = u.id
    WHERE 
        (p_company_id IS NULL OR tm."companyId" = p_company_id)
        AND (p_type IS NULL OR tm."movementType" = p_type)
        AND (p_start_date IS NULL OR tm."movementDate" >= p_start_date)
        AND (p_end_date IS NULL OR tm."movementDate" <= p_end_date)
        AND (p_bank_account_id IS NULL OR tm."bankAccountId" = p_bank_account_id)
        AND (p_cash_box_id IS NULL OR tm."cashBoxId" = p_cash_box_id)
        AND (p_status IS NULL OR tm.status = p_status)
        AND (
            p_search IS NULL OR TRIM(p_search) = ''
            OR tm."entryNumber" ILIKE '%' || TRIM(p_search) || '%'
            OR tm.concept ILIKE '%' || TRIM(p_search) || '%'
            OR (tp."fullName" IS NOT NULL AND tp."fullName" ILIKE '%' || TRIM(p_search) || '%')
        )
    ORDER BY tm."movementDate" DESC, tm.id DESC;
END;
$$ LANGUAGE plpgsql;
