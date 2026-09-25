import { NextResponse, NextRequest } from 'next/server';

export async function middleware(req: NextRequest) {
    const { pathname } = req.nextUrl;

    // 1. Rutas públicas que NUNCA se bloquean
    if (
        pathname.startsWith('/login') ||
        pathname.startsWith('/licencia-expirada') ||
        pathname.startsWith('/api/auth') ||
        pathname.startsWith('/api/config/license') ||
        pathname.startsWith('/_next') ||
        pathname.startsWith('/favicon.ico') ||
        pathname.includes('.')
    ) {
        return NextResponse.next();
    }

    // 2. Verificación de Token de Autenticación de Usuario (Obligatorio en todo el sistema)
    const authToken = req.cookies.get('auth_token')?.value;

    if (!authToken || authToken.trim() === '') {
        if (pathname.startsWith('/api')) {
            return NextResponse.json(
                { success: false, message: 'No autenticado. Inicie sesión para continuar.' },
                { status: 401 }
            );
        }
        const loginUrl = new URL('/login', req.url);
        loginUrl.searchParams.set('redirect', pathname);
        return NextResponse.redirect(loginUrl);
    }

    // 3. Verificación de Expiración / Falta de Licencia
    const licExpCookie = req.cookies.get('korex_lic_exp')?.value;
    let isLicenseBlocked = false;

    if (licExpCookie === 'EXPIRED' || licExpCookie === 'UNLICENSED') {
        isLicenseBlocked = true;
    } else if (licExpCookie) {
        const expDate = new Date(`${licExpCookie}T23:59:59.999Z`);
        if (isNaN(expDate.getTime()) || new Date() > expDate) {
            isLicenseBlocked = true;
        }
    }

    if (isLicenseBlocked) {
        if (pathname.startsWith('/api')) {
            return NextResponse.json(
                { success: false, message: 'La licencia del sistema Korex_Contabilidad ha expirado o no ha sido activada.' },
                { status: 402 }
            );
        }
        return NextResponse.redirect(new URL('/licencia-expirada', req.url));
    }

    return NextResponse.next();
}

export const config = {
    matcher: [
        '/',
        '/dashboard/:path*',
        '/api/:path*'
    ],
};
