-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIONES DE CONCILIACIÓN BANCARIA (POSTGRESQL)
-- Archivo: SQL/Function/fnConciliacionBancariaConsultar.sql
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnConciliacionBancariaConsultar"(INT, INT, INT);
    DROP FUNCTION IF EXISTS public."fnConciliacionPartidasListar"(INT);
END $$;

CREATE OR REPLACE FUNCTION public."fnConciliacionBancariaConsultar"(
    p_bank_account_id INT,
    p_year INT,
    p_month INT
)
RETURNS TABLE (
    id INT,
    "companyId" INT,
    "bankAccountId" INT,
    "bankName" VARCHAR,
    "accountNumber" VARCHAR,
    year INT,
    month INT,
    "initialBalance" NUMERIC,
    "finalBankStatementBalance" NUMERIC,
    "bookBalance" NUMERIC,
    difference NUMERIC,
    status VARCHAR,
    "closedAt" TIMESTAMP(3),
    "closedByName" VARCHAR,
    observations TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        br.id,
        br."companyId",
        br."bankAccountId",
        b.name AS "bankName",
        ba."accountNumber",
        br.year,
        br.month,
        br."initialBalance",
        br."finalBankStatementBalance",
        br."bookBalance",
        br.difference,
        br.status,
        br."closedAt",
        u.name AS "closedByName",
        br.observations
    FROM public."BankReconciliation" br
    INNER JOIN public."BankAccount" ba ON br."bankAccountId" = ba.id
    INNER JOIN public."Bank" b ON ba."bankId" = b.id
    LEFT JOIN public."User" u ON br."closedById" = u.id
    WHERE br."bankAccountId" = p_bank_account_id AND br.year = p_year AND br.month = p_month;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public."fnConciliacionPartidasListar"(
    p_reconciliation_id INT
)
RETURNS TABLE (
    id INT,
    "bankReconciliationId" INT,
    "itemType" VARCHAR,
    "itemDate" TIMESTAMP(3),
    "documentNumber" VARCHAR,
    description VARCHAR,
    amount NUMERIC,
    status VARCHAR,
    "journalEntryItemId" INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        bri.id,
        bri."bankReconciliationId",
        bri."itemType",
        bri."itemDate",
        bri."documentNumber",
        bri.description,
        bri.amount,
        bri.status,
        bri."journalEntryItemId"
    FROM public."BankReconciliationItem" bri
    WHERE bri."bankReconciliationId" = p_reconciliation_id
    ORDER BY bri."itemDate" ASC;
END;
$$ LANGUAGE plpgsql;
