-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTOS ALMACENADOS (POSTGRESQL)
-- Archivo: SQL/Procedure/spCompanyGuardar.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spCompanyGuardar"(INT, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, BOOLEAN);
END $$;

CREATE OR REPLACE PROCEDURE public."spCompanyGuardar"(
    IN p_id INT,
    IN p_code VARCHAR,
    IN p_business_name VARCHAR,
    IN p_trade_name VARCHAR,
    IN p_document_type VARCHAR,
    IN p_document_number VARCHAR,
    IN p_verification_digit VARCHAR,
    IN p_address VARCHAR,
    IN p_city VARCHAR,
    IN p_state VARCHAR,
    IN p_country VARCHAR,
    IN p_phone VARCHAR,
    IN p_email VARCHAR,
    IN p_legal_rep VARCHAR,
    IN p_tax_regime VARCHAR,
    IN p_fiscal_resp VARCHAR,
    IN p_ciiu VARCHAR,
    IN p_is_active BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_id IS NULL OR p_id = 0 THEN
        INSERT INTO public."Company" (
            code, "businessName", "tradeName", "documentType", "documentNumber",
            "verificationDigit", address, city, state, country, phone, email,
            "legalRepresentative", "taxRegime", "fiscalResponsibilities",
            "economicActivityCode", "isActive", "createdAt", "updatedAt"
        ) VALUES (
            p_code, p_business_name, p_trade_name, COALESCE(p_document_type, 'NIT'), p_document_number,
            p_verification_digit, p_address, p_city, p_state, COALESCE(p_country, 'Colombia'), p_phone, p_email,
            p_legal_rep, p_tax_regime, p_fiscal_resp,
            p_ciiu, COALESCE(p_is_active, true), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        );
    ELSE
        UPDATE public."Company"
        SET 
            code = p_code,
            "businessName" = p_business_name,
            "tradeName" = p_trade_name,
            "documentType" = COALESCE(p_document_type, 'NIT'),
            "documentNumber" = p_document_number,
            "verificationDigit" = p_verification_digit,
            address = p_address,
            city = p_city,
            state = p_state,
            country = COALESCE(p_country, 'Colombia'),
            phone = p_phone,
            email = p_email,
            "legalRepresentative" = p_legal_rep,
            "taxRegime" = p_tax_regime,
            "fiscalResponsibilities" = p_fiscal_resp,
            "economicActivityCode" = p_ciiu,
            "isActive" = COALESCE(p_is_active, "isActive"),
            "updatedAt" = CURRENT_TIMESTAMP
        WHERE id = p_id;
    END IF;
END;
$$;
