-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTOS ALMACENADOS: CARTERA Y PROVEEDORES (FASE 5)
-- MOTOR: SQL Server (T-SQL)
-- ============================================================================

IF OBJECT_ID('dbo.spFacturaVentaCrear', 'P') IS NOT NULL DROP PROCEDURE dbo.spFacturaVentaCrear;
GO
CREATE PROCEDURE dbo.spFacturaVentaCrear
    @companyId INT,
    @thirdPartyId INT,
    @documentTypeId INT,
    @issueDate DATETIME2,
    @paymentTermDays INT = 0,
    @subtotal DECIMAL(18, 4),
    @taxAmount DECIMAL(18, 4) = 0,
    @retentionAmount DECIMAL(18, 4) = 0,
    @accountIncomeId INT,
    @accountReceivableId INT,
    @accountTaxId INT = NULL,
    @costCenterId INT = NULL,
    @createdById INT,
    @observations NVARCHAR(MAX) = NULL,
    @installmentsCount INT = 1,
    @invoiceId INT OUTPUT,
    @invoiceNumber NVARCHAR(50) OUTPUT,
    @journalEntryId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @year INT = YEAR(@issueDate);
    DECLARE @month INT = MONTH(@issueDate);
    DECLARE @periodStatus NVARCHAR(20);

    SELECT @periodStatus = [status] FROM dbo.[FiscalPeriod] WHERE [year] = @year AND [month] = @month;
    IF @periodStatus = 'CLOSED'
    BEGIN
        RAISERROR('No se puede emitir factura en un periodo fiscal cerrado', 16, 1);
        RETURN;
    END

    DECLARE @prefix NVARCHAR(10);
    DECLARE @consecutive INT;

    SELECT @prefix = [prefix], @consecutive = [currentNumber]
    FROM dbo.[Consecutive] WITH (UPDLOCK, HOLDLOCK)
    WHERE [documentTypeId] = @documentTypeId AND [fiscalYear] = @year;

    IF @consecutive IS NULL
    BEGIN
        SET @prefix = 'FV';
        SET @consecutive = 1;
        INSERT INTO dbo.[Consecutive]([documentTypeId], [prefix], [currentNumber], [initialNumber], [fiscalYear], [isActive])
        VALUES (@documentTypeId, @prefix, 2, 1, @year, 1);
    END
    ELSE
    BEGIN
        UPDATE dbo.[Consecutive] SET [currentNumber] = @consecutive + 1
        WHERE [documentTypeId] = @documentTypeId AND [fiscalYear] = @year;
    END

    SET @invoiceNumber = ISNULL(@prefix, 'FV') + '-' + CAST(@year AS NVARCHAR(10)) + '-' + RIGHT('000000' + CAST(@consecutive AS NVARCHAR(10)), 6);
    DECLARE @total DECIMAL(18, 4) = ISNULL(@subtotal, 0) + ISNULL(@taxAmount, 0) - ISNULL(@retentionAmount, 0);
    DECLARE @dueDate DATETIME2 = DATEADD(DAY, ISNULL(@paymentTermDays, 0), @issueDate);

    INSERT INTO dbo.[ReceivableInvoice](
        [companyId], [thirdPartyId], [documentTypeId], [consecutiveNumber], [invoiceNumber],
        [issueDate], [dueDate], [paymentTermDays], [subtotal], [taxAmount], [retentionAmount],
        [totalAmount], [paidAmount], [balanceAmount], [status], [createdById], [observations]
    ) VALUES (
        @companyId, @thirdPartyId, @documentTypeId, @consecutive, @invoiceNumber,
        @issueDate, @dueDate, ISNULL(@paymentTermDays, 0), @subtotal, ISNULL(@taxAmount, 0),
        ISNULL(@retentionAmount, 0), @total, 0, @total, 'POSTED', @createdById, @observations
    );
    SET @invoiceId = SCOPE_IDENTITY();

    -- Cuota
    INSERT INTO dbo.[ReceivableInstallment]([receivableInvoiceId], [installmentNumber], [dueDate], [amount], [paidAmount], [balanceAmount], [status])
    VALUES (@invoiceId, 1, @dueDate, @total, 0, @total, 'PENDING');

    -- Comprobante Contable FV
    INSERT INTO dbo.[JournalEntry](
        [companyId], [documentTypeId], [consecutiveNumber], [entryNumber], [entryDate],
        [thirdPartyId], [concept], [observation], [totalDebit], [totalCredit], [status], [createdById], [postedAt]
    ) VALUES (
        @companyId, @documentTypeId, @consecutive, @invoiceNumber, @issueDate,
        @thirdPartyId, 'Factura de Venta ' + @invoiceNumber, @observations,
        @total + ISNULL(@retentionAmount, 0), ISNULL(@subtotal, 0) + ISNULL(@taxAmount, 0),
        'POSTED', @createdById, SYSUTCDATETIME()
    );
    SET @journalEntryId = SCOPE_IDENTITY();

    -- Débito: Clientes
    INSERT INTO dbo.[JournalEntryItem]([journalEntryId], [accountId], [thirdPartyId], [costCenterId], [debit], [credit], [description], [documentReference])
    VALUES (@journalEntryId, @accountReceivableId, @thirdPartyId, @costCenterId, @total, 0, 'CxC Cliente Factura ' + @invoiceNumber, @invoiceNumber);

    -- Crédito: Ingreso
    INSERT INTO dbo.[JournalEntryItem]([journalEntryId], [accountId], [thirdPartyId], [costCenterId], [debit], [credit], [description], [documentReference])
    VALUES (@journalEntryId, @accountIncomeId, @thirdPartyId, @costCenterId, 0, @subtotal, 'Ingreso Factura ' + @invoiceNumber, @invoiceNumber);

    IF ISNULL(@taxAmount, 0) > 0 AND @accountTaxId IS NOT NULL
    BEGIN
        INSERT INTO dbo.[JournalEntryItem]([journalEntryId], [accountId], [thirdPartyId], [costCenterId], [debit], [credit], [description], [documentReference])
        VALUES (@journalEntryId, @accountTaxId, @thirdPartyId, @costCenterId, 0, @taxAmount, 'IVA Generado ' + @invoiceNumber, @invoiceNumber);
    END

    UPDATE dbo.[ReceivableInvoice] SET [journalEntryId] = @journalEntryId WHERE [id] = @invoiceId;
