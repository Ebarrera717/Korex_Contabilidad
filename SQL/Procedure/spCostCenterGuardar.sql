-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTOS ALMACENADOS (POSTGRESQL)
-- Archivo: SQL/Procedure/spCostCenterGuardar.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spCostCenterGuardar"(INT, VARCHAR, VARCHAR, INT, INT, BOOLEAN);
END $$;

CREATE OR REPLACE PROCEDURE public."spCostCenterGuardar"(
    IN p_id INT,
    IN p_code VARCHAR,
    IN p_name VARCHAR,
    IN p_level INT,
    IN p_parent_id INT,
    IN p_is_active BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_id IS NULL OR p_id = 0 THEN
        INSERT INTO public."CostCenter" (
            code, name, level, "parentId", "isActive", "createdAt", "updatedAt"
        ) VALUES (
            TRIM(p_code), TRIM(p_name), COALESCE(p_level, 1), p_parent_id, COALESCE(p_is_active, true),
            CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        );
    ELSE
        UPDATE public."CostCenter"
        SET 
            code = TRIM(p_code),
            name = TRIM(p_name),
            level = COALESCE(p_level, level),
            "parentId" = p_parent_id,
            "isActive" = COALESCE(p_is_active, "isActive"),
            "updatedAt" = CURRENT_TIMESTAMP
        WHERE id = p_id;
    END IF;
END;
$$;
