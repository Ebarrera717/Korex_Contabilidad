-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTO ALMACENADO: spFacturaVentaAnular
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spFacturaVentaAnular";
END $$;

CREATE OR REPLACE PROCEDURE public."spFacturaVentaAnular"(
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
    FROM public."ReceivableInvoice"
    WHERE id = p_invoice_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION '❌ La factura de venta con ID % no existe', p_invoice_id;
    END IF;

    IF COALESCE(v_paid_amount, 0) > 0 THEN
        RAISE EXCEPTION '❌ No se puede anular la factura porque ya posee abonos o recaudos aplicados ($%)', v_paid_amount;
    END IF;

    -- Anular factura y cuotas
    UPDATE public."ReceivableInvoice"
    SET status = 'ANNULLED', observations = COALESCE(observations, '') || ' | ANULADA: ' || p_reason, "updatedAt" = CURRENT_TIMESTAMP
    WHERE id = p_invoice_id;

    UPDATE public."ReceivableInstallment"
    SET status = 'ANNULLED', "updatedAt" = CURRENT_TIMESTAMP
    WHERE "receivableInvoiceId" = p_invoice_id;

    -- Anular comprobante contable
    IF v_journal_id IS NOT NULL THEN
        UPDATE public."JournalEntry"
        SET status = 'ANNULLED', "annulledAt" = CURRENT_TIMESTAMP, "annulmentReason" = p_reason
        WHERE id = v_journal_id;
    END IF;
END;
$$;
