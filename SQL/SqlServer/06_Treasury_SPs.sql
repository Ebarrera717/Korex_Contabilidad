-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTOS Y FUNCIONES T-SQL DE TESORERÍA (SQL SERVER)
-- Archivo: SQL/SqlServer/06_Treasury_SPs.sql
-- ============================================================================

-- 1. spCajaGuardar
CREATE OR ALTER PROCEDURE [dbo].[spCajaGuardar]
    @p_id INT = NULL,
    @p_company_id INT,
    @p_code NVARCHAR(30),
    @p_name NVARCHAR(150),
    @p_account_id INT,
    @p_responsible_user_id INT = NULL,
    @p_currency NVARCHAR(10) = 'COP',
    @p_max_amount DECIMAL(18, 4) = 0,
    @p_is_active BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    IF @p_id IS NULL OR @p_id = 0
    BEGIN
        INSERT INTO [dbo].[CashBox] (
            [companyId], [code], [name], [accountId], [responsibleUserId],
            [currency], [maxAmount], [isActive], [createdAt], [updatedAt]
        ) VALUES (
            @p_company_id, RTRIM(LTRIM(@p_code)), RTRIM(LTRIM(@p_name)), @p_account_id, @p_responsible_user_id,
            ISNULL(@p_currency, 'COP'), ISNULL(@p_max_amount, 0), ISNULL(@p_is_active, 1),
            GETDATE(), GETDATE()
        );
    END
    ELSE
    BEGIN
        UPDATE [dbo].[CashBox]
        SET 
            [companyId] = @p_company_id,
            [code] = RTRIM(LTRIM(@p_code)),
            [name] = RTRIM(LTRIM(@p_name)),
            [accountId] = @p_account_id,
            [responsibleUserId] = @p_responsible_user_id,
            [currency] = ISNULL(@p_currency, [currency]),
            [maxAmount] = ISNULL(@p_max_amount, [maxAmount]),
            [isActive] = ISNULL(@p_is_active, [isActive]),
            [updatedAt] = GETDATE()
        WHERE [id] = @p_id;
    END
END;
GO

