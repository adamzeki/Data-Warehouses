-- Without CTE
SELECT TOP 20
    p.Name AS NazwaProduktu,
    pc.Name AS Kategoria,
    SUM(sod.OrderQty) AS LiczbaSprzedanych
FROM Sales.SalesOrderDetail AS sod
JOIN Production.Product AS p 
    ON sod.ProductID = p.ProductID
JOIN Production.ProductSubcategory AS ps 
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN Production.ProductCategory AS pc 
    ON ps.ProductCategoryID = pc.ProductCategoryID
GROUP BY p.Name, pc.Name
ORDER BY LiczbaSprzedanych DESC;

-- With CTE
WITH Sprzedaz AS (
    SELECT TOP 20
        ProductID AS IDProduktu,
        SUM(OrderQty) AS LiczbaSprzedanych
    FROM Sales.SalesOrderDetail
    GROUP BY ProductID
    ORDER BY LiczbaSprzedanych DESC
)
SELECT
    p.Name AS NAzwaPRoduktu,
    pc.Name AS Kategoria,
    s.LiczbaSprzedanych
FROM Sprzedaz AS s
JOIN Production.Product  AS p
    ON s.IDProduktu = p.ProductID
JOIN Production.ProductSubcategory AS ps
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN Production.ProductCategory AS pc
    ON ps.ProductCategoryID = pc.ProductCategoryID;