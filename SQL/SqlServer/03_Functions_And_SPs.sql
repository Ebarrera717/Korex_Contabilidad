-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTOS Y FUNCIONES T-SQL (SQL SERVER)
-- Archivo: SQL/SqlServer/03_Functions_And_SPs.sql
-- ============================================================================

-- 1. spCompanyGuardar
CREATE OR ALTER PROCEDURE [dbo].[spCompanyGuardar]
    @p_id INT = NULL,
    @p_code NVARCHAR(50),
    @p_business_name NVARCHAR(255),
    @p_trade_name NVARCHAR(255) = NULL,
    @p_document_type NVARCHAR(20) = 'NIT',
    @p_document_number NVARCHAR(50),
    @p_verification_digit NVARCHAR(2) = NULL,
    @p_address NVARCHAR(255) = NULL,
    @p_city NVARCHAR(100) = NULL,
    @p_state NVARCHAR(100) = NULL,
    @p_country NVARCHAR(100) = 'Colombia',
    @p_phone NVARCHAR(50) = NULL,
    @p_email NVARCHAR(150) = NULL,
    @p_legal_rep NVARCHAR(255) = NULL,
    @p_tax_regime NVARCHAR(100) = NULL,
    @p_fiscal_resp NVARCHAR(255) = NULL,
    @p_ciiu NVARCHAR(20) = NULL,
    @p_is_active BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    IF @p_id IS NULL OR @p_id = 0
    BEGIN
        INSERT INTO [dbo].[Company] (
            [code], [businessName], [tradeName], [documentType], [documentNumber],
            [verificationDigit], [address], [city], [state], [country], [phone], [email],
            [legalRepresentative], [taxRegime], [fiscalResponsibilities],
            [economicActivityCode], [isActive], [createdAt], [updatedAt]
        ) VALUES (
            @p_code, @p_business_name, @p_trade_name, ISNULL(@p_document_type, 'NIT'), @p_document_number,
            @p_verification_digit, @p_address, @p_city, @p_state, ISNULL(@p_country, 'Colombia'), @p_phone, @p_email,
            @p_legal_rep, @p_tax_regime, @p_fiscal_resp,
            @p_ciiu, ISNULL(@p_is_active, 1), GETDATE(), GETDATE()
        );
    END
    ELSE
    BEGIN
        UPDATE [dbo].[Company]
        SET 
            [code] = @p_code,
            [businessName] = @p_business_name,
            [tradeName] = @p_trade_name,
            [documentType] = ISNULL(@p_document_type, 'NIT'),
            [documentNumber] = @p_document_number,
            [verificationDigit] = @p_verification_digit,
            [address] = @p_address,
            [city] = @p_city,
            [state] = @p_state,
            [country] = ISNULL(@p_country, 'Colombia'),
            [phone] = @p_phone,
            [email] = @p_email,
            [legalRepresentative] = @p_legal_rep,
            [taxRegime] = @p_tax_regime,
            [fiscalResponsibilities] = @p_fiscal_resp,
            [economicActivityCode] = @p_ciiu,
            [isActive] = ISNULL(@p_is_active, [isActive]),
            [updatedAt] = GETDATE()
        WHERE [id] = @p_id;
    END
END;
GO

