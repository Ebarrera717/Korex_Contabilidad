-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTOS DE COMPROBANTES (POSTGRESQL)
-- Archivo: SQL/Procedure/spComprobanteGuardar.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spComprobanteGuardar"(INT, INT, INT, VARCHAR, TIMESTAMP(3), INT, VARCHAR, TEXT, JSONB, INT, INT);
END $$;

CREATE OR REPLACE PROCEDURE public."spComprobanteGuardar"(
    IN p_id INT,
    IN p_company_id INT,
    IN p_document_type_id INT,
    IN p_entry_number VARCHAR,
    IN p_entry_date TIMESTAMP(3),
    IN p_third_party_id INT,
    IN p_concept VARCHAR,
    IN p_observation TEXT,
    IN p_items JSONB, -- Arreglo de líneas [{accountId, thirdPartyId, costCenterId, debit, credit, baseAmount, description, documentReference}]
    IN p_user_id INT,
    OUT p_created_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_journal_id INT;
    v_item JSONB;
    v_total_debit NUMERIC(18, 4) := 0;
    v_total_credit NUMERIC(18, 4) := 0;
    v_fiscal_year INT;
    v_doc_prefix VARCHAR;
    v_curr_number INT;
    v_final_entry_number VARCHAR;
    v_status VARCHAR := 'DRAFT';
BEGIN
    v_fiscal_year := EXTRACT(YEAR FROM p_entry_date)::INT;

    -- Obtener prefijo y consecutivo si el comprobante es nuevo
    IF p_id IS NULL OR p_id = 0 THEN
        SELECT prefix INTO v_doc_prefix FROM public."DocumentType" WHERE id = p_document_type_id;
        
        -- Obtener o inicializar consecutivo
        SELECT "currentNumber" INTO v_curr_number 
        FROM public."Consecutive" 
        WHERE "documentTypeId" = p_document_type_id AND "fiscalYear" = v_fiscal_year;

        IF v_curr_number IS NULL THEN
            v_curr_number := 1;
            INSERT INTO public."Consecutive" ("documentTypeId", prefix, "currentNumber", "initialNumber", "fiscalYear", "isActive")
            VALUES (p_document_type_id, v_doc_prefix, 2, 1, v_fiscal_year, true);
        ELSE
            UPDATE public."Consecutive" 
            SET "currentNumber" = "currentNumber" + 1 
            WHERE "documentTypeId" = p_document_type_id AND "fiscalYear" = v_fiscal_year;
        END IF;

        v_final_entry_number := COALESCE(p_entry_number, CONCAT(COALESCE(v_doc_prefix, 'DOC'), '-', v_fiscal_year, '-', LPAD(v_curr_number::TEXT, 6, '0')));

        -- Calcular totales de débito y crédito del JSON
        IF p_items IS NOT NULL AND jsonb_array_length(p_items) > 0 THEN
            FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
            LOOP
                v_total_debit := v_total_debit + COALESCE((v_item->>'debit')::NUMERIC, 0);
                v_total_credit := v_total_credit + COALESCE((v_item->>'credit')::NUMERIC, 0);
            END LOOP;
        END IF;

        INSERT INTO public."JournalEntry" (
            "companyId", "documentTypeId", "consecutiveNumber", "entryNumber",
            "entryDate", "thirdPartyId", concept, observation,
            "totalDebit", "totalCredit", status, "createdById",
            "createdAt", "updatedAt"
        ) VALUES (
            p_company_id, p_document_type_id, v_curr_number, v_final_entry_number,
            p_entry_date, p_third_party_id, p_concept, p_observation,
            v_total_debit, v_total_credit, v_status, p_user_id,
            CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        ) RETURNING id INTO v_journal_id;

        p_created_id := v_journal_id;
    ELSE
        v_journal_id := p_id;
        p_created_id := p_id;

        -- Validar que no esté contabilizado si se va a editar
        SELECT status INTO v_status FROM public."JournalEntry" WHERE id = v_journal_id;
        IF v_status = 'POSTED' THEN
            RAISE EXCEPTION '❌ Comprobante ya Contabilizado: No se puede editar directamente un comprobante en estado POSTED. Use la opción de Ajuste o Reversión.';
        END IF;
        IF v_status = 'ANNULLED' THEN
            RAISE EXCEPTION '❌ Comprobante Anulado: No se puede modificar un comprobante anulado.';
        END IF;

        -- Recalcular totales
        IF p_items IS NOT NULL AND jsonb_array_length(p_items) > 0 THEN
            FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
            LOOP
                v_total_debit := v_total_debit + COALESCE((v_item->>'debit')::NUMERIC, 0);
                v_total_credit := v_total_credit + COALESCE((v_item->>'credit')::NUMERIC, 0);
            END LOOP;
        END IF;

        UPDATE public."JournalEntry"
        SET 
            "companyId" = p_company_id,
            "documentTypeId" = p_document_type_id,
            "entryDate" = p_entry_date,
            "thirdPartyId" = p_third_party_id,
            concept = p_concept,
            observation = p_observation,
            "totalDebit" = v_total_debit,
            "totalCredit" = v_total_credit,
            "updatedAt" = CURRENT_TIMESTAMP
        WHERE id = v_journal_id;

        -- Eliminar líneas previas para reinsertar las nuevas
        DELETE FROM public."JournalEntryItem" WHERE "journalEntryId" = v_journal_id;
    END IF;

    -- Inserción de líneas de detalle
    IF p_items IS NOT NULL AND jsonb_array_length(p_items) > 0 THEN
        FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
        LOOP
            INSERT INTO public."JournalEntryItem" (
                "journalEntryId", "accountId", "thirdPartyId", "costCenterId",
                debit, credit, "baseAmount", description, "documentReference",
                "createdAt", "updatedAt"
            ) VALUES (
                v_journal_id,
                (v_item->>'accountId')::INT,
                NULLIF((v_item->>'thirdPartyId')::INT, 0),
                NULLIF((v_item->>'costCenterId')::INT, 0),
                COALESCE((v_item->>'debit')::NUMERIC, 0),
                COALESCE((v_item->>'credit')::NUMERIC, 0),
                COALESCE((v_item->>'baseAmount')::NUMERIC, 0),
                v_item->>'description',
                v_item->>'documentReference',
                CURRENT_TIMESTAMP,
                CURRENT_TIMESTAMP
            );
        END LOOP;
    END IF;
END;
$$;
