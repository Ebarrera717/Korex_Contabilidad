-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTO DE CIERRE Y REAPERTURA DE PERÍODO (POSTGRESQL)
-- Archivo: SQL/Procedure/spPeriodoCerrar.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spPeriodoCerrar"(INT, INT, INT);
END $$;

CREATE OR REPLACE PROCEDURE public."spPeriodoCerrar"(
    IN p_year INT,
    IN p_month INT,
    IN p_user_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_draft_count INT;
BEGIN
    -- Validar que no existan comprobantes pendientes en borrador para el mes a cerrar
    SELECT COUNT(*) INTO v_draft_count
    FROM public."JournalEntry"
    WHERE EXTRACT(YEAR FROM "entryDate")::INT = p_year 
      AND EXTRACT(MONTH FROM "entryDate")::INT = p_month
      AND status = 'DRAFT';

    IF v_draft_count > 0 THEN
        RAISE EXCEPTION '❌ No se puede cerrar el período: Existen % comprobantes en estado BORRADOR (DRAFT) para el período %-%. Debe contabilizarlos o anularlos previamente.',
            v_draft_count, p_year, LPAD(p_month::TEXT, 2, '0');
    END IF;

    -- Cerrar período
    INSERT INTO public."FiscalPeriod" (
        year, month, "startDate", "endDate", status, "closedAt", "closedBy", "createdAt", "updatedAt"
    ) VALUES (
        p_year, p_month, 
        MAKE_DATE(p_year, p_month, 1),
        (MAKE_DATE(p_year, p_month, 1) + INTERVAL '1 MONTH - 1 DAY')::TIMESTAMP,
        'CLOSED', CURRENT_TIMESTAMP, p_user_id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    )
    ON CONFLICT (year, month)
    DO UPDATE SET 
        status = 'CLOSED',
        "closedAt" = CURRENT_TIMESTAMP,
        "closedBy" = p_user_id,
        "updatedAt" = CURRENT_TIMESTAMP;
END;
$$;
