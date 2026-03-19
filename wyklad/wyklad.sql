SELECT 
    st.CountryRegionCode AS Region,
    pc.Name AS Kategoria,
    SUM(sod.OrderQty) AS LiczbaSprzedanych
FROM Sales.SalesOrderDetail AS sod
JOIN Sales.SalesOrderHeader AS soh ON sod.SalesOrderID = soh.SalesOrderID
JOIN Sales.SalesTerritory AS st ON soh.TerritoryID = st.TerritoryID
JOIN Production.Product AS p ON sod.ProductID = p.ProductID
JOIN Production.ProductSubcategory AS ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN Production.ProductCategory AS pc ON ps.ProductCategoryID = pc.ProductCategoryID
GROUP BY CUBE(st.CountryRegionCode, pc.Name)
ORDER BY st.CountryRegionCode, pc.Name;