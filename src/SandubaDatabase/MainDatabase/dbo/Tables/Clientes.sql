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