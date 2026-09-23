import { NextRequest, NextResponse } from 'next/server';
import { executePostgresQuery } from '@/lib/postgres';
import { getSQLServerConnection, isSQLServerMode } from '@/lib/sqlserver';

export interface PucNode {
    id: number;
    code: string;
    name: string;
    level: number;
    nature: string;
    allowsMovement: boolean;
    requiresThirdParty: boolean;
    requiresCostCenter: boolean;
    parentId: number | null;
    isActive: boolean;
    children?: PucNode[];
}

export async function GET(req: NextRequest) {
    try {
        let accounts: any[] = [];

        if (isSQLServerMode()) {
            const pool = await getSQLServerConnection();
            const res = await pool.request().query('SELECT * FROM dbo.[Account] ORDER BY [code] ASC');
            accounts = res.recordset || [];
        } else {
            accounts = await executePostgresQuery('SELECT * FROM public."fnPucListar"()');
        }

        // Construcción del árbol jerárquico
        const map = new Map<number, PucNode>();
        const roots: PucNode[] = [];

        accounts.forEach(acc => {
            map.set(acc.id, {
                ...acc,
                children: []
            });
        });

        accounts.forEach(acc => {
            const node = map.get(acc.id)!;
            if (acc.parentId && map.has(acc.parentId)) {
                map.get(acc.parentId)!.children!.push(node);
            } else if (acc.level === 1) {
                roots.push(node);
            } else {
                // Fallback por código si parentId es nulo
                const parentCode = acc.code.length === 2 ? acc.code.substring(0, 1) :
                                   acc.code.length === 4 ? acc.code.substring(0, 2) :
                                   acc.code.length === 6 ? acc.code.substring(0, 4) :
                                   acc.code.length >= 8 ? acc.code.substring(0, 6) : null;
                
                const foundParent = accounts.find(a => a.code === parentCode);
                if (foundParent && map.has(foundParent.id)) {
                    map.get(foundParent.id)!.children!.push(node);
                } else {
                    roots.push(node);
                }
            }
        });

        return NextResponse.json({ success: true, tree: roots, totalAccounts: accounts.length });
    } catch (err: any) {
        console.error('[API_PUC_TREE_ERROR]', err);
        return NextResponse.json({ success: false, message: err.message }, { status: 500 });
    }
}