END;
GO

IF OBJECT_ID('dbo.spCarteraReciboCruzar', 'P') IS NOT NULL DROP PROCEDURE dbo.spCarteraReciboCruzar;
GO
CREATE PROCEDURE dbo.spCarteraReciboCruzar
    @receivableInvoiceId INT,
    @receivableInstallmentId INT = NULL,
    @treasuryMovementId INT = NULL,
    @advancePaymentId INT = NULL,
    @creditNoteId INT = NULL,
    @amount DECIMAL(18, 4),
    @discountAmount DECIMAL(18, 4) = 0,
    @withholdingAdjustment DECIMAL(18, 4) = 0,
    @observations NVARCHAR(MAX) = NULL,
    @allocationId INT OUTPUT,
    @newBalance DECIMAL(18, 4) OUTPUT,
    @invoiceStatus NVARCHAR(20) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @invBalance DECIMAL(18, 4);
    SELECT @invBalance = [balanceAmount] FROM dbo.[ReceivableInvoice] WITH (UPDLOCK) WHERE [id] = @receivableInvoiceId;

    DECLARE @totalApplied DECIMAL(18, 4) = ISNULL(@amount, 0) + ISNULL(@discountAmount, 0) + ISNULL(@withholdingAdjustment, 0);

    INSERT INTO dbo.[ReceivablePaymentAllocation](
        [receivableInvoiceId], [receivableInstallmentId], [treasuryMovementId],
        [advancePaymentId], [creditDebitNoteId], [allocationDate],
        [amount], [discountAmount], [withholdingAdjustment], [observations]
    ) VALUES (
        @receivableInvoiceId, @receivableInstallmentId, @treasuryMovementId,
        @advancePaymentId, @creditNoteId, SYSUTCDATETIME(),
        @amount, ISNULL(@discountAmount, 0), ISNULL(@withholdingAdjustment, 0), @observations
    );
    SET @allocationId = SCOPE_IDENTITY();

    SET @newBalance = @invBalance - @totalApplied;
    SET @invoiceStatus = CASE WHEN @newBalance <= 0 THEN 'PAID' ELSE 'PARTIAL' END;

    UPDATE dbo.[ReceivableInvoice]
    SET [paidAmount] = [paidAmount] + @totalApplied,
        [balanceAmount] = @newBalance,
        [status] = @invoiceStatus,
        [updatedAt] = SYSUTCDATETIME()
    WHERE [id] = @receivableInvoiceId;
END;
GO
