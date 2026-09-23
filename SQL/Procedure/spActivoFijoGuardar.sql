-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTO ALMACENADO: spActivoFijoGuardar
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spActivoFijoGuardar";
END $$;

CREATE OR REPLACE PROCEDURE public."spActivoFijoGuardar"(
    IN p_id INTEGER,
    IN p_company_id INTEGER,
    IN p_category_id INTEGER,
    IN p_code VARCHAR(50),
    IN p_name VARCHAR(150),
    IN p_description TEXT,
    IN p_serial_number VARCHAR(100),
    IN p_purchase_date TIMESTAMP WITH TIME ZONE,
    IN p_activation_date TIMESTAMP WITH TIME ZONE,
    IN p_acquisition_cost NUMERIC(18, 4),
    IN p_residual_value NUMERIC(18, 4),
    IN p_useful_life_months INTEGER,
    IN p_cost_center_id INTEGER,
    IN p_responsible_third_party_id INTEGER,
    IN p_location VARCHAR(150),
    IN p_created_by_id INTEGER,
    OUT p_out_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_monthly_depr NUMERIC(18, 4);
    v_net_value NUMERIC(18, 4);
BEGIN
    IF COALESCE(p_useful_life_months, 0) <= 0 THEN
        RAISE EXCEPTION '❌ La vida útil en meses debe ser mayor a cero';
    END IF;

    -- Cálculo mensual de línea recta: (Costo - Valor Residual) / Vida Útil en meses
    v_monthly_depr := ROUND((COALESCE(p_acquisition_cost, 0) - COALESCE(p_residual_value, 0)) / p_useful_life_months, 4);
    v_net_value := COALESCE(p_acquisition_cost, 0);

    IF p_id IS NULL OR p_id = 0 THEN
        INSERT INTO public."FixedAsset"(
            "companyId", "categoryId", code, name, description, "serialNumber",
            "purchaseDate", "activationDate", "acquisitionCost", "residualValue",
            "usefulLifeMonths", "depreciatedMonths", "accumulatedDepreciation",
            "netBookValue", "monthlyDepreciation", "costCenterId",
            "responsibleThirdPartyId", location, status, "createdById"
        ) VALUES (
            p_company_id, p_category_id, p_code, p_name, p_description, p_serial_number,
            p_purchase_date, p_activation_date, p_acquisition_cost, COALESCE(p_residual_value, 0),
            p_useful_life_months, 0, 0,
            v_net_value, v_monthly_depr, p_cost_center_id,
            p_responsible_third_party_id, p_location, 'ACTIVE', p_created_by_id
        ) RETURNING id INTO p_out_id;
    ELSE
        UPDATE public."FixedAsset"
        SET "categoryId" = p_category_id,
            code = p_code,
            name = p_name,
            description = p_description,
            "serialNumber" = p_serial_number,
            "purchaseDate" = p_purchase_date,
            "activationDate" = p_activation_date,
            "acquisitionCost" = p_acquisition_cost,
            "residualValue" = COALESCE(p_residual_value, 0),
            "usefulLifeMonths" = p_useful_life_months,
            "monthlyDepreciation" = v_monthly_depr,
            "netBookValue" = p_acquisition_cost - "accumulatedDepreciation",
            "costCenterId" = p_cost_center_id,
            "responsibleThirdPartyId" = p_responsible_third_party_id,
            location = p_location,
            "updatedAt" = CURRENT_TIMESTAMP
        WHERE id = p_id;
        p_out_id := p_id;
    END IF;
END;
$$;
