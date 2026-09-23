import { Pool } from 'pg';
import path from 'path';
import fs from 'fs';
import { decryptUrlPasswords } from './security';

let pgPool: Pool | null = null;

export function getPostgresUrl(): string {
    let pgUrl = process.env.DATABASE_URL_POSTGRES || process.env.DATABASE_URL || '';
    
    try {
        const envPath = path.join(process.cwd(), '.env');
        if (fs.existsSync(envPath)) {
            const content = fs.readFileSync(envPath, 'utf8');
            const match = content.match(/^DATABASE_URL_POSTGRES\s*=\s*["']?([^"'\r\n]+)/m) || content.match(/^DATABASE_URL\s*=\s*["']?([^"'\r\n]+)/m);
            if (match && match[1]) {
                const cleanUrl = match[1].replace(/["']/g, '').trim();
                if (cleanUrl.startsWith('postgresql://') || cleanUrl.startsWith('postgres://')) {
                    pgUrl = cleanUrl;
                }
            }
        }
    } catch (e) {}

    if (!pgUrl || (!pgUrl.startsWith('postgresql://') && !pgUrl.startsWith('postgres://'))) {
        pgUrl = "postgresql://postgres:zzeusagencias@localhost:5432/Korex_contabilidad_pg?schema=public";
    }

    return decryptUrlPasswords(pgUrl);
}

export function getPostgresPool(): Pool {
    if (!pgPool) {
        const connectionString = getPostgresUrl();
        pgPool = new Pool({ connectionString });
    }
    return pgPool;
}

export async function executePostgresQuery<T = any>(query: string, params: any[] = []): Promise<T[]> {
    const pool = getPostgresPool();
    const res = await pool.query(query, params);
    return res.rows || [];
}
