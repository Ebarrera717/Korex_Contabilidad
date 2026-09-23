-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTOS ALMACENADOS (POSTGRESQL)
-- Archivo: SQL/Procedure/spThirdPartyGuardar.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spThirdPartyGuardar"(INT, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, VARCHAR, VARCHAR, BOOLEAN);
END $$;

CREATE OR REPLACE PROCEDURE public."spThirdPartyGuardar"(
    IN p_id INT,
    IN p_document_type VARCHAR,
    IN p_document_number VARCHAR,
    IN p_verification_digit VARCHAR,
    IN p_business_name VARCHAR,
    IN p_first_name VARCHAR,
    IN p_second_name VARCHAR,
    IN p_first_last_name VARCHAR,
    IN p_second_last_name VARCHAR,
    IN p_person_type VARCHAR,
    IN p_address VARCHAR,
    IN p_city VARCHAR,
    IN p_state VARCHAR,
    IN p_country VARCHAR,
    IN p_phone VARCHAR,
    IN p_email VARCHAR,
    IN p_is_customer BOOLEAN,
    IN p_is_supplier BOOLEAN,
    IN p_is_employee BOOLEAN,
    IN p_is_partner BOOLEAN,
    IN p_is_other BOOLEAN,
    IN p_tax_regime VARCHAR,
    IN p_fiscal_resp VARCHAR,
    IN p_is_active BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_full_name VARCHAR;
BEGIN
    -- Consolidación de nombre completo
    IF UPPER(p_person_type) = 'JURIDICA' OR (p_business_name IS NOT NULL AND TRIM(p_business_name) <> '') THEN
        v_full_name := TRIM(p_business_name);
    ELSE
        v_full_name := TRIM(CONCAT(
            COALESCE(p_first_name, ''), ' ',
            COALESCE(p_second_name, ''), ' ',
            COALESCE(p_first_last_name, ''), ' ',
            COALESCE(p_second_last_name, '')
        ));
    END IF;

    IF p_id IS NULL OR p_id = 0 THEN
        INSERT INTO public."ThirdParty" (
            "documentType", "documentNumber", "verificationDigit", "businessName",
            "firstName", "secondName", "firstLastName", "secondLastName",
            "fullName", "personType", address, city, state, country, phone, email,
            "isCustomer", "isSupplier", "isEmployee", "isPartner", "isOther",
            "taxRegime", "fiscalResponsibilities", "isActive", "createdAt", "updatedAt"
        ) VALUES (
            COALESCE(p_document_type, 'NIT'), TRIM(p_document_number), p_verification_digit, p_business_name,
            p_first_name, p_second_name, p_first_last_name, p_second_last_name,
            v_full_name, COALESCE(p_person_type, 'JURIDICA'), p_address, p_city, p_state, COALESCE(p_country, 'Colombia'), p_phone, p_email,
            COALESCE(p_is_customer, false), COALESCE(p_is_supplier, false), COALESCE(p_is_employee, false),
            COALESCE(p_is_partner, false), COALESCE(p_is_other, false),
            p_tax_regime, p_fiscal_resp, COALESCE(p_is_active, true), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        );
    ELSE
        UPDATE public."ThirdParty"
        SET 
            "documentType" = COALESCE(p_document_type, 'NIT'),
            "documentNumber" = TRIM(p_document_number),
            "verificationDigit" = p_verification_digit,
            "businessName" = p_business_name,
            "firstName" = p_first_name,
            "secondName" = p_second_name,
            "firstLastName" = p_first_last_name,
            "secondLastName" = p_second_last_name,
            "fullName" = v_full_name,
            "personType" = COALESCE(p_person_type, 'JURIDICA'),
            address = p_address,
            city = p_city,
            state = p_state,
            country = COALESCE(p_country, 'Colombia'),
            phone = p_phone,
            email = p_email,
            "isCustomer" = COALESCE(p_is_customer, "isCustomer"),
            "isSupplier" = COALESCE(p_is_supplier, "isSupplier"),
            "isEmployee" = COALESCE(p_is_employee, "isEmployee"),
            "isPartner" = COALESCE(p_is_partner, "isPartner"),
            "isOther" = COALESCE(p_is_other, "isOther"),
            "taxRegime" = p_tax_regime,
            "fiscalResponsibilities" = p_fiscal_resp,
            "isActive" = COALESCE(p_is_active, "isActive"),
            "updatedAt" = CURRENT_TIMESTAMP
        WHERE id = p_id;
    END IF;
END;
$$;