-- 2. spPucGuardar
CREATE OR ALTER PROCEDURE [dbo].[spPucGuardar]
    @p_id INT = NULL,
    @p_code NVARCHAR(30),
    @p_name NVARCHAR(255),
    @p_level INT,
    @p_nature NVARCHAR(10),
    @p_allows_movement BIT = 0,
    @p_requires_third BIT = 0,
    @p_requires_cc BIT = 0,
    @p_parent_id INT = NULL,
    @p_is_active BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_clean_code NVARCHAR(30) = RTRIM(LTRIM(@p_code));
    DECLARE @v_parent_id INT = @p_parent_id;

    IF @v_parent_id IS NULL AND LEN(@v_clean_code) > 1
    BEGIN
        IF LEN(@v_clean_code) = 2
            SELECT @v_parent_id = [id] FROM [dbo].[Account] WHERE [code] = SUBSTRING(@v_clean_code, 1, 1);
        ELSE IF LEN(@v_clean_code) = 4
            SELECT @v_parent_id = [id] FROM [dbo].[Account] WHERE [code] = SUBSTRING(@v_clean_code, 1, 2);
        ELSE IF LEN(@v_clean_code) = 6
            SELECT @v_parent_id = [id] FROM [dbo].[Account] WHERE [code] = SUBSTRING(@v_clean_code, 1, 4);
        ELSE IF LEN(@v_clean_code) >= 8
            SELECT @v_parent_id = [id] FROM [dbo].[Account] WHERE [code] = SUBSTRING(@v_clean_code, 1, 6);
    END

    IF @v_parent_id IS NOT NULL
        UPDATE [dbo].[Account] SET [allowsMovement] = 0 WHERE [id] = @v_parent_id;

    IF @p_id IS NULL OR @p_id = 0
    BEGIN
        INSERT INTO [dbo].[Account] (
            [code], [name], [level], [nature], [allowsMovement],
            [requiresThirdParty], [requiresCostCenter], [parentId], [isActive],
            [createdAt], [updatedAt]
        ) VALUES (
            @v_clean_code, RTRIM(LTRIM(@p_name)), @p_level, UPPER(RTRIM(LTRIM(@p_nature))), ISNULL(@p_allows_movement, 0),
            ISNULL(@p_requires_third, 0), ISNULL(@p_requires_cc, 0), @v_parent_id, ISNULL(@p_is_active, 1),
            GETDATE(), GETDATE()
        );
    END
    ELSE
    BEGIN
        UPDATE [dbo].[Account]
        SET 
            [code] = @v_clean_code,
            [name] = RTRIM(LTRIM(@p_name)),
            [level] = @p_level,
            [nature] = UPPER(RTRIM(LTRIM(@p_nature))),
            [allowsMovement] = ISNULL(@p_allows_movement, [allowsMovement]),
            [requiresThirdParty] = ISNULL(@p_requires_third, [requiresThirdParty]),
            [requiresCostCenter] = ISNULL(@p_requires_cc, [requiresCostCenter]),
            [parentId] = @v_parent_id,
            [isActive] = ISNULL(@p_is_active, [isActive]),
            [updatedAt] = GETDATE()
        WHERE [id] = @p_id;
    END
END;
GO

