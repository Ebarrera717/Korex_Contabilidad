-- ============================================================================
-- PROYECTO: KOREX_CONTABILIDAD
-- FUNCION: fnBatchImportJobsListar
-- DESCRIPCION: Consulta del historial de procesos de importación masiva en lote
-- ============================================================================

CREATE OR REPLACE FUNCTION public."fnBatchImportJobsListar"(
    p_company_id INTEGER DEFAULT NULL,
    p_status VARCHAR DEFAULT NULL,
    p_interface_type VARCHAR DEFAULT NULL,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    "id" INTEGER,
    "jobCode" VARCHAR,
    "companyId" INTEGER,
    "templateCode" VARCHAR,
    "interfaceType" VARCHAR,
    "fileName" VARCHAR,
    "fileSizeBytes" INTEGER,
    "status" VARCHAR,
    "totalRows" INTEGER,
    "processedRows" INTEGER,
    "successRows" INTEGER,
    "failedRows" INTEGER,
    "errorsSummary" JSONB,
    "startedAt" TIMESTAMP(3),
    "completedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        j."id",
        j."jobCode",
        j."companyId",
        j."templateCode",
        j."interfaceType",
        j."fileName",
        j."fileSizeBytes",
        j."status",
        j."totalRows",
        j."processedRows",
        j."successRows",
        j."failedRows",
        j."errorsSummary",
        j."startedAt",
        j."completedAt",
        j."createdAt"
    FROM public."BatchImportJob" j
    WHERE (p_company_id IS NULL OR j."companyId" = p_company_id)
      AND (p_status IS NULL OR j."status" = p_status)
      AND (p_interface_type IS NULL OR j."interfaceType" = p_interface_type)
    ORDER BY j."createdAt" DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$;
