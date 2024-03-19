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