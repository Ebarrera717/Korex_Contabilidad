-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTO ALMACENADO: spActivoFijoCategoriaGuardar
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spActivoFijoCategoriaGuardar";
END $$;

CREATE OR REPLACE PROCEDURE public."spActivoFijoCategoriaGuardar"(
    IN p_id INTEGER,
    IN p_code VARCHAR(50),
    IN p_name VARCHAR(100),
    IN p_default_life_months INTEGER,
    IN p_account_asset_id INTEGER,
    IN p_account_accum_depr_id INTEGER,
    IN p_account_expense_depr_id INTEGER,
    IN p_is_active BOOLEAN,
    OUT p_out_id INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_id IS NULL OR p_id = 0 THEN
        INSERT INTO public."FixedAssetCategory"(
            code, name, "defaultUsefulLifeMonths", "accountAssetId",
            "accountAccumDeprId", "accountExpenseDeprId", "isActive"
        ) VALUES (
            p_code, p_name, COALESCE(p_default_life_months, 60), p_account_asset_id,
            p_account_accum_depr_id, p_account_expense_depr_id, COALESCE(p_is_active, TRUE)
        ) RETURNING id INTO p_out_id;
    ELSE
        UPDATE public."FixedAssetCategory"
        SET code = p_code,
            name = p_name,
            "defaultUsefulLifeMonths" = COALESCE(p_default_life_months, 60),
            "accountAssetId" = p_account_asset_id,
            "accountAccumDeprId" = p_account_accum_depr_id,
            "accountExpenseDeprId" = p_account_expense_depr_id,
            "isActive" = COALESCE(p_is_active, TRUE),
            "updatedAt" = CURRENT_TIMESTAMP
        WHERE id = p_id;
        p_out_id := p_id;
    END IF;
END;
$$;
