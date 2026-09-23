-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTOS ALMACENADOS (POSTGRESQL)
-- Archivo: SQL/Procedure/spBankGuardar.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spBankGuardar"(INT, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, BOOLEAN);
END $$;

CREATE OR REPLACE PROCEDURE public."spBankGuardar"(
    IN p_id INT,
    IN p_code VARCHAR,
    IN p_name VARCHAR,
    IN p_nit VARCHAR,
    IN p_phone VARCHAR,
    IN p_contact_name VARCHAR,
    IN p_is_active BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_id IS NULL OR p_id = 0 THEN
        INSERT INTO public."Bank" (
            code, name, nit, phone, "contactName", "isActive", "createdAt", "updatedAt"
        ) VALUES (
            TRIM(p_code), TRIM(p_name), p_nit, p_phone, p_contact_name, COALESCE(p_is_active, true),
            CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        );
    ELSE
        UPDATE public."Bank"
        SET 
            code = TRIM(p_code),
            name = TRIM(p_name),
            nit = p_nit,
            phone = p_phone,
            "contactName" = p_contact_name,
            "isActive" = COALESCE(p_is_active, "isActive"),
            "updatedAt" = CURRENT_TIMESTAMP
        WHERE id = p_id;
    END IF;
END;
$$;
