-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTO DE CIERRE ANUAL DEL EJERCICIO (POSTGRESQL)
-- Archivo: SQL/Procedure/spCierreAnual.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spCierreAnual"(INT, INT, INT, INT);
END $$;

CREATE OR REPLACE PROCEDURE public."spCierreAnual"(
    IN p_company_id INT,
    IN p_fiscal_year INT,
    IN p_user_id INT,
    OUT p_closing_journal_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_cz_doc_type_id INT;
    v_doc_prefix VARCHAR;
    v_curr_number INT;
    v_entry_number VARCHAR;
    v_journal_id INT;
    v_row RECORD;
    v_total_debit NUMERIC(18, 4) := 0;
    v_total_credit NUMERIC(18, 4) := 0;
    v_net_profit NUMERIC(18, 4) := 0;
    v_equity_account_id INT;
BEGIN
    -- 1. Obtener Tipo de Documento CZ (Cierre Contable)
    SELECT id, prefix INTO v_cz_doc_type_id, v_doc_prefix FROM public."DocumentType" WHERE code = 'CZ';
    IF v_cz_doc_type_id IS NULL THEN
        SELECT id, prefix INTO v_cz_doc_type_id, v_doc_prefix FROM public."DocumentType" WHERE code = 'CC';
    END IF;

    -- Consecutivo
    SELECT "currentNumber" INTO v_curr_number 
    FROM public."Consecutive" 
    WHERE "documentTypeId" = v_cz_doc_type_id AND "fiscalYear" = p_fiscal_year;

    IF v_curr_number IS NULL THEN
        v_curr_number := 1;
        INSERT INTO public."Consecutive" ("documentTypeId", prefix, "currentNumber", "initialNumber", "fiscalYear", "isActive")
        VALUES (v_cz_doc_type_id, v_doc_prefix, 2, 1, p_fiscal_year, true);
    ELSE
        UPDATE public."Consecutive" 
        SET "currentNumber" = "currentNumber" + 1 
        WHERE "documentTypeId" = v_cz_doc_type_id AND "fiscalYear" = p_fiscal_year;
    END IF;

    v_entry_number := CONCAT(COALESCE(v_doc_prefix, 'CZ'), '-', p_fiscal_year, '-', LPAD(v_curr_number::TEXT, 6, '0'));

    -- 2. Crear encabezado del comprobante de cierre anual
    INSERT INTO public."JournalEntry" (
        "companyId", "documentTypeId", "consecutiveNumber", "entryNumber",
        "entryDate", concept, observation,
        "totalDebit", "totalCredit", status, "createdById",
        "postedAt", "createdAt", "updatedAt"
    ) VALUES (
        p_company_id, v_cz_doc_type_id, v_curr_number, v_entry_number,
        MAKE_DATE(p_fiscal_year, 12, 31)::TIMESTAMP,
        CONCAT('CIERRE ANUAL DE CUENTAS DE RESULTADO - AÑO FISCAL ', p_fiscal_year),
        'Cancelación y traslado de saldos de las clases 4, 5, 6 y 7 a Resultado del Ejercicio',
        0, 0, 'POSTED', p_user_id,
        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    ) RETURNING id INTO v_journal_id;

    p_closing_journal_id := v_journal_id;

    -- 3. Recorrer saldos netos de cuentas de resultado (Clases 4, 5, 6, 7)
    FOR v_row IN 
        SELECT 
            ji."accountId",
            a.code AS account_code,
            a.name AS account_name,
            SUM(ji.debit) AS total_deb,
            SUM(ji.credit) AS total_cred,
            (SUM(ji.debit) - SUM(ji.credit)) AS net_balance
        FROM public."JournalEntryItem" ji
        INNER JOIN public."JournalEntry" j ON ji."journalEntryId" = j.id
        INNER JOIN public."Account" a ON ji."accountId" = a.id
        WHERE j."companyId" = p_company_id
          AND EXTRACT(YEAR FROM j."entryDate")::INT = p_fiscal_year
          AND j.status = 'POSTED'
          AND j.id <> v_journal_id
          AND (a.code LIKE '4%' OR a.code LIKE '5%' OR a.code LIKE '6%' OR a.code LIKE '7%')
        GROUP BY ji."accountId", a.code, a.name
        HAVING (SUM(ji.debit) - SUM(ji.credit)) <> 0
    LOOP
        IF v_row.net_balance > 0 THEN
            -- Saldo débito (Gasto/Costo): Se acredita para dejarlo en cero
            INSERT INTO public."JournalEntryItem" (
                "journalEntryId", "accountId", debit, credit, description, "createdAt", "updatedAt"
            ) VALUES (
                v_journal_id, v_row."accountId", 0, v_row.net_balance,
                CONCAT('Cierre Anual ', v_row.account_code), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
            );
            v_total_credit := v_total_credit + v_row.net_balance;
        ELSE
            -- Saldo crédito (Ingreso): Se debita para dejarlo en cero
            INSERT INTO public."JournalEntryItem" (
                "journalEntryId", "accountId", debit, credit, description, "createdAt", "updatedAt"
            ) VALUES (
                v_journal_id, v_row."accountId", ABS(v_row.net_balance), 0,
                CONCAT('Cierre Anual ', v_row.account_code), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
            );
            v_total_debit := v_total_debit + ABS(v_row.net_balance);
        END IF;
    END LOOP;

    -- 4. Asentar la Utilidad o Pérdida neta del ejercicio en Patrimonio (Clase 36)
    v_net_profit := v_total_credit - v_total_debit; -- Si Créditos > Débitos => Utilidad
    
    -- Buscar o crear cuenta de Resultado del Ejercicio
    SELECT id INTO v_equity_account_id FROM public."Account" WHERE code = '360505' OR code = '3605';
    IF v_equity_account_id IS NULL THEN
        SELECT id INTO v_equity_account_id FROM public."Account" WHERE code LIKE '36%' LIMIT 1;
    END IF;

    IF v_equity_account_id IS NOT NULL AND v_net_profit <> 0 THEN
        IF v_net_profit > 0 THEN
            -- Utilidad neta: Acreditar Patrimonio
            INSERT INTO public."JournalEntryItem" (
                "journalEntryId", "accountId", debit, credit, description, "createdAt", "updatedAt"
            ) VALUES (
                v_journal_id, v_equity_account_id, 0, v_net_profit,
                CONCAT('UTILIDAD NETA DEL EJERCICIO - AÑO ', p_fiscal_year), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
            );
            v_total_credit := v_total_credit + v_net_profit;
        ELSE
            -- Pérdida neta: Debitar Patrimonio
            INSERT INTO public."JournalEntryItem" (
                "journalEntryId", "accountId", debit, credit, description, "createdAt", "updatedAt"
            ) VALUES (
                v_journal_id, v_equity_account_id, ABS(v_net_profit), 0,
                CONCAT('PÉRDIDA NETA DEL EJERCICIO - AÑO ', p_fiscal_year), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
            );
            v_total_debit := v_total_debit + ABS(v_net_profit);
        END IF;
    END IF;

    -- Actualizar totales del comprobante de cierre
    UPDATE public."JournalEntry"
    SET "totalDebit" = v_total_debit, "totalCredit" = v_total_credit
    WHERE id = v_journal_id;
END;
$$;
