-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTOS ALMACENADOS (POSTGRESQL)
-- Archivo: SQL/Procedure/spConsecutiveGuardar.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spConsecutiveGuardar"(INT, INT, VARCHAR, INT, INT, INT, INT, BOOLEAN);
END $$;

CREATE OR REPLACE PROCEDURE public."spConsecutiveGuardar"(
    IN p_id INT,
    IN p_doc_type_id INT,
    IN p_prefix VARCHAR,
    IN p_current_number INT,
    IN p_initial_number INT,
    IN p_final_number INT,
    IN p_fiscal_year INT,
    IN p_is_active BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_id IS NULL OR p_id = 0 THEN
        INSERT INTO public."Consecutive" (
            "documentTypeId", prefix, "currentNumber", "initialNumber",
            "finalNumber", "fiscalYear", "isActive", "createdAt", "updatedAt"
        ) VALUES (
            p_doc_type_id, p_prefix, COALESCE(p_current_number, 1), COALESCE(p_initial_number, 1),
            p_final_number, p_fiscal_year, COALESCE(p_is_active, true),
            CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        );
    ELSE
        UPDATE public."Consecutive"
        SET 
            "documentTypeId" = p_doc_type_id,
            prefix = p_prefix,
            "currentNumber" = COALESCE(p_current_number, "currentNumber"),
            "initialNumber" = COALESCE(p_initial_number, "initialNumber"),
            "finalNumber" = p_final_number,
            "fiscalYear" = p_fiscal_year,
            "isActive" = COALESCE(p_is_active, "isActive"),
            "updatedAt" = CURRENT_TIMESTAMP
        WHERE id = p_id;
    END IF;
END;
$$;
