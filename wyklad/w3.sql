--1
WITH Sprzedaz AS (
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
        soh.SubTotal
    FROM Sales.SalesOrderHeader soh
)
SELECT *
FROM Sprzedaz
PIVOT (
    SUM(SubTotal) 
    FOR DzienTygodnia IN ([Poniedzialek], [Wtorek], [Sroda], [Czwartek], [Piatek], [Sobota], [Niedziela])
) AS PivotResult
ORDER BY Rok;

--bez CTE
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
    SUM(soh.SubTotal)
FROM Sales.SalesOrderHeader soh
GROUP BY YEAR(soh.OrderDate), DATEPART(dw, soh.OrderDate)
ORDER BY Rok, DATEPART(dw, soh.OrderDate);

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

--2

--bez CTE
SELECT 
    YEAR(OrderDate) AS Rok, 
    MONTH(OrderDate) AS Miesiac, 
    GrupaWiekowa, 
    COUNT(DISTINCT CustomerID) AS LiczbaKlientow
FROM (
    -- Podzapytanie przygotowujące segmentację
    SELECT 
        soh.OrderDate, 
        soh.CustomerID,
        CASE 
            WHEN DATEDIFF(YEAR, vpd.BirthDate, '2026-01-01') < 50 THEN '<50'
            WHEN DATEDIFF(YEAR, vpd.BirthDate, '2026-01-01') BETWEEN 50 AND 70 THEN '50-70'
            ELSE '70+60)'
        END AS GrupaWiekowa
    FROM Sales.SalesOrderHeader AS soh
    JOIN Sales.Customer AS c ON soh.CustomerID = c.CustomerID
    JOIN Sales.vPersonDemographics AS vpd ON c.PersonID = vpd.BusinessEntityID
) AS DaneBazowe
GROUP BY YEAR(OrderDate), MONTH(OrderDate), GrupaWiekowa
ORDER BY Rok, Miesiac, GrupaWiekowa;

SELECT 
    GrupaWiekowa, 
    COUNT(*) AS LiczbaKlientowJednorazowych
FROM (
    -- Podzapytanie liczące historię zakupów każdego klienta
    SELECT 
        soh.CustomerID,
        CASE 
            WHEN DATEDIFF(YEAR, vpd.BirthDate, '2026-01-01') < 40 THEN '1. Mlodzi (<40)'
            WHEN DATEDIFF(YEAR, vpd.BirthDate, '2026-01-01') BETWEEN 40 AND 60 THEN '2. Sredni (40-60)'
            ELSE '3. Seniorzy (>60)'
        END AS GrupaWiekowa,
        COUNT(soh.SalesOrderID) AS IleRazy
    FROM Sales.SalesOrderHeader AS soh
    JOIN Sales.Customer AS c ON soh.CustomerID = c.CustomerID
    JOIN Sales.vPersonDemographics AS vpd ON c.PersonID = vpd.BusinessEntityID
    GROUP BY soh.CustomerID, vpd.BirthDate
) AS Statystyki
WHERE IleRazy = 1
GROUP BY GrupaWiekowa;

--CTE
WITH Segmentacja AS (
    SELECT 
        BusinessEntityID,
        CASE
            WHEN DATEDIFF(YEAR, BirthDate, '2026-01-01') < 50 THEN '<50'
            WHEN DATEDIFF(YEAR, BirthDate, '2026-01-01') BETWEEN 50 AND 70 THEN '50-70'
            ELSE '70+'
        END AS GrupaWiekowa
    FROM Sales.vPersonDemographics
),
ZakupyKlientow AS (
    SELECT 
        s.CustomerID,
        s.SalesOrderID,
        seg.GrupaWiekowa,
        YEAR(s.OrderDate) AS Rok,
        MONTH(s.OrderDate) AS Miesiac
    FROM Sales.SalesOrderHeader s
    JOIN Sales.Customer c ON s.CustomerID = c.CustomerID
    JOIN Segmentacja seg ON c.PersonID = seg.BusinessEntityID
)
SELECT 
    Rok, 
    Miesiac, 
    GrupaWiekowa, 
    COUNT(DISTINCT CustomerID) AS LiczbaUnikalnychKlientow
FROM ZakupyKlientow
GROUP BY Rok, Miesiac, GrupaWiekowa
ORDER BY Rok, Miesiac, GrupaWiekowa;

WITH Segmentacja AS (
    SELECT 
        BusinessEntityID,
        CASE
            WHEN DATEDIFF(YEAR, BirthDate, '2026-01-01') < 50 THEN '<50'
            WHEN DATEDIFF(YEAR, BirthDate, '2026-01-01') BETWEEN 50 AND 70 THEN '50-70'
            ELSE '70+'
        END AS GrupaWiekowa
    FROM Sales.vPersonDemographics
),
LiczbaZakupow AS (
    SELECT 
        s.CustomerID,
        seg.GrupaWiekowa,
        COUNT(s.SalesOrderID) AS IleRazy
    FROM Sales.SalesOrderHeader s
    JOIN Sales.Customer c ON s.CustomerID = c.CustomerID
    JOIN Segmentacja seg ON c.PersonID = seg.BusinessEntityID
    GROUP BY s.CustomerID, seg.GrupaWiekowa
)
SELECT 
    GrupaWiekowa, 
    COUNT(*) AS LiczbaKlientowJednorazowych