-- 3. spThirdPartyGuardar
CREATE OR ALTER PROCEDURE [dbo].[spThirdPartyGuardar]
    @p_id INT = NULL,
    @p_document_type NVARCHAR(20) = 'NIT',
    @p_document_number NVARCHAR(50),
    @p_verification_digit NVARCHAR(2) = NULL,
    @p_business_name NVARCHAR(255) = NULL,
    @p_first_name NVARCHAR(100) = NULL,
    @p_second_name NVARCHAR(100) = NULL,
    @p_first_last_name NVARCHAR(100) = NULL,
    @p_second_last_name NVARCHAR(100) = NULL,
    @p_person_type NVARCHAR(20) = 'JURIDICA',
    @p_address NVARCHAR(255) = NULL,
    @p_city NVARCHAR(100) = NULL,
    @p_state NVARCHAR(100) = NULL,
    @p_country NVARCHAR(100) = 'Colombia',
    @p_phone NVARCHAR(50) = NULL,
    @p_email NVARCHAR(150) = NULL,
    @p_is_customer BIT = 0,
    @p_is_supplier BIT = 0,
    @p_is_employee BIT = 0,
    @p_is_partner BIT = 0,
    @p_is_other BIT = 0,
    @p_tax_regime NVARCHAR(100) = NULL,
    @p_fiscal_resp NVARCHAR(255) = NULL,
    @p_is_active BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_full_name NVARCHAR(255);
    IF UPPER(@p_person_type) = 'JURIDICA' OR (@p_business_name IS NOT NULL AND RTRIM(LTRIM(@p_business_name)) <> '')
        SET @v_full_name = RTRIM(LTRIM(@p_business_name));
    ELSE
        SET @v_full_name = RTRIM(LTRIM(CONCAT(
            ISNULL(@p_first_name, ''), ' ',
            ISNULL(@p_second_name, ''), ' ',
            ISNULL(@p_first_last_name, ''), ' ',
            ISNULL(@p_second_last_name, '')
        )));

    IF @p_id IS NULL OR @p_id = 0
    BEGIN
        INSERT INTO [dbo].[ThirdParty] (
            [documentType], [documentNumber], [verificationDigit], [businessName],
            [firstName], [secondName], [firstLastName], [secondLastName],
            [fullName], [personType], [address], [city], [state], [country], [phone], [email],
            [isCustomer], [isSupplier], [isEmployee], [isPartner], [isOther],
            [taxRegime], [fiscalResponsibilities], [isActive], [createdAt], [updatedAt]
        ) VALUES (
            ISNULL(@p_document_type, 'NIT'), RTRIM(LTRIM(@p_document_number)), @p_verification_digit, @p_business_name,
            @p_first_name, @p_second_name, @p_first_last_name, @p_second_last_name,
            @v_full_name, ISNULL(@p_person_type, 'JURIDICA'), @p_address, @p_city, @p_state, ISNULL(@p_country, 'Colombia'), @p_phone, @p_email,
            ISNULL(@p_is_customer, 0), ISNULL(@p_is_supplier, 0), ISNULL(@p_is_employee, 0),
            ISNULL(@p_is_partner, 0), ISNULL(@p_is_other, 0),
            @p_tax_regime, @p_fiscal_resp, ISNULL(@p_is_active, 1), GETDATE(), GETDATE()
        );
    END
    ELSE
    BEGIN
        UPDATE [dbo].[ThirdParty]
        SET 
            [documentType] = ISNULL(@p_document_type, 'NIT'),
            [documentNumber] = RTRIM(LTRIM(@p_document_number)),
            [verificationDigit] = @p_verification_digit,
            [businessName] = @p_business_name,
            [firstName] = @p_first_name,
            [secondName] = @p_second_name,
            [firstLastName] = @p_first_last_name,
            [secondLastName] = @p_second_last_name,
            [fullName] = @v_full_name,
            [personType] = ISNULL(@p_person_type, 'JURIDICA'),
            [address] = @p_address,
            [city] = @p_city,
            [state] = @p_state,
            [country] = ISNULL(@p_country, 'Colombia'),
            [phone] = @p_phone,
            [email] = @p_email,
            [isCustomer] = ISNULL(@p_is_customer, [isCustomer]),
            [isSupplier] = ISNULL(@p_is_supplier, [isSupplier]),
            [isEmployee] = ISNULL(@p_is_employee, [isEmployee]),
            [isPartner] = ISNULL(@p_is_partner, [isPartner]),
            [isOther] = ISNULL(@p_is_other, [isOther]),
            [taxRegime] = @p_tax_regime,
            [fiscalResponsibilities] = @p_fiscal_resp,
            [isActive] = ISNULL(@p_is_active, [isActive]),
            [updatedAt] = GETDATE()
        WHERE [id] = @p_id;
    END
END;
GO

-- 4. spTraceabilityLog
CREATE OR ALTER PROCEDURE [dbo].[spTraceabilityLog]
    @p_code NVARCHAR(100),
    @p_user_id INT = NULL,
    @p_origin NVARCHAR(50) = 'WEB',
    @p_module NVARCHAR(100),
    @p_screen NVARCHAR(100) = NULL,
    @p_action NVARCHAR(100),
    @p_process NVARCHAR(150) = NULL,
    @p_event_type NVARCHAR(50),
    @p_step_name NVARCHAR(150),
    @p_sp_name NVARCHAR(150) = NULL,
    @p_endpoint NVARCHAR(255) = NULL,
    @p_duration_ms INT = 0,
    @p_status NVARCHAR(50) = 'SUCCESS',
    @p_input_data NVARCHAR(MAX) = NULL,
    @p_output_data NVARCHAR(MAX) = NULL,
    @p_tech_message NVARCHAR(MAX) = NULL,
    @p_functional_message NVARCHAR(MAX) = NULL,
    @p_stack_trace NVARCHAR(MAX) = NULL,
    @p_affected_id NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO [dbo].[TraceabilityLog] (
        [code], [userId], [origin], [module], [screen], [action], [process],
        [eventType], [stepName], [spName], [endpoint], [durationMs],
        [status], [inputData], [outputData], [techMessage], [functionalMessage],
        [stackTrace], [affectedId], [createdAt]
    ) VALUES (
        @p_code, @p_user_id, ISNULL(@p_origin, 'WEB'), @p_module, @p_screen, @p_action, @p_process,
        @p_event_type, @p_step_name, @p_sp_name, @p_endpoint, ISNULL(@p_duration_ms, 0),
        ISNULL(@p_status, 'SUCCESS'), @p_input_data, @p_output_data, @p_tech_message, @p_functional_message,
        @p_stack_trace, @p_affected_id, GETDATE()
    );
END;
GO
