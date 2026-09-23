-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTO DE EGRESO / PAGO (POSTGRESQL)
-- Archivo: SQL/Procedure/spTesoreriaEgresoCrear.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spTesoreriaEgresoCrear"(INT, TIMESTAMP(3), INT, INT, INT, VARCHAR, VARCHAR, VARCHAR, NUMERIC, INT, NUMERIC, INT, INT, INT, INT, INT);
END $$;

CREATE OR REPLACE PROCEDURE public."spTesoreriaEgresoCrear"(
    IN p_company_id INT,
    IN p_movement_date TIMESTAMP(3),
    IN p_bank_account_id INT,
    IN p_cash_box_id INT,
    IN p_third_party_id INT,
    IN p_concept VARCHAR,
    IN p_payment_method VARCHAR,
    IN p_check_number VARCHAR,
    IN p_total_amount NUMERIC(18, 4), -- Monto neto pagado
    IN p_debit_account_id INT,        -- Cuenta débito (ej: 220505 Proveedores o 5135 Gastos)
    IN p_withholding_amount NUMERIC(18, 4), -- Retención aplicada
    IN p_withholding_account_id INT, -- Cuenta crédito de retención (ej: 236540)
    IN p_cost_center_id INT,
    IN p_user_id INT,
    OUT p_movement_id INT,
    OUT p_journal_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_ce_doc_type_id INT;
    v_doc_prefix VARCHAR;
    v_fiscal_year INT;
    v_curr_number INT;
    v_entry_number VARCHAR;
    v_credit_account_id INT;
    v_journal_id INT;
    v_mov_id INT;
    v_gross_amount NUMERIC(18, 4);
    v_total_journal NUMERIC(18, 4);
BEGIN
    IF p_total_amount <= 0 THEN
        RAISE EXCEPTION '❌ Error: El monto del egreso debe ser mayor a cero.';
    END IF;

    -- 1. Determinar cuenta contable Crédito (Caja o Banco pagador)
    IF p_bank_account_id IS NOT NULL AND p_bank_account_id > 0 THEN
        SELECT "accountId" INTO v_credit_account_id FROM public."BankAccount" WHERE id = p_bank_account_id;
    ELSIF p_cash_box_id IS NOT NULL AND p_cash_box_id > 0 THEN
        SELECT "accountId" INTO v_credit_account_id FROM public."CashBox" WHERE id = p_cash_box_id;
    END IF;

    IF v_credit_account_id IS NULL THEN
        SELECT id INTO v_credit_account_id FROM public."Account" WHERE code = '11100501' LIMIT 1;
    END IF;

    IF v_credit_account_id IS NULL OR p_debit_account_id IS NULL THEN
        RAISE EXCEPTION '❌ Error de Parametrización: No se determinó la cuenta pagadora o la cuenta de gasto/proveedor.';
    END IF;

    v_gross_amount := p_total_amount + COALESCE(p_withholding_amount, 0);
    v_total_journal := v_gross_amount;

    -- 2. Consecutivo de Comprobante de Egreso ('CE')
    SELECT id, prefix INTO v_ce_doc_type_id, v_doc_prefix FROM public."DocumentType" WHERE code = 'CE';
    IF v_ce_doc_type_id IS NULL THEN
        SELECT id, prefix INTO v_ce_doc_type_id, v_doc_prefix FROM public."DocumentType" WHERE code = 'CC';
    END IF;

    v_fiscal_year := EXTRACT(YEAR FROM p_movement_date)::INT;

    SELECT "currentNumber" INTO v_curr_number 
    FROM public."Consecutive" 
    WHERE "documentTypeId" = v_ce_doc_type_id AND "fiscalYear" = v_fiscal_year;

    IF v_curr_number IS NULL THEN
        v_curr_number := 1;
        INSERT INTO public."Consecutive" ("documentTypeId", prefix, "currentNumber", "initialNumber", "fiscalYear", "isActive")
        VALUES (v_ce_doc_type_id, v_doc_prefix, 2, 1, v_fiscal_year, true);
    ELSE
        UPDATE public."Consecutive" 
        SET "currentNumber" = "currentNumber" + 1 
        WHERE "documentTypeId" = v_ce_doc_type_id AND "fiscalYear" = v_fiscal_year;
    END IF;

    v_entry_number := CONCAT(COALESCE(v_doc_prefix, 'CE'), '-', v_fiscal_year, '-', LPAD(v_curr_number::TEXT, 6, '0'));

    -- 3. Crear Comprobante Contable de Egreso
    INSERT INTO public."JournalEntry" (
        "companyId", "documentTypeId", "consecutiveNumber", "entryNumber",
        "entryDate", "thirdPartyId", concept, observation,
        "totalDebit", "totalCredit", status, "createdById",
        "postedAt", "createdAt", "updatedAt"
    ) VALUES (
        p_company_id, v_ce_doc_type_id, v_curr_number, v_entry_number,
        p_movement_date, p_third_party_id, p_concept,
        CONCAT('Comprobante de Egreso / Pago #', v_entry_number, ' - Forma de Pago: ', p_payment_method),
        v_total_journal, v_total_journal, 'POSTED', p_user_id,
        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    ) RETURNING id INTO v_journal_id;

    -- Asiento Débito (Cancelación de Obligación o Gasto Bruto)
    INSERT INTO public."JournalEntryItem" (
        "journalEntryId", "accountId", "thirdPartyId", "costCenterId",
        debit, credit, "baseAmount", description, "documentReference",
        "createdAt", "updatedAt"
    ) VALUES (
        v_journal_id, p_debit_account_id, p_third_party_id, p_cost_center_id,
        v_gross_amount, 0, 0, CONCAT('Gasto/Obligación - ', p_concept), v_entry_number,
        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    );

    -- Asiento Crédito (Salida neta de Banco / Caja)
    INSERT INTO public."JournalEntryItem" (
        "journalEntryId", "accountId", "thirdPartyId", "costCenterId",
        debit, credit, "baseAmount", description, "documentReference",
        "createdAt", "updatedAt"
    ) VALUES (
        v_journal_id, v_credit_account_id, p_third_party_id, p_cost_center_id,
        0, p_total_amount, 0, CONCAT('Pago Tesorería - ', p_concept), v_entry_number,
        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    );

    -- Asiento Crédito Retención en la Fuente (si aplica)
    IF p_withholding_amount IS NOT NULL AND p_withholding_amount > 0 AND p_withholding_account_id IS NOT NULL THEN
        INSERT INTO public."JournalEntryItem" (
            "journalEntryId", "accountId", "thirdPartyId", "costCenterId",
            debit, credit, "baseAmount", description, "documentReference",
            "createdAt", "updatedAt"
        ) VALUES (
            v_journal_id, p_withholding_account_id, p_third_party_id, p_cost_center_id,
            0, p_withholding_amount, v_gross_amount, CONCAT('Retención en la fuente aplicada - ', p_concept), v_entry_number,
            CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        );
    END IF;

    -- 4. Insertar Movimiento de Tesorería
    INSERT INTO public."TreasuryMovement" (
        "companyId", "movementType", "documentTypeId", "consecutiveNumber", "entryNumber",
        "movementDate", "bankAccountId", "cashBoxId", "thirdPartyId",
        concept, "paymentMethod", "checkNumber", "totalAmount", status,
        "journalEntryId", "createdById", "createdAt", "updatedAt"
    ) VALUES (
        p_company_id, 'EGRESO', v_ce_doc_type_id, v_curr_number, v_entry_number,
        p_movement_date, p_bank_account_id, p_cash_box_id, p_third_party_id,
        p_concept, COALESCE(p_payment_method, 'TRANSFERENCIA'), p_check_number,
        p_total_amount, 'POSTED', v_journal_id, p_user_id,
        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    ) RETURNING id INTO v_mov_id;

    p_movement_id := v_mov_id;
    p_journal_id := v_journal_id;
END;
$$;
