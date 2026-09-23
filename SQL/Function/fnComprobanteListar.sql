-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIONES DE CONSULTA DE COMPROBANTES (POSTGRESQL)
-- Archivo: SQL/Function/fnComprobanteListar.sql
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnComprobanteListar"(INT, INT, TIMESTAMP(3), TIMESTAMP(3), VARCHAR, VARCHAR);
END $$;

CREATE OR REPLACE FUNCTION public."fnComprobanteListar"(
    p_company_id INT DEFAULT NULL,
    p_doc_type_id INT DEFAULT NULL,
    p_start_date TIMESTAMP(3) DEFAULT NULL,
    p_end_date TIMESTAMP(3) DEFAULT NULL,
    p_status VARCHAR DEFAULT NULL,
    p_search VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    id INT,
    "companyId" INT,
    "companyName" VARCHAR,
    "documentTypeId" INT,
    "documentTypeCode" VARCHAR,
    "documentTypeName" VARCHAR,
    "consecutiveNumber" INT,
    "entryNumber" VARCHAR,
    "entryDate" TIMESTAMP(3),
    "thirdPartyId" INT,
    "thirdPartyDoc" VARCHAR,
    "thirdPartyName" VARCHAR,
    concept VARCHAR,
    observation TEXT,
    "totalDebit" NUMERIC,
    "totalCredit" NUMERIC,
    status VARCHAR,
    "createdById" INT,
    "createdByName" VARCHAR,
    "postedAt" TIMESTAMP(3),
    "annulledAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        j.id,
        j."companyId",
        c."businessName" AS "companyName",
        j."documentTypeId",
        d.code AS "documentTypeCode",
        d.name AS "documentTypeName",
        j."consecutiveNumber",
        j."entryNumber",
        j."entryDate",
        j."thirdPartyId",
        t."documentNumber" AS "thirdPartyDoc",
        t."fullName" AS "thirdPartyName",
        j.concept,
        j.observation,
        j."totalDebit",
        j."totalCredit",
        j.status,
        j."createdById",
        u.name AS "createdByName",
        j."postedAt",
        j."annulledAt",
        j."createdAt"
    FROM public."JournalEntry" j
    INNER JOIN public."Company" c ON j."companyId" = c.id
    INNER JOIN public."DocumentType" d ON j."documentTypeId" = d.id
    LEFT JOIN public."ThirdParty" t ON j."thirdPartyId" = t.id
    LEFT JOIN public."User" u ON j."createdById" = u.id
    WHERE 
        (p_company_id IS NULL OR j."companyId" = p_company_id)
        AND (p_doc_type_id IS NULL OR j."documentTypeId" = p_doc_type_id)
        AND (p_start_date IS NULL OR j."entryDate" >= p_start_date)
        AND (p_end_date IS NULL OR j."entryDate" <= p_end_date)
        AND (p_status IS NULL OR j.status = p_status)
        AND (
            p_search IS NULL OR TRIM(p_search) = '' 
            OR j."entryNumber" ILIKE '%' || TRIM(p_search) || '%'
            OR j.concept ILIKE '%' || TRIM(p_search) || '%'
            OR (t."fullName" IS NOT NULL AND t."fullName" ILIKE '%' || TRIM(p_search) || '%')
        )
    ORDER BY j."entryDate" DESC, j.id DESC;
END;
$$ LANGUAGE plpgsql;
