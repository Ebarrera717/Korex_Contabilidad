-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTO DE TRASLADOS / TRANSFERENCIAS (POSTGRESQL)
-- Archivo: SQL/Procedure/spTesoreriaTransferenciaCrear.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spTesoreriaTransferenciaCrear"(INT, TIMESTAMP(3), INT, INT, INT, INT, VARCHAR, NUMERIC, INT, INT, INT);
END $$;

CREATE OR REPLACE PROCEDURE public."spTesoreriaTransferenciaCrear"(
    IN p_company_id INT,
    IN p_movement_date TIMESTAMP(3),
    IN p_source_bank_id INT,
    IN p_source_cash_id INT,
    IN p_target_bank_id INT,
    IN p_target_cash_id INT,
    IN p_concept VARCHAR,
    IN p_total_amount NUMERIC(18, 4),
    IN p_user_id INT,
    OUT p_movement_id INT,
    OUT p_journal_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_cc_doc_type_id INT;
    v_doc_prefix VARCHAR;
    v_fiscal_year INT;
    v_curr_number INT;
    v_entry_number VARCHAR;
    v_credit_account_id INT;
    v_debit_account_id INT;
    v_journal_id INT;
    v_mov_id INT;
BEGIN
    IF p_total_amount <= 0 THEN
        RAISE EXCEPTION '❌ Error: El monto del traslado debe ser mayor a cero.';
    END IF;

    -- 1. Determinar Cuenta Crédito (Origen)
    IF p_source_bank_id IS NOT NULL AND p_source_bank_id > 0 THEN
        SELECT "accountId" INTO v_credit_account_id FROM public."BankAccount" WHERE id = p_source_bank_id;
    ELSIF p_source_cash_id IS NOT NULL AND p_source_cash_id > 0 THEN
        SELECT "accountId" INTO v_credit_account_id FROM public."CashBox" WHERE id = p_source_cash_id;
    END IF;

    -- 2. Determinar Cuenta Débito (Destino)
    IF p_target_bank_id IS NOT NULL AND p_target_bank_id > 0 THEN
        SELECT "accountId" INTO v_debit_account_id FROM public."BankAccount" WHERE id = p_target_bank_id;
    ELSIF p_target_cash_id IS NOT NULL AND p_target_cash_id > 0 THEN
        SELECT "accountId" INTO v_debit_account_id FROM public."CashBox" WHERE id = p_target_cash_id;
    END IF;

    IF v_credit_account_id IS NULL OR v_debit_account_id IS NULL THEN
        RAISE EXCEPTION '❌ Error: No se determinaron las cuentas contables de origen y destino para la transferencia.';
    END IF;

    IF v_credit_account_id = v_debit_account_id THEN
        RAISE EXCEPTION '❌ Error: La cuenta contable de origen y destino no pueden ser la misma.';
    END IF;

    -- 3. Consecutivo CC
    SELECT id, prefix INTO v_cc_doc_type_id, v_doc_prefix FROM public."DocumentType" WHERE code = 'CC';
    v_fiscal_year := EXTRACT(YEAR FROM p_movement_date)::INT;

    SELECT "currentNumber" INTO v_curr_number 
    FROM public."Consecutive" 
    WHERE "documentTypeId" = v_cc_doc_type_id AND "fiscalYear" = v_fiscal_year;

    IF v_curr_number IS NULL THEN
        v_curr_number := 1;
        INSERT INTO public."Consecutive" ("documentTypeId", prefix, "currentNumber", "initialNumber", "fiscalYear", "isActive")
        VALUES (v_cc_doc_type_id, v_doc_prefix, 2, 1, v_fiscal_year, true);
    ELSE
        UPDATE public."Consecutive" 
        SET "currentNumber" = "currentNumber" + 1 
        WHERE "documentTypeId" = v_cc_doc_type_id AND "fiscalYear" = v_fiscal_year;
    END IF;

    v_entry_number := CONCAT(COALESCE(v_doc_prefix, 'CC'), '-', v_fiscal_year, '-', LPAD(v_curr_number::TEXT, 6, '0'));

    -- 4. Crear Comprobante de Traslado
    INSERT INTO public."JournalEntry" (
        "companyId", "documentTypeId", "consecutiveNumber", "entryNumber",
        "entryDate", concept, observation,
        "totalDebit", "totalCredit", status, "createdById",
        "postedAt", "createdAt", "updatedAt"
    ) VALUES (
        p_company_id, v_cc_doc_type_id, v_curr_number, v_entry_number,
        p_movement_date, p_concept,
        CONCAT('Traslado de Fondos #', v_entry_number),
        p_total_amount, p_total_amount, 'POSTED', p_user_id,
        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    ) RETURNING id INTO v_journal_id;

    -- Asiento Débito (Entrada a Cuenta Destino)
    INSERT INTO public."JournalEntryItem" (
        "journalEntryId", "accountId", debit, credit, description, "documentReference",
        "createdAt", "updatedAt"
    ) VALUES (
        v_journal_id, v_debit_account_id, p_total_amount, 0,
        CONCAT('Traslado Entrada - ', p_concept), v_entry_number,
        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    );

    -- Asiento Crédito (Salida de Cuenta Origen)
    INSERT INTO public."JournalEntryItem" (
        "journalEntryId", "accountId", debit, credit, description, "documentReference",
        "createdAt", "updatedAt"
    ) VALUES (
        v_journal_id, v_credit_account_id, 0, p_total_amount,
        CONCAT('Traslado Salida - ', p_concept), v_entry_number,
        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    );

    -- 5. Insertar Movimiento de Tesorería
    INSERT INTO public."TreasuryMovement" (
        "companyId", "movementType", "documentTypeId", "consecutiveNumber", "entryNumber",
        "movementDate", "bankAccountId", "cashBoxId", "targetBankAccountId", "targetCashBoxId",
        concept, "paymentMethod", "totalAmount", status,
        "journalEntryId", "createdById", "createdAt", "updatedAt"
    ) VALUES (
        p_company_id, 'TRANSFERENCIA', v_cc_doc_type_id, v_curr_number, v_entry_number,
        p_movement_date, p_source_bank_id, p_source_cash_id, p_target_bank_id, p_target_cash_id,
        p_concept, 'TRANSFERENCIA', p_total_amount, 'POSTED',
        v_journal_id, p_user_id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    ) RETURNING id INTO v_mov_id;

    p_movement_id := v_mov_id;
    p_journal_id := v_journal_id;
END;
$$;
