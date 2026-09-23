-- ============================================================================
-- PROYECTO: KOREX_CONTABILIDAD
-- PROCEDIMIENTO: spBatchImportComprobantes
-- DESCRIPCION: Ingesta y validación en lote de Comprobantes Contables desde JSON
-- ============================================================================

CREATE OR REPLACE PROCEDURE public."spBatchImportComprobantes"(
    IN p_company_id INTEGER,
    IN p_entries_json JSONB,
    IN p_auto_post BOOLEAN,
    IN p_user_id INTEGER,
    OUT p_total_rows INTEGER,
    OUT p_success_rows INTEGER,
    OUT p_failed_rows INTEGER,
    OUT p_errors JSONB
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_entry JSONB;
    v_doc_type_code VARCHAR(10);
    v_date DATE;
    v_concept VARCHAR(255);
    v_lines JSONB;
    v_line JSONB;
    v_line_idx INTEGER;
    
    v_doc_type_id INTEGER;
    v_journal_id INTEGER;
    v_consecutive INTEGER;
    v_fiscal_year INTEGER;
    v_total_debit DECIMAL(18,4) := 0;
    v_total_credit DECIMAL(18,4) := 0;
    
    v_account_id INTEGER;
    v_account_code VARCHAR(20);
    v_third_party_id INTEGER;
    v_third_party_doc VARCHAR(50);
    v_cost_center_id INTEGER;
    v_cost_center_code VARCHAR(50);
    v_debit DECIMAL(18,4);
    v_credit DECIMAL(18,4);
    v_desc VARCHAR(255);
    v_errors_arr JSONB := '[]'::JSONB;
BEGIN
    p_total_rows := jsonb_array_length(p_entries_json);
    p_success_rows := 0;
    p_failed_rows := 0;

    FOR v_entry IN SELECT * FROM jsonb_array_elements(p_entries_json)
    LOOP
        BEGIN
            v_doc_type_code := UPPER(TRIM(v_entry->>'documentTypeCode'));
            v_date := (v_entry->>'entryDate')::DATE;
            v_concept := TRIM(COALESCE(v_entry->>'concept', 'Importación Masiva de Comprobante'));
            v_lines := v_entry->'lines';

            IF v_doc_type_code IS NULL OR v_doc_type_code = '' THEN
                RAISE EXCEPTION 'Tipo de documento es obligatorio';
            END IF;

            IF v_date IS NULL THEN
                RAISE EXCEPTION 'Fecha de comprobante es obligatoria';
            END IF;

            IF v_lines IS NULL OR jsonb_array_length(v_lines) = 0 THEN
                RAISE EXCEPTION 'El comprobante debe contener al menos una línea de asiento';
            END IF;

            SELECT id INTO v_doc_type_id 
            FROM public."DocumentType" 
            WHERE "code" = v_doc_type_code AND "isActive" = true;

            IF v_doc_type_id IS NULL THEN
                RAISE EXCEPTION 'Tipo de documento % no existe o está inactivo', v_doc_type_code;
            END IF;

            -- Validar partida doble previa en las líneas
            v_total_debit := 0;
            v_total_credit := 0;
            FOR v_line IN SELECT * FROM jsonb_array_elements(v_lines)
            LOOP
                v_total_debit := v_total_debit + COALESCE((v_line->>'debit')::DECIMAL, 0);
                v_total_credit := v_total_credit + COALESCE((v_line->>'credit')::DECIMAL, 0);
            END LOOP;

            IF ROUND(v_total_debit, 2) <> ROUND(v_total_credit, 2) THEN
                RAISE EXCEPTION 'Comprobante descuadrado: Débitos ($%) <> Créditos ($%)', v_total_debit, v_total_credit;
            END IF;

            -- Asignar consecutivo seguro
            v_fiscal_year := EXTRACT(YEAR FROM v_date)::INTEGER;

            SELECT "currentNumber" + 1 INTO v_consecutive
            FROM public."Consecutive"
            WHERE "companyId" = p_company_id 
              AND "documentTypeId" = v_doc_type_id 
              AND "fiscalYear" = v_fiscal_year
            FOR UPDATE;

            IF v_consecutive IS NULL THEN
                v_consecutive := 1;
                INSERT INTO public."Consecutive" (
                    "companyId", "documentTypeId", "fiscalYear", "currentNumber", "isActive", "createdAt", "updatedAt"
                ) VALUES (
                    p_company_id, v_doc_type_id, v_fiscal_year, 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
                );
            ELSE
                UPDATE public."Consecutive" SET
                    "currentNumber" = v_consecutive,
                    "updatedAt" = CURRENT_TIMESTAMP
                WHERE "companyId" = p_company_id 
                  AND "documentTypeId" = v_doc_type_id 
                  AND "fiscalYear" = v_fiscal_year;
            END IF;

            -- Insertar cabecera JournalEntry
            INSERT INTO public."JournalEntry" (
                "companyId", "documentTypeId", "consecutive", "entryDate", "concept",
                "status", "totalDebit", "totalCredit", "createdById", "createdAt", "updatedAt"
            ) VALUES (
                p_company_id, v_doc_type_id, v_consecutive, v_date, v_concept,
                'DRAFT', v_total_debit, v_total_credit, p_user_id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
            ) RETURNING id INTO v_journal_id;

            -- Insertar líneas
            v_line_idx := 1;
            FOR v_line IN SELECT * FROM jsonb_array_elements(v_lines)
            LOOP
                v_account_code := TRIM(v_line->>'accountCode');
                v_third_party_doc := TRIM(COALESCE(v_line->>'thirdPartyDoc', ''));
                v_cost_center_code := TRIM(COALESCE(v_line->>'costCenterCode', ''));
                v_debit := COALESCE((v_line->>'debit')::DECIMAL, 0);
                v_credit := COALESCE((v_line->>'credit')::DECIMAL, 0);
                v_desc := TRIM(COALESCE(v_line->>'description', v_concept));

                SELECT id INTO v_account_id FROM public."PucAccount" WHERE "code" = v_account_code;
                IF v_account_id IS NULL THEN
                    RAISE EXCEPTION 'Cuenta contable % no existe', v_account_code;
                END IF;

                v_third_party_id := NULL;
                IF v_third_party_doc <> '' THEN
                    SELECT id INTO v_third_party_id FROM public."ThirdParty" WHERE "documentNumber" = v_third_party_doc;
                END IF;

                v_cost_center_id := NULL;
                IF v_cost_center_code <> '' THEN
                    SELECT id INTO v_cost_center_id FROM public."CostCenter" WHERE "code" = v_cost_center_code;
                END IF;

                INSERT INTO public."JournalEntryLine" (
                    "journalEntryId", "lineNumber", "accountId", "thirdPartyId",
                    "costCenterId", "description", "debit", "credit", "baseAmount", "createdAt"
                ) VALUES (
                    v_journal_id, v_line_idx, v_account_id, v_third_party_id,
                    v_cost_center_id, v_desc, v_debit, v_credit, 
                    COALESCE((v_line->>'baseAmount')::DECIMAL, 0), CURRENT_TIMESTAMP
                );

                v_line_idx := v_line_idx + 1;
            END LOOP;

            -- Auto-post si se solicitó
            IF p_auto_post = true THEN
                CALL public."spComprobanteContabilizar"(
                    v_journal_id,
                    p_user_id,
                    NULL,
                    NULL
                );
            END IF;

            p_success_rows := p_success_rows + 1;

        EXCEPTION WHEN OTHERS THEN
            p_failed_rows := p_failed_rows + 1;
            v_errors_arr := v_errors_arr || jsonb_build_object(
                'docType', COALESCE(v_doc_type_code, 'N/A'),
                'concept', COALESCE(v_concept, 'N/A'),
                'error', SQLERRM
            );
        END;
    END LOOP;

    p_errors := v_errors_arr;
END;
$$;
