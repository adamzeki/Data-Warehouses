--1
WITH SredniaWartosc AS (
    SELECT AVG(SubTotal) AS GlobalnaSrednia
    FROM Sales.SalesOrderHeader
),
TransakcjeInfo AS (
    SELECT 
        soh.CustomerID,
        soh.SalesOrderID,
        soh.SubTotal,
        CASE WHEN soh.SubTotal > 2.5 * (SELECT GlobalnaSrednia FROM SredniaWartosc) THEN 1 ELSE 0 END AS CzyDuza,
        COUNT(DISTINCT pc.ProductCategoryID) AS LiczbaKategoriiWTransakcji
    FROM Sales.SalesOrderHeader soh
    JOIN Sales.SalesOrderDetail sod 
        ON soh.SalesOrderID = sod.SalesOrderID
    JOIN Production.Product p 
        ON sod.ProductID = p.ProductID
    JOIN Production.ProductSubcategory ps 
        ON p.ProductSubcategoryID = ps.ProductSubcategoryID
    JOIN Production.ProductCategory pc 
        ON ps.ProductCategoryID = pc.ProductCategoryID
    GROUP BY soh.CustomerID, soh.SalesOrderID, soh.SubTotal
),
StatyKlientow AS (
    SELECT 
        p.FirstName AS Imie,
        p.LastName AS Nazwisko,
        COUNT(ti.SalesOrderID) AS LiczbaTransakcji,
        SUM(ti.SubTotal) AS LacznaKwota,
        SUM(ti.CzyDuza) AS LiczbaDuzychTransakcji,
        MAX(CASE WHEN ti.LiczbaKategoriiWTransakcji = 4 THEN 1 ELSE 0 END) AS CzyKupilWszystkoNaraz
    FROM Sales.Customer c
    JOIN Person.Person p 
        ON c.PersonID = p.BusinessEntityID
    JOIN TransakcjeInfo ti 
        ON c.CustomerID = ti.CustomerID
    GROUP BY p.FirstName, p.LastName, c.CustomerID
)
SELECT 
    Imie, 
    Nazwisko, 
    LiczbaTransakcji, 
    LacznaKwota,
    CASE 
        WHEN LiczbaTransakcji >= 4 AND LiczbaDuzychTransakcji >= 2 AND CzyKupilWszystkoNaraz = 1 THEN 'Platynowa'
        WHEN LiczbaTransakcji >= 4 AND LiczbaDuzychTransakcji >= 2 THEN 'Zlota'
        WHEN LiczbaTransakcji >= 2 THEN 'Srebrna'
        ELSE 'Brak karty'
    END AS [Kolor karty]
FROM StatyKlientow
ORDER BY LacznaKwota DESC;

--2

--2.1
--ROLLUP
SELECT
    YEAR(soh.OrderDate) AS Rok,
    soh.CustomerID AS IDKlienta,
    SUM(soh.SubTotal) AS LacznaKwota
FROM Sales.SalesOrderHeader soh
GROUP BY ROLLUP (YEAR(soh.OrderDate), soh.CustomerID)
ORDER BY Rok, IDKlienta;

--CUBE
SELECT
    YEAR(soh.OrderDate) AS Rok,
    soh.CustomerID AS IDKlienta,
    SUM(soh.SubTotal) AS LacznaKwota
FROM Sales.SalesOrderHeader soh
GROUP BY CUBE (YEAR(soh.OrderDate), soh.CustomerID)
ORDER BY Rok, IDKlienta;

--GROUPING SETS
SELECT
    YEAR(soh.OrderDate) AS Rok,
    soh.CustomerID AS IDKlienta,
    SUM(soh.SubTotal) AS LacznaKwota
FROM Sales.SalesOrderHeader soh
GROUP BY GROUPING SETS (
    (YEAR(soh.OrderDate), soh.CustomerID),
    (YEAR(soh.OrderDate)),
    ()
)
ORDER BY Rok, IDKlienta;

--2.2
SELECT 
    pc.Name AS Kategoria,
    p.Name AS Produkt,
    YEAR(soh.OrderDate) AS Rok,
    SUM(sod.UnitPrice * sod.OrderQty * sod.UnitPriceDiscount) AS SumaZnizek
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod 
    ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product p 
    ON sod.ProductID = p.ProductID
JOIN Production.ProductSubcategory ps 
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN Production.ProductCategory pc 
    ON ps.ProductCategoryID = pc.ProductCategoryID
GROUP BY ROLLUP (pc.Name, p.Name, YEAR(soh.OrderDate))
ORDER BY Kategoria, Produkt, Rok;


--3

--3.1
WITH SprzedazProduktow AS (
    SELECT 
        pc.Name AS Kategoria,
        p.Name AS Produkt,
        YEAR(soh.OrderDate) AS Rok,
        SUM(sod.LineTotal) AS SumaProduktu
    FROM Sales.SalesOrderDetail sod
    JOIN Production.Product p 
        ON sod.ProductID = p.ProductID
    JOIN Production.ProductSubcategory ps 
        ON p.ProductSubcategoryID = ps.ProductSubcategoryID
    JOIN Production.ProductCategory pc 
        ON ps.ProductCategoryID = pc.ProductCategoryID
    JOIN Sales.SalesOrderHeader soh
        ON sod.SalesOrderID = soh.SalesOrderID
    WHERE pc.Name = 'Bikes'
    GROUP BY pc.Name, p.Name, YEAR(soh.OrderDate)
)
SELECT 
    Rok,
    Produkt,
    Kategoria,
    SumaProduktu,
    SUM(SumaProduktu) OVER(PARTITION BY Kategoria, Rok) AS SumaCalkowitaKategorii,
    (SumaProduktu * 100.0 / SUM(SumaProduktu) OVER(PARTITION BY Kategoria, Rok)) AS UdzialProcentowy
FROM SprzedazProduktow
ORDER BY Rok, UdzialProcentowy DESC;

--3.2

--3.3
SELECT 
    soh.CustomerID AS IDKlienta,
    SUM(sod.OrderQty) AS IloscProduktow,
    SUM(soh.SubTotal) AS LacznaKwota,
    DENSE_RANK() OVER (ORDER BY SUM(soh.SubTotal) DESC) AS GestaRanga,
    RANK() OVER (ORDER BY SUM(soh.SubTotal) DESC) AS Ranga
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod
    ON soh.SalesOrderID = sod.SalesOrderID
GROUP BY soh.CustomerID
ORDER BY Ranga;

--3.4
WITH Sprzedaz AS(
    SELECT
        p.Name AS Produkt,
        AVG(sod.OrderQty) AS SredniaIlosc
    FROM Sales.SalesOrderDetail sod
    JOIN Production.Product p
        ON sod.ProductID = p.ProductID
    GROUP BY p.Name
)
SELECT
    Produkt,
    SredniaIlosc,
    CASE NTILE(3) OVER (ORDER BY SredniaIlosc DESC)
        WHEN 1 THEN 'Najlepsze'
        WHEN 2 THEN 'Srednie'
        ELSE 'Slabe'
    END AS Ranga
FROM Sprzedaz
ORDER BY SredniaIlosc DESC;