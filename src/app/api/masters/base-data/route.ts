import { NextRequest, NextResponse } from 'next/server';
import { executePostgresQuery } from '@/lib/postgres';
import { getSQLServerConnection, isSQLServerMode } from '@/lib/sqlserver';

export async function GET(req: NextRequest) {
    try {
        let companies: any[] = [];
        let movementAccounts: any[] = [];
        let thirdParties: any[] = [];
        let costCenters: any[] = [];
        let banks: any[] = [];
        let docTypes: any[] = [];
        let taxConcepts: any[] = [];

        if (isSQLServerMode()) {
            const pool = await getSQLServerConnection();
            const [rComp, rAcc, rTP, rCC, rBank, rDoc, rTax] = await Promise.all([
                pool.request().query('SELECT [id], [code], [businessName], [documentNumber] FROM dbo.[Company] WHERE [isActive] = 1 ORDER BY [businessName] ASC'),
                pool.request().query('SELECT [id], [code], [name], [nature], [requiresThirdParty], [requiresCostCenter] FROM dbo.[Account] WHERE [allowsMovement] = 1 AND [isActive] = 1 ORDER BY [code] ASC'),
                pool.request().query('SELECT [id], [documentType], [documentNumber], [verificationDigit], [fullName], [isCustomer], [isSupplier], [isEmployee] FROM dbo.[ThirdParty] WHERE [isActive] = 1 ORDER BY [fullName] ASC'),
                pool.request().query('SELECT [id], [code], [name] FROM dbo.[CostCenter] WHERE [isActive] = 1 ORDER BY [code] ASC'),
                pool.request().query('SELECT [id], [code], [name] FROM dbo.[Bank] WHERE [isActive] = 1 ORDER BY [name] ASC'),
                pool.request().query('SELECT [id], [code], [name], [prefix] FROM dbo.[DocumentType] WHERE [isActive] = 1 ORDER BY [code] ASC'),
                pool.request().query('SELECT [id], [code], [name], [type], [ratePercentage], [minimumBaseAmount], [accountDebitId], [accountCreditId] FROM dbo.[TaxConcept] WHERE [isActive] = 1 ORDER BY [code] ASC')
            ]);
            companies = rComp.recordset || [];
            movementAccounts = rAcc.recordset || [];
            thirdParties = rTP.recordset || [];
            costCenters = rCC.recordset || [];
            banks = rBank.recordset || [];
            docTypes = rDoc.recordset || [];
            taxConcepts = rTax.recordset || [];
        } else {
            const [rComp, rAcc, rTP, rCC, rBank, rDoc, rTax] = await Promise.all([
                executePostgresQuery('SELECT id, code, "businessName", "documentNumber" FROM public."Company" WHERE "isActive" = true ORDER BY "businessName" ASC'),
                executePostgresQuery('SELECT id, code, name, nature, "requiresThirdParty", "requiresCostCenter" FROM public."Account" WHERE "allowsMovement" = true AND "isActive" = true ORDER BY code ASC'),
                executePostgresQuery('SELECT id, "documentType", "documentNumber", "verificationDigit", "fullName", "isCustomer", "isSupplier", "isEmployee" FROM public."ThirdParty" WHERE "isActive" = true ORDER BY "fullName" ASC'),
                executePostgresQuery('SELECT id, code, name FROM public."CostCenter" WHERE "isActive" = true ORDER BY code ASC'),
                executePostgresQuery('SELECT id, code, name FROM public."Bank" WHERE "isActive" = true ORDER BY name ASC'),
                executePostgresQuery('SELECT id, code, name, prefix FROM public."DocumentType" WHERE "isActive" = true ORDER BY code ASC'),
                executePostgresQuery('SELECT id, code, name, type, "ratePercentage", "minimumBaseAmount", "accountDebitId", "accountCreditId" FROM public."TaxConcept" WHERE "isActive" = true ORDER BY code ASC')
            ]);
            companies = rComp;
            movementAccounts = rAcc;
            thirdParties = rTP;
            costCenters = rCC;
            banks = rBank;
            docTypes = rDoc;
            taxConcepts = rTax;
        }

        return NextResponse.json({
            success: true,
            data: {
                companies,
                movementAccounts,
                thirdParties,
                costCenters,
                banks,
                docTypes,
                taxConcepts
            }
        });
    } catch (err: any) {
        console.error('[API_BASE_DATA_GET_ERROR]', err);
        return NextResponse.json({ success: false, message: err.message }, { status: 500 });
    }
}
