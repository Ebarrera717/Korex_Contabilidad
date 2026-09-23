import { NextRequest, NextResponse } from 'next/server';
import { executeQuery } from '@/lib/postgres';
import { encrypt } from '@/lib/security';

export async function GET(request: NextRequest) {
    try {
        const { searchParams } = new URL(request.url);
        const isActive = searchParams.get('isActive') !== null ? searchParams.get('isActive') === 'true' : null;

        const result = await executeQuery(
            `SELECT * FROM public."fnIntegrationEndpointsListar"($1)`,
            [isActive]
        );

        return NextResponse.json({
            success: true,
            count: result.rows.length,
            data: result.rows
        });
    } catch (error: any) {
        return NextResponse.json({ success: false, error: error.message }, { status: 500 });
    }
}

export async function POST(request: NextRequest) {
    try {
        const body = await request.json();
        const { code, systemName, adapterType, endpointUrl, authType, credentials, subscribedEvents } = body;

        if (!code || !systemName) {
            return NextResponse.json({
                success: false,
                error: 'Parámetros obligatorios: code, systemName'
            }, { status: 400 });
        }

        const credentialsEnc = credentials ? encrypt(credentials) : null;

        await executeQuery(
            `INSERT INTO public."ExternalIntegrationEndpoint" (
                "code", "systemName", "adapterType", "endpointUrl", "authType",
                "credentialsEnc", "subscribedEvents", "isActive", "createdAt", "updatedAt"
            ) VALUES ($1, $2, $3, $4, $5, $6, $7::jsonb, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            ON CONFLICT ("code") DO UPDATE SET
                "systemName" = EXCLUDED."systemName",
                "adapterType" = EXCLUDED."adapterType",
                "endpointUrl" = EXCLUDED."endpointUrl",
                "authType" = EXCLUDED."authType",
                "credentialsEnc" = COALESCE(EXCLUDED."credentialsEnc", public."ExternalIntegrationEndpoint"."credentialsEnc"),
                "subscribedEvents" = EXCLUDED."subscribedEvents",
                "updatedAt" = CURRENT_TIMESTAMP`,
            [code, systemName, adapterType || 'API_REST', endpointUrl || null, authType || 'BEARER_TOKEN', credentialsEnc, JSON.stringify(subscribedEvents || [])]
        );

        return NextResponse.json({
            success: true,
            message: `Endpoint de integración ${code} configurado exitosamente`
        });
    } catch (error: any) {
        return NextResponse.json({ success: false, error: error.message }, { status: 500 });
    }
}
