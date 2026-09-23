-- ============================================================================
-- PROYECTO: KOREX_CONTABILIDAD
-- PROCEDIMIENTO: spBatchImportThirdParties
-- DESCRIPCION: Ingesta y validación en lote de Terceros desde JSON con cálculo de DV
-- ============================================================================

CREATE OR REPLACE PROCEDURE public."spBatchImportThirdParties"(
    IN p_company_id INTEGER,
    IN p_third_parties_json JSONB,
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
    v_doc_type VARCHAR(10);
    v_doc_num VARCHAR(50);
    v_dv VARCHAR(2);
    v_business_name VARCHAR(255);
    v_first_name VARCHAR(100);
    v_last_name VARCHAR(100);
    v_person_type VARCHAR(20);
    v_email VARCHAR(255);
    v_phone VARCHAR(50);
    v_address VARCHAR(255);
    v_city VARCHAR(100);
    v_is_customer BOOLEAN;
    v_is_vendor BOOLEAN;
    v_is_employee BOOLEAN;
    v_errors_arr JSONB := '[]'::JSONB;
    v_existing_id INTEGER;
    
    -- Variables para cálculo DV Módulo 11
    v_clean_nit VARCHAR(50);
    v_len INTEGER;
    v_weights INTEGER[] := ARRAY[3, 7, 13, 17, 19, 23, 29, 37, 41, 43, 47, 53, 59, 67, 71];
    v_sum INTEGER := 0;
    v_i INTEGER;
    v_digit INTEGER;
    v_remainder INTEGER;
BEGIN
    p_total_rows := jsonb_array_length(p_third_parties_json);
    p_success_rows := 0;
    p_failed_rows := 0;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_third_parties_json)
    LOOP
        BEGIN
            v_doc_type := UPPER(TRIM(COALESCE(v_item->>'documentType', 'NIT')));
            v_doc_num := TRIM(v_item->>'documentNumber');
            v_dv := TRIM(COALESCE(v_item->>'verificationDigit', ''));
            v_business_name := TRIM(COALESCE(v_item->>'businessName', ''));
            v_first_name := TRIM(COALESCE(v_item->>'firstName', ''));
            v_last_name := TRIM(COALESCE(v_item->>'lastName', ''));
            v_email := TRIM(COALESCE(v_item->>'email', ''));
            v_phone := TRIM(COALESCE(v_item->>'phone', ''));
            v_address := TRIM(COALESCE(v_item->>'address', ''));
            v_city := TRIM(COALESCE(v_item->>'city', ''));
            v_is_customer := COALESCE((v_item->>'isCustomer')::BOOLEAN, true);
            v_is_vendor := COALESCE((v_item->>'isVendor')::BOOLEAN, false);
            v_is_employee := COALESCE((v_item->>'isEmployee')::BOOLEAN, false);

            IF v_doc_num IS NULL OR v_doc_num = '' THEN
                RAISE EXCEPTION 'Número de documento es obligatorio';
            END IF;

            -- Auto-completar nombres o razón social
            IF v_business_name = '' THEN
                IF v_first_name <> '' OR v_last_name <> '' THEN
                    v_business_name := TRIM(v_first_name || ' ' || v_last_name);
                    v_person_type := 'NATURAL';
                ELSE
                    RAISE EXCEPTION 'Debe especificar razón social o nombres para el documento %', v_doc_num;
                END IF;
            ELSE
                v_person_type := COALESCE(v_item->>'personType', CASE WHEN v_doc_type = 'NIT' THEN 'LEGAL' ELSE 'NATURAL' END);
            END IF;

            -- Cálculo automático de DV si está vacío y es NIT
            IF v_dv = '' AND v_doc_type = 'NIT' THEN
                v_clean_nit := regexp_replace(v_doc_num, '[^0-9]', '', 'g');
                v_len := LENGTH(v_clean_nit);
                IF v_len > 0 THEN
                    v_sum := 0;
                    FOR v_i IN 1..v_len LOOP
                        v_digit := CAST(SUBSTRING(v_clean_nit, v_len - v_i + 1, 1) AS INTEGER);
                        v_sum := v_sum + (v_digit * v_weights[v_i]);
                    END LOOP;
                    v_remainder := v_sum % 11;
                    IF v_remainder > 1 THEN
                        v_dv := CAST((11 - v_remainder) AS VARCHAR);
                    ELSE
                        v_dv := CAST(v_remainder AS VARCHAR);
                    END IF;
                END IF;
            END IF;

            -- Upsert en ThirdParty
            SELECT id INTO v_existing_id 
            FROM public."ThirdParty" 
            WHERE "documentNumber" = v_doc_num;

            IF v_existing_id IS NOT NULL THEN
                UPDATE public."ThirdParty" SET
                    "documentType" = v_doc_type,
                    "verificationDigit" = NULLIF(v_dv, ''),
                    "businessName" = v_business_name,
                    "firstName" = NULLIF(v_first_name, ''),
                    "lastName" = NULLIF(v_last_name, ''),
                    "personType" = v_person_type,
                    "email" = NULLIF(v_email, ''),
                    "phone" = NULLIF(v_phone, ''),
                    "address" = NULLIF(v_address, ''),
                    "city" = NULLIF(v_city, ''),
                    "isCustomer" = v_is_customer,
                    "isVendor" = v_is_vendor,
                    "isEmployee" = v_is_employee,
                    "updatedAt" = CURRENT_TIMESTAMP
                WHERE "id" = v_existing_id;
            ELSE
                INSERT INTO public."ThirdParty" (
                    "documentType", "documentNumber", "verificationDigit",
                    "businessName", "firstName", "lastName", "personType",
                    "email", "phone", "address", "city",
                    "isCustomer", "isVendor", "isEmployee", "isActive",
                    "createdAt", "updatedAt"
                ) VALUES (
                    v_doc_type, v_doc_num, NULLIF(v_dv, ''),
                    v_business_name, NULLIF(v_first_name, ''), NULLIF(v_last_name, ''), v_person_type,
                    NULLIF(v_email, ''), NULLIF(v_phone, ''), NULLIF(v_address, ''), NULLIF(v_city, ''),
                    v_is_customer, v_is_vendor, v_is_employee, true,
                    CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
                );
            END IF;

            p_success_rows := p_success_rows + 1;

        EXCEPTION WHEN OTHERS THEN
            p_failed_rows := p_failed_rows + 1;
            v_errors_arr := v_errors_arr || jsonb_build_object(
                'documentNumber', COALESCE(v_doc_num, 'N/A'),
                'error', SQLERRM
            );
        END;
    END LOOP;

    p_errors := v_errors_arr;
END;
$$;
