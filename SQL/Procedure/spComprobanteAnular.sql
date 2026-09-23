-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTOS DE ANULACIÓN Y REVERSIÓN (POSTGRESQL)
-- Archivo: SQL/Procedure/spComprobanteAnular.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spComprobanteAnular"(INT, TEXT, INT);
END $$;

CREATE OR REPLACE PROCEDURE public."spComprobanteAnular"(
    IN p_journal_id INT,
    IN p_reason TEXT,
    IN p_user_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_journal RECORD;
    v_period RECORD;
    v_year INT;
    v_month INT;
BEGIN
    SELECT * INTO v_journal FROM public."JournalEntry" WHERE id = p_journal_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION '❌ Error: El comprobante #% no existe.', p_journal_id;
    END IF;

    IF v_journal.status = 'ANNULLED' THEN
        RAISE EXCEPTION '⚠️ Advertencia: El comprobante #% (%) ya se encuentra anulado.', p_journal_id, v_journal."entryNumber";
    END IF;

    -- Validar que el período no esté cerrado
    v_year := EXTRACT(YEAR FROM v_journal."entryDate")::INT;
    v_month := EXTRACT(MONTH FROM v_journal."entryDate")::INT;

    SELECT * INTO v_period FROM public."FiscalPeriod" WHERE year = v_year AND month = v_month;
    IF FOUND AND v_period.status = 'CLOSED' THEN
        RAISE EXCEPTION '❌ Período Cerrado: El período contable %-% está cerrado. No se puede anular un comprobante histórico.', v_year, LPAD(v_month::TEXT, 2, '0');
    END IF;

    UPDATE public."JournalEntry"
    SET 
        status = 'ANNULLED',
        "annulledAt" = CURRENT_TIMESTAMP,
        "annulmentReason" = COALESCE(p_reason, 'Anulado por usuario'),
        "updatedAt" = CURRENT_TIMESTAMP
    WHERE id = p_journal_id;
END;
$$;
