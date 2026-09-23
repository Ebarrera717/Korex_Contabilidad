import { NextRequest, NextResponse } from 'next/server';
import { calculateVerificationDigit, formatColombianNit } from '@/lib/dian-utils';

export async function GET(req: NextRequest) {
    const { searchParams } = new URL(req.url);
    const nit = searchParams.get('nit') || '';

    if (!nit) {
        return NextResponse.json({ success: false, message: 'NIT requerido' }, { status: 400 });
    }

    const dv = calculateVerificationDigit(nit);
    const formatted = formatColombianNit(nit, dv);

    return NextResponse.json({
        success: true,
        nit: nit.replace(/\D/g, ''),
        verificationDigit: dv,
        formattedNit: formatted
    });
}