-- 2. spTesoreriaIngresoCrear
CREATE OR ALTER PROCEDURE [dbo].[spTesoreriaIngresoCrear]
    @p_company_id INT,
    @p_movement_date DATETIME2,
    @p_bank_account_id INT = NULL,
    @p_cash_box_id INT = NULL,
    @p_third_party_id INT = NULL,
    @p_concept NVARCHAR(255),
    @p_payment_method NVARCHAR(50) = 'TRANSFERENCIA',
    @p_check_number NVARCHAR(50) = NULL,
    @p_total_amount DECIMAL(18, 4),
    @p_counterpart_account_id INT,
    @p_cost_center_id INT = NULL,
    @p_user_id INT = 1,
    @p_movement_id INT OUTPUT,
    @p_journal_id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_ci_doc_type_id INT;
    DECLARE @v_doc_prefix NVARCHAR(10);
    DECLARE @v_fiscal_year INT = YEAR(@p_movement_date);
    DECLARE @v_curr_number INT;
    DECLARE @v_entry_number NVARCHAR(50);
    DECLARE @v_debit_account_id INT;
    DECLARE @v_journal_id INT;
    DECLARE @v_mov_id INT;

    IF @p_total_amount <= 0
    BEGIN
        RAISERROR('❌ Error: El monto del ingreso debe ser mayor a cero.', 16, 1);
        RETURN;
    END

    -- Determinar cuenta Débito
    IF @p_bank_account_id IS NOT NULL AND @p_bank_account_id > 0
        SELECT @v_debit_account_id = [accountId] FROM [dbo].[BankAccount] WHERE [id] = @p_bank_account_id;
    ELSE IF @p_cash_box_id IS NOT NULL AND @p_cash_box_id > 0
        SELECT @v_debit_account_id = [accountId] FROM [dbo].[CashBox] WHERE [id] = @p_cash_box_id;

    IF @v_debit_account_id IS NULL
        SELECT TOP 1 @v_debit_account_id = [id] FROM [dbo].[Account] WHERE [code] = '110505';

    -- Consecutivo CI
    SELECT TOP 1 @v_ci_doc_type_id = [id], @v_doc_prefix = [prefix] FROM [dbo].[DocumentType] WHERE [code] = 'CI';
    IF @v_ci_doc_type_id IS NULL
        SELECT TOP 1 @v_ci_doc_type_id = [id], @v_doc_prefix = [prefix] FROM [dbo].[DocumentType] WHERE [code] = 'CC';

    SELECT @v_curr_number = [currentNumber] 
    FROM [dbo].[Consecutive] 
    WHERE [documentTypeId] = @v_ci_doc_type_id AND [fiscalYear] = @v_fiscal_year;

    IF @v_curr_number IS NULL
    BEGIN
        SET @v_curr_number = 1;
        INSERT INTO [dbo].[Consecutive] ([documentTypeId], [prefix], [currentNumber], [initialNumber], [fiscalYear], [isActive])
        VALUES (@v_ci_doc_type_id, @v_doc_prefix, 2, 1, @v_fiscal_year, 1);
    END
    ELSE
    BEGIN
        UPDATE [dbo].[Consecutive] 
        SET [currentNumber] = [currentNumber] + 1 
        WHERE [documentTypeId] = @v_ci_doc_type_id AND [fiscalYear] = @v_fiscal_year;
    END

    SET @v_entry_number = CONCAT(ISNULL(@v_doc_prefix, 'CI'), '-', @v_fiscal_year, '-', RIGHT('000000' + CAST(@v_curr_number AS VARCHAR(6)), 6));

    -- Comprobante Contable
    INSERT INTO [dbo].[JournalEntry] (
        [companyId], [documentTypeId], [consecutiveNumber], [entryNumber],
        [entryDate], [thirdPartyId], [concept], [observation],
        [totalDebit], [totalCredit], [status], [createdById],
        [postedAt], [createdAt], [updatedAt]
    ) VALUES (
        @p_company_id, @v_ci_doc_type_id, @v_curr_number, @v_entry_number,
        @p_movement_date, @p_third_party_id, @p_concept,
        CONCAT('Recibo de Caja / Ingreso de Tesorería #', @v_entry_number),
        @p_total_amount, @p_total_amount, 'POSTED', @p_user_id,
        GETDATE(), GETDATE(), GETDATE()
    );
    SET @v_journal_id = SCOPE_IDENTITY();

    -- Débito Caja/Banco
    INSERT INTO [dbo].[JournalEntryItem] ([journalEntryId], [accountId], [thirdPartyId], [costCenterId], [debit], [credit], [baseAmount], [description], [documentReference], [createdAt], [updatedAt])
    VALUES (@v_journal_id, @v_debit_account_id, @p_third_party_id, @p_cost_center_id, @p_total_amount, 0, 0, CONCAT('Ingreso Tesorería - ', @p_concept), @v_entry_number, GETDATE(), GETDATE());

    -- Crédito Contrapartida
    INSERT INTO [dbo].[JournalEntryItem] ([journalEntryId], [accountId], [thirdPartyId], [costCenterId], [debit], [credit], [baseAmount], [description], [documentReference], [createdAt], [updatedAt])
    VALUES (@v_journal_id, @p_counterpart_account_id, @p_third_party_id, @p_cost_center_id, 0, @p_total_amount, 0, CONCAT('Contrapartida Ingreso - ', @p_concept), @v_entry_number, GETDATE(), GETDATE());

    -- Movimiento de Tesorería
    INSERT INTO [dbo].[TreasuryMovement] (
        [companyId], [movementType], [documentTypeId], [consecutiveNumber], [entryNumber],
        [movementDate], [bankAccountId], [cashBoxId], [thirdPartyId],
        [concept], [paymentMethod], [checkNumber], [totalAmount], [status],
        [journalEntryId], [createdById], [createdAt], [updatedAt]
    ) VALUES (
        @p_company_id, 'INGRESO', @v_ci_doc_type_id, @v_curr_number, @v_entry_number,
        @p_movement_date, @p_bank_account_id, @p_cash_box_id, @p_third_party_id,
        @p_concept, ISNULL(@p_payment_method, 'TRANSFERENCIA'), @p_check_number,
        @p_total_amount, 'POSTED', @v_journal_id, @p_user_id,
        GETDATE(), GETDATE()
    );
    SET @v_mov_id = SCOPE_IDENTITY();

    SET @p_movement_id = @v_mov_id;
    SET @p_journal_id = @v_journal_id;
END;
GO
