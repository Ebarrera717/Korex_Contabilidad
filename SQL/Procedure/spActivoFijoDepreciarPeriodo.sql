-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTO ALMACENADO: spActivoFijoDepreciarPeriodo
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spActivoFijoDepreciarPeriodo";
END $$;

CREATE OR REPLACE PROCEDURE public."spActivoFijoDepreciarPeriodo"(
    IN p_company_id INTEGER,
    IN p_year INTEGER,
    IN p_month INTEGER,
    IN p_created_by_id INTEGER,
    OUT p_total_depreciation NUMERIC(18, 4),
    OUT p_assets_processed INTEGER,
    OUT p_journal_entry_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_period_status VARCHAR(20);
    v_doc_type_id INTEGER;
    v_consecutive INTEGER;
    v_entry_number VARCHAR(50);
    v_period_date TIMESTAMP WITH TIME ZONE;
    r_asset RECORD;
    r_cat RECORD;
    v_asset_depr NUMERIC(18, 4);
    v_new_accum NUMERIC(18, 4);
    v_new_net NUMERIC(18, 4);
    v_depr_id INTEGER;
BEGIN
    -- Validar período abierto
    SELECT status INTO v_period_status FROM public."FiscalPeriod" WHERE year = p_year AND month = p_month;
    IF v_period_status = 'CLOSED' THEN
        RAISE EXCEPTION '❌ No se puede ejecutar depreciación en un período fiscal cerrado (% - %)', p_year, p_month;
    END IF;

    -- Verificar si ya fue depreciado el período
    IF EXISTS (
        SELECT 1 FROM public."FixedAssetDepreciation" d
        JOIN public."FixedAsset" a ON a.id = d."fixedAssetId"
        WHERE a."companyId" = p_company_id AND d.year = p_year AND d.month = p_month
    ) THEN
        RAISE EXCEPTION '❌ El período % - % ya cuenta con depreciación ejecutada para esta empresa', p_year, p_month;
    END IF;

    -- Document Type para Depreciación (DP o CC)
    SELECT id INTO v_doc_type_id FROM public."DocumentType" WHERE code = 'DP';
    IF v_doc_type_id IS NULL THEN
        SELECT id INTO v_doc_type_id FROM public."DocumentType" WHERE code = 'CC' LIMIT 1;
    END IF;

    -- Consecutivo
    SELECT "currentNumber" INTO v_consecutive 
    FROM public."Consecutive"
    WHERE "documentTypeId" = v_doc_type_id AND "fiscalYear" = p_year
    FOR UPDATE;

    IF v_consecutive IS NULL THEN
        v_consecutive := 1;
        INSERT INTO public."Consecutive"("documentTypeId", prefix, "currentNumber", "initialNumber", "fiscalYear", "isActive")
        VALUES (v_doc_type_id, 'DP', 2, 1, p_year, TRUE);
    ELSE
        UPDATE public."Consecutive" SET "currentNumber" = v_consecutive + 1 WHERE "documentTypeId" = v_doc_type_id AND "fiscalYear" = p_year;
    END IF;

    v_entry_number := 'DP-' || p_year::TEXT || '-' || LPAD(p_month::TEXT, 2, '0') || '-' || LPAD(v_consecutive::TEXT, 4, '0');
    v_period_date := (p_year::TEXT || '-' || LPAD(p_month::TEXT, 2, '0') || '-28 23:59:59')::TIMESTAMP WITH TIME ZONE;

    p_total_depreciation := 0;
    p_assets_processed := 0;

    -- Crear Comprobante Contable de Depreciación (Borrador inicial)
    INSERT INTO public."JournalEntry"(
        "companyId", "documentTypeId", "consecutiveNumber", "entryNumber", "entryDate",
        concept, observation, "totalDebit", "totalCredit", status, "createdById", "postedAt"
    ) VALUES (
        p_company_id, v_doc_type_id, v_consecutive, v_entry_number, v_period_date,
        'Depreciación de Activos Fijos ' || p_year::TEXT || '-' || LPAD(p_month::TEXT, 2, '0'),
        'Depreciación periódica NIIF en línea recta', 0, 0, 'POSTED', p_created_by_id, CURRENT_TIMESTAMP
    ) RETURNING id INTO p_journal_entry_id;

    -- Iterar activos fijos activos
    FOR r_asset IN (
        SELECT a.id, a."acquisitionCost", a."residualValue", a."usefulLifeMonths",
               a."depreciatedMonths", a."accumulatedDepreciation", a."monthlyDepreciation",
               c."accountExpenseDeprId", c."accountAccumDeprId", a."costCenterId", a.code, a.name
        FROM public."FixedAsset" a
        JOIN public."FixedAssetCategory" c ON c.id = a."categoryId"
        WHERE a."companyId" = p_company_id
          AND a.status = 'ACTIVE'
          AND a."depreciatedMonths" < a."usefulLifeMonths"
    ) LOOP
        -- Cuota mensual no puede superar el saldo por depreciar
        v_asset_depr := LEAST(r_asset."monthlyDepreciation", (r_asset."acquisitionCost" - r_asset."residualValue" - r_asset."accumulatedDepreciation"));
        
        IF v_asset_depr > 0 THEN
            v_new_accum := r_asset."accumulatedDepreciation" + v_asset_depr;
            v_new_net := r_asset."acquisitionCost" - v_new_accum;

            -- Registrar cuota individual
            INSERT INTO public."FixedAssetDepreciation"(
                "fixedAssetId", year, month, amount, "accumulatedAmount", "netBookValue", "journalEntryId"
            ) VALUES (
                r_asset.id, p_year, p_month, v_asset_depr, v_new_accum, v_new_net, p_journal_entry_id
            );

            -- Actualizar Activo Fijo
            UPDATE public."FixedAsset"
            SET "accumulatedDepreciation" = v_new_accum,
                "depreciatedMonths" = "depreciatedMonths" + 1,
                "netBookValue" = v_new_net,
                status = CASE WHEN "depreciatedMonths" + 1 >= "usefulLifeMonths" THEN 'FULLY_DEPRECIATED' ELSE 'ACTIVE' END,
                "updatedAt" = CURRENT_TIMESTAMP
            WHERE id = r_asset.id;

            -- Detalle Débito: Gasto Depreciación (5160xx)
            INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "costCenterId", debit, credit, description, "documentReference")
            VALUES (p_journal_entry_id, r_asset."accountExpenseDeprId", r_asset."costCenterId", v_asset_depr, 0, 'Gasto Depreciación ' || r_asset.code || ' ' || r_asset.name, r_asset.code);

            -- Detalle Crédito: Depreciación Acumulada (1592xx)
            INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "costCenterId", debit, credit, description, "documentReference")
            VALUES (p_journal_entry_id, r_asset."accountAccumDeprId", r_asset."costCenterId", 0, v_asset_depr, 'Deprec Acumulada ' || r_asset.code || ' ' || r_asset.name, r_asset.code);

            p_total_depreciation := p_total_depreciation + v_asset_depr;
            p_assets_processed := p_assets_processed + 1;
        END IF;
    END LOOP;

    -- Actualizar totales del comprobante contable
    UPDATE public."JournalEntry"
    SET "totalDebit" = p_total_depreciation,
        "totalCredit" = p_total_depreciation
    WHERE id = p_journal_entry_id;
END;
$$;
