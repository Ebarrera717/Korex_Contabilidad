-- ============================================================================
-- PROYECTO: KOREX_CONTABILIDAD
-- FUNCION: fnIntegrationEndpointsListar
-- DESCRIPCION: Consulta del catálogo de endpoints de integración externa
-- ============================================================================

CREATE OR REPLACE FUNCTION public."fnIntegrationEndpointsListar"(
    p_is_active BOOLEAN DEFAULT NULL
)
RETURNS TABLE (
    "id" INTEGER,
    "code" VARCHAR,
    "systemName" VARCHAR,
    "adapterType" VARCHAR,
    "endpointUrl" VARCHAR,
    "authType" VARCHAR,
    "subscribedEvents" JSONB,
    "isActive" BOOLEAN,
    "createdAt" TIMESTAMP(3)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        e."id",
        e."code",
        e."systemName",
        e."adapterType",
        e."endpointUrl",
        e."authType",
        e."subscribedEvents",
        e."isActive",
        e."createdAt"
    FROM public."ExternalIntegrationEndpoint" e
    WHERE (p_is_active IS NULL OR e."isActive" = p_is_active)
    ORDER BY e."systemName" ASC;
END;
$$;
