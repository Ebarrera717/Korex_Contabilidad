import { NextRequest, NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { executePostgresQuery } from '@/lib/postgres';
import { executeSQLServerProcedure, getSQLServerConnection, isSQLServerMode } from '@/lib/sqlserver';
import { recordTraceEvent } from '@/lib/traceability';

export async function GET(req: NextRequest) {
    try {
        if (isSQLServerMode()) {
            const pool = await getSQLServerConnection();
            const res = await pool.request().query('SELECT * FROM dbo.[Company] ORDER BY [id] ASC');
            return NextResponse.json({ success: true, data: res.recordset || [] });
        }

        const data = await executePostgresQuery('SELECT * FROM public."fnCompanyListar"()');
        return NextResponse.json({ success: true, data });
    } catch (err: any) {
        console.error('[API_COMPANY_GET_ERROR]', err);
        return NextResponse.json({ success: false, message: err.message }, { status: 500 });
    }
}

export async function POST(req: NextRequest) {
    try {
        const body = await req.json();
        const {
            id, code, businessName, tradeName, documentType, documentNumber,
            verificationDigit, address, city, state, country, phone, email,
            legalRepresentative, taxRegime, fiscalResponsibilities, economicActivityCode, isActive
        } = body;

        if (!code || !businessName || !documentNumber) {
            return NextResponse.json({ success: false, message: 'Código, Razón Social y Número de Documento son obligatorios.' }, { status: 400 });
        }

        if (isSQLServerMode()) {
            await executeSQLServerProcedure('spCompanyGuardar', {
                p_id: id || null,
                p_code: code,
                p_business_name: businessName,
                p_trade_name: tradeName || null,
                p_document_type: documentType || 'NIT',
                p_document_number: documentNumber,
                p_verification_digit: verificationDigit || null,
                p_address: address || null,
                p_city: city || null,
                p_state: state || null,
                p_country: country || 'Colombia',
                p_phone: phone || null,
                p_email: email || null,
                p_legal_rep: legalRepresentative || null,
                p_tax_regime: taxRegime || null,
                p_fiscal_resp: fiscalResponsibilities || null,
                p_ciiu: economicActivityCode || null,
                p_is_active: isActive !== undefined ? isActive : true
            });
        } else {
            await executePostgresQuery(
                'CALL public."spCompanyGuardar"($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18)',
                [
                    id || null, code, businessName, tradeName || null, documentType || 'NIT', documentNumber,
                    verificationDigit || null, address || null, city || null, state || null, country || 'Colombia',
                    phone || null, email || null, legalRepresentative || null, taxRegime || null,
                    fiscalResponsibilities || null, economicActivityCode || null, isActive !== undefined ? isActive : true
                ]
            );
        }

        await recordTraceEvent({
            module: 'MAESTROS',
            screen: 'Empresas',
            action: id ? 'UPDATE' : 'INSERT',
            eventType: id ? 'UPDATE' : 'INSERT',
            stepName: id ? 'Empresa Actualizada' : 'Empresa Creada',
            affectedId: code,
            inputData: body
        });

        return NextResponse.json({ success: true, message: 'Empresa guardada exitosamente.' });
    } catch (err: any) {
        console.error('[API_COMPANY_POST_ERROR]', err);
        return NextResponse.json({ success: false, message: err.message }, { status: 500 });
    }
}
