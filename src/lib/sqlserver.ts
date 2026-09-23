import mssql from 'mssql';
import { decryptPassword } from './security';
import fs from 'fs';
import path from 'path';

export function isSQLServerMode(): boolean {
    try {
        const envPath = path.join(process.cwd(), '.env');
        if (fs.existsSync(envPath)) {
            const content = fs.readFileSync(envPath, 'utf8');
            const match = content.match(/^DATABASE_PROVIDER\s*=\s*["']?([^"'\r\n]+)/m);
            if (match && match[1]) {
                const prov = match[1].replace(/["']/g, '').trim().toLowerCase();
                if (prov === 'sqlserver') return true;
                if (prov === 'postgresql') return false;
            }
        }
    } catch (e) {}

    const provider = (process.env.DATABASE_PROVIDER || '').toLowerCase().trim();
    if (provider === 'sqlserver') return true;
    if (provider === 'postgresql') return false;

    const dbUrl = (process.env.DATABASE_URL || '').trim();
    return dbUrl.startsWith('sqlserver://') || dbUrl.startsWith('mssql://');
}

export function parseSQLServerUrl(connStr: string) {
    let clean = connStr.replace(/^(sqlserver|mssql):\/\//i, '');
    let hostPortPart = clean.split(';')[0];
    let host = hostPortPart.split(':')[0] || '127.0.0.1';
    let portStr = hostPortPart.split(':')[1] || '';

    let instanceName: string | undefined = undefined;
    if (host.includes('\\')) {
        const parts = host.split('\\');
        host = parts[0];
        instanceName = parts[1];
    }

    let database = '';
    let user = '';
    let password = '';

    const params = clean.split(';');
    for (const p of params) {
        const eqIdx = p.indexOf('=');
        if (eqIdx > 0) {
            const key = p.substring(0, eqIdx).trim().toLowerCase();
            const val = decodeURIComponent(p.substring(eqIdx + 1).trim());
            if (key === 'database') database = val;
            else if (key === 'user' || key === 'user id' || key === 'uid') user = val;
            else if (key === 'password' || key === 'pwd') password = decryptPassword(val);
            else if (key === 'instance' || key === 'instancename') instanceName = val;
            else if (key === 'port') portStr = val;
        }
    }

    return {
        servidor: instanceName ? `${host}\\${instanceName}` : host,
        instanceName: instanceName,
        rawHost: host,
        usuario: user,
        clave: password,
        base_datos: database || 'Korex_Contabilidad_sql',
        puerto: portStr
    };
}

export async function getSQLServerConnection(overrideDbName?: string) {
    let configRow: any = null;
    let sqlUrl = process.env.DATABASE_URL_SQLSERVER || process.env.DATABASE_URL;

    try {
        const envPath = path.join(process.cwd(), '.env');
        if (fs.existsSync(envPath)) {
            const content = fs.readFileSync(envPath, 'utf8');
            const match = content.match(/^DATABASE_URL_SQLSERVER\s*=\s*["']?([^"'\r\n]+)/m) || content.match(/^DATABASE_URL\s*=\s*["']?([^"'\r\n]+)/m);
            if (match && match[1]) {
                const cleanUrl = match[1].replace(/["']/g, '').trim();
                if (cleanUrl.startsWith('sqlserver://') || cleanUrl.startsWith('mssql://')) {
                    sqlUrl = cleanUrl;
                }
            }
        }
    } catch (e) {}

    if (sqlUrl && (sqlUrl.startsWith('sqlserver://') || sqlUrl.startsWith('mssql://'))) {
        configRow = parseSQLServerUrl(sqlUrl);
    } else {
        configRow = {
            servidor: '127.0.0.1',
            usuario: 'sa',
            clave: 'zzeusagencias',
            base_datos: overrideDbName || 'Korex_Contabilidad_sql',
            puerto: '1433'
        };
    }

    const host = configRow.rawHost || configRow.servidor;
    const sqlConfig: any = {
        user: configRow.usuario,
        password: configRow.clave,
        server: host,
        database: overrideDbName || configRow.base_datos,
        options: {
            encrypt: false,
            trustServerCertificate: true,
            enableArithAbort: true,
            connectTimeout: 15000
        },
        connectionTimeout: 15000,
        requestTimeout: 60000
    };

    if (configRow.instanceName) {
        sqlConfig.options.instanceName = configRow.instanceName;
    } else if (configRow.puerto) {
        sqlConfig.port = parseInt(configRow.puerto, 10);
    }

    const pool = new mssql.ConnectionPool(sqlConfig);
    await pool.connect();
    return pool;
}

export async function executeSQLServerProcedure(spName: string, params: any, targetDb?: string) {
    let pool;
    const startTime = Date.now();
    const isTraceProcedure = spName.toLowerCase().includes('sptraceability');

    try {
        const fullSpName = spName.includes('.') ? spName : `dbo.${spName}`;
        pool = await getSQLServerConnection(targetDb);
        const request = pool.request();

        if (params) {
            Object.keys(params).forEach(key => {
                const val = params[key];
                if (val === null || val === undefined) {
                    request.input(key, mssql.VarChar(mssql.MAX), null);
                } else if (typeof val === 'number') {
                    if (Number.isInteger(val)) {
                        request.input(key, mssql.Int, val);
                    } else {
                        request.input(key, mssql.Float, val);
                    }
                } else if (typeof val === 'boolean') {
                    request.input(key, mssql.Bit, val);
                } else {
                    request.input(key, mssql.VarChar(mssql.MAX), String(val));
                }
            });
        }

        const result = await request.execute(fullSpName);
        await pool.close();
        let executionResult: any = result.recordset || result.rowsAffected;

        if (!isTraceProcedure) {
            import('@/lib/traceability').then(({ recordTraceEvent }) => {
                recordTraceEvent({
                    module: 'CONTABILIDAD_DB',
                    screen: 'Ejecución SP SQL Server',
                    action: 'EJECUCION_SP',
                    process: `Invocación ${fullSpName}`,
                    eventType: 'SP_FIN',
                    stepName: `SP ${spName} Ejecutado`,
                    spName: fullSpName,
                    durationMs: Date.now() - startTime,
                    status: 'SUCCESS',
                    inputData: params,
                    outputData: executionResult
                }).catch(e => console.error('[TRACE_SP_AUTO_ERROR]', e?.message));
            }).catch(() => {});
        }

        return executionResult;
    } catch (err: any) {
        if (pool) await pool.close();

        const formattedTechMsg = err?.lineNumber || err?.procedureName
            ? `❌ Error T-SQL #${err?.number || 0} en SP '${err?.procedureName || spName}' (Línea ${err?.lineNumber || 'N/A'}): ${err?.message}`
            : (err?.message || 'Error de ejecución en SQL Server');

        if (!isTraceProcedure) {
            import('@/lib/traceability').then(({ recordTraceEvent }) => {
                recordTraceEvent({
                    module: 'CONTABILIDAD_DB',
                    screen: 'Ejecución SP SQL Server',
                    action: 'EJECUCION_SP',
                    process: `Fallo ${spName}`,
                    eventType: 'ERROR',
                    stepName: `Error en SP ${spName}`,
                    spName: spName,
                    durationMs: Date.now() - startTime,
                    status: 'ERROR',
                    inputData: params,
                    techMessage: formattedTechMsg,
                    stackTrace: err?.stack
                }).catch(e => console.error('[TRACE_SP_AUTO_ERROR]', e?.message));
            }).catch(() => {});
        }
        throw new Error(formattedTechMsg);
    }
}
