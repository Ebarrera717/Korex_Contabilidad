-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTOS DE CONCILIACIÓN BANCARIA (POSTGRESQL)
-- Archivo: SQL/Procedure/spConciliacionBancariaCalcular.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spConciliacionBancariaCalcular"(INT, INT, INT, NUMERIC, NUMERIC, TEXT, INT, INT);
END $$;

CREATE OR REPLACE PROCEDURE public."spConciliacionBancariaCalcular"(
    IN p_company_id INT,
    IN p_bank_account_id INT,
    IN p_year INT,
    IN p_month INT,
    IN p_statement_balance NUMERIC(18, 4),
    IN p_initial_balance NUMERIC(18, 4),
    IN p_observations TEXT,
    IN p_user_id INT,
    OUT p_reconciliation_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_account_id INT;
    v_book_balance NUMERIC(18, 4) := 0;
    v_difference NUMERIC(18, 4) := 0;
    v_rec_id INT;
BEGIN
    -- 1. Obtener la cuenta contable asociada a la cuenta bancaria
    SELECT "accountId" INTO v_account_id FROM public."BankAccount" WHERE id = p_bank_account_id;
    IF v_account_id IS NULL THEN
        RAISE EXCEPTION '❌ Error: La cuenta bancaria no posee cuenta contable PUC configurada.';
    END IF;

    -- 2. Calcular saldo en libros acumulado hasta el fin del mes especificado
    SELECT 
        COALESCE(SUM(ji.debit) - SUM(ji.credit), 0) INTO v_book_balance
    FROM public."JournalEntryItem" ji
    INNER JOIN public."JournalEntry" j ON ji."journalEntryId" = j.id
    WHERE ji."accountId" = v_account_id
      AND j.status = 'POSTED'
      AND j."entryDate" <= (MAKE_DATE(p_year, p_month, 1) + INTERVAL '1 MONTH - 1 DAY')::TIMESTAMP;

    -- 3. Calcular diferencia conciliatoria (Saldo en Libros vs Saldo según Extracto)
    v_difference := v_book_balance - COALESCE(p_statement_balance, 0);

    -- 4. Guardar o actualizar registro de conciliación
    INSERT INTO public."BankReconciliation" (
        "companyId", "bankAccountId", year, month,
        "initialBalance", "finalBankStatementBalance", "bookBalance", difference,
        status, observations, "createdAt", "updatedAt"
    ) VALUES (
        p_company_id, p_bank_account_id, p_year, p_month,
        COALESCE(p_initial_balance, 0), COALESCE(p_statement_balance, 0), v_book_balance, v_difference,
        'DRAFT', p_observations, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    )
    ON CONFLICT ("bankAccountId", year, month)
    DO UPDATE SET 
        "initialBalance" = EXCLUDED."initialBalance",
        "finalBankStatementBalance" = EXCLUDED."finalBankStatementBalance",
        "bookBalance" = EXCLUDED."bookBalance",
        difference = EXCLUDED.difference,
        observations = EXCLUDED.observations,
        "updatedAt" = CURRENT_TIMESTAMP
    RETURNING id INTO v_rec_id;

    p_reconciliation_id := v_rec_id;
END;
$$;
