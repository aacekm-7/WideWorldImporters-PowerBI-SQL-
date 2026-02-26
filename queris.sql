
--VIEW Dim_Clientes
ALTER VIEW Dim_Clientes AS
SELECT 
c.CustomerID AS ID_Cliente,
c.CustomerName AS Nombre_cliente,
c.CustomerCategoryID AS ID_CategoriaCliente,
c.PhoneNumber AS Telefono,
cg.CustomerCategoryName AS Categoria_cliente
FROM Sales.Customers AS c
INNER JOIN Sales.CustomerCategories AS cg
ON c.CustomerCategoryID = cg.CustomerCategoryID;

--VIEW Dim_Productos
ALTER VIEW Dim_Productos AS
SELECT
    si.StockItemID AS ID_Producto,
    si.StockItemName AS NombreProducto,
    si.Brand AS Marca,
    si.ColorID AS ID_Color,
    si.UnitPrice AS Precio_unidad,
    si.RecommendedRetailPrice AS PrecioDeVenta_recomendado,
    si.TaxRate AS Tasa_impositiva,
    si.Size AS Tamaño,
    si.Barcode AS Codigo_barras,
    si.TypicalWeightPerUnit AS PesoTipico_porUnidad,
    si.LeadTimeDays AS DiasPlazo_Entrega,
    si.QuantityPerOuter AS CantidadPor_orden
FROM Warehouse.StockItems si;

--CREATE VIEW Dim_CategoriaProducto
ALTER VIEW Dim_CategoriaProducto AS
SELECT DISTINCT
pc.StockGroupID AS ID_CategoriaProducto,
pc.StockGroupName AS Categoria_producto
FROM Warehouse.StockGroups AS pc

--CREATE VIEW Dim_CategoriaProductoGRUPO
ALTER VIEW Dim_CategoriaProductoGRUPO AS
SELECT DISTINCT
pcc.StockItemID AS ID_Producto,
pcc.StockGroupID AS ID_ProductoGrupo 
FROM Warehouse.StockItemStockGroups AS PCC

--CREATE VIEW Dim_Suplidor
CREATE VIEW Dim_Suplidor AS
SELECT 
su.SupplierID AS ID_Suplidor,
su.SupplierCategoryID AS ID_CategoriaSuplidor,
su.PrimaryContactPersonID AS ID_ContactoPersona,
su.PhoneNumber AS Telefono,
su.DeliveryMethodID AS ID_Entrega,
su.SupplierName AS Nombre_suplidor,
suc.SupplierCategoryName AS Nombre_categoria,
su.PaymentDays AS DiasPago
FROM Purchasing.Suppliers AS su
INNER JOIN Purchasing.SupplierCategories AS suc
ON su.SupplierCategoryID = suc.SupplierCategoryID;

ALTER TABLE DimDate (
    DateKey INT PRIMARY KEY,          -- 20140220
    FullDate DATE,                    -- 2014-02-20
    Day INT,
    Month INT,
    Year INT,
    Quarter INT,
    MonthName VARCHAR(20),
    DayName VARCHAR(20),
    WeekOfYear INT,
    IsWeekend BIT,
    IsHoliday BIT DEFAULT 0
);

DECLARE @StartDate DATE = '2012-01-01';
DECLARE @EndDate DATE   = '2016-12-31';

WHILE @StartDate <= @EndDate
BEGIN
    INSERT INTO DimDate (
        DateKey,
        FullDate,
        Day,
        Month,
        Year,
        Quarter,
        MonthName,
        DayName,
        WeekOfYear,
        IsWeekend
    )
    SELECT
        CONVERT(INT, FORMAT(@StartDate, 'yyyyMMdd')),
        @StartDate,
        DAY(@StartDate),
        MONTH(@StartDate),
        YEAR(@StartDate),
        DATEPART(QUARTER, @StartDate),
        DATENAME(MONTH, @StartDate),
        DATENAME(WEEKDAY, @StartDate),
        DATEPART(WEEK, @StartDate),
        CASE WHEN DATENAME(WEEKDAY, @StartDate) IN ('Saturday','Sunday') THEN 1 ELSE 0 END;

    SET @StartDate = DATEADD(DAY, 1, @StartDate);
END;

select * from DimDate

--VIEW FACT_Inventory ALTER VIEW FACT_Inventory AS

