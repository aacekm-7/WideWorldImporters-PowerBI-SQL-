-- ============================================================
-- EDA - WideWorldImporters (WWI)
-- Enfoque: por área de negocio
-- ============================================================

USE WideWorldImporters;


-- ============================================================
-- ÁREA 1: VENTAS
-- ============================================================

-- 1.1 ¿Cuántas facturas, órdenes y líneas de detalle existen?
SELECT
    (SELECT COUNT(*) FROM Sales.Invoices)      AS TotalFacturas,
    (SELECT COUNT(*) FROM Sales.Orders)        AS TotalOrdenes,
    (SELECT COUNT(*) FROM Sales.InvoiceLines)  AS TotalLineasFactura;

-- 1.2 Rango temporal de ventas
SELECT
    MIN(InvoiceDate)                                    AS PrimeraFactura,
    MAX(InvoiceDate)                                    AS UltimaFactura,
    DATEDIFF(MONTH, MIN(InvoiceDate), MAX(InvoiceDate)) AS MesesCubiertos
FROM Sales.Invoices;

-- 1.3 Estadísticas de ingresos por línea de factura
SELECT
    ROUND(MIN(ExtendedPrice), 2)  AS PrecioMin,
    ROUND(MAX(ExtendedPrice), 2)  AS PrecioMax,
    ROUND(AVG(ExtendedPrice), 2)  AS PrecioPromedio,
    ROUND(SUM(ExtendedPrice), 2)  AS IngresoTotal,
    ROUND(SUM(LineProfit), 2)     AS BeneficioTotal,
    ROUND(AVG(TaxRate), 2)        AS TasaImpuestoPromedio
FROM Sales.InvoiceLines;

-- 1.4 Top 10 clientes por ingreso generado
SELECT TOP 10
    c.CustomerID,
    c.CustomerName        AS Cliente,
    cg.CustomerCategoryName AS Categoria,
    ROUND(SUM(il.ExtendedPrice), 2) AS IngresoTotal
FROM Sales.InvoiceLines il
INNER JOIN Sales.Invoices inv  ON il.InvoiceID = inv.InvoiceID
INNER JOIN Sales.Customers c   ON inv.CustomerID = c.CustomerID
INNER JOIN Sales.CustomerCategories cg ON c.CustomerCategoryID = cg.CustomerCategoryID
GROUP BY c.CustomerID, c.CustomerName, cg.CustomerCategoryName
ORDER BY IngresoTotal DESC;

-- 1.5 Distribución de ventas por categoría de cliente
SELECT
    cg.CustomerCategoryName AS Categoria,
    COUNT(DISTINCT c.CustomerID)    AS TotalClientes,
    ROUND(SUM(il.ExtendedPrice), 2) AS IngresoTotal
FROM Sales.InvoiceLines il
INNER JOIN Sales.Invoices inv  ON il.InvoiceID = inv.InvoiceID
INNER JOIN Sales.Customers c   ON inv.CustomerID = c.CustomerID
INNER JOIN Sales.CustomerCategories cg ON c.CustomerCategoryID = cg.CustomerCategoryID
GROUP BY cg.CustomerCategoryName
ORDER BY IngresoTotal DESC;

-- 1.6 Ventas por año y mes
SELECT
    YEAR(inv.InvoiceDate)  AS Año,
    MONTH(inv.InvoiceDate) AS Mes,
    ROUND(SUM(il.ExtendedPrice), 2) AS IngresoMensual,
    COUNT(DISTINCT inv.InvoiceID)   AS Facturas
FROM Sales.InvoiceLines il
INNER JOIN Sales.Invoices inv ON il.InvoiceID = inv.InvoiceID
GROUP BY YEAR(inv.InvoiceDate), MONTH(inv.InvoiceDate)
ORDER BY Año, Mes;


-- ============================================================
-- ÁREA 2: PRODUCTOS
-- ============================================================

-- 2.1 Volumen del catálogo
SELECT
    (SELECT COUNT(*) FROM Warehouse.StockItems)           AS TotalProductos,
    (SELECT COUNT(*) FROM Warehouse.StockGroups)          AS TotalCategorias,
    (SELECT COUNT(*) FROM Warehouse.StockItemStockGroups) AS TotalAsignaciones;

