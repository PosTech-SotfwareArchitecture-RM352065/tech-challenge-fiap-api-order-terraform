CREATE PROCEDURE dbo.Sp_ValidaLogin
    @Cpf            VARCHAR(11)
,   @Senha          NVARCHAR(50)
,   @Valido         BIT OUTPUT

AS
BEGIN

    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    SET @Valido 
        = CASE WHEN EXISTS (SELECT *
                              FROM dbo.Clientes 
                             WHERE Cpf = @Cpf
                               AND Senha = HASHBYTES('SHA2_512', @Senha+CAST(Id AS NVARCHAR(36)))) THEN 1 ELSE 0 END
END