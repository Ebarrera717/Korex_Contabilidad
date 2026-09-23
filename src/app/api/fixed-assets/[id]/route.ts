import { NextRequest, NextResponse } from 'next/server';
import { executeQuery } from '@/lib/postgres';

export async function GET(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
    try {
        const { id } = await params;
        const assetId = parseInt(id, 10);

        const assetResult = await executeQuery(
            `SELECT a.*, c.name AS "categoryName", cc.name AS "costCenterName", t."fullName" AS "responsibleName"
             FROM public."FixedAsset" a
             JOIN public."FixedAssetCategory" c ON c.id = a."categoryId"
             LEFT JOIN public."CostCenter" cc ON cc.id = a."costCenterId"
             LEFT JOIN public."ThirdParty" t ON t.id = a."responsibleThirdPartyId"
             WHERE a.id = $1`,
            [assetId]
        );

        if (!assetResult.rows || assetResult.rows.length === 0) {
            return NextResponse.json({ success: false, message: 'Activo fijo no encontrado' }, { status: 404 });
        }

        const deprHistory = await executeQuery(
            'SELECT * FROM public."fnActivoFijoHistorialDepreciacion"($1)',
            [assetId]
        );

        const improvementsResult = await executeQuery(
            `SELECT * FROM public."FixedAssetImprovement" WHERE "fixedAssetId" = $1 ORDER BY "improvementDate" DESC`,
            [assetId]
        );

        const disposalResult = await executeQuery(
            `SELECT * FROM public."FixedAssetDisposal" WHERE "fixedAssetId" = $1 LIMIT 1`,
            [assetId]
        );

        return NextResponse.json({
            success: true,
            data: {
                ...assetResult.rows[0],
                depreciations: deprHistory.rows || [],
                improvements: improvementsResult.rows || [],
                disposal: disposalResult.rows ? disposalResult.rows[0] : null
            }
        });
    } catch (error: any) {
        return NextResponse.json({ success: false, message: error.message }, { status: 500 });
    }
}
