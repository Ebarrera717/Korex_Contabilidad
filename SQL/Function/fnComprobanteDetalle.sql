-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIONES DE CONSULTA DE DETALLE COMPROBANTES (POSTGRESQL)
-- Archivo: SQL/Function/fnComprobanteDetalle.sql
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnComprobanteDetalle"(INT);
END $$;

CREATE OR REPLACE FUNCTION public."fnComprobanteDetalle"(
    p_journal_id INT
)
RETURNS TABLE (
    id INT,
    "journalEntryId" INT,
    "accountId" INT,
    "accountCode" VARCHAR,
    "accountName" VARCHAR,
    "thirdPartyId" INT,
    "thirdPartyDoc" VARCHAR,
    "thirdPartyName" VARCHAR,
    "costCenterId" INT,
    "costCenterCode" VARCHAR,
    "costCenterName" VARCHAR,
    debit NUMERIC,
    credit NUMERIC,
    "baseAmount" NUMERIC,
    description VARCHAR,
    "documentReference" VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ji.id,
        ji."journalEntryId",
        ji."accountId",
        a.code AS "accountCode",
        a.name AS "accountName",
        ji."thirdPartyId",
        t."documentNumber" AS "thirdPartyDoc",
        t."fullName" AS "thirdPartyName",
        ji."costCenterId",
        cc.code AS "costCenterCode",
        cc.name AS "costCenterName",
        ji.debit,
        ji.credit,
        ji."baseAmount",
        ji.description,
        ji."documentReference"
    FROM public."JournalEntryItem" ji
    INNER JOIN public."Account" a ON ji."accountId" = a.id
    LEFT JOIN public."ThirdParty" t ON ji."thirdPartyId" = t.id
    LEFT JOIN public."CostCenter" cc ON ji."costCenterId" = cc.id
    WHERE ji."journalEntryId" = p_journal_id
    ORDER BY ji.id ASC;
END;
$$ LANGUAGE plpgsql;
