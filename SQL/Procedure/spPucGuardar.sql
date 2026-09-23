-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTOS ALMACENADOS (POSTGRESQL)
-- Archivo: SQL/Procedure/spPucGuardar.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spPucGuardar"(INT, VARCHAR, VARCHAR, INT, VARCHAR, BOOLEAN, BOOLEAN, BOOLEAN, INT, BOOLEAN);
END $$;

CREATE OR REPLACE PROCEDURE public."spPucGuardar"(
    IN p_id INT,
    IN p_code VARCHAR,
    IN p_name VARCHAR,
    IN p_level INT,
    IN p_nature VARCHAR,
    IN p_allows_movement BOOLEAN,
    IN p_requires_third BOOLEAN,
    IN p_requires_cc BOOLEAN,
    IN p_parent_id INT,
    IN p_is_active BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_clean_code VARCHAR;
    v_parent_id INT;
BEGIN
    v_clean_code := TRIM(p_code);

    -- Validación jerárquica: Si no se pasó parent_id explícito, intentar inferirlo por longitud del código
    v_parent_id := p_parent_id;
    IF v_parent_id IS NULL AND LENGTH(v_clean_code) > 1 THEN
        IF LENGTH(v_clean_code) = 2 THEN -- Grupo -> Padre Clase (1)
            SELECT id INTO v_parent_id FROM public."Account" WHERE code = SUBSTRING(v_clean_code, 1, 1);
        ELSIF LENGTH(v_clean_code) = 4 THEN -- Cuenta -> Padre Grupo (2)
            SELECT id INTO v_parent_id FROM public."Account" WHERE code = SUBSTRING(v_clean_code, 1, 2);
        ELSIF LENGTH(v_clean_code) = 6 THEN -- Subcuenta -> Padre Cuenta (4)
            SELECT id INTO v_parent_id FROM public."Account" WHERE code = SUBSTRING(v_clean_code, 1, 4);
        ELSIF LENGTH(v_clean_code) >= 8 THEN -- Auxiliar -> Padre Subcuenta (6)
            SELECT id INTO v_parent_id FROM public."Account" WHERE code = SUBSTRING(v_clean_code, 1, 6);
        END IF;
    END IF;

    -- Si la cuenta padre tiene allowsMovement = true, se le debe desactivar el movimiento porque ahora tiene hijos
    IF v_parent_id IS NOT NULL THEN
        UPDATE public."Account" SET "allowsMovement" = false WHERE id = v_parent_id;
    END IF;

    IF p_id IS NULL OR p_id = 0 THEN
        INSERT INTO public."Account" (
            code, name, level, nature, "allowsMovement",
            "requiresThirdParty", "requiresCostCenter", "parentId", "isActive",
            "createdAt", "updatedAt"
        ) VALUES (
            v_clean_code, TRIM(p_name), p_level, UPPER(TRIM(p_nature)), COALESCE(p_allows_movement, false),
            COALESCE(p_requires_third, false), COALESCE(p_requires_cc, false), v_parent_id, COALESCE(p_is_active, true),
            CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        );
    ELSE
        UPDATE public."Account"
        SET 
            code = v_clean_code,
            name = TRIM(p_name),
            level = p_level,
            nature = UPPER(TRIM(p_nature)),
            "allowsMovement" = COALESCE(p_allows_movement, "allowsMovement"),
            "requiresThirdParty" = COALESCE(p_requires_third, "requiresThirdParty"),
            "requiresCostCenter" = COALESCE(p_requires_cc, "requiresCostCenter"),
            "parentId" = v_parent_id,
            "isActive" = COALESCE(p_is_active, "isActive"),
            "updatedAt" = CURRENT_TIMESTAMP
        WHERE id = p_id;
    END IF;
END;
$$;
