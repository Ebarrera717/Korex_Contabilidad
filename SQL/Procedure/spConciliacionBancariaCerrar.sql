-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTO DE CIERRE DE CONCILIACIÓN BANCARIA (POSTGRESQL)
-- Archivo: SQL/Procedure/spConciliacionBancariaCerrar.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spConciliacionBancariaCerrar"(INT, INT);
END $$;

CREATE OR REPLACE PROCEDURE public."spConciliacionBancariaCerrar"(
    IN p_reconciliation_id INT,
    IN p_user_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE public."BankReconciliation"
    SET 
        status = 'CLOSED',
        "closedAt" = CURRENT_TIMESTAMP,
        "closedById" = p_user_id,
        "updatedAt" = CURRENT_TIMESTAMP
    WHERE id = p_reconciliation_id;
END;
$$;
