--Kompression
--für Client komplett transparent (bei SELECT, INSERT, UPDATE, DELETE, ...)
--Abfragen dauern etwas länger (mehr CPU benötigt)
--Daten benötigen weniger Speicherplatz

--Zwei verschiedene Typen:
--Row Compression
--> 40-60% Kompressionsrate

--Page Compression
--> 60-70% Kompressionsrate

USE Northwind;

--SELECT        Employees.LastName, Employees.FirstName, Employees.BirthDate, Employees.HireDate, Employees.Address, Employees.City, Employees.Region, Employees.PostalCode, Employees.Country, Employees.HomePhone, 
--                         Employees.Salary, Orders.OrderDate, Orders.RequiredDate, Orders.ShippedDate, Orders.OrderID, Employees.EmployeeID AS Expr1, Orders.Freight, Shippers.ShipperID AS Expr2, Shippers.CompanyName AS Expr3, 
--                         Shippers.Phone AS Expr4, Products.ProductID, Products.ProductName, Products.QuantityPerUnit, Products.UnitPrice, [Order Details].OrderID AS Expr5, [Order Details].ProductID AS Expr6, [Order Details].Quantity, 
--                         [Order Details].Discount, [Order Details].UnitPrice AS Expr7, Customers.CustomerID, Customers.CompanyName, Customers.ContactName, Customers.ContactTitle, Customers.Address AS Expr8, Customers.City AS Expr9, 
--                         Customers.Region AS Expr10, Customers.PostalCode AS Expr11, Customers.Country AS Expr12, Customers.Phone, Customers.Fax
--INTO KundenUmsatz
--FROM            Customers INNER JOIN
--                         Orders ON Customers.CustomerID = Orders.CustomerID INNER JOIN
--                         Employees ON Orders.EmployeeID = Employees.EmployeeID INNER JOIN
--                         [Order Details] ON Orders.OrderID = [Order Details].OrderID INNER JOIN
--                         Products ON [Order Details].ProductID = Products.ProductID INNER JOIN
--                         Shippers ON Orders.ShipVia = Shippers.ShipperID

USE Demo2;

--SELECT * INTO KundenUmsatz
--FROM Northwind.dbo.KundenUmsatz

INSERT INTO KundenUmsatz
SELECT * FROM KundenUmsatz
GO 10

--Rechtsklick auf Tabelle -> Storage -> Manage Compression

SET STATISTICS TIME, IO ON;

--Ohne Kompression
SELECT * FROM KundenUmsatz;
--logische Lesevorgänge: 179821, CPU-Zeit = 4484 ms, verstrichene Zeit = 37644 ms

--Row Compression
--1.4GB -> 785MB: 44%
SELECT * FROM KundenUmsatz;
--logische Lesevorgänge: 100114, CPU-Zeit = 5875 ms, verstrichene Zeit = 38515 ms

--Page Compression
--782MB -> 390MB: 50%
--1.4GB -> 390MB: 73%
SELECT * FROM KundenUmsatz;
--logische Lesevorgänge: 48580, CPU-Zeit = 9563 ms, verstrichene Zeit = 39223 ms