-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTO ALMACENADO: spActivoFijoMejoraRegistrar
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spActivoFijoMejoraRegistrar";
END $$;

CREATE OR REPLACE PROCEDURE public."spActivoFijoMejoraRegistrar"(
    IN p_fixed_asset_id INTEGER,
    IN p_description TEXT,
    IN p_amount NUMERIC(18, 4),
    IN p_additional_months INTEGER,
    IN p_account_counterpart_id INTEGER,
    IN p_created_by_id INTEGER,
    OUT p_improvement_id INTEGER,
    OUT p_journal_entry_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_company_id INTEGER;
    v_category_id INTEGER;
    v_account_asset_id INTEGER;
    v_cost_center_id INTEGER;
    v_cost NUMERIC(18, 4);
    v_accum NUMERIC(18, 4);
    v_res NUMERIC(18, 4);
    v_life INTEGER;
    v_depr_months INTEGER;
    v_new_cost NUMERIC(18, 4);
    v_new_life INTEGER;
    v_new_monthly NUMERIC(18, 4);
    v_code VARCHAR(50);
BEGIN
    SELECT a."companyId", a."categoryId", a."acquisitionCost", a."accumulatedDepreciation",
           a."residualValue", a."usefulLifeMonths", a."depreciatedMonths", a."costCenterId", a.code,
           c."accountAssetId"
    INTO v_company_id, v_category_id, v_cost, v_accum, v_res, v_life, v_depr_months, v_cost_center_id, v_code, v_account_asset_id
    FROM public."FixedAsset" a
    JOIN public."FixedAssetCategory" c ON c.id = a."categoryId"
    WHERE a.id = p_fixed_asset_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION '❌ Activo fijo con ID % no encontrado', p_fixed_asset_id;
    END IF;

    IF COALESCE(p_amount, 0) <= 0 THEN
        RAISE EXCEPTION '❌ El monto de la mejora capitalizable debe ser mayor a cero';
    END IF;

    v_new_cost := v_cost + p_amount;
    v_new_life := v_life + COALESCE(p_additional_months, 0);
    
    -- Recalcular cuota mensual para los meses restantes
    IF (v_new_life - v_depr_months) > 0 THEN
        v_new_monthly := ROUND((v_new_cost - v_res - v_accum) / (v_new_life - v_depr_months), 4);
    ELSE
        v_new_monthly := 0;
    END IF;

    -- Generar comprobante contable de adición / mejora (Partida Doble)
    INSERT INTO public."JournalEntry"(
        "companyId", "documentTypeId", "consecutiveNumber", "entryNumber", "entryDate",
        concept, observation, "totalDebit", "totalCredit", status, "createdById", "postedAt"
    ) VALUES (
        v_company_id, 1, 1, 'AF-MEJ-' || v_code || '-' || EXTRACT(EPOCH FROM CURRENT_TIMESTAMP)::BIGINT, CURRENT_TIMESTAMP,
        'Mejora Capitalizable Activo ' || v_code, p_description,
        p_amount, p_amount, 'POSTED', p_created_by_id, CURRENT_TIMESTAMP
    ) RETURNING id INTO p_journal_entry_id;

    -- Débito: Cuenta Activo Fijo (15xx)
    INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "costCenterId", debit, credit, description, "documentReference")
    VALUES (p_journal_entry_id, v_account_asset_id, v_cost_center_id, p_amount, 0, 'Adición/Mejora ' || v_code, v_code);

    -- Crédito: Contrapartida (Banco/Caja/CxP)
    INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "costCenterId", debit, credit, description, "documentReference")
    VALUES (p_journal_entry_id, p_account_counterpart_id, v_cost_center_id, 0, p_amount, 'Contrapartida Mejora ' || v_code, v_code);

    -- Insertar registro de mejora
    INSERT INTO public."FixedAssetImprovement"(
        "fixedAssetId", "improvementDate", description, amount, "additionalMonths", "journalEntryId", "createdById"
    ) VALUES (
        p_fixed_asset_id, CURRENT_TIMESTAMP, p_description, p_amount, COALESCE(p_additional_months, 0), p_journal_entry_id, p_created_by_id
    ) RETURNING id INTO p_improvement_id;

    -- Actualizar Activo Fijo
    UPDATE public."FixedAsset"
    SET "acquisitionCost" = v_new_cost,
        "usefulLifeMonths" = v_new_life,
        "monthlyDepreciation" = v_new_monthly,
        "netBookValue" = v_new_cost - "accumulatedDepreciation",
        status = 'ACTIVE',
        "updatedAt" = CURRENT_TIMESTAMP
    WHERE id = p_fixed_asset_id;
END;
$$;
