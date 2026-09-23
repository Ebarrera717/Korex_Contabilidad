-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTOS Y FUNCIONES T-SQL DE CONTABILIDAD (SQL SERVER)
-- Archivo: SQL/SqlServer/04_Accounting_Core_SPs.sql
-- ============================================================================

-- 1. spComprobanteGuardar
CREATE OR ALTER PROCEDURE [dbo].[spComprobanteGuardar]
    @p_id INT = NULL,
    @p_company_id INT,
    @p_document_type_id INT,
    @p_entry_number NVARCHAR(50) = NULL,
    @p_entry_date DATETIME2,
    @p_third_party_id INT = NULL,
    @p_concept NVARCHAR(255),
    @p_observation NVARCHAR(MAX) = NULL,
    @p_items NVARCHAR(MAX) = NULL, -- JSON
    @p_user_id INT = 1,
    @p_created_id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_journal_id INT;
    DECLARE @v_fiscal_year INT = YEAR(@p_entry_date);
    DECLARE @v_doc_prefix NVARCHAR(10);
    DECLARE @v_curr_number INT;
    DECLARE @v_final_entry_number NVARCHAR(50);
    DECLARE @v_status NVARCHAR(20) = 'DRAFT';
    DECLARE @v_total_debit DECIMAL(18,4) = 0;
    DECLARE @v_total_credit DECIMAL(18,4) = 0;

    -- Calcular totales del JSON
    IF @p_items IS NOT NULL AND ISJSON(@p_items) = 1
    BEGIN
        SELECT 
            @v_total_debit = ISNULL(SUM(CAST(JSON_VALUE(value, '$.debit') AS DECIMAL(18,4))), 0),
            @v_total_credit = ISNULL(SUM(CAST(JSON_VALUE(value, '$.credit') AS DECIMAL(18,4))), 0)
        FROM OPENJSON(@p_items);
    END

    IF @p_id IS NULL OR @p_id = 0
    BEGIN
        SELECT @v_doc_prefix = [prefix] FROM [dbo].[DocumentType] WHERE [id] = @p_document_type_id;

        SELECT @v_curr_number = [currentNumber] 
        FROM [dbo].[Consecutive] 
        WHERE [documentTypeId] = @p_document_type_id AND [fiscalYear] = @v_fiscal_year;

        IF @v_curr_number IS NULL
        BEGIN
            SET @v_curr_number = 1;
            INSERT INTO [dbo].[Consecutive] ([documentTypeId], [prefix], [currentNumber], [initialNumber], [fiscalYear], [isActive])
            VALUES (@p_document_type_id, @v_doc_prefix, 2, 1, @v_fiscal_year, 1);
        END
        ELSE
        BEGIN
            UPDATE [dbo].[Consecutive] 
            SET [currentNumber] = [currentNumber] + 1 
            WHERE [documentTypeId] = @p_document_type_id AND [fiscalYear] = @v_fiscal_year;
        END

        SET @v_final_entry_number = ISNULL(@p_entry_number, CONCAT(ISNULL(@v_doc_prefix, 'DOC'), '-', @v_fiscal_year, '-', RIGHT('000000' + CAST(@v_curr_number AS VARCHAR(6)), 6)));

        INSERT INTO [dbo].[JournalEntry] (
            [companyId], [documentTypeId], [consecutiveNumber], [entryNumber],
            [entryDate], [thirdPartyId], [concept], [observation],
            [totalDebit], [totalCredit], [status], [createdById],
            [createdAt], [updatedAt]
        ) VALUES (
            @p_company_id, @p_document_type_id, @v_curr_number, @v_final_entry_number,
            @p_entry_date, @p_third_party_id, @p_concept, @p_observation,
            @v_total_debit, @v_total_credit, @v_status, @p_user_id,
            GETDATE(), GETDATE()
        );

        SET @v_journal_id = SCOPE_IDENTITY();
        SET @p_created_id = @v_journal_id;
    END
    ELSE
    BEGIN
        SET @v_journal_id = @p_id;
        SET @p_created_id = @p_id;

        SELECT @v_status = [status] FROM [dbo].[JournalEntry] WHERE [id] = @v_journal_id;
        IF @v_status = 'POSTED'
        BEGIN
            RAISERROR('❌ Comprobante ya Contabilizado: No se puede editar un comprobante en estado POSTED.', 16, 1);
            RETURN;
        END

        UPDATE [dbo].[JournalEntry]
        SET 
            [companyId] = @p_company_id,
            [documentTypeId] = @p_document_type_id,
            [entryDate] = @p_entry_date,
            [thirdPartyId] = @p_third_party_id,
            [concept] = @p_concept,
            [observation] = @p_observation,
            [totalDebit] = @v_total_debit,
            [totalCredit] = @v_total_credit,
            [updatedAt] = GETDATE()
        WHERE [id] = @v_journal_id;

        DELETE FROM [dbo].[JournalEntryItem] WHERE [journalEntryId] = @v_journal_id;
    END

    -- Insertar líneas del JSON
    IF @p_items IS NOT NULL AND ISJSON(@p_items) = 1
    BEGIN
        INSERT INTO [dbo].[JournalEntryItem] (
            [journalEntryId], [accountId], [thirdPartyId], [costCenterId],
            [debit], [credit], [baseAmount], [description], [documentReference],
            [createdAt], [updatedAt]
        )
        SELECT 
            @v_journal_id,
            CAST(JSON_VALUE(value, '$.accountId') AS INT),
            NULLIF(CAST(JSON_VALUE(value, '$.thirdPartyId') AS INT), 0),
            NULLIF(CAST(JSON_VALUE(value, '$.costCenterId') AS INT), 0),
            ISNULL(CAST(JSON_VALUE(value, '$.debit') AS DECIMAL(18,4)), 0),
            ISNULL(CAST(JSON_VALUE(value, '$.credit') AS DECIMAL(18,4)), 0),
            ISNULL(CAST(JSON_VALUE(value, '$.baseAmount') AS DECIMAL(18,4)), 0),
            JSON_VALUE(value, '$.description'),
            JSON_VALUE(value, '$.documentReference'),
            GETDATE(),
            GETDATE()
        FROM OPENJSON(@p_items);
    END
