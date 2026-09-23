-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTOS DE TESORERÍA (POSTGRESQL)
-- Archivo: SQL/Procedure/spCajaGuardar.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spCajaGuardar"(INT, INT, VARCHAR, VARCHAR, INT, INT, VARCHAR, NUMERIC, BOOLEAN);
END $$;

CREATE OR REPLACE PROCEDURE public."spCajaGuardar"(
    IN p_id INT,
    IN p_company_id INT,
    IN p_code VARCHAR,
    IN p_name VARCHAR,
    IN p_account_id INT,
    IN p_responsible_user_id INT,
    IN p_currency VARCHAR,
    IN p_max_amount NUMERIC,
    IN p_is_active BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_id IS NULL OR p_id = 0 THEN
        INSERT INTO public."CashBox" (
            "companyId", code, name, "accountId", "responsibleUserId",
            currency, "maxAmount", "isActive", "createdAt", "updatedAt"
        ) VALUES (
            p_company_id, TRIM(p_code), TRIM(p_name), p_account_id, p_responsible_user_id,
            COALESCE(p_currency, 'COP'), COALESCE(p_max_amount, 0), COALESCE(p_is_active, true),
            CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        );
    ELSE
        UPDATE public."CashBox"
        SET 
            "companyId" = p_company_id,
            code = TRIM(p_code),
            name = TRIM(p_name),
            "accountId" = p_account_id,
            "responsibleUserId" = p_responsible_user_id,
            currency = COALESCE(p_currency, currency),
            "maxAmount" = COALESCE(p_max_amount, "maxAmount"),
            "isActive" = COALESCE(p_is_active, "isActive"),
            "updatedAt" = CURRENT_TIMESTAMP
        WHERE id = p_id;
    END IF;
END;
$$;
