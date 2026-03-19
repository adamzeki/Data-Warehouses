-- 1
SELECT COUNT(*) AS IloscProduktow FROM Production.Product;
SELECT COUNT(*) AS IloscKategorii FROM Production.ProductCategory;
SELECT COUNT(*) AS IloscPodkategorii FROM Production.ProductSubcategory;

SELECT
    pc.Name AS Kategoria,
    COUNT(DISTINCT ps.ProductSubcategoryID) AS IloscPodkategorii,
    COUNT(DISTINCT p.ProductID) AS IloscProduktow
FROM Production.Product p
JOIN Production.ProductSubcategory ps 
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN Production.ProductCategory pc 
    ON ps.ProductCategoryID = pc.ProductCategoryID
GROUP BY pc.Name;

--2
SELECT 
    Name 
FROM Production.Product p 
WHERE Color IS NULL 
    AND FinishedGoodsFlag = 1;

SELECT 
    p.Name,
    p.SellEndDate,
    pc.Name AS Kategoria 
FROM Production.Product p 
JOIN Production.ProductSubcategory ps 
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN Production.ProductCategory pc
    ON ps.ProductCategoryID = pc.ProductCategoryID
WHERE Color IS NULL 
    AND FinishedGoodsFlag = 1;

SELECT 
    p.Name,
    p.SellEndDate,
FROM Production.Product p 
WHERE Color IS NULL 
    AND FinishedGoodsFlag = 1;

--3
SELECT 
    YEAR(OrderDate) AS Rok, 
    SUM(TotalDue) AS RocznaKwota 
FROM Sales.SalesOrderHeader 
GROUP BY YEAR(OrderDate);

--4
--Klienci
SELECT 
	COUNT(*) AS IloscKlientow
FROM Sales.Customer;
--Klienci z terytorium
SELECT 
	SalesTerritory.Name, 
	COUNT(*) AS IloscKlientow
FROM Sales.Customer
JOIN Sales.SalesTerritory 
	ON Customer.TerritoryID = SalesTerritory.TerritoryID
GROUP BY SalesTerritory.Name;
--Sprzedawcy
SELECT 
	COUNT(*) AS IloscSprzedawcow
FROM Sales.SalesPerson;
--Sprzedawcy z terytorium
SELECT 
	SalesTerritory.Name, 
	COUNT(*) AS IloscSprzedawcow
FROM Sales.SalesPerson
JOIN Sales.SalesTerritory 
	ON SalesPerson.TerritoryID = SalesTerritory.TerritoryID
GROUP BY SalesTerritory.Name;

--5
SELECT
    YEAR(OrderDate) AS Rok,
    MONTH(OrderDate) AS Miesiac,
    COUNT(*) AS LiczbaTransakcji
FROM Sales.SalesOrderHeader
GROUP BY
    YEAR(OrderDate),
    MONTH(OrderDate)
ORDER BY
    Rok, Miesiac;

--6
SELECT 
    c.Name AS Kategoria, 
    sc.Name AS Podkategoria, 
    COUNT(p.ProductID) AS LiczbaNiesprzedanych
FROM Production.Product p
LEFT JOIN Sales.SalesOrderDetail sod 
    ON p.ProductID = sod.ProductID
LEFT JOIN Production.ProductSubcategory sc 
    ON p.ProductSubcategoryID = sc.ProductSubcategoryID
LEFT JOIN Production.ProductCategory c 
    ON sc.ProductCategoryID = c.ProductCategoryID
WHERE sod.ProductID IS NULL
GROUP BY 
    c.Name, 
    sc.Name
ORDER BY 
    Kategoria, 
    Podkategoria;

SELECT
    p.Name AS NazwaProduktu
FROM Production.Product p
WHERE p.ProductSubCategoryID IS NULL
ORDER BY p.Name;

--7
SELECT
	sc.Name AS Podkategoria,
	MIN(sod.UnitPriceDiscount * sod.UnitPrice * 1.0) AS MinRabat,
	MAX(sod.UnitPriceDiscount * sod.UnitPrice * 1.0) AS MaxRabat
FROM Production.Product p 
JOIN Sales.SalesOrderDetail sod
	ON p.ProductID = sod.ProductID
JOIN Production.ProductSubcategory sc
	ON p.ProductSubcategoryID = sc.ProductSubcategoryID
GROUP BY sc.Name
ORDER BY MaxRabat DESC;

--8
WITH AvgPrice AS (
    SELECT AVG(ListPrice) AS AvgListPrice
    FROM Production.Product
)
SELECT p.Name
FROM Production.Product p
WHERE p.ListPrice > (SELECT AvgListPrice FROM AvgPrice);

