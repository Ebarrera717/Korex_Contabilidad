-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIONES SQL DE LISTADO MAESTROS (POSTGRESQL)
-- Archivo: SQL/Function/fnThirdPartyListar.sql
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnThirdPartyListar"(VARCHAR, VARCHAR, BOOLEAN);
END $$;

CREATE OR REPLACE FUNCTION public."fnThirdPartyListar"(
    p_search VARCHAR DEFAULT NULL,
    p_role_filter VARCHAR DEFAULT NULL, -- 'CUSTOMER', 'SUPPLIER', 'EMPLOYEE', 'PARTNER'
    p_is_active BOOLEAN DEFAULT NULL
)
RETURNS TABLE (
    id INT,
    "documentType" VARCHAR,
    "documentNumber" VARCHAR,
    "verificationDigit" VARCHAR,
    "businessName" VARCHAR,
    "firstName" VARCHAR,
    "firstLastName" VARCHAR,
    "fullName" VARCHAR,
    "personType" VARCHAR,
    address VARCHAR,
    city VARCHAR,
    phone VARCHAR,
    email VARCHAR,
    "isCustomer" BOOLEAN,
    "isSupplier" BOOLEAN,
    "isEmployee" BOOLEAN,
    "isPartner" BOOLEAN,
    "isOther" BOOLEAN,
    "taxRegime" VARCHAR,
    "isActive" BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id,
        t."documentType",
        t."documentNumber",
        t."verificationDigit",
        t."businessName",
        t."firstName",
        t."firstLastName",
        t."fullName",
        t."personType",
        t.address,
        t.city,
        t.phone,
        t.email,
        t."isCustomer",
        t."isSupplier",
        t."isEmployee",
        t."isPartner",
        t."isOther",
        t."taxRegime",
        t."isActive"
    FROM public."ThirdParty" t
    WHERE 
        (p_search IS NULL OR TRIM(p_search) = '' OR (t."documentNumber" ILIKE '%' || TRIM(p_search) || '%' OR t."fullName" ILIKE '%' || TRIM(p_search) || '%'))
        AND (p_is_active IS NULL OR t."isActive" = p_is_active)
        AND (
            p_role_filter IS NULL 
            OR (p_role_filter = 'CUSTOMER' AND t."isCustomer" = true)
            OR (p_role_filter = 'SUPPLIER' AND t."isSupplier" = true)
            OR (p_role_filter = 'EMPLOYEE' AND t."isEmployee" = true)
            OR (p_role_filter = 'PARTNER' AND t."isPartner" = true)
        )
    ORDER BY t."fullName" ASC;
END;
$$ LANGUAGE plpgsql;
