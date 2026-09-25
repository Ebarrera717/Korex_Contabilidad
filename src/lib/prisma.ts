import { PrismaClient } from '@prisma/client'
import { Pool } from 'pg'
import { PrismaPg } from '@prisma/adapter-pg'
import { decryptUrlPasswords } from './security'
import { executePostgresQuery, getPostgresUrl } from './postgres'

const getActiveDbUrl = () => {
    const provider = (process.env.DATABASE_PROVIDER || '').toLowerCase().trim();
    let url = '';
    if (provider === 'sqlserver') {
        url = (process.env.DATABASE_URL_SQLSERVER || process.env.DATABASE_URL || '').trim();
    } else {
        url = (process.env.DATABASE_URL_POSTGRES || process.env.DATABASE_URL || '').trim();
    }
    return decryptUrlPasswords(url) || getPostgresUrl();
};

const isSqlUrl = (url: string) => {
    const provider = (process.env.DATABASE_PROVIDER || '').toLowerCase().trim();
    if (provider === 'postgresql') return false;
    if (provider === 'sqlserver') return true;
    return url.startsWith('sqlserver://') || url.startsWith('mssql://');
};

const prismaClientSingleton = () => {
    const connectionString = getActiveDbUrl();

    if (isSqlUrl(connectionString)) {
        const proxyObj = new Proxy({} as any, {
            get(target, prop) {
                if (prop === 'then' || prop === 'catch' || prop === 'finally') return undefined;
                if (prop === '$queryRawUnsafe' || prop === '$executeRawUnsafe') {
                    return async (query: string, ...params: any[]) => {
                        return executePostgresQuery(query, params);
                    };
                }
                return new Proxy(() => {}, {
                    get(t, p) {
                        return () => Promise.reject(new Error(`[PRISMA_SQLSERVER_PROXY] En modo SQL Server directo, use executeSQLServerQuery / getSQLServerConnection para '${String(prop)}.${String(p)}'.`));
                    },
                    apply() {
                        return Promise.reject(new Error(`[PRISMA_SQLSERVER_PROXY] En modo SQL Server directo, use executeSQLServerQuery / getSQLServerConnection para '${String(prop)}'.`));
                    }
                });
            }
        }) as PrismaClient;
        ;(proxyObj as any).__isProxy = true;
        return proxyObj;
    }

    const pgUrl = connectionString || getPostgresUrl();
    const pool = new Pool({ connectionString: pgUrl });
    const adapter = new PrismaPg(pool);

    const prisma = new PrismaClient({
        adapter,
        log: process.env.NODE_ENV === 'development' ? ['error', 'warn'] : ['error']
    });

    return prisma;
};

type PrismaClientSingleton = ReturnType<typeof prismaClientSingleton>;

const globalForPrisma = globalThis as unknown as { prisma_contabilidad_v1: PrismaClient | undefined };

const isCurrentSqlMode = (() => {
    return isSqlUrl(getActiveDbUrl());
})();

const isProxyInstance = (obj: any): boolean => {
    if (!obj) return false;
    if (obj.__isProxy === true) return true;
    if (typeof obj._clientVersion !== 'string') return true;
    return false;
};

const cachedPrisma = globalForPrisma.prisma_contabilidad_v1;

if (cachedPrisma && isProxyInstance(cachedPrisma) !== isCurrentSqlMode) {
    globalForPrisma.prisma_contabilidad_v1 = undefined;
}

export const prisma = globalForPrisma.prisma_contabilidad_v1 ?? prismaClientSingleton();

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma_contabilidad_v1 = prisma;

export default prisma;
