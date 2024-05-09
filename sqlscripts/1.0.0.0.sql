IF(OBJECT_ID('OrderItems') IS NOT NULL) DROP TABLE OrderItems
IF(OBJECT_ID('Payments') IS NOT NULL) DROP TABLE Payments
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
,   ProductName         VARCHAR(20)         NOT NULL
,   ProductDescription  VARCHAR(50)         NOT NULL
,   ProductCategory     VARCHAR(10)         NOT NULL
,   ProductUnitPrice    DECIMAL(18, 2)      NOT NULL
,   CONSTRAINT Pk_OrderItems PRIMARY KEY NONCLUSTERED (OrderId, Code)
,   CONSTRAINT Fk1_OrderItems FOREIGN KEY (OrderId) REFERENCES Orders (Id)
)

CREATE TABLE Payments (
    Id                  UNIQUEIDENTIFIER    NOT NULL
,   OrderId             UNIQUEIDENTIFIER    NOT NULL
,   [Status]            VARCHAR(10)         NOT NULL
,   CONSTRAINT Pk_Payments PRIMARY KEY NONCLUSTERED (Id)
,   CONSTRAINT Fk1_Payments FOREIGN KEY (OrderId) REFERENCES Orders (Id)
)
GO