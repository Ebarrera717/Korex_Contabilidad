import prisma from '@/lib/prisma';
import { executeSQLServerProcedure, isSQLServerMode } from '@/lib/sqlserver';

export type TraceabilityMode = 'OFF' | 'BASIC' | 'DETAILED' | 'DIAGNOSTIC';

export interface TraceEventParams {
    code?: string;
    userId?: number | null;
    origin?: string;
    module: string;
    screen?: string;
    action: string;
    process?: string;
    eventType: 
        | 'INICIO_PROCESO'
        | 'FIN_PROCESO'
        | 'ACCION_USUARIO'
        | 'CONSULTA'
        | 'INSERT'
        | 'UPDATE'
        | 'DELETE'
        | 'SP_INICIO'
        | 'SP_FIN'
        | 'CONTABILIZACION'
        | 'CIERRE_PERIODO'
        | 'VALIDACION'
        | 'INTEGRACION'
        | 'API_REQUEST'
        | 'API_RESPONSE'
        | 'TRANSACCION_INICIO'
        | 'TRANSACCION_COMMIT'
        | 'TRANSACCION_ROLLBACK'
        | 'ERROR'
        | 'EXCEPCION'
        | 'ADVERTENCIA';
    stepName: string;
    spName?: string;
    endpoint?: string;
    durationMs?: number;
    status?: 'SUCCESS' | 'ERROR' | 'WARNING' | 'IN_PROGRESS';
    inputData?: any;
    outputData?: any;
    techMessage?: string;
    functionalMessage?: string;
    stackTrace?: string;
    affectedId?: string | number;
}

const SENSITIVE_KEYS = new Set([
    'password',
    'passwordhash',
    'clave',
    'secret',
    'token',
    'authorization',
    'creditcard',
    'cardnumber',
    'cvv',
    'pin',
    'privatekey'
]);

export function maskSensitiveData(data: any): any {
    if (data === null || data === undefined) return data;
    if (typeof data === 'string') {
        return data;
    }
    if (Array.isArray(data)) {
        return data.map(item => maskSensitiveData(item));
    }
    if (typeof data === 'object') {
        const maskedObj: Record<string, any> = {};
        for (const [key, val] of Object.entries(data)) {
            const lowerKey = key.toLowerCase();
            if (SENSITIVE_KEYS.has(lowerKey) || Array.from(SENSITIVE_KEYS).some(k => lowerKey.includes(k))) {
                maskedObj[key] = '***MASKED***';
            } else {
                maskedObj[key] = maskSensitiveData(val);
            }
        }
        return maskedObj;
    }
    return data;
}

export function generateTraceCode(): string {
    const dateStr = new Date().toISOString().substring(0, 10).replace(/-/g, '');
    const rand = Math.floor(100000 + Math.random() * 900000);
    return `TRC-CONT-${dateStr}-${rand}`;
}

export async function recordTraceEvent(params: TraceEventParams): Promise<string> {
    const code = params.code || generateTraceCode();
    const origin = params.origin || 'WEB';
    const maskedInput = params.inputData ? maskSensitiveData(params.inputData) : null;
    const maskedOutput = params.outputData ? maskSensitiveData(params.outputData) : null;

    try {
        if (isSQLServerMode()) {
            await executeSQLServerProcedure('spTraceabilityLog', {
                p_code: code,
                p_user_id: params.userId || null,
                p_origin: origin,
                p_module: params.module,
                p_screen: params.screen || null,
                p_action: params.action,
                p_process: params.process || null,
                p_event_type: params.eventType,
                p_step_name: params.stepName,
                p_sp_name: params.spName || null,
                p_endpoint: params.endpoint || null,
                p_duration_ms: params.durationMs || 0,
                p_status: params.status || 'SUCCESS',
                p_input_data: maskedInput ? JSON.stringify(maskedInput) : null,
                p_output_data: maskedOutput ? JSON.stringify(maskedOutput) : null,
                p_tech_message: params.techMessage || null,
                p_functional_message: params.functionalMessage || null,
                p_stack_trace: params.stackTrace || null,
                p_affected_id: params.affectedId ? String(params.affectedId) : null
            });
            return code;
        }

        await prisma.$queryRawUnsafe(
            `CALL public."spTraceabilityLog"($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14::jsonb, $15::jsonb, $16, $17, $18, $19, $20)`,
            code,
            params.userId || null,
            origin,
            params.module,
            params.screen || null,
            params.action,
            params.process || null,
            params.eventType,
            params.stepName,
            params.spName || null,
            params.endpoint || null,
            params.durationMs || 0,
            params.status || 'SUCCESS',
            maskedInput ? JSON.stringify(maskedInput) : null,
            maskedOutput ? JSON.stringify(maskedOutput) : null,
            params.techMessage || null,
            params.functionalMessage || null,
            params.stackTrace || null,
            params.affectedId ? String(params.affectedId) : null,
            null
        );
        return code;
    } catch (e: any) {
        console.error('[TRACEABILITY_ERROR] Fallo al registrar evento de traza:', e?.message);
        return code;
    }
}
