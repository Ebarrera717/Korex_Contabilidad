-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTOS ALMACENADOS (POSTGRESQL)
-- Archivo: SQL/Procedure/spDocumentTypeGuardar.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spDocumentTypeGuardar"(INT, VARCHAR, VARCHAR, VARCHAR, BOOLEAN, BOOLEAN);
END $$;

CREATE OR REPLACE PROCEDURE public."spDocumentTypeGuardar"(
    IN p_id INT,
    IN p_code VARCHAR,
    IN p_name VARCHAR,
    IN p_prefix VARCHAR,
    IN p_is_automatic BOOLEAN,
    IN p_is_active BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_id IS NULL OR p_id = 0 THEN
        INSERT INTO public."DocumentType" (
            code, name, prefix, "isAutomatic", "isActive", "createdAt", "updatedAt"
        ) VALUES (
            TRIM(p_code), TRIM(p_name), p_prefix, COALESCE(p_is_automatic, true), COALESCE(p_is_active, true),
            CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        );
    ELSE
        UPDATE public."DocumentType"
        SET 
            code = TRIM(p_code),
            name = TRIM(p_name),
            prefix = p_prefix,
            "isAutomatic" = COALESCE(p_is_automatic, "isAutomatic"),
            "isActive" = COALESCE(p_is_active, "isActive"),
            "updatedAt" = CURRENT_TIMESTAMP
        WHERE id = p_id;
    END IF;
END;
$$;
