-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTOS ALMACENADOS: ACTIVOS FIJOS (FASE 6)
-- MOTOR: SQL Server (T-SQL)
-- ============================================================================

IF OBJECT_ID('dbo.spActivoFijoCategoriaGuardar', 'P') IS NOT NULL DROP PROCEDURE dbo.spActivoFijoCategoriaGuardar;
GO
CREATE PROCEDURE dbo.spActivoFijoCategoriaGuardar
    @id INT = NULL,
    @code NVARCHAR(50),
    @name NVARCHAR(100),
    @defaultUsefulLifeMonths INT = 60,
    @accountAssetId INT,
    @accountAccumDeprId INT,
    @accountExpenseDeprId INT,
    @isActive BIT = 1,
    @outId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    IF @id IS NULL OR @id = 0
    BEGIN
        INSERT INTO dbo.[FixedAssetCategory]([code], [name], [defaultUsefulLifeMonths], [accountAssetId], [accountAccumDeprId], [accountExpenseDeprId], [isActive])
        VALUES (@code, @name, ISNULL(@defaultUsefulLifeMonths, 60), @accountAssetId, @accountAccumDeprId, @accountExpenseDeprId, ISNULL(@isActive, 1));
        SET @outId = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE dbo.[FixedAssetCategory]
        SET [code] = @code, [name] = @name, [defaultUsefulLifeMonths] = ISNULL(@defaultUsefulLifeMonths, 60),
            [accountAssetId] = @accountAssetId, [accountAccumDeprId] = @accountAccumDeprId, [accountExpenseDeprId] = @accountExpenseDeprId,
            [isActive] = ISNULL(@isActive, 1), [updatedAt] = SYSUTCDATETIME()
        WHERE [id] = @id;
        SET @outId = @id;
    END
END;
GO

IF OBJECT_ID('dbo.spActivoFijoGuardar', 'P') IS NOT NULL DROP PROCEDURE dbo.spActivoFijoGuardar;
GO
CREATE PROCEDURE dbo.spActivoFijoGuardar
    @id INT = NULL,
    @companyId INT,
    @categoryId INT,
    @code NVARCHAR(50),
    @name NVARCHAR(150),
    @description NVARCHAR(MAX) = NULL,
    @serialNumber NVARCHAR(100) = NULL,
    @purchaseDate DATETIME2,
    @activationDate DATETIME2,
    @acquisitionCost DECIMAL(18, 4),
    @residualValue DECIMAL(18, 4) = 0,
    @usefulLifeMonths INT = 60,
    @costCenterId INT = NULL,
    @responsibleThirdPartyId INT = NULL,
    @location NVARCHAR(150) = NULL,
    @createdById INT,
    @outId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @monthlyDepr DECIMAL(18, 4) = ROUND((ISNULL(@acquisitionCost, 0) - ISNULL(@residualValue, 0)) / @usefulLifeMonths, 4);

    IF @id IS NULL OR @id = 0
    BEGIN
        INSERT INTO dbo.[FixedAsset](
            [companyId], [categoryId], [code], [name], [description], [serialNumber],
            [purchaseDate], [activationDate], [acquisitionCost], [residualValue],
            [usefulLifeMonths], [depreciatedMonths], [accumulatedDepreciation],
            [netBookValue], [monthlyDepreciation], [costCenterId],
            [responsibleThirdPartyId], [location], [status], [createdById]
        ) VALUES (
            @companyId, @categoryId, @code, @name, @description, @serialNumber,
            @purchaseDate, @activationDate, @acquisitionCost, ISNULL(@residualValue, 0),
            @usefulLifeMonths, 0, 0,
            @acquisitionCost, @monthlyDepr, @costCenterId,
            @responsibleThirdPartyId, @location, 'ACTIVE', @createdById
        );
        SET @outId = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE dbo.[FixedAsset]
        SET [categoryId] = @categoryId, [code] = @code, [name] = @name, [description] = @description,
            [serialNumber] = @serialNumber, [purchaseDate] = @purchaseDate, [activationDate] = @activationDate,
            [acquisitionCost] = @acquisitionCost, [residualValue] = ISNULL(@residualValue, 0),
            [usefulLifeMonths] = @usefulLifeMonths, [monthlyDepreciation] = @monthlyDepr,
            [netBookValue] = @acquisitionCost - [accumulatedDepreciation],
            [costCenterId] = @costCenterId, [responsibleThirdPartyId] = @responsibleThirdPartyId,
            [location] = @location, [updatedAt] = SYSUTCDATETIME()
        WHERE [id] = @id;
        SET @outId = @id;
    END
END;
GO
