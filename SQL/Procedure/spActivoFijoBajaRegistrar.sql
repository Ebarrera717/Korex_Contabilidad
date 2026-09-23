-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTO ALMACENADO: spActivoFijoBajaRegistrar
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spActivoFijoBajaRegistrar";
END $$;

CREATE OR REPLACE PROCEDURE public."spActivoFijoBajaRegistrar"(
    IN p_fixed_asset_id INTEGER,
    IN p_disposal_type VARCHAR(30),
    IN p_sale_price NUMERIC(18, 4),
    IN p_account_sale_income_id INTEGER,
    IN p_reason TEXT,
    IN p_created_by_id INTEGER,
    OUT p_disposal_id INTEGER,
    OUT p_net_gain_loss NUMERIC(18, 4),
    OUT p_journal_entry_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_company_id INTEGER;
    v_category_id INTEGER;
    v_account_asset_id INTEGER;
    v_account_accum_depr_id INTEGER;
    v_cost_center_id INTEGER;
    v_cost NUMERIC(18, 4);
    v_accum NUMERIC(18, 4);
    v_net_value NUMERIC(18, 4);
    v_sale NUMERIC(18, 4);
    v_code VARCHAR(50);
BEGIN
    SELECT a."companyId", a."categoryId", a."acquisitionCost", a."accumulatedDepreciation",
           a."netBookValue", a."costCenterId", a.code,
           c."accountAssetId", c."accountAccumDeprId"
    INTO v_company_id, v_category_id, v_cost, v_accum, v_net_value, v_cost_center_id, v_code, v_account_asset_id, v_account_accum_depr_id
    FROM public."FixedAsset" a
    JOIN public."FixedAssetCategory" c ON c.id = a."categoryId"
    WHERE a.id = p_fixed_asset_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION '❌ Activo fijo con ID % no encontrado', p_fixed_asset_id;
    END IF;

    v_sale := COALESCE(p_sale_price, 0);
    -- Utilidad o Pérdida = Precio Venta - Valor Neto en Libros
    p_net_gain_loss := v_sale - v_net_value;

    -- Generar comprobante contable de baja / enajenación (Partida Doble)
    INSERT INTO public."JournalEntry"(
        "companyId", "documentTypeId", "consecutiveNumber", "entryNumber", "entryDate",
        concept, observation, "totalDebit", "totalCredit", status, "createdById", "postedAt"
    ) VALUES (
        v_company_id, 1, 1, 'AF-BAJA-' || v_code || '-' || EXTRACT(EPOCH FROM CURRENT_TIMESTAMP)::BIGINT, CURRENT_TIMESTAMP,
        'Baja/Venta de Activo Fijo ' || v_code, p_reason,
        v_cost + CASE WHEN p_net_gain_loss > 0 THEN p_net_gain_loss ELSE 0 END,
        v_cost + CASE WHEN p_net_gain_loss > 0 THEN p_net_gain_loss ELSE 0 END,
        'POSTED', p_created_by_id, CURRENT_TIMESTAMP
    ) RETURNING id INTO p_journal_entry_id;

    -- Débito: Cancelación de Depreciación Acumulada (1592xx)
    IF v_accum > 0 THEN
        INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "costCenterId", debit, credit, description, "documentReference")
        VALUES (p_journal_entry_id, v_account_accum_depr_id, v_cost_center_id, v_accum, 0, 'Cancelación Depr Acum ' || v_code, v_code);
    END IF;

    -- Débito: Ingreso de Fondos por Venta (si hubo venta)
    IF v_sale > 0 AND p_account_sale_income_id IS NOT NULL THEN
        INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "costCenterId", debit, credit, description, "documentReference")
        VALUES (p_journal_entry_id, p_account_sale_income_id, v_cost_center_id, v_sale, 0, 'Recaudo Venta Activo ' || v_code, v_code);
    END IF;

    -- Débito: Pérdida en Retiro/Venta de Activos Fijos (si aplica)
    IF p_net_gain_loss < 0 THEN
        INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "costCenterId", debit, credit, description, "documentReference")
        VALUES (p_journal_entry_id, (SELECT id FROM public."Account" WHERE code = '531015' LIMIT 1), v_cost_center_id, ABS(p_net_gain_loss), 0, 'Pérdida en Retiro Activo ' || v_code, v_code);
    END IF;

    -- Crédito: Cancelación del Costo Histórico del Activo (15xx)
    INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "costCenterId", debit, credit, description, "documentReference")
    VALUES (p_journal_entry_id, v_account_asset_id, v_cost_center_id, 0, v_cost, 'Cancelación Costo Activo ' || v_code, v_code);

    -- Crédito: Utilidad en Venta de Activos Fijos (si aplica)
    IF p_net_gain_loss > 0 THEN
        INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "costCenterId", debit, credit, description, "documentReference")
        VALUES (p_journal_entry_id, (SELECT id FROM public."Account" WHERE code = '424515' LIMIT 1), v_cost_center_id, 0, p_net_gain_loss, 'Utilidad en Venta Activo ' || v_code, v_code);
    END IF;

    -- Insertar registro de baja
    INSERT INTO public."FixedAssetDisposal"(
        "fixedAssetId", "disposalDate", "disposalType", "salePrice",
        "acquisitionCostAtDisposal", "accumulatedDeprAtDisposal", "netGainLoss",
        "journalEntryId", reason, "createdById"
    ) VALUES (
        p_fixed_asset_id, CURRENT_TIMESTAMP, p_disposal_type, v_sale,
        v_cost, v_accum, p_net_gain_loss,
        p_journal_entry_id, p_reason, p_created_by_id
    ) RETURNING id INTO p_disposal_id;

    -- Actualizar estado del Activo Fijo
    UPDATE public."FixedAsset"
    SET status = CASE WHEN p_disposal_type = 'VENTA' THEN 'SOLD' ELSE 'DISPOSED' END,
        "netBookValue" = 0,
        "updatedAt" = CURRENT_TIMESTAMP
    WHERE id = p_fixed_asset_id;
END;
$$;
