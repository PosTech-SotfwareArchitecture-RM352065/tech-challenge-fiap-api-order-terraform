IF(OBJECT_ID('OrderItems') IS NOT NULL) DROP TABLE OrderItems
IF(OBJECT_ID('OrderPayments') IS NOT NULL) DROP TABLE OrderPayments
IF(OBJECT_ID('Orders') IS NOT NULL) DROP TABLE Orders

CREATE TABLE Orders (
    Id          UNIQUEIDENTIFIER    NOT NULL
,   Code        INT                 NOT NULL
,   ClientId    UNIQUEIDENTIFIER        NULL
,   [Status]    INT                 NOT NULL DEFAULT (0)
,   CONSTRAINT Pk_Orders PRIMARY KEY NONCLUSTERED (Id)
)

CREATE TABLE OrderItems (
    OrderId             UNIQUEIDENTIFIER    NOT NULL
,   Code                INT                 NOT NULL
,   ProductId           UNIQUEIDENTIFIER    NOT NULL
,   ProductUnitPrice    DECIMAL(18, 2)      NOT NULL
,   CONSTRAINT Pk_OrderItems PRIMARY KEY NONCLUSTERED (OrderId, Code)
,   CONSTRAINT Fk1_OrderItems FOREIGN KEY (OrderId) REFERENCES Orders (Id)
)

CREATE TABLE OrderPayments (
    Id                  UNIQUEIDENTIFIER    NOT NULL
,   OrderId             UNIQUEIDENTIFIER    NOT NULL
,   [Status]            VARCHAR(10)         NOT NULL DEFAULT("Created")
,   CONSTRAINT Pk_OrderPayments PRIMARY KEY NONCLUSTERED (Id)
,   CONSTRAINT Fk1_OrderPayments FOREIGN KEY (OrderId) REFERENCES Orders (Id)
)
GO