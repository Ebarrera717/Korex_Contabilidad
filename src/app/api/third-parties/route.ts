import { NextRequest, NextResponse } from 'next/server';
import { executePostgresQuery } from '@/lib/postgres';
import { executeSQLServerProcedure, getSQLServerConnection, isSQLServerMode } from '@/lib/sqlserver';
import { calculateVerificationDigit } from '@/lib/dian-utils';
import { recordTraceEvent } from '@/lib/traceability';

export async function GET(req: NextRequest) {
    try {
        const { searchParams } = new URL(req.url);
        const search = searchParams.get('search') || null;
        const roleFilter = searchParams.get('role') || null;
        const isActiveStr = searchParams.get('isActive');
        const isActive = isActiveStr !== null ? isActiveStr === 'true' : null;

        if (isSQLServerMode()) {
            const pool = await getSQLServerConnection();
            let query = `
                SELECT * FROM dbo.[ThirdParty]
                WHERE 1=1
            `;
            if (search) query += ` AND ([documentNumber] LIKE '%${search}%' OR [fullName] LIKE '%${search}%')`;
            if (isActive !== null) query += ` AND [isActive] = ${isActive ? 1 : 0}`;
            if (roleFilter === 'CUSTOMER') query += ` AND [isCustomer] = 1`;
            if (roleFilter === 'SUPPLIER') query += ` AND [isSupplier] = 1`;
            if (roleFilter === 'EMPLOYEE') query += ` AND [isEmployee] = 1`;
            if (roleFilter === 'PARTNER') query += ` AND [isPartner] = 1`;
            query += ` ORDER BY [fullName] ASC`;

            const res = await pool.request().query(query);
            return NextResponse.json({ success: true, data: res.recordset || [] });
        }

        const data = await executePostgresQuery(
            'SELECT * FROM public."fnThirdPartyListar"($1, $2, $3)',
            [search, roleFilter, isActive]
        );
        return NextResponse.json({ success: true, data });
    } catch (err: any) {
        console.error('[API_THIRD_PARTY_GET_ERROR]', err);
        return NextResponse.json({ success: false, message: err.message }, { status: 500 });
    }
}

export async function POST(req: NextRequest) {
    try {
        const body = await req.json();
        const {
            id, documentType, documentNumber, verificationDigit, businessName,
            firstName, secondName, firstLastName, secondLastName, personType,
            address, city, state, country, phone, email,
            isCustomer, isSupplier, isEmployee, isPartner, isOther,
            taxRegime, fiscalResponsibilities, isActive
        } = body;

        if (!documentNumber) {
            return NextResponse.json({ success: false, message: 'Número de Documento es obligatorio.' }, { status: 400 });
        }

        // Auto-calcular DV si es NIT y no viene provisto
        let finalDv = verificationDigit;
        if ((!finalDv || finalDv.trim() === '') && (documentType === 'NIT' || personType === 'JURIDICA')) {
            finalDv = calculateVerificationDigit(documentNumber);
        }

        if (isSQLServerMode()) {
            await executeSQLServerProcedure('spThirdPartyGuardar', {
                p_id: id || null,
                p_document_type: documentType || 'NIT',
                p_document_number: documentNumber,
                p_verification_digit: finalDv || null,
                p_business_name: businessName || null,
                p_first_name: firstName || null,
                p_second_name: secondName || null,
                p_first_last_name: firstLastName || null,
                p_second_last_name: secondLastName || null,
                p_person_type: personType || 'JURIDICA',
                p_address: address || null,
                p_city: city || null,
                p_state: state || null,
                p_country: country || 'Colombia',
                p_phone: phone || null,
                p_email: email || null,
                p_is_customer: isCustomer ? 1 : 0,
                p_is_supplier: isSupplier ? 1 : 0,
                p_is_employee: isEmployee ? 1 : 0,
                p_is_partner: isPartner ? 1 : 0,
                p_is_other: isOther ? 1 : 0,
                p_tax_regime: taxRegime || null,
                p_fiscal_resp: fiscalResponsibilities || null,
                p_is_active: isActive !== undefined ? (isActive ? 1 : 0) : 1
            });
        } else {
            await executePostgresQuery(
                'CALL public."spThirdPartyGuardar"($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24)',
                [
                    id || null, documentType || 'NIT', documentNumber, finalDv || null, businessName || null,
                    firstName || null, secondName || null, firstLastName || null, secondLastName || null,
                    personType || 'JURIDICA', address || null, city || null, state || null, country || 'Colombia',
                    phone || null, email || null, isCustomer || false, isSupplier || false, isEmployee || false,
                    isPartner || false, isOther || false, taxRegime || null, fiscalResponsibilities || null,
                    isActive !== undefined ? isActive : true
                ]
            );
        }

        await recordTraceEvent({
            module: 'TERCEROS',
            screen: 'Maestro de Terceros',
            action: id ? 'UPDATE' : 'INSERT',
            eventType: id ? 'UPDATE' : 'INSERT',
            stepName: id ? 'Tercero Actualizado' : 'Tercero Creado',
            affectedId: documentNumber,
            inputData: body
        });

        return NextResponse.json({ success: true, message: 'Tercero guardado exitosamente.', calculatedDv: finalDv });
    } catch (err: any) {
        console.error('[API_THIRD_PARTY_POST_ERROR]', err);
        return NextResponse.json({ success: false, message: err.message }, { status: 500 });
    }
}
