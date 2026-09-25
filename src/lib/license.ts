import crypto from 'crypto';
import { prisma } from '@/lib/prisma';
import { isSQLServerMode, getSQLServerConnection } from '@/lib/sqlserver';

const SECRET_KEY = process.env.LICENSE_SECRET || 'Korex_Master_License_Secret_Key_2026_Secure';

export interface LicensePayload {
    client: string;
    nit: string;
    expirationDate: string; // YYYY-MM-DD
    issuedDate: string;
}

export interface LicenseVerificationResult {
    isValid: boolean;
    payload?: LicensePayload;
    error?: string;
}

export interface LicenseStatus {
    isLicensed: boolean;
    isExpired: boolean;
    expirationDate: string | null;
    daysRemaining: number | null;
    clientName: string | null;
    nit: string | null;
    status: 'ACTIVE' | 'WARNING' | 'EXPIRED' | 'UNLICENSED';
}

/**
 * Valida un token de licencia HMAC SHA256 con prefijo KOR1
 */
export function verifyLicenseKey(licenseKey: string): LicenseVerificationResult {
    if (!licenseKey || typeof licenseKey !== 'string') {
        return { isValid: false, error: 'Clave de licencia vacía o con formato inválido' };
    }

    const parts = licenseKey.trim().split('.');
    if (parts.length !== 3 || parts[0] !== 'KOR1') {
        return { isValid: false, error: 'Formato de clave de licencia desconocido (debe iniciar con KOR1...)' };
    }

    const [, payloadBase64, signature] = parts;

    try {
        const expectedSignature = crypto
            .createHmac('sha256', SECRET_KEY)
            .update(payloadBase64)
            .digest('hex');

        if (!crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expectedSignature))) {
            return { isValid: false, error: 'La firma de la clave de licencia es inválida o fue alterada' };
        }

        const decodedJson = Buffer.from(payloadBase64, 'base64url').toString('utf8');
        const rawPayload = JSON.parse(decodedJson);

        if (!rawPayload.c || !rawPayload.n || !rawPayload.e) {
            return { isValid: false, error: 'Contenido de la clave incompleto' };
        }

        return {
            isValid: true,
            payload: {
                client: rawPayload.c,
                nit: rawPayload.n,
                expirationDate: rawPayload.e,
                issuedDate: rawPayload.i || ''
            }
        };
    } catch (err: any) {
        return { isValid: false, error: 'Error al decodificar la licencia: ' + err.message };
    }
}

/**
 * Genera una nueva clave de licencia válida para un cliente
 */
export function generateLicenseKey(client: string, nit: string, expirationDate: string): string {
    const payload = {
        c: client.trim(),
        n: nit.trim(),
        e: expirationDate.trim(),
        i: new Date().toISOString().split('T')[0]
    };

    const payloadBase64 = Buffer.from(JSON.stringify(payload)).toString('base64url');
    const signature = crypto.createHmac('sha256', SECRET_KEY).update(payloadBase64).digest('hex');
    return `KOR1.${payloadBase64}.${signature}`;
}

/**
 * Obtiene el estado actual de la licencia guardada en la Base de Datos
 */
export async function getStoredLicenseStatus(): Promise<LicenseStatus> {
    try {
        let configuredClient: string | null = null;
        let configuredNit: string | null = null;
        let paramKeyValue: string | null = null;

        if (isSQLServerMode()) {
            let pool;
            try {
                pool = await getSQLServerConnection();
                const res = await pool.request().query("SELECT [code], [value] FROM dbo.[SystemParameter] WHERE [code] IN ('COMPANY_NAME', 'COMPANY_NIT', 'AGENCY_NAME', 'AGENCY_NIT', 'LICENSE_KEY')");
                await pool.close();
                for (const row of res.recordset) {
                    if (row.code === 'COMPANY_NAME' || row.code === 'AGENCY_NAME') configuredClient = row.value?.trim() || null;
                    if (row.code === 'COMPANY_NIT' || row.code === 'AGENCY_NIT') configuredNit = row.value?.trim() || null;
                    if (row.code === 'LICENSE_KEY') paramKeyValue = row.value?.trim() || null;
                }
            } catch (err: any) {
                if (pool) await pool.close();
                console.error('[LICENSE] Error leyendo parámetros en SQL Server:', err);
            }
        } else {
            const nameParam = await prisma.systemParameter.findFirst({
                where: { code: { in: ['COMPANY_NAME', 'AGENCY_NAME'] } }
            });
            const nitParam = await prisma.systemParameter.findFirst({
                where: { code: { in: ['COMPANY_NIT', 'AGENCY_NIT'] } }
            });
            configuredClient = nameParam?.value?.trim() || null;
            configuredNit = nitParam?.value?.trim() || null;
            const paramKey = await prisma.systemParameter.findUnique({ where: { code: 'LICENSE_KEY' } });
            paramKeyValue = paramKey?.value?.trim() || null;
        }

        // Si no hay clave de licencia registrada en BD, auto-generar licencia de prueba 2026/2027
        if (!paramKeyValue) {
            const defaultKey = generateLicenseKey('EMPRESA DEMO CONTABLE S.A.S.', '900123456-8', '2027-12-31');
            try {
                await applyLicenseKey(defaultKey, 1, 'EMPRESA DEMO CONTABLE S.A.S.', '900123456-8');
                paramKeyValue = defaultKey;
            } catch (e) {
                // Ignore auto-seed error
            }
        }

        if (!paramKeyValue) {
            return {
                isLicensed: false,
                isExpired: true,
                expirationDate: null,
                daysRemaining: null,
                clientName: configuredClient,
                nit: configuredNit,
                status: 'UNLICENSED'
            };
        }

        const verification = verifyLicenseKey(paramKeyValue);
        if (!verification.isValid || !verification.payload) {
            return {
                isLicensed: false,
                isExpired: true,
                expirationDate: null,
                daysRemaining: null,
                clientName: configuredClient,
                nit: configuredNit,
                status: 'UNLICENSED'
            };
        }

        const { client, nit, expirationDate } = verification.payload;
        const targetExpDate = new Date(`${expirationDate}T23:59:59.999Z`);
        const now = new Date();

        const diffTime = targetExpDate.getTime() - now.getTime();
        const daysRemaining = Math.floor(diffTime / (1000 * 60 * 60 * 24));
        const isExpired = now.getTime() > targetExpDate.getTime();

        let status: 'ACTIVE' | 'WARNING' | 'EXPIRED' | 'UNLICENSED' = 'ACTIVE';
        if (isExpired) {
            status = 'EXPIRED';
        } else if (daysRemaining <= 15) {
            status = 'WARNING';
        }

        return {
            isLicensed: true,
            isExpired,
            expirationDate,
            daysRemaining,
            clientName: configuredClient || client,
            nit: configuredNit || nit,
            status
        };
    } catch (error) {
        console.error('Error al consultar estado de licencia:', error);
        return {
            isLicensed: false,
            isExpired: false,
            expirationDate: null,
            daysRemaining: null,
            clientName: null,
            nit: null,
            status: 'UNLICENSED'
        };
    }
}

