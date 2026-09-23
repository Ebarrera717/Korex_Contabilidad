-- ============================================================================
-- PROYECTO: KOREX_CONTABILIDAD
-- MODULO: FASE 8 - INTEGRACIONES E INTERFACES DE DATOS (TABLAS DDL)
-- MOTOR: PostgreSQL (Korex_contabilidad_pg)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public."DataInterfaceTemplate" (
    "id" SERIAL PRIMARY KEY,
    "code" VARCHAR(50) UNIQUE NOT NULL,
    "name" VARCHAR(150) NOT NULL,
    "category" VARCHAR(50) NOT NULL, -- PUC, TERCEROS, COMPROBANTES, CARTERA, FACTURAS
    "formatType" VARCHAR(20) NOT NULL, -- EXCEL, CSV, JSON, XML
    "mappingConfig" JSONB,
    "sampleFile" BYTEA,
    "isActive" BOOLEAN DEFAULT true NOT NULL,
    "createdAt" TIMESTAMP(3) DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" TIMESTAMP(3) DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS public."BatchImportJob" (
    "id" SERIAL PRIMARY KEY,
    "jobCode" VARCHAR(50) UNIQUE NOT NULL,
    "companyId" INTEGER NOT NULL,
    "templateCode" VARCHAR(50) NOT NULL,
    "interfaceType" VARCHAR(50) NOT NULL,
    "fileName" VARCHAR(255),
    "fileSizeBytes" INTEGER,
    "status" VARCHAR(20) DEFAULT 'PENDING' NOT NULL, -- PENDING, PROCESSING, COMPLETED, FAILED
    "totalRows" INTEGER DEFAULT 0 NOT NULL,
    "processedRows" INTEGER DEFAULT 0 NOT NULL,
    "successRows" INTEGER DEFAULT 0 NOT NULL,
    "failedRows" INTEGER DEFAULT 0 NOT NULL,
    "errorsSummary" JSONB,
    "startedAt" TIMESTAMP(3),
    "completedAt" TIMESTAMP(3),
    "userId" INTEGER,
    "createdAt" TIMESTAMP(3) DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" TIMESTAMP(3) DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE INDEX IF NOT EXISTS "BatchImportJob_companyId_idx" ON public."BatchImportJob"("companyId");
CREATE INDEX IF NOT EXISTS "BatchImportJob_status_idx" ON public."BatchImportJob"("status");
CREATE INDEX IF NOT EXISTS "BatchImportJob_createdAt_idx" ON public."BatchImportJob"("createdAt");

CREATE TABLE IF NOT EXISTS public."ExternalIntegrationEndpoint" (
    "id" SERIAL PRIMARY KEY,
    "code" VARCHAR(50) UNIQUE NOT NULL,
    "systemName" VARCHAR(150) NOT NULL,
    "adapterType" VARCHAR(50) DEFAULT 'API_REST' NOT NULL,
    "endpointUrl" VARCHAR(500),
    "authType" VARCHAR(50) DEFAULT 'BEARER_TOKEN' NOT NULL,
    "credentialsEnc" TEXT,
    "subscribedEvents" JSONB,
    "isActive" BOOLEAN DEFAULT true NOT NULL,
    "createdAt" TIMESTAMP(3) DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" TIMESTAMP(3) DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS public."IntegrationTransaction" (
    "id" SERIAL PRIMARY KEY,
    "txCode" VARCHAR(50) UNIQUE NOT NULL,
    "endpointCode" VARCHAR(50) NOT NULL,
    "direction" VARCHAR(20) NOT NULL, -- INBOUND, OUTBOUND
    "eventType" VARCHAR(50) NOT NULL, -- COMPROBANTE_SYNC, TERCERO_SYNC, INVOICE_SYNC
    "requestPayload" JSONB,
    "responsePayload" JSONB,
    "httpStatus" INTEGER,
    "durationMs" INTEGER DEFAULT 0 NOT NULL,
    "status" VARCHAR(20) DEFAULT 'SUCCESS' NOT NULL,
    "errorMessage" TEXT,
    "createdAt" TIMESTAMP(3) DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE INDEX IF NOT EXISTS "IntegrationTransaction_endpointCode_idx" ON public."IntegrationTransaction"("endpointCode");
CREATE INDEX IF NOT EXISTS "IntegrationTransaction_direction_idx" ON public."IntegrationTransaction"("direction");
CREATE INDEX IF NOT EXISTS "IntegrationTransaction_status_idx" ON public."IntegrationTransaction"("status");
CREATE INDEX IF NOT EXISTS "IntegrationTransaction_createdAt_idx" ON public."IntegrationTransaction"("createdAt");
