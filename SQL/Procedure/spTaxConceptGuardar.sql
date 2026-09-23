-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTOS ALMACENADOS (POSTGRESQL)
-- Archivo: SQL/Procedure/spTaxConceptGuardar.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spTaxConceptGuardar"(INT, VARCHAR, VARCHAR, VARCHAR, NUMERIC, NUMERIC, INT, INT, BOOLEAN);
END $$;

CREATE OR REPLACE PROCEDURE public."spTaxConceptGuardar"(
    IN p_id INT,
    IN p_code VARCHAR,
    IN p_name VARCHAR,
    IN p_type VARCHAR,
    IN p_rate NUMERIC,
    IN p_min_base NUMERIC,
    IN p_debit_account_id INT,
    IN p_credit_account_id INT,
    IN p_is_active BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_id IS NULL OR p_id = 0 THEN
        INSERT INTO public."TaxConcept" (
            code, name, type, "ratePercentage", "minimumBaseAmount",
            "accountDebitId", "accountCreditId", "isActive", "createdAt", "updatedAt"
        ) VALUES (
            TRIM(p_code), TRIM(p_name), UPPER(TRIM(p_type)), COALESCE(p_rate, 0), COALESCE(p_min_base, 0),
            p_debit_account_id, p_credit_account_id, COALESCE(p_is_active, true),
            CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        );
    ELSE
        UPDATE public."TaxConcept"
        SET 
            code = TRIM(p_code),
            name = TRIM(p_name),
            type = UPPER(TRIM(p_type)),
            "ratePercentage" = COALESCE(p_rate, "ratePercentage"),
            "minimumBaseAmount" = COALESCE(p_min_base, "minimumBaseAmount"),
            "accountDebitId" = p_debit_account_id,
            "accountCreditId" = p_credit_account_id,
            "isActive" = COALESCE(p_is_active, "isActive"),
            "updatedAt" = CURRENT_TIMESTAMP
        WHERE id = p_id;
    END IF;
END;
$$;
