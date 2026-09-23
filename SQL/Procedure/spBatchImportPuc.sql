-- ============================================================================
-- PROYECTO: KOREX_CONTABILIDAD
-- PROCEDIMIENTO: spBatchImportPuc
-- DESCRIPCION: Ingesta y validación en lote de cuentas contables del PUC desde JSON
-- ============================================================================

CREATE OR REPLACE PROCEDURE public."spBatchImportPuc"(
    IN p_company_id INTEGER,
    IN p_accounts_json JSONB,
    IN p_user_id INTEGER,
    OUT p_total_rows INTEGER,
    OUT p_success_rows INTEGER,
    OUT p_failed_rows INTEGER,
    OUT p_errors JSONB
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_item JSONB;
    v_code VARCHAR(20);
    v_name VARCHAR(255);
    v_nature VARCHAR(10);
    v_level INTEGER;
    v_is_movement BOOLEAN;
    v_parent_id INTEGER;
    v_parent_code VARCHAR(20);
    v_requires_third_party BOOLEAN;
    v_requires_cost_center BOOLEAN;
    v_errors_arr JSONB := '[]'::JSONB;
    v_class_digit CHAR(1);
    v_existing_id INTEGER;
BEGIN
    p_total_rows := jsonb_array_length(p_accounts_json);
    p_success_rows := 0;
    p_failed_rows := 0;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_accounts_json)
    LOOP
        BEGIN
            v_code := TRIM(v_item->>'code');
            v_name := TRIM(v_item->>'name');
            v_nature := UPPER(TRIM(COALESCE(v_item->>'nature', '')));
            v_level := COALESCE((v_item->>'level')::INTEGER, 
                CASE 
                    WHEN LENGTH(v_code) = 1 THEN 1
                    WHEN LENGTH(v_code) = 2 THEN 2
                    WHEN LENGTH(v_code) = 4 THEN 3
                    WHEN LENGTH(v_code) = 6 THEN 4
                    ELSE 5
                END
            );
            v_is_movement := COALESCE((v_item->>'isMovement')::BOOLEAN, (v_level >= 4));
            v_requires_third_party := COALESCE((v_item->>'requiresThirdParty')::BOOLEAN, false);
            v_requires_cost_center := COALESCE((v_item->>'requiresCostCenter')::BOOLEAN, false);

            -- Validaciones básicas
            IF v_code IS NULL OR v_code = '' THEN
                RAISE EXCEPTION 'Código de cuenta requerido';
            END IF;

            IF v_name IS NULL OR v_name = '' THEN
                RAISE EXCEPTION 'Nombre de cuenta requerido para %', v_code;
            END IF;

            -- Determinar naturaleza si no viene explícita
            IF v_nature = '' OR v_nature IS NULL THEN
                v_class_digit := SUBSTRING(v_code, 1, 1);
                IF v_class_digit IN ('1', '5', '6', '7') THEN
                    v_nature := 'DEBIT';
                ELSE
                    v_nature := 'CREDIT';
                END IF;
            END IF;

            -- Inferencia de cuenta padre
            v_parent_id := NULL;
            IF v_level > 1 THEN
                v_parent_code := CASE
                    WHEN v_level = 2 THEN SUBSTRING(v_code, 1, 1)
                    WHEN v_level = 3 THEN SUBSTRING(v_code, 1, 2)
                    WHEN v_level = 4 THEN SUBSTRING(v_code, 1, 4)
                    ELSE SUBSTRING(v_code, 1, 6)
                END;

                SELECT id INTO v_parent_id 
                FROM public."PucAccount" 
                WHERE "code" = v_parent_code;
            END IF;

            -- Upsert en PucAccount
            SELECT id INTO v_existing_id FROM public."PucAccount" WHERE "code" = v_code;

            IF v_existing_id IS NOT NULL THEN
                UPDATE public."PucAccount" SET
                    "name" = v_name,
                    "nature" = v_nature,
                    "level" = v_level,
                    "parentId" = v_parent_id,
                    "isMovement" = v_is_movement,
                    "requiresThirdParty" = v_requires_third_party,
                    "requiresCostCenter" = v_requires_cost_center,
                    "updatedAt" = CURRENT_TIMESTAMP
                WHERE "id" = v_existing_id;
            ELSE
                INSERT INTO public."PucAccount" (
                    "code", "name", "nature", "level", "parentId", 
                    "isMovement", "requiresThirdParty", "requiresCostCenter", "isActive", "createdAt", "updatedAt"
                ) VALUES (
                    v_code, v_name, v_nature, v_level, v_parent_id,
                    v_is_movement, v_requires_third_party, v_requires_cost_center, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
                );
            END IF;

            p_success_rows := p_success_rows + 1;

        EXCEPTION WHEN OTHERS THEN
            p_failed_rows := p_failed_rows + 1;
            v_errors_arr := v_errors_arr || jsonb_build_object(
                'code', COALESCE(v_code, 'N/A'),
                'error', SQLERRM
            );
        END;
    END LOOP;

    p_errors := v_errors_arr;
END;
$$;
