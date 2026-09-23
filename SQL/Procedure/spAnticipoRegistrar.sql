-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTO ALMACENADO: spAnticipoRegistrar
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spAnticipoRegistrar";
END $$;

CREATE OR REPLACE PROCEDURE public."spAnticipoRegistrar"(
    IN p_company_id INTEGER,
    IN p_advance_type VARCHAR(20),
    IN p_third_party_id INTEGER,
    IN p_treasury_movement_id INTEGER,
    IN p_amount NUMERIC(18, 4),
    IN p_concept TEXT,
    IN p_created_by_id INTEGER,
    OUT p_advance_id INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF COALESCE(p_amount, 0) <= 0 THEN
        RAISE EXCEPTION '❌ El valor del anticipo debe ser mayor a cero';
    END IF;

    INSERT INTO public."AdvancePayment"(
        "companyId", "advanceType", "thirdPartyId", "treasuryMovementId",
        "advanceDate", amount, "usedAmount", "balanceAmount",
        status, concept, "createdById"
    ) VALUES (
        p_company_id, p_advance_type, p_third_party_id, p_treasury_movement_id,
        CURRENT_TIMESTAMP, p_amount, 0, p_amount,
        'ACTIVE', p_concept, p_created_by_id
    ) RETURNING id INTO p_advance_id;
END;
$$;
