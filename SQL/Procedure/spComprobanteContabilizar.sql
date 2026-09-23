-- ============================================================================
-- KOREX_CONTABILIDAD - MOTOR DE CONTABILIZACIÓN (POSTGRESQL)
-- Archivo: SQL/Procedure/spComprobanteContabilizar.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spComprobanteContabilizar"(INT, INT);
END $$;

CREATE OR REPLACE PROCEDURE public."spComprobanteContabilizar"(
    IN p_journal_id INT,
    IN p_user_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_journal RECORD;
    v_total_debit NUMERIC(18, 4) := 0;
    v_total_credit NUMERIC(18, 4) := 0;
    v_diff NUMERIC(18, 4);
    v_line_count INT := 0;
    v_invalid_acc RECORD;
    v_missing_tp RECORD;
    v_missing_cc RECORD;
    v_period RECORD;
    v_year INT;
    v_month INT;
BEGIN
    -- 1. Obtener encabezado del comprobante
    SELECT * INTO v_journal FROM public."JournalEntry" WHERE id = p_journal_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION '❌ Error de Contabilización: El comprobante #% no existe.', p_journal_id;
    END IF;

    IF v_journal.status = 'POSTED' THEN
        RAISE EXCEPTION '⚠️ Advertencia: El comprobante #% (%) ya se encuentra contabilizado.', p_journal_id, v_journal."entryNumber";
    END IF;

    IF v_journal.status = 'ANNULLED' THEN
        RAISE EXCEPTION '❌ Error: El comprobante #% (%) está anulado y no puede ser contabilizado.', p_journal_id, v_journal."entryNumber";
    END IF;

    -- 2. VALIDACIÓN DE PERÍODO FISCAL
    v_year := EXTRACT(YEAR FROM v_journal."entryDate")::INT;
    v_month := EXTRACT(MONTH FROM v_journal."entryDate")::INT;

    SELECT * INTO v_period FROM public."FiscalPeriod" WHERE year = v_year AND month = v_month;
    IF FOUND AND v_period.status = 'CLOSED' THEN
        RAISE EXCEPTION '❌ Período Cerrado: El período contable %-% se encuentra cerrado. No se permiten contabilizaciones.', v_year, LPAD(v_month::TEXT, 2, '0');
    END IF;

    -- 3. CALCULAR TOTALES DE LÍNEAS Y CONTAR
    SELECT 
        COUNT(*),
        COALESCE(SUM(debit), 0),
        COALESCE(SUM(credit), 0)
    INTO v_line_count, v_total_debit, v_total_credit
    FROM public."JournalEntryItem"
    WHERE "journalEntryId" = p_journal_id;

    IF v_line_count < 2 THEN
        RAISE EXCEPTION '❌ Asientos Insuficientes: Un comprobante contable debe poseer al menos 2 asientos para cumplir la partida doble (registrados: %).', v_line_count;
    END IF;

    -- 4. VALIDACIÓN ESTRICTA DE PARTIDA DOBLE (DÉBITOS = CRÉDITOS)
    v_diff := ABS(v_total_debit - v_total_credit);
    IF v_diff > 0.0001 THEN
        RAISE EXCEPTION '❌ Descuadre Contable (Partida Doble): El comprobante % no cumple con la partida doble. Total Débitos ($%) != Total Créditos ($%). Diferencia: $%',
            v_journal."entryNumber", v_total_debit, v_total_credit, v_diff;
    END IF;

    -- 5. VALIDACIÓN DE CUENTAS DE MOVIMIENTO (PROHIBIDO CUENTAS PADRE)
    SELECT a.code, a.name INTO v_invalid_acc
    FROM public."JournalEntryItem" ji
    INNER JOIN public."Account" a ON ji."accountId" = a.id
    WHERE ji."journalEntryId" = p_journal_id AND a."allowsMovement" = false
    LIMIT 1;

    IF FOUND THEN
        RAISE EXCEPTION '❌ Cuenta Inválida de Movimiento: La cuenta "% - %" es una cuenta de nivel superior/padre y no permite movimientos directos. Debe seleccionar una cuenta auxiliar de último nivel.',
            v_invalid_acc.code, v_invalid_acc.name;
    END IF;

    -- 6. VALIDACIÓN DE EXIGENCIA DE TERCEROS
    SELECT a.code, a.name INTO v_missing_tp
    FROM public."JournalEntryItem" ji
    INNER JOIN public."Account" a ON ji."accountId" = a.id
    WHERE ji."journalEntryId" = p_journal_id 
      AND a."requiresThirdParty" = true 
      AND (ji."thirdPartyId" IS NULL OR ji."thirdPartyId" = 0)
    LIMIT 1;

    IF FOUND THEN
        RAISE EXCEPTION '❌ Exigencia de Tercero: La cuenta "% - %" requiere obligatoriamente un Tercero asignado en el asiento.',
            v_missing_tp.code, v_missing_tp.name;
    END IF;

    -- 7. VALIDACIÓN DE EXIGENCIA DE CENTRO DE COSTO
    SELECT a.code, a.name INTO v_missing_cc
    FROM public."JournalEntryItem" ji
    INNER JOIN public."Account" a ON ji."accountId" = a.id
    WHERE ji."journalEntryId" = p_journal_id 
      AND a."requiresCostCenter" = true 
      AND (ji."costCenterId" IS NULL OR ji."costCenterId" = 0)
    LIMIT 1;

    IF FOUND THEN
        RAISE EXCEPTION '❌ Exigencia de Centro de Costo: La cuenta "% - %" requiere obligatoriamente un Centro de Costo asignado en el asiento.',
            v_missing_cc.code, v_missing_cc.name;
    END IF;

    -- 8. ASENTAMIENTO EXITOSO
    UPDATE public."JournalEntry"
    SET 
        status = 'POSTED',
        "totalDebit" = v_total_debit,
        "totalCredit" = v_total_credit,
        "postedAt" = CURRENT_TIMESTAMP,
        "updatedAt" = CURRENT_TIMESTAMP
    WHERE id = p_journal_id;
END;
$$;
