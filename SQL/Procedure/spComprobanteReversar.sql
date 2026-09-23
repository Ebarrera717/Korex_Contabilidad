-- ============================================================================
-- KOREX_CONTABILIDAD - MOTOR DE REVERSIÓN AUTOMÁTICA (POSTGRESQL)
-- Archivo: SQL/Procedure/spComprobanteReversar.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spComprobanteReversar"(INT, TEXT, INT, INT);
END $$;

CREATE OR REPLACE PROCEDURE public."spComprobanteReversar"(
    IN p_journal_id INT,
    IN p_reason TEXT,
    IN p_user_id INT,
    OUT p_reverse_journal_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_orig RECORD;
    v_aj_doc_type_id INT;
    v_fiscal_year INT;
    v_doc_prefix VARCHAR;
    v_curr_number INT;
    v_new_entry_number VARCHAR;
    v_new_id INT;
    v_item RECORD;
BEGIN
    -- 1. Obtener comprobante origen
    SELECT * INTO v_orig FROM public."JournalEntry" WHERE id = p_journal_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION '❌ Error: El comprobante origen #% no existe.', p_journal_id;
    END IF;

    IF v_orig.status <> 'POSTED' THEN
        RAISE EXCEPTION '❌ Error: Solo se pueden reversar comprobantes formalmente contabilizados (estado POSTED).';
    END IF;

    -- 2. Obtener tipo de documento de Ajuste ('AJ') o usar el mismo tipo
    SELECT id, prefix INTO v_aj_doc_type_id, v_doc_prefix FROM public."DocumentType" WHERE code = 'AJ';
    IF v_aj_doc_type_id IS NULL THEN
        v_aj_doc_type_id := v_orig."documentTypeId";
        SELECT prefix INTO v_doc_prefix FROM public."DocumentType" WHERE id = v_aj_doc_type_id;
    END IF;

    v_fiscal_year := EXTRACT(YEAR FROM CURRENT_DATE)::INT;

    -- Consecutivo
    SELECT "currentNumber" INTO v_curr_number 
    FROM public."Consecutive" 
    WHERE "documentTypeId" = v_aj_doc_type_id AND "fiscalYear" = v_fiscal_year;

    IF v_curr_number IS NULL THEN
        v_curr_number := 1;
        INSERT INTO public."Consecutive" ("documentTypeId", prefix, "currentNumber", "initialNumber", "fiscalYear", "isActive")
        VALUES (v_aj_doc_type_id, v_doc_prefix, 2, 1, v_fiscal_year, true);
    ELSE
        UPDATE public."Consecutive" 
        SET "currentNumber" = "currentNumber" + 1 
        WHERE "documentTypeId" = v_aj_doc_type_id AND "fiscalYear" = v_fiscal_year;
    END IF;

    v_new_entry_number := CONCAT(COALESCE(v_doc_prefix, 'AJ'), '-', v_fiscal_year, '-', LPAD(v_curr_number::TEXT, 6, '0'));

    -- 3. Crear encabezado del comprobante de reversión (invertido)
    INSERT INTO public."JournalEntry" (
        "companyId", "documentTypeId", "consecutiveNumber", "entryNumber",
        "entryDate", "thirdPartyId", concept, observation,
        "totalDebit", "totalCredit", status, "createdById",
        "postedAt", "createdAt", "updatedAt"
    ) VALUES (
        v_orig."companyId", v_aj_doc_type_id, v_curr_number, v_new_entry_number,
        CURRENT_TIMESTAMP, v_orig."thirdPartyId",
        CONCAT('REVERSIÓN DE ', v_orig."entryNumber", ': ', COALESCE(p_reason, 'Ajuste contable inverso')),
        CONCAT('Documento de reversión generado automáticamente del comprobante original ID #', v_orig.id),
        v_orig."totalCredit", -- Débito nuevo = Crédito original
        v_orig."totalDebit",  -- Crédito nuevo = Débito original
        'POSTED',
        p_user_id,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    ) RETURNING id INTO v_new_id;

    p_reverse_journal_id := v_new_id;

    -- 4. Copiar asientos invirtiendo Débito y Crédito
    FOR v_item IN SELECT * FROM public."JournalEntryItem" WHERE "journalEntryId" = p_journal_id
    LOOP
        INSERT INTO public."JournalEntryItem" (
            "journalEntryId", "accountId", "thirdPartyId", "costCenterId",
            debit, credit, "baseAmount", description, "documentReference",
            "createdAt", "updatedAt"
        ) VALUES (
            v_new_id,
            v_item."accountId",
            v_item."thirdPartyId",
            v_item."costCenterId",
            v_item.credit, -- Se invierte
            v_item.debit,  -- Se invierte
            v_item."baseAmount",
            CONCAT('Rev. ', COALESCE(v_item.description, '')),
            v_orig."entryNumber",
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
    END LOOP;
END;
$$;