--9 zla kolejnosc dni tygodnia - defaultowo zaczyna od niedzieli :/; SET DATEFIRST 1 by naprawiało
WITH SumyDzienne AS (
    SELECT 
        c.Name AS Kategoria,
        soh.OrderDate,
        SUM(sod.OrderQty) AS Suma
    FROM Sales.SalesOrderDetail sod
    JOIN Sales.SalesOrderHeader soh 
        ON sod.SalesOrderID = soh.SalesOrderID
    JOIN Production.Product p 
        ON sod.ProductID = p.ProductID
    JOIN Production.ProductSubcategory sc 
        ON p.ProductSubcategoryID = sc.ProductSubcategoryID
    JOIN Production.ProductCategory c 
        ON sc.ProductCategoryID = c.ProductCategoryID
    GROUP BY c.Name, soh.OrderDate
)
SELECT 
    Kategoria,
    CASE DATEPART(weekday, OrderDate)
        WHEN 1 THEN 'Poniedzialek'
        WHEN 2 THEN 'Wtorek'
        WHEN 3 THEN 'Sroda'
        WHEN 4 THEN 'Czwartek'
        WHEN 5 THEN 'Piatek'
        WHEN 6 THEN 'Sobota'
        WHEN 7 THEN 'Niedziela'
    END AS DzienTygodnia,
    AVG(CAST(Suma AS float)) AS SredniaSprzedaz
FROM SumyDzienne
GROUP BY Kategoria, DATEPART(weekday, OrderDate)
ORDER BY Kategoria, DATEPART(weekday, OrderDate);

SELECT 
    c.Name AS Kategoria,
    CASE DATEPART(weekday, soh.OrderDate)
        WHEN 1 THEN 'Poniedzialek'
        WHEN 2 THEN 'Wtorek'
        WHEN 3 THEN 'Sroda'
        WHEN 4 THEN 'Czwartek'
        WHEN 5 THEN 'Piatek'
        WHEN 6 THEN 'Sobota'
        WHEN 7 THEN 'Niedziela'
    END AS DzienTygodnia,
    COUNT(DISTINCT(sod.SalesOrderID)) AS LiczbaPromocji
FROM Sales.SalesOrderDetail sod
JOIN Sales.SalesOrderHeader soh 
    ON sod.SalesOrderID = soh.SalesOrderID
JOIN Production.Product p
    ON sod.ProductID = p.ProductID
JOIN Production.ProductSubcategory sc
    ON p.ProductSubcategoryID = sc.ProductSubcategoryID
JOIN Production.ProductCategory c
    ON sc.ProductCategoryID = c.ProductCategoryID
WHERE sod.UnitPriceDiscount > 0
GROUP BY c.Name, DATEPART(weekday, soh.OrderDate)
ORDER BY c.Name, LiczbaPromocji DESC;

--10
SELECT
	st.CountryRegionCode AS KodRegionu,
	AVG(DATEDIFF(day, soh.OrderDate, soh.ShipDate) * 1.0) AS SrednieOczekiwanie
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesTerritory st
	ON soh.TerritoryID = st.TerritoryID
GROUP BY st.CountryRegionCode
ORDER BY SrednieOczekiwanie DESC;

SELECT
	st.CountryRegionCode AS KodRegionu,
	DATEDIFF(day, soh.OrderDate, soh.ShipDate) AS Oczekiwanie,
	COUNT(DISTINCT(soh.SalesOrderID)) AS LiczbaZamowien
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesTerritory st
	ON soh.TerritoryID = st.TerritoryID
WHERE st.CountryRegionCode = 'DE'
GROUP BY st.CountryRegionCode, DATEDIFF(day, soh.OrderDate, soh.ShipDate)
ORDER BY Oczekiwanie DESC;

--11 skok związany z rozszerzeniem oferty
--Bez pivot
SELECT
	YEAR(soh.OrderDate) AS Rok,
	Month(soh.OrderDate) AS Miesiac,
	COUNT(DISTINCT(soh.CustomerID)) AS LiczbaRoznychKlientow
FROM Sales.SalesOrderHeader soh
GROUP BY YEAR(soh.OrderDate), MONTH(soh.OrderDate)
ORDER BY Rok, Miesiac;
--Z pivot
SELECT * FROM
(
    SELECT DISTINCT
        YEAR(soh.OrderDate) AS Rok,
        MONTH(soh.OrderDate) AS Miesiac,
        soh.CustomerID AS KlientID
    FROM Sales.SalesOrderHeader soh
) AS ZrodloDanych
PIVOT 
(
    COUNT(KlientID)
    FOR Rok IN ([2022], [2023], [2024], [2025])
) AS X
ORDER BY Miesiac;

