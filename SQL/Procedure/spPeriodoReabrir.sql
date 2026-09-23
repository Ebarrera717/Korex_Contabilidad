-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTO DE REAPERTURA DE PERÍODO (POSTGRESQL)
-- Archivo: SQL/Procedure/spPeriodoReabrir.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spPeriodoReabrir"(INT, INT, INT);
END $$;

CREATE OR REPLACE PROCEDURE public."spPeriodoReabrir"(
    IN p_year INT,
    IN p_month INT,
    IN p_user_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE public."FiscalPeriod"
    SET 
        status = 'OPEN',
        "closedAt" = NULL,
        "closedBy" = NULL,
        "updatedAt" = CURRENT_TIMESTAMP
    WHERE year = p_year AND month = p_month;
END;
$$;
