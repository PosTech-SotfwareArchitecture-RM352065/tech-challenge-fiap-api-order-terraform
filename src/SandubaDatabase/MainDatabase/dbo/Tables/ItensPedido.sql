CREATE TABLE ItensPedido (
    PedidoId    UNIQUEIDENTIFIER    NOT NULL
,   Codigo      INT                 NOT NULL
,   ProdutoId   UNIQUEIDENTIFIER    NOT NULL
,   Preco       DECIMAL(18, 2)      NOT NULL
,   CONSTRAINT Pk_ItensPedido PRIMARY KEY NONCLUSTERED (PedidoId, Codigo)
,   CONSTRAINT Fk1_ItensPedido FOREIGN KEY (PedidoId) REFERENCES Pedidos (Id)
,   CONSTRAINT Fk2_ItensPedido FOREIGN KEY (ProdutoId) REFERENCES Produtos (Id)
)