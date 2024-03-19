CREATE PROCEDURE dbo.Sp_AdicionaCliente
    @Id              UNIQUEIDENTIFIER
,   @Tipo            INT
,   @Cpf             VARCHAR(11)
,   @Nome            VARCHAR(50)
,   @Email           VARCHAR(50)
,   @Senha           NVARCHAR(50)

AS
BEGIN
    INSERT INTO dbo.Cliente (Id, Tipo, Cpf, Nome, Email, Senha)
    VALUES(@Id, @Tipo, @Cpf, @Nome, @Email, HASHBYTES('SHA2_512', @Senha+CAST(@Id AS NVARCHAR(36))))
END