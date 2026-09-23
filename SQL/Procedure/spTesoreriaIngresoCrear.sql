-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTO DE INGRESO / RECAUDO (POSTGRESQL)
-- Archivo: SQL/Procedure/spTesoreriaIngresoCrear.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spTesoreriaIngresoCrear"(INT, TIMESTAMP(3), INT, INT, INT, VARCHAR, VARCHAR, VARCHAR, NUMERIC, INT, INT, INT, INT);
END $$;

CREATE OR REPLACE PROCEDURE public."spTesoreriaIngresoCrear"(
    IN p_company_id INT,
    IN p_movement_date TIMESTAMP(3),
    IN p_bank_account_id INT,
    IN p_cash_box_id INT,
    IN p_third_party_id INT,
    IN p_concept VARCHAR,
    IN p_payment_method VARCHAR,
    IN p_check_number VARCHAR,
    IN p_total_amount NUMERIC(18, 4),
    IN p_counterpart_account_id INT, -- Cuenta crédito (ej: 130505 Clientes o 2805 Anticipos)
    IN p_cost_center_id INT,
    IN p_user_id INT,
    OUT p_movement_id INT,
    OUT p_journal_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_ci_doc_type_id INT;
    v_doc_prefix VARCHAR;
    v_fiscal_year INT;
    v_curr_number INT;
    v_entry_number VARCHAR;
    v_debit_account_id INT;
    v_journal_id INT;
    v_mov_id INT;
BEGIN
    IF p_total_amount <= 0 THEN
        RAISE EXCEPTION '❌ Error: El monto del ingreso debe ser mayor a cero.';
    END IF;

    -- 1. Determinar cuenta contable Débito (Caja o Banco)
    IF p_bank_account_id IS NOT NULL AND p_bank_account_id > 0 THEN
        SELECT "accountId" INTO v_debit_account_id FROM public."BankAccount" WHERE id = p_bank_account_id;
    ELSIF p_cash_box_id IS NOT NULL AND p_cash_box_id > 0 THEN
        SELECT "accountId" INTO v_debit_account_id FROM public."CashBox" WHERE id = p_cash_box_id;
    END IF;

    IF v_debit_account_id IS NULL THEN
        -- Fallback a Caja General 110505
        SELECT id INTO v_debit_account_id FROM public."Account" WHERE code = '110505' LIMIT 1;
    END IF;

    IF v_debit_account_id IS NULL OR p_counterpart_account_id IS NULL THEN
        RAISE EXCEPTION '❌ Error de Parametrización: No se determinó la cuenta débito de tesorería o la cuenta crédito de contrapartida.';
    END IF;

    -- 2. Consecutivo de Comprobante de Ingreso ('CI')
    SELECT id, prefix INTO v_ci_doc_type_id, v_doc_prefix FROM public."DocumentType" WHERE code = 'CI';
    IF v_ci_doc_type_id IS NULL THEN
        SELECT id, prefix INTO v_ci_doc_type_id, v_doc_prefix FROM public."DocumentType" WHERE code = 'CC';
    END IF;

    v_fiscal_year := EXTRACT(YEAR FROM p_movement_date)::INT;

    SELECT "currentNumber" INTO v_curr_number 
    FROM public."Consecutive" 
    WHERE "documentTypeId" = v_ci_doc_type_id AND "fiscalYear" = v_fiscal_year;

    IF v_curr_number IS NULL THEN
        v_curr_number := 1;
        INSERT INTO public."Consecutive" ("documentTypeId", prefix, "currentNumber", "initialNumber", "fiscalYear", "isActive")
        VALUES (v_ci_doc_type_id, v_doc_prefix, 2, 1, v_fiscal_year, true);
    ELSE
        UPDATE public."Consecutive" 
        SET "currentNumber" = "currentNumber" + 1 
        WHERE "documentTypeId" = v_ci_doc_type_id AND "fiscalYear" = v_fiscal_year;
    END IF;

    v_entry_number := CONCAT(COALESCE(v_doc_prefix, 'CI'), '-', v_fiscal_year, '-', LPAD(v_curr_number::TEXT, 6, '0'));

    -- 3. Crear Comprobante Contable Automático (Partida Doble Exacta)
    INSERT INTO public."JournalEntry" (
        "companyId", "documentTypeId", "consecutiveNumber", "entryNumber",
        "entryDate", "thirdPartyId", concept, observation,
        "totalDebit", "totalCredit", status, "createdById",
        "postedAt", "createdAt", "updatedAt"
    ) VALUES (
        p_company_id, v_ci_doc_type_id, v_curr_number, v_entry_number,
        p_movement_date, p_third_party_id, p_concept,
        CONCAT('Recibo de Caja / Ingreso de Tesorería #', v_entry_number, ' - Forma de Pago: ', p_payment_method),
        p_total_amount, p_total_amount, 'POSTED', p_user_id,
        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    ) RETURNING id INTO v_journal_id;

    -- Asiento Débito (Ingreso a Caja/Banco)
    INSERT INTO public."JournalEntryItem" (
        "journalEntryId", "accountId", "thirdPartyId", "costCenterId",
        debit, credit, "baseAmount", description, "documentReference",
        "createdAt", "updatedAt"
    ) VALUES (
        v_journal_id, v_debit_account_id, p_third_party_id, p_cost_center_id,
        p_total_amount, 0, 0, CONCAT('Ingreso Tesorería - ', p_concept), v_entry_number,
        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    );

    -- Asiento Crédito (Abono a Cartera / Contrapartida)
    INSERT INTO public."JournalEntryItem" (
        "journalEntryId", "accountId", "thirdPartyId", "costCenterId",
        debit, credit, "baseAmount", description, "documentReference",
        "createdAt", "updatedAt"
    ) VALUES (
        v_journal_id, p_counterpart_account_id, p_third_party_id, p_cost_center_id,
        0, p_total_amount, 0, CONCAT('Contrapartida Ingreso - ', p_concept), v_entry_number,
        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    );

    -- 4. Insertar Movimiento de Tesorería
    INSERT INTO public."TreasuryMovement" (
        "companyId", "movementType", "documentTypeId", "consecutiveNumber", "entryNumber",
        "movementDate", "bankAccountId", "cashBoxId", "thirdPartyId",
        concept, "paymentMethod", "checkNumber", "totalAmount", status,
        "journalEntryId", "createdById", "createdAt", "updatedAt"
    ) VALUES (
        p_company_id, 'INGRESO', v_ci_doc_type_id, v_curr_number, v_entry_number,
        p_movement_date, p_bank_account_id, p_cash_box_id, p_third_party_id,
        p_concept, COALESCE(p_payment_method, 'TRANSFERENCIA'), p_check_number,
        p_total_amount, 'POSTED', v_journal_id, p_user_id,
        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    ) RETURNING id INTO v_mov_id;

    p_movement_id := v_mov_id;
    p_journal_id := v_journal_id;
END;
$$;
