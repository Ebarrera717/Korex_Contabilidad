-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTO DE TRAZABILIDAD (POSTGRESQL)
-- Archivo: SQL/Procedure/spTraceabilityLog.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spTraceabilityLog"(VARCHAR, INT, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, INT, VARCHAR, JSONB, JSONB, TEXT, TEXT, TEXT, VARCHAR, VARCHAR);
END $$;

CREATE OR REPLACE PROCEDURE public."spTraceabilityLog"(
    IN p_code VARCHAR,
    IN p_user_id INT,
    IN p_origin VARCHAR,
    IN p_module VARCHAR,
    IN p_screen VARCHAR,
    IN p_action VARCHAR,
    IN p_process VARCHAR,
    IN p_event_type VARCHAR,
    IN p_step_name VARCHAR,
    IN p_sp_name VARCHAR,
    IN p_endpoint VARCHAR,
    IN p_duration_ms INT,
    IN p_status VARCHAR,
    IN p_input_data JSONB,
    IN p_output_data JSONB,
    IN p_tech_message TEXT,
    IN p_functional_message TEXT,
    IN p_stack_trace TEXT,
    IN p_affected_id VARCHAR,
    IN p_extra VARCHAR DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public."TraceabilityLog" (
        code, "userId", origin, module, screen, action, process,
        "eventType", "stepName", "spName", endpoint, "durationMs",
        status, "inputData", "outputData", "techMessage", "functionalMessage",
        "stackTrace", "affectedId", "createdAt"
    ) VALUES (
        p_code, p_user_id, COALESCE(p_origin, 'WEB'), p_module, p_screen, p_action, p_process,
        p_event_type, p_step_name, p_sp_name, p_endpoint, COALESCE(p_duration_ms, 0),
        COALESCE(p_status, 'SUCCESS'), p_input_data, p_output_data, p_tech_message, p_functional_message,
        p_stack_trace, p_affected_id, CURRENT_TIMESTAMP
    );
END;
$$;