-- 2.2 Nulos en campos clave del producto
SELECT
    COUNT(*)                                            AS TotalProductos,
    SUM(CASE WHEN Brand        IS NULL THEN 1 END)     AS SinMarca,
    SUM(CASE WHEN ColorID      IS NULL THEN 1 END)     AS SinColor,
    SUM(CASE WHEN Size         IS NULL THEN 1 END)     AS SinTamaño,
    SUM(CASE WHEN Barcode      IS NULL THEN 1 END)     AS SinCodigoBarras,
    SUM(CASE WHEN UnitPrice    = 0     THEN 1 END)     AS PrecioUnitarioCero,
    SUM(CASE WHEN RecommendedRetailPrice IS NULL THEN 1 END) AS SinPrecioRecomendado
FROM Warehouse.StockItems;

-- 2.3 Estadísticas de precios del catálogo
SELECT
    ROUND(MIN(UnitPrice), 2)               AS PrecioMin,
    ROUND(MAX(UnitPrice), 2)               AS PrecioMax,
    ROUND(AVG(UnitPrice), 2)               AS PrecioPromedio,
    ROUND(MIN(RecommendedRetailPrice), 2)  AS PVPMin,
    ROUND(MAX(RecommendedRetailPrice), 2)  AS PVPMax,
    ROUND(AVG(RecommendedRetailPrice), 2)  AS PVPPromedio
FROM Warehouse.StockItems
WHERE UnitPrice > 0;

-- 2.4 Productos por categoría (grupo)
SELECT
    sg.StockGroupName AS Categoria,
    COUNT(sisg.StockItemID) AS TotalProductos
FROM Warehouse.StockItemStockGroups sisg
INNER JOIN Warehouse.StockGroups sg ON sisg.StockGroupID = sg.StockGroupID
GROUP BY sg.StockGroupName
ORDER BY TotalProductos DESC;

-- 2.5 Top 10 productos más vendidos por cantidad
SELECT TOP 10
    si.StockItemName AS Producto,
    SUM(il.Quantity) AS CantidadVendida,
    ROUND(SUM(il.ExtendedPrice), 2) AS IngresoTotal
FROM Sales.InvoiceLines il
INNER JOIN Warehouse.StockItems si ON il.StockItemID = si.StockItemID
GROUP BY si.StockItemName
ORDER BY CantidadVendida DESC;


-- ============================================================
-- ÁREA 3: COMPRAS Y SUPLIDORES
-- ============================================================

-- 3.1 Volumen de compras
SELECT
    (SELECT COUNT(*) FROM Purchasing.PurchaseOrders)     AS TotalOrdenes,
    (SELECT COUNT(*) FROM Purchasing.PurchaseOrderLines) AS TotalLineas,
    (SELECT COUNT(*) FROM Purchasing.Suppliers)          AS TotalSuplidores;

-- 3.2 Rango temporal de compras
SELECT
    MIN(OrderDate)  AS PrimeraOrden,
    MAX(OrderDate)  AS UltimaOrden,
    DATEDIFF(MONTH, MIN(OrderDate), MAX(OrderDate)) AS MesesCubiertos
FROM Purchasing.PurchaseOrders;

-- 3.3 Órdenes finalizadas vs pendientes
SELECT
    CASE WHEN IsOrderFinalized = 1 THEN 'Finalizada' ELSE 'Pendiente' END AS Estado,
    COUNT(*) AS TotalOrdenes
FROM Purchasing.PurchaseOrders
GROUP BY IsOrderFinalized;

-- 3.4 Discrepancia entre cantidad ordenada y recibida
SELECT
    COUNT(*) AS LineasConDiscrepancia,
    ROUND(SUM(ReceivedOuters - OrderedOuters), 2) AS DiferenciaTotal
FROM Purchasing.PurchaseOrderLines
WHERE ReceivedOuters <> OrderedOuters;

-- 3.5 Top 5 suplidores por volumen de compra
SELECT TOP 5
    s.SupplierName AS Suplidor,
    sc.SupplierCategoryName AS Categoria,
    COUNT(po.PurchaseOrderID) AS TotalOrdenes,
    SUM(pol.OrderedOuters)    AS UnidadesOrdenadas
FROM Purchasing.PurchaseOrders po
INNER JOIN Purchasing.PurchaseOrderLines pol ON po.PurchaseOrderID = pol.PurchaseOrderID
INNER JOIN Purchasing.Suppliers s            ON po.SupplierID = s.SupplierID
INNER JOIN Purchasing.SupplierCategories sc  ON s.SupplierCategoryID = sc.SupplierCategoryID
GROUP BY s.SupplierName, sc.SupplierCategoryName
ORDER BY TotalOrdenes DESC;


-- ============================================================
-- ÁREA 4: INVENTARIO
-- ============================================================

