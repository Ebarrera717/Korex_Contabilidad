-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTO ALMACENADO: spFacturaCompraCrear
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spFacturaCompraCrear";
END $$;

CREATE OR REPLACE PROCEDURE public."spFacturaCompraCrear"(
    IN p_company_id INTEGER,
    IN p_third_party_id INTEGER,
    IN p_document_type_id INTEGER,
    IN p_invoice_number VARCHAR(50),
    IN p_issue_date TIMESTAMP WITH TIME ZONE,
    IN p_payment_term_days INTEGER,
    IN p_subtotal NUMERIC(18, 4),
    IN p_tax_amount NUMERIC(18, 4),
    IN p_retention_amount NUMERIC(18, 4),
    IN p_account_expense_id INTEGER,
    IN p_account_payable_id INTEGER,
    IN p_account_tax_id INTEGER,
    IN p_cost_center_id INTEGER,
    IN p_created_by_id INTEGER,
    IN p_observations TEXT,
    IN p_installments_count INTEGER,
    OUT p_payable_id INTEGER,
    OUT p_internal_number VARCHAR(50),
    OUT p_journal_entry_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_year INTEGER;
    v_month INTEGER;
    v_period_status VARCHAR(20);
    v_prefix VARCHAR(10);
    v_consecutive INTEGER;
    v_total NUMERIC(18, 4);
    v_due_date TIMESTAMP WITH TIME ZONE;
    v_inst_amount NUMERIC(18, 4);
    v_inst_date TIMESTAMP WITH TIME ZONE;
    v_i INTEGER;
BEGIN
    v_year := EXTRACT(YEAR FROM p_issue_date);
    v_month := EXTRACT(MONTH FROM p_issue_date);
    
    -- Validar período abierto
    SELECT status INTO v_period_status FROM public."FiscalPeriod" WHERE year = v_year AND month = v_month;
    IF v_period_status = 'CLOSED' THEN
        RAISE EXCEPTION '❌ No se puede causar factura de compra en un período fiscal cerrado (% - %)', v_year, v_month;
    END IF;

    -- Consecutivo interno para FC
    SELECT prefix, "currentNumber" INTO v_prefix, v_consecutive 
    FROM public."Consecutive"
    WHERE "documentTypeId" = p_document_type_id AND "fiscalYear" = v_year
    FOR UPDATE;

    IF v_consecutive IS NULL THEN
        v_prefix := 'FC';
        v_consecutive := 1;
        INSERT INTO public."Consecutive"("documentTypeId", prefix, "currentNumber", "initialNumber", "fiscalYear", "isActive")
        VALUES (p_document_type_id, v_prefix, 2, 1, v_year, TRUE);
    ELSE
        UPDATE public."Consecutive" SET "currentNumber" = v_consecutive + 1 WHERE "documentTypeId" = p_document_type_id AND "fiscalYear" = v_year;
    END IF;

    p_internal_number := COALESCE(v_prefix, 'FC') || '-' || v_year::TEXT || '-' || LPAD(v_consecutive::TEXT, 6, '0');
    v_total := COALESCE(p_subtotal, 0) + COALESCE(p_tax_amount, 0) - COALESCE(p_retention_amount, 0);
    v_due_date := p_issue_date + (COALESCE(p_payment_term_days, 0) || ' days')::INTERVAL;

    -- Insertar Factura de Compra
    INSERT INTO public."PayableInvoice"(
        "companyId", "thirdPartyId", "documentTypeId", "consecutiveNumber", "invoiceNumber", "internalNumber",
        "issueDate", "dueDate", "paymentTermDays", subtotal, "taxAmount", "retentionAmount",
        "totalAmount", "paidAmount", "balanceAmount", status, "createdById", observations
    ) VALUES (
        p_company_id, p_third_party_id, p_document_type_id, v_consecutive, p_invoice_number, p_internal_number,
        p_issue_date, v_due_date, COALESCE(p_payment_term_days, 0), p_subtotal, COALESCE(p_tax_amount, 0),
        COALESCE(p_retention_amount, 0), v_total, 0, v_total, 'POSTED', p_created_by_id, p_observations
    ) RETURNING id INTO p_payable_id;

    -- Generar Cuotas de CxP
    v_i := 1;
    IF COALESCE(p_installments_count, 1) <= 1 THEN
        INSERT INTO public."PayableInstallment"("payableInvoiceId", "installmentNumber", "dueDate", amount, "paidAmount", "balanceAmount", status)
        VALUES (p_payable_id, 1, v_due_date, v_total, 0, v_total, 'PENDING');
    ELSE
        v_inst_amount := ROUND(v_total / p_installments_count, 4);
        WHILE v_i <= p_installments_count LOOP
            v_inst_date := p_issue_date + ((v_i * p_payment_term_days / p_installments_count) || ' days')::INTERVAL;
            INSERT INTO public."PayableInstallment"("payableInvoiceId", "installmentNumber", "dueDate", amount, "paidAmount", "balanceAmount", status)
            VALUES (p_payable_id, v_i, v_inst_date, v_inst_amount, 0, v_inst_amount, 'PENDING');
            v_i := v_i + 1;
        END LOOP;
    END IF;

    -- Generar Comprobante Contable FC automático (Partida Doble)
    INSERT INTO public."JournalEntry"(
        "companyId", "documentTypeId", "consecutiveNumber", "entryNumber", "entryDate",
        "thirdPartyId", concept, observation, "totalDebit", "totalCredit", status, "createdById", "postedAt"
    ) VALUES (
        p_company_id, p_document_type_id, v_consecutive, p_internal_number, p_issue_date,
        p_third_party_id, 'Causación Compra ' || p_invoice_number || ' (' || p_internal_number || ')', p_observations,
        COALESCE(p_subtotal, 0) + COALESCE(p_tax_amount, 0), v_total + COALESCE(p_retention_amount, 0),
        'POSTED', p_created_by_id, CURRENT_TIMESTAMP
    ) RETURNING id INTO p_journal_entry_id;

    -- Débito: Gasto / Costo / Inventario (Subtotal)
    INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "thirdPartyId", "costCenterId", debit, credit, description, "documentReference")
    VALUES (p_journal_entry_id, p_account_expense_id, p_third_party_id, p_cost_center_id, p_subtotal, 0, 'Gasto/Compra Factura ' || p_invoice_number, p_invoice_number);

    -- Débito: IVA Descontable (si aplica)
    IF COALESCE(p_tax_amount, 0) > 0 AND p_account_tax_id IS NOT NULL THEN
        INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "thirdPartyId", "costCenterId", debit, credit, description, "documentReference")
        VALUES (p_journal_entry_id, p_account_tax_id, p_third_party_id, p_cost_center_id, p_tax_amount, 0, 'IVA Descontable Factura ' || p_invoice_number, p_invoice_number);
    END IF;

    -- Crédito: Retención en la Fuente practicada (si aplica)
    IF COALESCE(p_retention_amount, 0) > 0 THEN
        INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "thirdPartyId", "costCenterId", debit, credit, description, "documentReference")
        VALUES (p_journal_entry_id, (SELECT id FROM public."Account" WHERE code = '236540' LIMIT 1), p_third_party_id, p_cost_center_id, 0, p_retention_amount, 'Retefuente Practicada Factura ' || p_invoice_number, p_invoice_number);
    END IF;

    -- Crédito: Proveedor / CxP (Total Neto a Pagar)
    INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "thirdPartyId", "costCenterId", debit, credit, description, "documentReference")
    VALUES (p_journal_entry_id, p_account_payable_id, p_third_party_id, p_cost_center_id, 0, v_total, 'CxP Proveedor Factura ' || p_invoice_number, p_invoice_number);

    -- Enlazar JournalEntry en Factura
    UPDATE public."PayableInvoice" SET "journalEntryId" = p_journal_entry_id WHERE id = p_payable_id;
END;
$$;
