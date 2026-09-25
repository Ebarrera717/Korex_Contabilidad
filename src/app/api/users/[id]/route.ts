import { NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { encryptPassword } from '@/lib/security';

export async function PUT(
  req: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const userId = parseInt(id, 10);

    if (isNaN(userId)) {
      return NextResponse.json({ success: false, error: 'ID de usuario inválido.' }, { status: 400 });
    }

    const { name, email, password, roleId, isActive } = await req.json();

    const updateData: any = {};
    if (name) updateData.name = name.trim();
    if (email) updateData.email = email.trim().toLowerCase();
    if (roleId) updateData.roleId = parseInt(roleId, 10);
    if (isActive !== undefined) updateData.isActive = Boolean(isActive);
    if (password && password.trim() !== '') {
      updateData.passwordHash = encryptPassword(password.trim());
    }

    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: updateData,
      include: { role: true }
    });

    return NextResponse.json({
      success: true,
      message: 'Usuario actualizado correctamente.',
      data: {
        id: updatedUser.id,
        name: updatedUser.name,
        email: updatedUser.email,
        roleId: updatedUser.roleId,
        roleName: updatedUser.role?.name,
        isActive: updatedUser.isActive
      }
    });
  } catch (error: any) {
    console.error('Error en PUT /api/users/[id]:', error);
    return NextResponse.json(
      { success: false, error: error.message || 'Error al actualizar usuario.' },
      { status: 500 }
    );
  }
}

export async function DELETE(
  req: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const userId = parseInt(id, 10);

    if (isNaN(userId)) {
      return NextResponse.json({ success: false, error: 'ID de usuario inválido.' }, { status: 400 });
    }

    // Desactivar usuario en lugar de eliminación física para preservar integridad referencial contable
    await prisma.user.update({
      where: { id: userId },
      data: { isActive: false }
    });

    return NextResponse.json({
      success: true,
      message: 'Usuario desactivado correctamente.'
    });
  } catch (error: any) {
    console.error('Error en DELETE /api/users/[id]:', error);
    return NextResponse.json(
      { success: false, error: error.message || 'Error al desactivar usuario.' },
      { status: 500 }
    );
  }
}