-- 4.1 Volumen de movimientos
SELECT
    COUNT(*)         AS TotalMovimientos,
    SUM(CASE WHEN Quantity > 0 THEN 1 END) AS Entradas,
    SUM(CASE WHEN Quantity < 0 THEN 1 END) AS Salidas
FROM Warehouse.StockItemTransactions;

-- 4.2 Rango temporal del inventario
SELECT
    MIN(TransactionOccurredWhen) AS PrimerMovimiento,
    MAX(TransactionOccurredWhen) AS UltimoMovimiento
FROM Warehouse.StockItemTransactions;

-- 4.3 Movimientos nulos en cliente o suplidor
-- (transacciones sin origen identificado)
SELECT
    SUM(CASE WHEN CustomerID IS NULL AND SupplierID IS NULL THEN 1 END) AS SinOrigen,
    SUM(CASE WHEN CustomerID IS NOT NULL THEN 1 END) AS AsociadoCliente,
    SUM(CASE WHEN SupplierID IS NOT NULL THEN 1 END) AS AsociadoSuplidor
FROM Warehouse.StockItemTransactions;

-- 4.4 Top 10 productos con más movimientos de inventario
SELECT TOP 10
    si.StockItemName AS Producto,
    COUNT(*) AS TotalMovimientos,
    SUM(Quantity) AS MovimientoNeto
FROM Warehouse.StockItemTransactions stt
INNER JOIN Warehouse.StockItems si ON stt.StockItemID = si.StockItemID
GROUP BY si.StockItemName
ORDER BY TotalMovimientos DESC;


-- ============================================================
-- ÁREA 5: TRANSACCIONES FINANCIERAS
-- ============================================================

-- 5.1 Transacciones de clientes: estado y saldos
SELECT
    CASE WHEN IsFinalized = 1 THEN 'Finalizada' ELSE 'Pendiente' END AS Estado,
    COUNT(*)                          AS Total,
    ROUND(SUM(TransactionAmount), 2)  AS MontoTotal,
    ROUND(SUM(OutstandingBalance), 2) AS SaldoPendienteTotal
FROM Sales.CustomerTransactions
GROUP BY IsFinalized;

-- 5.2 Transacciones de suplidores: estado y saldos
SELECT
    CASE WHEN IsFinalized = 1 THEN 'Finalizada' ELSE 'Pendiente' END AS Estado,
    COUNT(*)                          AS Total,
    ROUND(SUM(TransactionAmount), 2)  AS MontoTotal,
    ROUND(SUM(OutstandingBalance), 2) AS SaldoPendienteTotal
FROM Purchasing.SupplierTransactions
GROUP BY IsFinalized;

-- 5.3 Rango temporal de transacciones financieras
SELECT
    'Clientes'  AS Origen,
    MIN(TransactionDate) AS Primera,
    MAX(TransactionDate) AS Ultima
FROM Sales.CustomerTransactions
UNION ALL
SELECT
    'Suplidores',
    MIN(TransactionDate),
    MAX(TransactionDate)
FROM Purchasing.SupplierTransactions;

-- 5.4 Outliers: transacciones con monto atípicamente alto
SELECT TOP 10
    CustomerTransactionID AS ID,
    CustomerID,
    TransactionDate,
    ROUND(TransactionAmount, 2) AS Monto
FROM Sales.CustomerTransactions
ORDER BY TransactionAmount DESC;


-- ============================================================
-- INTEGRIDAD REFERENCIAL — JOINs sin huérfanos
-- ============================================================

-- Líneas de factura sin factura padre
SELECT COUNT(*) AS LineasSinFactura
FROM Sales.InvoiceLines il
LEFT JOIN Sales.Invoices inv ON il.InvoiceID = inv.InvoiceID
WHERE inv.InvoiceID IS NULL;

-- Facturas sin orden de origen
SELECT COUNT(*) AS FacturasSinOrden
FROM Sales.Invoices inv
LEFT JOIN Sales.Orders o ON inv.OrderID = o.OrderID
WHERE o.OrderID IS NULL;

-- Transacciones de inventario con producto inexistente
SELECT COUNT(*) AS MovimientosSinProducto
FROM Warehouse.StockItemTransactions stt
LEFT JOIN Warehouse.StockItems si ON stt.StockItemID = si.StockItemID
WHERE si.StockItemID IS NULL;

-- Clientes sin categoría asignada
SELECT COUNT(*) AS ClientesSinCategoria
FROM Sales.Customers c
LEFT JOIN Sales.CustomerCategories cg ON c.CustomerCategoryID = cg.CustomerCategoryID
WHERE cg.CustomerCategoryID IS NULL;
