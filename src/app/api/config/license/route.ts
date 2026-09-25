import { NextRequest, NextResponse } from 'next/server';
import { getStoredLicenseStatus, applyLicenseKey } from '@/lib/license';

export const dynamic = 'force-dynamic';

export async function GET(req: NextRequest) {
    try {
        const status = await getStoredLicenseStatus();
        const response = NextResponse.json(status);

        if (status.isLicensed && !status.isExpired && status.expirationDate) {
            response.cookies.set('korex_lic_exp', status.expirationDate, {
                path: '/',
                httpOnly: true,
                sameSite: 'lax'
            });
        } else {
            response.cookies.set('korex_lic_exp', 'EXPIRED', {
                path: '/',
                httpOnly: true,
                sameSite: 'lax'
            });
        }

        return response;
    } catch (error: any) {
        console.error('Error in GET /api/config/license:', error);
        return NextResponse.json({ message: 'Error consultando estado de licencia' }, { status: 500 });
    }
}

export async function POST(req: NextRequest) {
    try {
        const { licenseKey, clientName, nit } = await req.json();

        if (!licenseKey) {
            return NextResponse.json({ message: 'La clave de licencia es requerida' }, { status: 400 });
        }

        const userIdHeader = req.headers.get('X-User-Id');
        const actingUserId = userIdHeader ? parseInt(userIdHeader, 10) : 1;

        const payload = await applyLicenseKey(licenseKey, actingUserId, clientName, nit);

        const response = NextResponse.json({
            message: 'Licencia actualizada con éxito',
            license: payload
        });

        // Actualizar Cookie de Expiración en el Navegador inmediatamente
        response.cookies.set('korex_lic_exp', payload.expirationDate, {
            path: '/',
            httpOnly: true,
            sameSite: 'lax'
        });

        return response;
    } catch (error: any) {
        console.error('Error in POST /api/config/license:', error);
        return NextResponse.json(
            { message: error.message || 'Error al aplicar la clave de licencia' },
            { status: 400 }
        );
    }
}
