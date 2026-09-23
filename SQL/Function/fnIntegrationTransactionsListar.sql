-- ============================================================================
-- PROYECTO: KOREX_CONTABILIDAD
-- FUNCION: fnIntegrationTransactionsListar
-- DESCRIPCION: Consulta y auditoría de transacciones e intercambios de datos externos
-- ============================================================================

CREATE OR REPLACE FUNCTION public."fnIntegrationTransactionsListar"(
    p_endpoint_code VARCHAR DEFAULT NULL,
    p_direction VARCHAR DEFAULT NULL,
    p_status VARCHAR DEFAULT NULL,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    "id" INTEGER,
    "txCode" VARCHAR,
    "endpointCode" VARCHAR,
    "direction" VARCHAR,
    "eventType" VARCHAR,
    "requestPayload" JSONB,
    "responsePayload" JSONB,
    "httpStatus" INTEGER,
    "durationMs" INTEGER,
    "status" VARCHAR,
    "errorMessage" TEXT,
    "createdAt" TIMESTAMP(3)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t."id",
        t."txCode",
        t."endpointCode",
        t."direction",
        t."eventType",
        t."requestPayload",
        t."responsePayload",
        t."httpStatus",
        t."durationMs",
        t."status",
        t."errorMessage",
        t."createdAt"
    FROM public."IntegrationTransaction" t
    WHERE (p_endpoint_code IS NULL OR t."endpointCode" = p_endpoint_code)
      AND (p_direction IS NULL OR t."direction" = p_direction)
      AND (p_status IS NULL OR t."status" = p_status)
      AND (p_start_date IS NULL OR t."createdAt"::DATE >= p_start_date)
      AND (p_end_date IS NULL OR t."createdAt"::DATE <= p_end_date)
    ORDER BY t."createdAt" DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$;
