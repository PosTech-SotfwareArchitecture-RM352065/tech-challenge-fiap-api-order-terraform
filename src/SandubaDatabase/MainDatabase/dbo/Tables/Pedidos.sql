CREATE TABLE Pedidos (
    Id          UNIQUEIDENTIFIER    NOT NULL
,   Numero      INT                 NOT NULL
,   ClienteId   UNIQUEIDENTIFIER        NULL
,   [Status]    INT                 NOT NULL DEFAULT (0)
,   CONSTRAINT Pk_Pedidos PRIMARY KEY NONCLUSTERED (Id)
,   CONSTRAINT Fk1_Pedidos FOREIGN KEY (ClienteId) REFERENCES Clientes (Id)
)