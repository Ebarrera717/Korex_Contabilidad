import { NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';

export async function GET() {
  try {
    let roles = await prisma.role.findMany({
      where: { isActive: true },
      orderBy: { name: 'asc' }
    });

    if (roles.length === 0) {
      // Seed default accounting roles
      const defaultRoles = [
        { name: 'Administrador', description: 'Acceso total y configuración del sistema contable' },
        { name: 'Contador General', description: 'Emisión de estados financieros, cierre fiscal y parametrización PUC' },
        { name: 'Auxiliar Contable', description: 'Causación de comprobantes, recibos, facturas y tesorería' },
        { name: 'Auditor / Revisor Fiscal', description: 'Consulta y auditoría de libros oficiales e informes DIAN' }
      ];

      for (const r of defaultRoles) {
        await prisma.role.upsert({
          where: { name: r.name },
          update: {},
          create: r
        });
      }

      roles = await prisma.role.findMany({
        where: { isActive: true },
        orderBy: { name: 'asc' }
      });
    }

    return NextResponse.json({ success: true, data: roles });
  } catch (error: any) {
    console.error('Error en GET /api/roles:', error);
    return NextResponse.json({
      success: true,
      data: [
        { id: 1, name: 'Administrador', description: 'Acceso total y configuración' },
        { id: 2, name: 'Contador General', description: 'Estados financieros y cierres' },
        { id: 3, name: 'Auxiliar Contable', description: 'Causación y registros' },
        { id: 4, name: 'Auditor / Revisor Fiscal', description: 'Solo lectura y auditoría' }
      ]
    });
  }
}
