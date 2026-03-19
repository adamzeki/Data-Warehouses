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
-- Klienci na miesiąc
SELECT 
    YEAR(OrderDate) AS Rok, 
    MONTH(OrderDate) AS Miesiac, 
    GrupaWiekowa, 
    COUNT(DISTINCT CustomerID) AS LiczbaKlientow
FROM (
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

-- Jednorazowi klienci
SELECT 
    GrupaWiekowa,
    COUNT(*) AS LiczbaKlientowJednorazowych
FROM (
    SELECT 
        soh.CustomerID,
        CASE 
            WHEN DATEDIFF(YEAR, vpd.BirthDate, '2026-01-01') < 50 THEN '<50'
            WHEN DATEDIFF(YEAR, vpd.BirthDate, '2026-01-01') BETWEEN 50 AND 70 THEN '50-70'
            ELSE '70+'
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
-- Klienci na miesiąc
WITH Segmentacja AS (
    SELECT 
        c.CustomerID,
        CASE
            WHEN DATEDIFF(YEAR, BirthDate, '2026-01-01') < 50 THEN '<50'
            WHEN DATEDIFF(YEAR, BirthDate, '2026-01-01') BETWEEN 50 AND 70 THEN '50-70'
            ELSE '70+'
        END AS GrupaWiekowa
    FROM Sales.vPersonDemographics vpd
    JOIN Sales.Customer c 
        ON vpd.BusinessEntityID = c.PersonID
),
ZakupyKlientow AS (
    SELECT 
        soh.CustomerID,
        soh.SalesOrderID,
        seg.GrupaWiekowa,
        YEAR(soh.OrderDate) AS Rok,
        MONTH(soh.OrderDate) AS Miesiac
    FROM Sales.SalesOrderHeader soh
    JOIN Segmentacja seg
        ON seg.CustomerID = soh.CustomerID
)
SELECT 
    Rok, 
    Miesiac, 
    GrupaWiekowa, 
    COUNT(DISTINCT CustomerID) AS LiczbaUnikalnychKlientow
FROM ZakupyKlientow
GROUP BY Rok, Miesiac, GrupaWiekowa
ORDER BY Rok, Miesiac, GrupaWiekowa;

-- Jednorazowi klienci
WITH Segmentacja AS (
    SELECT 
        c.CustomerID,
        CASE
            WHEN DATEDIFF(YEAR, BirthDate, '2026-01-01') < 50 THEN '<50'
            WHEN DATEDIFF(YEAR, BirthDate, '2026-01-01') BETWEEN 50 AND 70 THEN '50-70'
            ELSE '70+'
        END AS GrupaWiekowa
    FROM Sales.vPersonDemographics vpd
    JOIN Sales.Customer c 
        ON vpd.BusinessEntityID = c.PersonID
),
LiczbaZakupow AS (
    SELECT 
        soh.CustomerID,
        seg.GrupaWiekowa,
        COUNT(soh.SalesOrderID) AS IleRazy
    FROM Sales.SalesOrderHeader soh
    JOIN Segmentacja seg
        ON seg.CustomerID = soh.CustomerID
    GROUP BY soh.CustomerID, seg.GrupaWiekowa
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
--4 
--bez CTE
SELECT
    vpd.Gender AS Plec,
    YEAR(soh.OrderDate) AS Rok,
    MONTH(soh.OrderDate) AS Miesiac,
    COUNT(DISTINCT soh.CustomerID) AS LiczbaKlientow,
    SUM(soh.TotalDue) * 100.0 / SUM(SUM(soh.TotalDue)) OVER(YEAR(soh.OrderDate), MONTH(soh.OrderDate)) AS UdzialSprzedazy
FROM Sales.vPersonDemographics vpd
JOIN Sales.Customer c
    ON c.PersonID = vpd.BusinessEntityID
JOIN Sales.SalesOrderHeader soh
    ON soh.CustomerID = c.CustomerID
GROUP BY vpd.Gender, YEAR(soh.OrderDate), MONTH(soh.OrderDate)
ORDER BY Rok, Miesiac, Plec;

-- CTE
WITH SprzedazPlci AS (
    SELECT
        vpd.Gender AS Plec,
        YEAR(soh.OrderDate) AS Rok,
        MONTH(soh.OrderDate) AS Miesiac,
        COUNT(DISTINCT soh.CustomerID) AS LiczbaKlientow,
        SUM(soh.TotalDue) AS SumaMiesieczna
    FROM Sales.vPersonDemographics vpd
    JOIN Sales.Customer c
        ON c.PersonID = vpd.BusinessEntityID
    JOIN Sales.SalesOrderHeader soh
        ON soh.CustomerID = c.CustomerID
)
SELECT
    Plec,
    Rok,
    Miesiac,
    LiczbaKlientow,
    SumaMiesieczna * 100.0 / SUM(SumaMiesieczna) OVER(PARTITION BY Rok, Miesiac) AS UdzialProcentowy
FROM SprzedazPlci
 
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