FROM LiczbaZakupow
WHERE IleRazy = 1
GROUP BY GrupaWiekowa;

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

--3
--bez CTE
SELECT
    p.Name AS Produkt,
    pc.Name AS Kategoria
FROM Production.Product p
JOIN Production.ProductSubcategory ps
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN Production.ProductCategory pc
    ON pc.ProductCategoryID = ps.ProductCategoryID
JOIN Sales.SalesOrderDetail sod
    ON p.ProductID = sod.ProductID
JOIN Sales.SalesOrderHeader soh
    ON soh.SalesOrderID = sod.SalesOrderID
GROUP BY p.Name, pc.Name, YEAR(soh.OrderDate), MONTH(soh.OrderDate)
HAVING SUM(sod.OrderQty) > 19
ORDER BY Kategoria, Produkt;

--z CTE
WITH CTE AS (
    SELECT
        sod.ProductID AS ID
    FROM Sales.SalesOrderDetail sod
    JOIN Sales.SalesOrderHeader soh
        ON soh.SalesOrderID = sod.SalesOrderID
    GROUP BY YEAR(soh.OrderDate), MONTH(soh.OrderDate), sod.ProductID
    HAVING SUM(sod.OrderQty) > 19
)
SELECT
    p.Name AS Produkt,
    pc.Name AS Kategoria
FROM CTE c
JOIN Production.Product p
    ON p.ProductID = c.ProductID
JOIN Production.ProductSubcategory ps
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN Production.ProductCategory pc
    ON pc.ProductCategoryID = ps.ProductCategoryID
GROUP BY p.Name, pc.Name
ORDER BY Kategoria, Produkt;

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

--5
WITH SprzedazPodkategorii AS (
    SELECT
        p.ProductSubcategoryID AS psID,
        SUM(sod.OrderQty) AS SztukiPodkategoria,
        SUM(sod.LineTotal) AS SprzedazPodkategoria
    FROM Sales.SalesOrderDetail sod
    JOIN Production.Product p
        ON p.ProductID = sod.ProductID
    GROUP BY p.ProductSubcategoryID
)
SELECT
    pc.Name AS Kategoria,
    ps.Name AS Podkategoria,
    SztukiPodkategoria,
    SUM(SztukiPodkategoria) OVER(PARTITION BY pc.ProductCategoryID) AS SztukiKategoria,
    100.0 * SztukiPodkategoria / SUM(SztukiPodkategoria) OVER(PARTITION BY pc.ProductCategoryID) AS UdzialIlosciowy,
    SprzedazPodkategoria,
    SUM(SprzedazPodkategoria) OVER(PARTITION BY pc.ProductCategoryID) AS SprzedazKategoria,
    100.0 * SprzedazPodkategoria / SUM(SprzedazPodkategoria) OVER(PARTITION BY pc.ProductCategoryID) AS UdzialKwotowy
FROM SprzedazPodkategorii
JOIN Production.ProductSubcategory ps 
    ON ps.ProductSubcategoryID = psID
JOIN Production.ProductCategory pc 
    ON pc.ProductCategoryID = ps.ProductCategoryID
ORDER BY Kategoria, UdzialKwotowy DESC;

--bez CTE
SELECT
    pc.Name AS Kategoria,
    ps.Name AS Podkategoria,
    SUM(sod.OrderQty) AS SztukiPodkategoria,
    SUM(SUM(sod.OrderQty)) OVER(PARTITION BY pc.ProductCategoryID) AS SztukiKategoria,
    100.0 * SUM(sod.OrderQty) / SUM(SUM(sod.OrderQty)) OVER(PARTITION BY pc.ProductCategoryID) AS UdzialIlosciowy,
    SUM(sod.LineTotal) AS SprzedazPodkategoria,
    SUM(SUM(sod.LineTotal)) OVER(PARTITION BY pc.ProductCategoryID) AS SprzedazKategoria,
    100.0 * SUM(sod.LineTotal) / SUM(SUM(sod.LineTotal)) OVER(PARTITION BY pc.ProductCategoryID) AS UdzialKwotowy
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p 
    ON p.ProductID = sod.ProductID
JOIN Production.ProductSubcategory ps 
    ON ps.ProductSubcategoryID = p.ProductSubcategoryID
JOIN Production.ProductCategory pc 
    ON pc.ProductCategoryID = ps.ProductCategoryID
GROUP BY pc.ProductCategoryID, pc.Name, ps.Name
ORDER BY Kategoria, UdzialKwotowy DESC;

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

--6