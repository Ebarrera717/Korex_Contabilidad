-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTO ALMACENADO: spNotaCarteraCrear
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spNotaCarteraCrear";
END $$;

CREATE OR REPLACE PROCEDURE public."spNotaCarteraCrear"(
    IN p_company_id INTEGER,
    IN p_note_type VARCHAR(30),
    IN p_document_type_id INTEGER,
    IN p_third_party_id INTEGER,
    IN p_receivable_invoice_id INTEGER,
    IN p_payable_invoice_id INTEGER,
    IN p_concept TEXT,
    IN p_subtotal NUMERIC(18, 4),
    IN p_tax_amount NUMERIC(18, 4),
    IN p_account_concept_id INTEGER,
    IN p_account_counterpart_id INTEGER,
    IN p_created_by_id INTEGER,
    IN p_observations TEXT,
    OUT p_note_id INTEGER,
    OUT p_note_number VARCHAR(50),
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
    v_auto_cross_id INTEGER;
    v_new_bal NUMERIC(18, 4);
    v_stat VARCHAR(20);
BEGIN
    v_year := EXTRACT(YEAR FROM CURRENT_TIMESTAMP);
    v_month := EXTRACT(MONTH FROM CURRENT_TIMESTAMP);
    
    -- Validar período abierto
    SELECT status INTO v_period_status FROM public."FiscalPeriod" WHERE year = v_year AND month = v_month;
    IF v_period_status = 'CLOSED' THEN
        RAISE EXCEPTION '❌ No se puede emitir nota en un período fiscal cerrado (% - %)', v_year, v_month;
    END IF;

    -- Consecutivo para NC / ND
    SELECT prefix, "currentNumber" INTO v_prefix, v_consecutive 
    FROM public."Consecutive"
    WHERE "documentTypeId" = p_document_type_id AND "fiscalYear" = v_year
    FOR UPDATE;

    IF v_consecutive IS NULL THEN
        v_prefix := CASE WHEN p_note_type LIKE 'NC%' THEN 'NC' ELSE 'ND' END;
        v_consecutive := 1;
        INSERT INTO public."Consecutive"("documentTypeId", prefix, "currentNumber", "initialNumber", "fiscalYear", "isActive")
        VALUES (p_document_type_id, v_prefix, 2, 1, v_year, TRUE);
    ELSE
        UPDATE public."Consecutive" SET "currentNumber" = v_consecutive + 1 WHERE "documentTypeId" = p_document_type_id AND "fiscalYear" = v_year;
    END IF;

    p_note_number := COALESCE(v_prefix, 'NC') || '-' || v_year::TEXT || '-' || LPAD(v_consecutive::TEXT, 6, '0');
    v_total := COALESCE(p_subtotal, 0) + COALESCE(p_tax_amount, 0);

    -- Insertar Nota
    INSERT INTO public."CreditDebitNote"(
        "companyId", "noteType", "documentTypeId", "consecutiveNumber", "noteNumber",
        "noteDate", "thirdPartyId", "receivableInvoiceId", "payableInvoiceId", concept,
        subtotal, "taxAmount", "totalAmount", "appliedAmount", "balanceAmount",
        status, "createdById", observations
    ) VALUES (
        p_company_id, p_note_type, p_document_type_id, v_consecutive, p_note_number,
        CURRENT_TIMESTAMP, p_third_party_id, p_receivable_invoice_id, p_payable_invoice_id, p_concept,
        p_subtotal, COALESCE(p_tax_amount, 0), v_total, 0, v_total,
        'POSTED', p_created_by_id, p_observations
    ) RETURNING id INTO p_note_id;

    -- Generar Comprobante Contable NC / ND automático (Partida Doble)
    INSERT INTO public."JournalEntry"(
        "companyId", "documentTypeId", "consecutiveNumber", "entryNumber", "entryDate",
        "thirdPartyId", concept, observation, "totalDebit", "totalCredit", status, "createdById", "postedAt"
    ) VALUES (
        p_company_id, p_document_type_id, v_consecutive, p_note_number, CURRENT_TIMESTAMP,
        p_third_party_id, 'Nota ' || p_note_type || ' ' || p_note_number, p_observations,
        v_total, v_total, 'POSTED', p_created_by_id, CURRENT_TIMESTAMP
    ) RETURNING id INTO p_journal_entry_id;

    IF p_note_type = 'NC_CLIENTE' THEN
        -- Débito: Devolución en ventas / Descuento (Concepto)
        INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "thirdPartyId", debit, credit, description, "documentReference")
        VALUES (p_journal_entry_id, p_account_concept_id, p_third_party_id, p_subtotal, 0, 'Devolución/Rebaja NC ' || p_note_number, p_note_number);

        -- Débito: IVA Descontable / Reversión (si aplica)
        IF COALESCE(p_tax_amount, 0) > 0 THEN
            INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "thirdPartyId", debit, credit, description, "documentReference")
            VALUES (p_journal_entry_id, (SELECT id FROM public."Account" WHERE code = '240805' LIMIT 1), p_third_party_id, p_tax_amount, 0, 'IVA en Devolución NC ' || p_note_number, p_note_number);
        END IF;

        -- Crédito: CxC Clientes (Contrapartida)
        INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "thirdPartyId", debit, credit, description, "documentReference")
        VALUES (p_journal_entry_id, p_account_counterpart_id, p_third_party_id, 0, v_total, 'Disminución CxC NC ' || p_note_number, p_note_number);

    ELSIF p_note_type = 'ND_CLIENTE' THEN
        -- Débito: CxC Clientes
        INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "thirdPartyId", debit, credit, description, "documentReference")
        VALUES (p_journal_entry_id, p_account_counterpart_id, p_third_party_id, v_total, 0, 'Mayor Valor CxC ND ' || p_note_number, p_note_number);

        -- Crédito: Ingreso / Intereses (Concepto)
        INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "thirdPartyId", debit, credit, description, "documentReference")
        VALUES (p_journal_entry_id, p_account_concept_id, p_third_party_id, 0, v_total, 'Ingreso/Interés ND ' || p_note_number, p_note_number);

    ELSIF p_note_type = 'NC_PROVEEDOR' THEN
        -- Débito: CxP Proveedores
        INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "thirdPartyId", debit, credit, description, "documentReference")
        VALUES (p_journal_entry_id, p_account_counterpart_id, p_third_party_id, v_total, 0, 'Disminución CxP NC Prov ' || p_note_number, p_note_number);

        -- Crédito: Gasto / Devolución Compras
        INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "thirdPartyId", debit, credit, description, "documentReference")
        VALUES (p_journal_entry_id, p_account_concept_id, p_third_party_id, 0, v_total, 'Devolución Compra NC ' || p_note_number, p_note_number);

    ELSE -- ND_PROVEEDOR
        -- Débito: Gasto / Intereses
        INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "thirdPartyId", debit, credit, description, "documentReference")
        VALUES (p_journal_entry_id, p_account_concept_id, p_third_party_id, v_total, 0, 'Mayor Gasto ND Prov ' || p_note_number, p_note_number);

        -- Crédito: CxP Proveedores
        INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "thirdPartyId", debit, credit, description, "documentReference")
        VALUES (p_journal_entry_id, p_account_counterpart_id, p_third_party_id, 0, v_total, 'Mayor Valor CxP ND ' || p_note_number, p_note_number);
    END IF;

    -- Enlazar comprobante contable
    UPDATE public."CreditDebitNote" SET "journalEntryId" = p_journal_entry_id WHERE id = p_note_id;

    -- Si está vinculada a factura de venta y es NC_CLIENTE, cruzar automáticamente
    IF p_receivable_invoice_id IS NOT NULL AND p_note_type = 'NC_CLIENTE' THEN
        CALL public."spCarteraReciboCruzar"(p_receivable_invoice_id, NULL, NULL, NULL, p_note_id, v_total, 0, 0, 'Cruce automático con ' || p_note_number, v_auto_cross_id, v_new_bal, v_stat);
    END IF;

    -- Si está vinculada a factura de compra y es NC_PROVEEDOR, cruzar automáticamente
    IF p_payable_invoice_id IS NOT NULL AND p_note_type = 'NC_PROVEEDOR' THEN
        CALL public."spProveedorEgresoCruzar"(p_payable_invoice_id, NULL, NULL, NULL, p_note_id, v_total, 0, 'Cruce automático con ' || p_note_number, v_auto_cross_id, v_new_bal, v_stat);
    END IF;
END;
$$;
