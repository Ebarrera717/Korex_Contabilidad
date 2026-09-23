-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTOS DE PERÍODOS Y CIERRE ANUAL (POSTGRESQL)
-- Archivo: SQL/Procedure/spPeriodoGuardar.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spPeriodoGuardar"(INT, INT, TIMESTAMP(3), TIMESTAMP(3), VARCHAR);
END $$;

CREATE OR REPLACE PROCEDURE public."spPeriodoGuardar"(
    IN p_year INT,
    IN p_month INT,
    IN p_start_date TIMESTAMP(3),
    IN p_end_date TIMESTAMP(3),
    IN p_status VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public."FiscalPeriod" (
        year, month, "startDate", "endDate", status, "createdAt", "updatedAt"
    ) VALUES (
        p_year, p_month, p_start_date, p_end_date, COALESCE(p_status, 'OPEN'), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    )
    ON CONFLICT (year, month) 
    DO UPDATE SET 
        "startDate" = EXCLUDED."startDate",
        "endDate" = EXCLUDED."endDate",
        status = EXCLUDED.status,
        "updatedAt" = CURRENT_TIMESTAMP;
END;
$$;
