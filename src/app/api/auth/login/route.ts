import { NextRequest, NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { encryptPassword, decryptPassword } from '@/lib/security';
import { isSQLServerMode, getSQLServerConnection } from '@/lib/sqlserver';
import { getStoredLicenseStatus } from '@/lib/license';

export async function POST(req: NextRequest) {
  try {
    const body = await req.json().catch(() => ({}));
    const { email, password } = body;
    const targetEmail = (email || '').trim().toLowerCase();

    if (!targetEmail || !password) {
      return NextResponse.json(
        {
          success: false,
          message: 'Email y contraseña son requeridos',
          detail: 'No se enviaron los campos obligatorios email o password en la solicitud.',
          category: 'CREDENTIALS',
          suggestion: 'Por favor ingrese su correo electrónico y contraseña registrados.'
        },
        { status: 400 }
      );
    }

    let user: any = null;
    let roleName = 'Administrador';

    // 1. Autenticación en modo SQL Server
    if (isSQLServerMode()) {
      let pool;
      try {
        pool = await getSQLServerConnection();
        const result = await pool.request()
          .input('email', targetEmail)
          .query('SELECT TOP 1 u.*, r.name AS roleName FROM dbo.[User] u LEFT JOIN dbo.[Role] r ON u.roleId = r.id WHERE LOWER(u.email) = LOWER(@email)');

        user = result.recordset[0];

        // Si no existe ningún usuario admin inicial en SQL Server, auto-crearlo
        if (!user && (targetEmail === 'admin@korex.com.co' || targetEmail === 'ebarrera@zagencias.com' || targetEmail === 'ebarrrera@zagencias.com')) {
          let roleRes = await pool.request()
            .query("SELECT TOP 1 id, name FROM dbo.[Role] WHERE UPPER(name) LIKE '%SUPERADMIN%' OR UPPER(name) LIKE '%ADMIN%'");
          
          let roleId = roleRes.recordset[0]?.id;
          if (!roleId) {
            const newRole = await pool.request()
              .input('name', 'SUPERADMINISTRADOR')
              .input('desc', 'Super Administrador con control total del sistema y gestión de módulos del sitio')
              .query("INSERT INTO dbo.[Role] ([name], [description]) OUTPUT INSERTED.id VALUES (@name, @desc)");
            roleId = newRole.recordset[0]?.id;
          }

          const userName = targetEmail.includes('ebarr') ? 'Eduardo Barrera' : 'Administrador del Sistema';
          const userPwd = targetEmail.includes('ebarr') ? encryptPassword('admin123') : encryptPassword('Admin123*');

          const insertAdmin = await pool.request()
            .input('name', userName)
            .input('email', targetEmail)
            .input('pwd', userPwd)
            .input('roleId', roleId)
            .input('active', 1)
            .query("INSERT INTO dbo.[User] ([name], [email], [passwordHash], [roleId], [isActive]) OUTPUT INSERTED.* VALUES (@name, @email, @pwd, @roleId, @active)");
          
          user = insertAdmin.recordset[0];
          roleName = 'SUPERADMINISTRADOR';
        } else if (user) {
          roleName = user.roleName || 'SUPERADMINISTRADOR';
        }

        await pool.close();
      } catch (sqlErr: any) {
        if (pool) await pool.close().catch(() => {});
        throw sqlErr;
      }
    } else {
      // 2. Autenticación en modo PostgreSQL (Prisma)
      user = await prisma.user.findUnique({
        where: { email: targetEmail },
        include: { role: true }
      });

      if (!user && (targetEmail === 'admin@korex.com.co' || targetEmail === 'ebarrera@zagencias.com' || targetEmail === 'ebarrrera@zagencias.com')) {
        let adminRole = await prisma.role.findFirst({
          where: {
            OR: [
              { name: { contains: 'SUPERADMIN', mode: 'insensitive' } },
              { name: { contains: 'ADMIN', mode: 'insensitive' } }
            ]
          }
        });

        if (!adminRole) {
          adminRole = await prisma.role.create({
            data: {
              name: 'SUPERADMINISTRADOR',
              description: 'Super Administrador con control total del sistema y gestión de módulos del sitio'
            }
          });
        }

        const userName = targetEmail.includes('ebarr') ? 'Eduardo Barrera' : 'Administrador del Sistema';
        const userPwd = targetEmail.includes('ebarr') ? encryptPassword('admin123') : encryptPassword('Admin123*');

        user = await prisma.user.create({
          data: {
            name: userName,
            email: targetEmail,
            passwordHash: userPwd,
            roleId: adminRole.id,
            isActive: true
          },
          include: { role: true }
        });
      }

      if (user) {
        roleName = user.role?.name || 'SUPERADMINISTRADOR';
      }
    }

    if (!user) {
      return NextResponse.json(
        {
          success: false,
          message: 'Usuario no encontrado o credenciales incorrectas',
          detail: `No se encontró ninguna cuenta registrada con el correo '${targetEmail}'.`,
          category: 'CREDENTIALS',
          suggestion: '1. Verifique que el correo esté escrito correctamente.\n2. Si es la primera vez, use admin@korex.com.co con clave Admin123* o ebarrera@zagencias.com con admin123'
        },
        { status: 401 }
      );
    }

    if (user.isActive === false || user.isActive === 0) {
      return NextResponse.json(
        {
          success: false,
          message: 'Cuenta de usuario desactivada',
          detail: 'El usuario se encuentra marcado como inactivo en la base de datos.',
          category: 'CREDENTIALS',
          suggestion: 'Contacte al Administrador del sistema para reactivar su usuario.'
        },
        { status: 403 }
      );
    }

    // 3. Validar contraseña (soporta texto plano, bcrypt, o encriptado Korex Security AES-256)
    let passwordMatches = false;
    const storedHash = user.passwordHash || '';

    if (storedHash.startsWith('ENC(')) {
      const decrypted = decryptPassword(storedHash);
      passwordMatches = decrypted === password;
    } else {
      passwordMatches = storedHash === password;
    }

    // Verificación bcrypt si aplica
    if (!passwordMatches && (storedHash.startsWith('$2b$') || storedHash.startsWith('$2a$'))) {
      try {
        const bcrypt = await import('bcryptjs');
        passwordMatches = await bcrypt.compare(password, storedHash);
      } catch (e) {}
    }

    // Contingencia admin / superadmin inicial
    if (!passwordMatches && targetEmail === 'admin@korex.com.co' && password === 'Admin123*') {
      passwordMatches = true;
    }
    if (!passwordMatches && (targetEmail === 'ebarrera@zagencias.com' || targetEmail === 'ebarrrera@zagencias.com') && password === 'admin123') {
      passwordMatches = true;
    }

    if (!passwordMatches) {
      return NextResponse.json(
        {
          success: false,
          message: 'Contraseña incorrecta',
          detail: 'La contraseña ingresada no coincide con el registro de seguridad de la cuenta.',
          category: 'CREDENTIALS',
          suggestion: '1. Verifique mayúsculas y caracteres especiales.\n2. Si olvidó su clave, solicite un restablecimiento al Administrador.'
        },
        { status: 401 }
      );
    }

    // 4. Preparar Token y Cookies
    const tokenPayload = {
      id: user.id,
      name: user.name,
      email: user.email,
      role: roleName,
      timestamp: Date.now()
    };

    const tokenBase64 = Buffer.from(JSON.stringify(tokenPayload)).toString('base64');
    const response = NextResponse.json({
      success: true,
      message: 'Acceso concedido',
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: roleName
      }
    });

    response.cookies.set({
      name: 'auth_token',
      value: `korex-jwt-${tokenBase64}`,
      path: '/',
      maxAge: 60 * 60 * 24 * 7,
      sameSite: 'lax'
    });

    response.cookies.set({
      name: 'user_name',
      value: encodeURIComponent(user.name),
      path: '/',
      maxAge: 60 * 60 * 24 * 7,
      sameSite: 'lax'
    });

    response.cookies.set({
      name: 'user_email',
      value: user.email,
      path: '/',
      maxAge: 60 * 60 * 24 * 7,
      sameSite: 'lax'
    });

    // Adjuntar cookie de vigencia de licencia si está activa
    try {
      const licenseStatus = await getStoredLicenseStatus();
      if (licenseStatus.expirationDate) {
        response.cookies.set({
          name: 'korex_lic_exp',
          value: licenseStatus.expirationDate,
          path: '/',
          httpOnly: true,
          sameSite: 'lax'
        });
      }
    } catch (licErr) {
      console.error('Error al obtener estado de licencia en login:', licErr);
    }

    return response;
  } catch (error: any) {
    console.error('Login error:', error);

    let message = 'Error interno del servidor';
    let mainDetail = error?.message || String(error) || 'Error no especificado';
    if (error?.originalError?.message) {
      mainDetail += ` | Causa raíz: ${error.originalError.message}`;
    }
    let detail = mainDetail;
    let category: 'DATABASE' | 'CREDENTIALS' | 'SERVER' = 'SERVER';
    let suggestion = '1. Verifique los logs del servidor.\n2. Asegúrese de que el servicio de base de datos esté iniciado.\n3. Revise la variable de entorno DATABASE_URL_POSTGRES / DATABASE_URL_SQLSERVER en .env';

    const errStr = String(error?.message || '').toLowerCase();
    const errCode = String(error?.code || error?.originalError?.code || '');

    if (
      errStr.includes('connect') ||
      errStr.includes('econnrefused') ||
      errStr.includes('connection') ||
      errStr.includes('unable to open') ||
      errStr.includes('server is not reachable') ||
      errStr.includes('timeout') ||
      errStr.includes('closed') ||
      errStr.includes('elogin') ||
      errStr.includes('enotfound') ||
      errCode === 'P1001' ||
      errCode === 'P1002' ||
      errCode === 'P1008' ||
      errCode === 'ELOGIN'
    ) {
      category = 'DATABASE';
      message = 'No se pudo conectar con la Base de Datos';
      suggestion = '1. Verifique que el servicio de PostgreSQL o SQL Server esté en ejecución en el servidor.\n2. Si usa un host remoto o Docker, confirme la IP y puerto (5432 / 1433).\n3. Confirme que las credenciales en .env sean válidas.';
    } else if (
      errStr.includes('does not exist') ||
      errStr.includes('invalid object name') ||
      errStr.includes('relation') ||
      errStr.includes('prismaclientconstructorvalidationerror') ||
      errCode === 'P2021' ||
      errCode === 'P2022'
    ) {
      category = 'DATABASE';
      message = 'Esquema o Cliente de Base de Datos Incompleto';
      suggestion = '1. Verifique que la base de datos configurada en .env exista.\n2. Ejecute las migraciones iniciales o el script de creación de tablas.';
    } else if (
      errStr.includes('access denied') ||
      errStr.includes('login failed') ||
      errStr.includes('authentication') ||
      errCode === 'P1000'
    ) {
      category = 'CREDENTIALS';
      message = 'Fallo de Autenticación con el Motor de Base de Datos';
      suggestion = '1. Verifique el usuario y contraseña del motor en el archivo .env.\n2. Confirme que la cuenta tenga permisos de lectura y escritura.';
    }

    return NextResponse.json(
      {
        success: false,
        message,
        detail,
        category,
        suggestion,
        errorCode: errCode || 'SERVER_ERROR',
        error: message
      },
      { status: 500 }
    );
  }
}
