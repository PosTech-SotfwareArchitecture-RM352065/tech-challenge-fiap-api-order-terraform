IF(OBJECT_ID('ItensPedido') IS NOT NULL) DROP TABLE ItensPedido
IF(OBJECT_ID('Pedidos') IS NOT NULL) DROP TABLE Pedidos
IF(OBJECT_ID('Produtos') IS NOT NULL) DROP TABLE Produtos
IF(OBJECT_ID('Clientes') IS NOT NULL) DROP TABLE Clientes
IF(OBJECT_ID('Sp_AdicionaCliente') IS NOT NULL) DROP PROCEDURE dbo.Sp_AdicionaCliente
IF(OBJECT_ID('Sp_ValidaLogin') IS NOT NULL) DROP PROCEDURE dbo.Sp_ValidaLogin
GO

CREATE TABLE Clientes (
    Id              UNIQUEIDENTIFIER    NOT NULL
,   Tipo            INT                 NOT NULL
,   Cpf             VARCHAR(11)         NOT NULL
,   Nome            VARCHAR(50)         NOT NULL
,   Email           VARCHAR(50)         NOT NULL
,   Senha           BINARY(64)          NOT NULL
,   CONSTRAINT Pk_Clientes PRIMARY KEY NONCLUSTERED (Id)
,   CONSTRAINT Uk1_Clientes UNIQUE CLUSTERED (Cpf)
)
GO

CREATE TABLE Produtos (
    Id          UNIQUEIDENTIFIER    NOT NULL
,   Categoria   INT                 NOT NULL
,   Nome        VARCHAR(50)         NOT NULL
,   Descricao   VARCHAR(100)        NOT NULL
,   Preco       DECIMAL(18, 2)      NOT NULL
,   Ativo       BIT                 NOT NULL DEFAULT (1)
,   CONSTRAINT Pk_Produtos PRIMARY KEY NONCLUSTERED (Id) 
,   CONSTRAINT Uk1_Produtos UNIQUE CLUSTERED (Descricao)
)
GO

CREATE TABLE Pedidos (
    Id          UNIQUEIDENTIFIER    NOT NULL
,   Numero      INT                 NOT NULL
,   ClienteId   UNIQUEIDENTIFIER        NULL
,   [Status]    INT                 NOT NULL DEFAULT (0)
,   CONSTRAINT Pk_Pedidos PRIMARY KEY NONCLUSTERED (Id)
,   CONSTRAINT Fk1_Pedidos FOREIGN KEY (ClienteId) REFERENCES Clientes (Id)
)
GO

CREATE TABLE ItensPedido (
    PedidoId    UNIQUEIDENTIFIER    NOT NULL
,   Codigo      INT                 NOT NULL
,   ProdutoId   UNIQUEIDENTIFIER    NOT NULL
,   Preco       DECIMAL(18, 2)      NOT NULL
,   CONSTRAINT Pk_ItensPedido PRIMARY KEY NONCLUSTERED (PedidoId, Codigo)
,   CONSTRAINT Fk1_ItensPedido FOREIGN KEY (PedidoId) REFERENCES Pedidos (Id)
,   CONSTRAINT Fk2_ItensPedido FOREIGN KEY (ProdutoId) REFERENCES Produtos (Id)
)
GO

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
GO

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
GO