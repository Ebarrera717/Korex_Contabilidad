-- ============================================================================
-- PROYECTO: KOREX_CONTABILIDAD
-- PROCEDIMIENTO: spIntegrationTransactionRegistrar
-- DESCRIPCION: Registro de auditoría y telemetría de transacciones e interfaces de datos
-- ============================================================================

CREATE OR REPLACE PROCEDURE public."spIntegrationTransactionRegistrar"(
    IN p_endpoint_code VARCHAR(50),
    IN p_direction VARCHAR(20),
    IN p_event_type VARCHAR(50),
    IN p_request_payload JSONB,
    IN p_response_payload JSONB,
    IN p_http_status INTEGER,
    IN p_duration_ms INTEGER,
    IN p_status VARCHAR(20),
    IN p_error_message TEXT,
    OUT p_tx_code VARCHAR(50)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_date_str VARCHAR(8);
    v_seq_num INTEGER;
BEGIN
    v_date_str := TO_CHAR(CURRENT_DATE, 'YYYYMMDD');
    
    SELECT COUNT(id) + 1 INTO v_seq_num
    FROM public."IntegrationTransaction"
    WHERE "txCode" LIKE 'ITX-' || v_date_str || '-%';

    p_tx_code := 'ITX-' || v_date_str || '-' || LPAD(v_seq_num::TEXT, 4, '0');

    INSERT INTO public."IntegrationTransaction" (
        "txCode", "endpointCode", "direction", "eventType",
        "requestPayload", "responsePayload", "httpStatus",
        "durationMs", "status", "errorMessage", "createdAt"
    ) VALUES (
        p_tx_code, p_endpoint_code, p_direction, p_event_type,
        p_request_payload, p_response_payload, p_http_status,
        COALESCE(p_duration_ms, 0), COALESCE(p_status, 'SUCCESS'),
        p_error_message, CURRENT_TIMESTAMP
    );
END;
$$;
