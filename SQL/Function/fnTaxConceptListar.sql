-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIONES SQL DE LISTADO MAESTROS (POSTGRESQL)
-- Archivo: SQL/Function/fnTaxConceptListar.sql
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnTaxConceptListar"();
END $$;

CREATE OR REPLACE FUNCTION public."fnTaxConceptListar"()
RETURNS TABLE (
    id INT,
    code VARCHAR,
    name VARCHAR,
    type VARCHAR,
    "ratePercentage" NUMERIC,
    "minimumBaseAmount" NUMERIC,
    "accountDebitId" INT,
    "accountDebitCode" VARCHAR,
    "accountDebitName" VARCHAR,
    "accountCreditId" INT,
    "accountCreditCode" VARCHAR,
    "accountCreditName" VARCHAR,
    "isActive" BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id,
        t.code,
        t.name,
        t.type,
        t."ratePercentage",
        t."minimumBaseAmount",
        t."accountDebitId",
        ad.code AS "accountDebitCode",
        ad.name AS "accountDebitName",
        t."accountCreditId",
        ac.code AS "accountCreditCode",
        ac.name AS "accountCreditName",
        t."isActive"
    FROM public."TaxConcept" t
    LEFT JOIN public."Account" ad ON t."accountDebitId" = ad.id
    LEFT JOIN public."Account" ac ON t."accountCreditId" = ac.id
    ORDER BY t.code ASC;
END;
$$ LANGUAGE plpgsql;