END;
GO

-- 2. spComprobanteContabilizar
CREATE OR ALTER PROCEDURE [dbo].[spComprobanteContabilizar]
    @p_journal_id INT,
    @p_user_id INT = 1
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_status NVARCHAR(20);
    DECLARE @v_entry_number NVARCHAR(50);
    DECLARE @v_entry_date DATETIME2;
    DECLARE @v_year INT;
    DECLARE @v_month INT;
    DECLARE @v_total_debit DECIMAL(18,4);
    DECLARE @v_total_credit DECIMAL(18,4);
    DECLARE @v_line_count INT;
    DECLARE @v_period_status NVARCHAR(20);

    SELECT 
        @v_status = [status],
        @v_entry_number = [entryNumber],
        @v_entry_date = [entryDate]
    FROM [dbo].[JournalEntry] WHERE [id] = @p_journal_id;

    IF @v_status IS NULL
    BEGIN
        RAISERROR('❌ Error: El comprobante no existe.', 16, 1);
        RETURN;
    END

    IF @v_status = 'POSTED'
    BEGIN
        RAISERROR('⚠️ Advertencia: El comprobante ya se encuentra contabilizado.', 16, 1);
        RETURN;
    END

    -- Validar período
    SET @v_year = YEAR(@v_entry_date);
    SET @v_month = MONTH(@v_entry_date);
    SELECT @v_period_status = [status] FROM [dbo].[FiscalPeriod] WHERE [year] = @v_year AND [month] = @v_month;
    IF @v_period_status = 'CLOSED'
    BEGIN
        RAISERROR('❌ Período Cerrado: El período contable se encuentra cerrado.', 16, 1);
        RETURN;
    END

    -- Calcular totales
    SELECT 
        @v_line_count = COUNT(*),
        @v_total_debit = ISNULL(SUM([debit]), 0),
        @v_total_credit = ISNULL(SUM([credit]), 0)
    FROM [dbo].[JournalEntryItem]
    WHERE [journalEntryId] = @p_journal_id;

    IF @v_line_count < 2
    BEGIN
        RAISERROR('❌ Asientos Insuficientes: Se requieren al menos 2 asientos para cumplir partida doble.', 16, 1);
        RETURN;
    END

    -- Validar Partida Doble
    IF ABS(@v_total_debit - @v_total_credit) > 0.0001
    BEGIN
        DECLARE @errMsg NVARCHAR(255) = CONCAT('❌ Descuadre Contable: Total Débitos (', @v_total_debit, ') != Total Créditos (', @v_total_credit, ')');
        RAISERROR(@errMsg, 16, 1);
        RETURN;
    END

    -- Validar cuentas de movimiento
    IF EXISTS (
        SELECT 1 FROM [dbo].[JournalEntryItem] ji
        INNER JOIN [dbo].[Account] a ON ji.[accountId] = a.[id]
        WHERE ji.[journalEntryId] = @p_journal_id AND a.[allowsMovement] = 0
    )
    BEGIN
        RAISERROR('❌ Cuenta Inválida: Una o más cuentas no permiten movimiento directo por ser cuentas padre.', 16, 1);
        RETURN;
    END

    -- Validar exigencia de tercero
    IF EXISTS (
        SELECT 1 FROM [dbo].[JournalEntryItem] ji
        INNER JOIN [dbo].[Account] a ON ji.[accountId] = a.[id]
        WHERE ji.[journalEntryId] = @p_journal_id AND a.[requiresThirdParty] = 1 AND (ji.[thirdPartyId] IS NULL OR ji.[thirdPartyId] = 0)
    )
    BEGIN
        RAISERROR('❌ Exigencia de Tercero: Una o más cuentas requieren obligatoriamente un Tercero.', 16, 1);
        RETURN;
    END

    -- Asentar
    UPDATE [dbo].[JournalEntry]
    SET 
        [status] = 'POSTED',
        [totalDebit] = @v_total_debit,
        [totalCredit] = @v_total_credit,
        [postedAt] = GETDATE(),
        [updatedAt] = GETDATE()
    WHERE [id] = @p_journal_id;
END;
GO
