-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTO ALMACENADO: spProveedorEgresoCruzar
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spProveedorEgresoCruzar";
END $$;

CREATE OR REPLACE PROCEDURE public."spProveedorEgresoCruzar"(
    IN p_payable_invoice_id INTEGER,
    IN p_payable_installment_id INTEGER,
    IN p_treasury_movement_id INTEGER,
    IN p_advance_payment_id INTEGER,
    IN p_credit_note_id INTEGER,
    IN p_amount NUMERIC(18, 4),
    IN p_discount_amount NUMERIC(18, 4),
    IN p_observations TEXT,
    OUT p_allocation_id INTEGER,
    OUT p_new_balance NUMERIC(18, 4),
    OUT p_invoice_status VARCHAR(20)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_inv_balance NUMERIC(18, 4);
    v_inst_balance NUMERIC(18, 4);
    v_total_applied NUMERIC(18, 4);
    v_adv_balance NUMERIC(18, 4);
    v_note_balance NUMERIC(18, 4);
BEGIN
    -- Validar factura de compra
    SELECT "balanceAmount" INTO v_inv_balance
    FROM public."PayableInvoice"
    WHERE id = p_payable_invoice_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION '❌ Factura de compra con ID % no encontrada', p_payable_invoice_id;
    END IF;

    v_total_applied := COALESCE(p_amount, 0) + COALESCE(p_discount_amount, 0);

    IF v_total_applied <= 0 THEN
        RAISE EXCEPTION '❌ El monto total a cruzar debe ser mayor a cero';
    END IF;

    IF v_total_applied > v_inv_balance THEN
        RAISE EXCEPTION '❌ El monto a cruzar ($%) supera el saldo pendiente de la factura ($%)', v_total_applied, v_inv_balance;
    END IF;

    -- Validar saldo de anticipo a proveedor si aplica
    IF p_advance_payment_id IS NOT NULL THEN
        SELECT "balanceAmount" INTO v_adv_balance
        FROM public."AdvancePayment"
        WHERE id = p_advance_payment_id
        FOR UPDATE;

        IF v_adv_balance < p_amount THEN
            RAISE EXCEPTION '❌ El anticipo no posee saldo disponible ($% vs $%)', v_adv_balance, p_amount;
        END IF;

        UPDATE public."AdvancePayment"
        SET "usedAmount" = "usedAmount" + p_amount,
            "balanceAmount" = "balanceAmount" - p_amount,
            status = CASE WHEN "balanceAmount" - p_amount <= 0 THEN 'EXHAUSTED' ELSE 'ACTIVE' END,
            "updatedAt" = CURRENT_TIMESTAMP
        WHERE id = p_advance_payment_id;
    END IF;

    -- Validar saldo de nota débito si aplica
    IF p_credit_note_id IS NOT NULL THEN
        SELECT "balanceAmount" INTO v_note_balance
        FROM public."CreditDebitNote"
        WHERE id = p_credit_note_id
        FOR UPDATE;

        IF v_note_balance < p_amount THEN
            RAISE EXCEPTION '❌ La Nota no posee saldo disponible ($% vs $%)', v_note_balance, p_amount;
        END IF;

        UPDATE public."CreditDebitNote"
        SET "appliedAmount" = "appliedAmount" + p_amount,
            "balanceAmount" = "balanceAmount" - p_amount,
            status = CASE WHEN "balanceAmount" - p_amount <= 0 THEN 'APPLIED' ELSE 'POSTED' END,
            "updatedAt" = CURRENT_TIMESTAMP
        WHERE id = p_credit_note_id;
    END IF;

    -- Insertar asignación de pago
    INSERT INTO public."PayablePaymentAllocation"(
        "payableInvoiceId", "payableInstallmentId", "treasuryMovementId",
        "advancePaymentId", "creditDebitNoteId", "allocationDate",
        amount, "discountAmount", observations
    ) VALUES (
        p_payable_invoice_id, p_payable_installment_id, p_treasury_movement_id,
        p_advance_payment_id, p_credit_note_id, CURRENT_TIMESTAMP,
        p_amount, COALESCE(p_discount_amount, 0), p_observations
    ) RETURNING id INTO p_allocation_id;

    -- Actualizar cuota si se especificó
    IF p_payable_installment_id IS NOT NULL THEN
        SELECT "balanceAmount" INTO v_inst_balance
        FROM public."PayableInstallment"
        WHERE id = p_payable_installment_id
        FOR UPDATE;

        UPDATE public."PayableInstallment"
        SET "paidAmount" = "paidAmount" + v_total_applied,
            "balanceAmount" = "balanceAmount" - v_total_applied,
            status = CASE WHEN "balanceAmount" - v_total_applied <= 0 THEN 'PAID' ELSE 'PARTIAL' END,
            "updatedAt" = CURRENT_TIMESTAMP
        WHERE id = p_payable_installment_id;
    END IF;

    -- Actualizar Factura
    p_new_balance := v_inv_balance - v_total_applied;
    p_invoice_status := CASE WHEN p_new_balance <= 0 THEN 'PAID' ELSE 'PARTIAL' END;

    UPDATE public."PayableInvoice"
    SET "paidAmount" = "paidAmount" + v_total_applied,
        "balanceAmount" = p_new_balance,
        status = p_invoice_status,
        "updatedAt" = CURRENT_TIMESTAMP
    WHERE id = p_payable_invoice_id;
END;
$$;