--12
SELECT * FROM 
(
    SELECT
        p.FirstName + ' ' + p.LastName AS Sprzedawca,
        YEAR(soh.OrderDate) AS Rok,
        soh.SalesOrderID AS OrderID
    FROM Sales.SalesOrderHeader soh
    JOIN Sales.SalesPerson sp 
        ON soh.SalesPersonID = sp.BusinessEntityID
    JOIN Person.Person p 
        ON sp.BusinessEntityID = p.BusinessEntityID
    WHERE soh.SalesPersonID IN (
        SELECT SalesPersonID 
        FROM Sales.SalesOrderHeader 
        GROUP BY SalesPersonID 
        HAVING COUNT(DISTINCT YEAR(OrderDate)) = 4
    )
) AS SourceData
PIVOT 
(
    COUNT(OrderID)
    FOR Rok IN ([2022], [2023], [2024], [2025])
) AS PivotResult
ORDER BY Sprzedawca;

--13
SELECT
    YEAR(soh.OrderDate) AS Rok,
    MONTH(soh.OrderDate) AS Miesiac,
    DAY(soh.OrderDate) AS Dzien,
    COUNT(DISTINCT(sod.ProductID)) AS LiczbaRoznychProduktow,
    SUM(sod.LineTotal) AS SumaSprzedazy
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod 
    ON soh.SalesOrderID = sod.SalesOrderID
GROUP BY ROLLUP(YEAR(soh.OrderDate), MONTH(soh.OrderDate), DAY(soh.OrderDate));

--14
SELECT
    YEAR(soh.OrderDate) AS Rok,
    CASE DATEPART(dw, soh.OrderDate)
        WHEN 1 THEN 'Niedziela'
        WHEN 2 THEN 'Poniedzialek'
        WHEN 3 THEN 'Wtorek'
        WHEN 4 THEN 'Sroda'
        WHEN 5 THEN 'Czwartek'
        WHEN 6 THEN 'Piatek'
        WHEN 7 THEN 'Sobota'
    END AS DzienTygodnia,
    COUNT(DISTINCT(sod.ProductID)) AS LiczbaRoznychProduktow,
    SUM(sod.LineTotal) AS SumaSprzedazy
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod 
    ON soh.SalesOrderID = sod.SalesOrderID
GROUP BY ROLLUP(YEAR(soh.OrderDate), DATEPART(dw, soh.OrderDate))
ORDER BY Rok, DATEPART(dw, soh.OrderDate);

--mod, nie wypisuje 2 które się nie sprzedały, trzeba by right join zrobić
SELECT
    ps.Name AS Podkategoria,
    pc.Name AS Kategoria,
    COUNT(DISTINCT(p.ProductID)) AS LiczbaProduktow,
    SUM(sod.OrderQty) AS Sprzedaz
FROM Production.Product p
JOIN Production.ProductSubcategory ps
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN Production.ProductCategory pc
    ON ps.ProductCategoryID = pc.ProductCategoryID
JOIN Sales.SalesOrderDetail sod
    ON sod.ProductID = p.ProductID
GROUP BY GROUPING SETS ((pc.Name, ps.Name))
ORDER BY pc.Name, Sprzedaz DESC;

--ilosc klientow danego rodzaju w danym miesiacu i roku
SELECT
    YEAR(soh.OrderDate) AS Rok,
    MONTH(soh.OrderDate) AS Miesiac,
    p.PersonType AS RodzajKlienta,
    COUNT(DISTINCT(soh.CustomerID)) AS LiczbaKlientow
FROM Sales.SalesOrderHeader soh
JOIN Sales.Customer c
    ON soh.CustomerID = c.CustomerID
JOIN Person.Person p
    ON c.PersonID = p.BusinessEntityID
GROUP BY YEAR(soh.OrderDate), MONTH(soh.OrderDate), p.PersonType
ORDER BY Rok, Miesiac, RodzajKlienta;

--łączna wartość sprzedaży per kategoria
SELECT
    pc.Name AS Kategoria,
    SUM(sod.LineTotal) AS WartoscSprzedazy
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p
    ON sod.ProductID = p.ProductID
JOIN Production.ProductSubcategory ps
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN Production.ProductCategory pc
    ON ps.ProductCategoryID = pc.ProductCategoryID
GROUP BY pc.Name
ORDER BY WartoscSprzedazy DESC;