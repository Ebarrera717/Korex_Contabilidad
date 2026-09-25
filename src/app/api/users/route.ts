import { NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { encryptPassword } from '@/lib/security';

export async function GET() {
  try {
    let users = await prisma.user.findMany({
      include: {
        role: {
          select: { id: true, name: true, description: true }
        }
      },
      orderBy: { createdAt: 'desc' }
    });

    if (users.length === 0) {
      // Seed default admin user
      let adminRole = await prisma.role.findFirst({ where: { name: 'Administrador' } });
      if (!adminRole) {
        adminRole = await prisma.role.create({
          data: { name: 'Administrador', description: 'Acceso total y configuración' }
        });
      }

      const defaultAdmin = await prisma.user.create({
        data: {
          name: 'Administrador del Sistema',
          email: 'admin@korex.com.co',
          passwordHash: encryptPassword('Admin123*'),
          roleId: adminRole.id,
          isActive: true
        },
        include: { role: true }
      });

      users = [defaultAdmin];
    }

    const sanitizedUsers = users.map((u) => ({
      id: u.id,
      name: u.name,
      email: u.email,
      roleId: u.roleId,
      roleName: u.role?.name || 'Administrador',
      isActive: u.isActive,
      createdAt: u.createdAt,
      updatedAt: u.updatedAt
    }));

    return NextResponse.json({ success: true, data: sanitizedUsers });
  } catch (error: any) {
    console.error('Error en GET /api/users:', error);
    return NextResponse.json(
      { success: false, error: 'Error al obtener lista de usuarios.' },
      { status: 500 }
    );
  }
}

export async function POST(req: Request) {
  try {
    const { name, email, password, roleId, isActive } = await req.json();

    if (!name || !email || !password) {
      return NextResponse.json(
        { success: false, error: 'Nombre, correo electrónico y contraseña son campos obligatorios.' },
        { status: 400 }
      );
    }

    const cleanEmail = email.trim().toLowerCase();

    // Validar si el correo ya existe
    const existing = await prisma.user.findUnique({
      where: { email: cleanEmail }
    });

    if (existing) {
      return NextResponse.json(
        { success: false, error: 'Ya existe un usuario registrado con este correo electrónico.' },
        { status: 409 }
      );
    }

    // Obtener o asignar rol
    let assignedRoleId = parseInt(roleId, 10);
    if (isNaN(assignedRoleId) || assignedRoleId <= 0) {
      let defaultRole = await prisma.role.findFirst({ where: { name: 'Auxiliar Contable' } });
      if (!defaultRole) {
        defaultRole = await prisma.role.findFirst();
      }
      if (!defaultRole) {
        defaultRole = await prisma.role.create({
          data: { name: 'Auxiliar Contable', description: 'Causación y registros' }
        });
      }
      assignedRoleId = defaultRole.id;
    }

    const newUser = await prisma.user.create({
      data: {
        name: name.trim(),
        email: cleanEmail,
        passwordHash: encryptPassword(password.trim()),
        roleId: assignedRoleId,
        isActive: isActive !== undefined ? Boolean(isActive) : true
      },
      include: { role: true }
    });

    return NextResponse.json({
      success: true,
      message: 'Usuario creado exitosamente.',
      data: {
        id: newUser.id,
        name: newUser.name,
        email: newUser.email,
        roleId: newUser.roleId,
        roleName: newUser.role?.name,
        isActive: newUser.isActive
      }
    });
  } catch (error: any) {
    console.error('Error en POST /api/users:', error);
    return NextResponse.json(
      { success: false, error: error.message || 'Error al registrar usuario.' },
      { status: 500 }
    );
  }
}
