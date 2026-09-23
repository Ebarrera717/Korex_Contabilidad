-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTO ALMACENADO: spFacturaCompraAnular
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spFacturaCompraAnular";
END $$;

CREATE OR REPLACE PROCEDURE public."spFacturaCompraAnular"(
    IN p_invoice_id INTEGER,
    IN p_reason TEXT,
    IN p_user_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_paid_amount NUMERIC(18, 4);
    v_journal_id INTEGER;
BEGIN
    SELECT "paidAmount", "journalEntryId" INTO v_paid_amount, v_journal_id
    FROM public."PayableInvoice"
    WHERE id = p_invoice_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION '❌ La factura de compra con ID % no existe', p_invoice_id;
    END IF;

    IF COALESCE(v_paid_amount, 0) > 0 THEN
        RAISE EXCEPTION '❌ No se puede anular la factura de compra porque ya posee pagos o egresos aplicados ($%)', v_paid_amount;
    END IF;

    -- Anular factura y cuotas
    UPDATE public."PayableInvoice"
    SET status = 'ANNULLED', observations = COALESCE(observations, '') || ' | ANULADA: ' || p_reason, "updatedAt" = CURRENT_TIMESTAMP
    WHERE id = p_invoice_id;

    UPDATE public."PayableInstallment"
    SET status = 'ANNULLED', "updatedAt" = CURRENT_TIMESTAMP
    WHERE "payableInvoiceId" = p_invoice_id;

    -- Anular comprobante contable
    IF v_journal_id IS NOT NULL THEN
        UPDATE public."JournalEntry"
        SET status = 'ANNULLED', "annulledAt" = CURRENT_TIMESTAMP, "annulmentReason" = p_reason
        WHERE id = v_journal_id;
    END IF;
END;
$$;