ALTER VIEW FACT_Inventario AS
SELECT
    stt.StockItemTransactionID AS ID_Transaccion,
    stt.StockItemID AS ID_Producto,
    stt.CustomerID AS ID_Cliente,
    stt.SupplierID AS ID_Suplidor,
    stt.TransactionOccurredWhen AS FechaTransaccion,
    stt.Quantity AS CantidadMovimiento,
    stt.TransactionTypeID AS TipoMovimiento
FROM Warehouse.StockItemTransactions stt;


--View FACT_Sales
ALTER VIEW FACT_Ventas AS
SELECT
    il.InvoiceLineID AS ID_LineaFactura,
    inv.CustomerID AS ID_Cliente, 
    il.InvoiceID AS ID_Factura,
    inv.OrderID AS ID_Orden,
    inv.SalespersonPersonID AS ID_Vendedor,
    inv.ContactPersonID AS ID_Contacto,
    prod.StockItemID AS ID_Producto,
    il.Quantity AS Cantidad,
    il.UnitPrice AS Precio_Unidad,
    il.TaxRate AS Tasa_Impositiva,
    il.TaxAmount AS Impuesto,
    il.LineProfit AS BeneficioDe_Linea,
    il.ExtendedPrice AS Precio_Extendido,
    inv.InvoiceDate AS FechaFactura,
    o.OrderDate AS FechaPedido,
    o.ExpectedDeliveryDate AS FechaEntrega
FROM Sales.InvoiceLines AS il
INNER JOIN Sales.Invoices AS inv
ON il.InvoiceID = inv.InvoiceID
INNER JOIN Sales.Orders AS o
ON inv.OrderID = o.OrderID
INNER JOIN Warehouse.StockItems AS prod
ON il.StockItemID = prod.StockItemID;


--CREATE VIEW FACT_CustomerTransactions
CREATE VIEW FACT_CustomerTransactions AS
SELECT
    ct.CustomerTransactionID AS ID_Transaccion,
    ct.CustomerID AS ID_Cliente,
    ct.InvoiceID AS ID_Factura,
    ct.TransactionTypeID AS ID_TipoTransaccion,
    ct.PaymentMethodID AS ID_MetodoPago,
    ct.TransactionDate AS FechaTransaccion,
    ct.FinalizationDate AS FechaFinalizacion,
    ct.AmountExcludingTax AS MontoSinImpuesto,
    ct.TaxAmount AS Impuesto,
    ct.TransactionAmount AS MontoTotal,
    ct.OutstandingBalance AS SaldoPendiente,
    ct.IsFinalized AS EstaFinalizada
FROM Sales.CustomerTransactions ct;


--VIEW FACT_Compras

ALTER VIEW FACT_Compras AS
SELECT
    pol.PurchaseOrderLineID      AS ID_LineaOrden,
    pol.PurchaseOrderID          AS ID_Orden,
    po.SupplierID                AS ID_Suplidor,
    pol.StockItemID              AS ID_Producto,
    po.ContactPersonID           AS ID_Contacto,
    po.DeliveryMethodID          AS ID_MetodoEntrega,
    pol.OrderedOuters            AS Cantidad_Ordenada,
    pol.ReceivedOuters           AS Cantidad_Recibida,
    pol.ExpectedUnitPricePerOuter AS PrecioEsperado_Unidad,
    po.OrderDate                 AS FechaOrden,
    po.ExpectedDeliveryDate      AS FechaEntregaEsperada,
    po.IsOrderFinalized          AS OrdenFinalizada

FROM Purchasing.PurchaseOrderLines AS pol
INNER JOIN Purchasing.PurchaseOrders AS po
ON pol.PurchaseOrderID = po.PurchaseOrderID;


--CREATE VIEW Fact_Supplier
ALTER VIEW FACT_SuplidorTransacciones AS
SELECT
    st.SupplierTransactionID AS ID_Transaccion,
    st.SupplierID AS ID_Proveedor,
    st.TransactionTypeID AS ID_TipoTransaccion,
    st.PaymentMethodID AS ID_MetodoPago,
    st.TransactionDate AS FechaTransaccion,
    st.FinalizationDate AS FechaFinalizacion,
    st.AmountExcludingTax AS MontoSinImpuesto,
    st.TaxAmount AS Impuesto,
    st.TransactionAmount AS MontoTotal,
    st.OutstandingBalance AS SaldoPendiente,
    st.IsFinalized AS EstaFinalizada
FROM Purchasing.SupplierTransactions st;