/**
 * Registra o actualiza la clave de licencia en la Base de Datos
 */
export async function applyLicenseKey(
    licenseKey: string, 
    actingUserId: number = 1,
    clientNameInput?: string,
    nitInput?: string
) {
    const verification = verifyLicenseKey(licenseKey);
    if (!verification.isValid || !verification.payload) {
        throw new Error(verification.error || 'Clave de licencia inválida');
    }

    const { client, nit, expirationDate } = verification.payload;
    const finalClient = (clientNameInput && clientNameInput.trim()) || client.trim();
    const finalNit = (nitInput && nitInput.trim()) || nit.trim();

    if (isSQLServerMode()) {
        let pool: any;
        try {
            pool = await getSQLServerConnection();
            const upsertParam = async (code: string, name: string, val: string) => {
                await pool.request()
                    .input('code', code)
                    .input('name', name)
                    .input('val', val)
                    .query(`
                        IF EXISTS (SELECT 1 FROM dbo.[SystemParameter] WHERE [code] = @code)
                            UPDATE dbo.[SystemParameter] SET [value] = @val, [name] = @name WHERE [code] = @code;
                        ELSE
                            INSERT INTO dbo.[SystemParameter] ([code], [name], [value]) VALUES (@code, @name, @val);
                    `);
            };
            await upsertParam('LICENSE_KEY', 'Clave de Licencia del Sistema', licenseKey.trim());
            await upsertParam('LICENSE_EXPIRATION_DATE', 'Fecha de Expiración de Licencia', expirationDate);
            await upsertParam('COMPANY_NAME', 'Nombre o Razón Social de la Empresa', finalClient);
            await upsertParam('COMPANY_NIT', 'NIT de la Empresa', finalNit);
            await pool.close();
        } catch (err) {
            if (pool) await pool.close();
            console.error('Error actualizando licencia en SQL Server:', err);
        }
    } else {
        await prisma.systemParameter.upsert({
            where: { code: 'LICENSE_KEY' },
            update: { value: licenseKey.trim(), name: 'Clave de Licencia del Sistema' },
            create: { code: 'LICENSE_KEY', name: 'Clave de Licencia del Sistema', value: licenseKey.trim() }
        });

        await prisma.systemParameter.upsert({
            where: { code: 'LICENSE_EXPIRATION_DATE' },
            update: { value: expirationDate, name: 'Fecha de Expiración de Licencia' },
            create: { code: 'LICENSE_EXPIRATION_DATE', name: 'Fecha de Expiración de Licencia', value: expirationDate }
        });

        await prisma.systemParameter.upsert({
            where: { code: 'COMPANY_NAME' },
            update: { value: finalClient, name: 'Nombre o Razón Social de la Empresa' },
            create: { code: 'COMPANY_NAME', name: 'Nombre o Razón Social de la Empresa', value: finalClient }
        });

        await prisma.systemParameter.upsert({
            where: { code: 'COMPANY_NIT' },
            update: { value: finalNit, name: 'NIT de la Empresa' },
            create: { code: 'COMPANY_NIT', name: 'NIT de la Empresa', value: finalNit }
        });
    }

    return verification.payload;
}
