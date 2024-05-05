IF(OBJECT_ID('OrderItems') IS NOT NULL) DROP TABLE OrderItems
IF(OBJECT_ID('Orders') IS NOT NULL) DROP TABLE Orders
GO

CREATE TABLE Orders (
    Id          UNIQUEIDENTIFIER    NOT NULL
,   Code        INT                 NOT NULL
,   ClientId    UNIQUEIDENTIFIER        NULL
,   [Status]    INT                 NOT NULL DEFAULT (0)
,   CONSTRAINT Pk_Orders PRIMARY KEY NONCLUSTERED (Id)
)
GO

CREATE TABLE OrderItems (
    OrderId     UNIQUEIDENTIFIER    NOT NULL
,   Code        INT                 NOT NULL
,   ProductId   UNIQUEIDENTIFIER    NOT NULL
,   UnitPrice   DECIMAL(18, 2)      NOT NULL
,   CONSTRAINT Pk_OrderItems PRIMARY KEY NONCLUSTERED (OrderId, Code)
,   CONSTRAINT Fk1_OrderItems FOREIGN KEY (OrderId) REFERENCES Orders (Id)
)
GO