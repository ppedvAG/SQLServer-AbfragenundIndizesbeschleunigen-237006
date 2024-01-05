USE Demo2;

/*
	Table Scan: Durchsuchen des gesamten Tables
	Index Scan: Durchsuchen eines Indizes (besser als Table Scan)
	Index Seek: Gezieltes Suchen innerhalb eines Indizes (bestes)

	Clustered Index (CIX):
	Maximal einmal pro Tabelle
	Wenn ein eingefügt oder verändert wird, wird die Indexspalte sortiert
	-> Kostet bei großen Tabellen viel Performance
	Bei einem PK wird dieser Index automatisch erstellt

	Non-Clustered Index (NCIX):
	Der Standardindex
	Maximal 1000 Stück pro Tabelle
	Funktioniert wie CIX aber ohne Sortierung
	Der NCIX sollte auf häufig verwendete Statements angepasst werden (z.B. Prozeduren, ...)
*/

--Clustered Index
INSERT INTO Northwind.dbo.Customers (CustomerID, CompanyName) VALUES ('PPEDV', 'ppedv AG') --Clustered Index Insert (automatische Sortierung, Kosten 0.05)
DELETE FROM Northwind.dbo.Customers WHERE CustomerID = 'PPEDV' --Clustered Index Delete (Kosten: 0.05)
SELECT * FROM Northwind.dbo.Customers WHERE CustomerID = 'ALFKI' --Clustered Index Seek (suche genau den Datensatz), Kosten: 0.0033

--Non-Clustered Index
SELECT * FROM KundenUmsatz; --Kosten 26 (Table Scan)
SELECT * FROM KundenUmsatz WHERE OrderID = 10248; --Kosten 25 (Table Scan)

--Index Key Columns: Die Spalte nach der Indiziert werden soll (die Spalte(n) im WHERE)
--Included Columns: Die Spalten die beim Index gefunden werden sollen (die Spalte(n) in SELECT)
SELECT * FROM KundenUmsatz WHERE OrderID = 10248; --Nach NCIX_OrderID haben wir Index Seek (gezielte Suche nach einem Wert, Kosten: 0.1)
SELECT OrderID, OrderDate, FirstName, LastName FROM KundenUmsatz WHERE OrderID = 10248; --Index Seek

--Kompression entfernen
SELECT *
INTO KU
FROM KundenUmsatz;

SET STATISTICS TIME, IO ON;

SELECT * FROM KU;
SELECT * FROM KU WHERE OrderID = 10248;

--Aufbau des Index
SELECT  OBJECT_NAME(object_id), *
FROM sys.dm_db_index_physical_stats(DB_ID(), 0, -1, 0, 'DETAILED')
WHERE object_id = 999322970;

--Index ist eine Baumstruktur
--Heap: 98353 Seiten
--1. Ebene: 99194 Seiten
--2. Ebene: 263 Seiten
--3. Ebene: Eine Seite (oberste)

--Bei einem Primary Key wird automatisch ein CIX hinzugefügt
ALTER TABLE KU ADD ID int identity primary key;

SELECT * FROM KU WHERE ID = 10000; --Clustered Index Seek
SELECT * FROM KU WHERE ID BETWEEN 10000 AND 15000; --Clustered Index Seek

SELECT * FROM KU; --Index Scan (keinen konkreten Unterschied zu Table Scan)
SELECT FirstName, LastName FROM KU; --Index Scan über den neuen Index mit nur First- und LastName

USE Northwind;

SELECT * FROM Orders
INNER JOIN Customers ON Orders.CustomerID = Customers.CustomerID;

SELECT * FROM Orders
INNER JOIN Customers ON Orders.CustomerID = Customers.CustomerID
WHERE Orders.OrderID = 10248; --Seek bei beiden Tabellen

SELECT * FROM Orders
INNER JOIN Customers ON Orders.CustomerID = Customers.CustomerID
WHERE Orders.OrderID > 10248; --Customers: Scan, Orders: Seek

USE Demo2;

SELECT ID, FirstName FROM KU WHERE Freight > 100; --Vorschlag der DB: Missing Index auf Freight mit FirstName
SELECT ID, FirstName FROM KU WHERE Freight > 1000; --Key Lookup: Seek mit mitnehmen bestimmer Spalten (schneller als Scan)

SELECT * FROM KU WHERE CustomerID LIKE 'A%'; --Bei Wildcards kann auch ein Seek angewandt werden
SELECT * FROM KU WHERE ID > 50 AND CustomerID LIKE 'A%'; --Index Seek
SELECT * FROM KU WHERE ID > 50 AND CustomerID LIKE 'A%'; --Index Scan nach Änderung der Reihenfolge der Key-Columns
--Der Key bei dem weniger DS herauskommen, sollte der erste Key sein
SELECT * FROM KU WHERE ID > 50 AND CustomerID LIKE '%A'; --Hier wieder Scan, nachdem der Anfang des Prädikats nicht bekannt ist

--Filtered Index
--Index mit Bedingung, Index wird nur verwendet, wenn die Bedingung gegeben ist
SELECT * FROM KU WHERE ID > 50; --Filtered Index
SELECT * FROM KU WHERE ID > 100; --Filtered Index
SELECT * FROM KU; --Index Scan auf OrderID IndexEffektiv Table Scan
SELECT * FROM KU WHERE ID > 40; --Effektiv Table Scan

--Indizierte View
--Auf eine View kann auch ein Index gelegt werden
--Nur möglich, wenn die View eine Schemabindung (WITH SCHEMABINDING)
GO
CREATE VIEW test WITH SCHEMABINDING AS --Sperrt die unterliegende Tabellenstruktur, sodass hier ein Index angewandt werden kann
SELECT Country, COUNT_BIG(*) AS Anz --COUNT_BIG um einen Index auf die View legen zu können
FROM dbo.KU
GROUP BY Country
GO

ALTER TABLE KU DROP COLUMN Country; --Country kann nicht gelöscht werden, weil die View test von Country abhängig ist

SELECT * FROM test WHERE Country = 'UK'; --Index Seek

--------------------------------------------------------------------

--Columnstore Index
--Beim Columnstore Index wird nicht die gesamte Tabelle indiziert, sondern nur einzelne Spalten
--Besonders nützlich bei Big Data Szenarien

--Nimmt alle Daten aus der Spalte, und legt diese sozusagen in einer eigenen "Tabelle" ab
--Diese Tabelle ist 2^20 (1048576) Zeilen lang und ab dem nächsten Wert wird eine neue Spalte angelegt
--Rest: Deltastore

SELECT *
INTO KUColumnStore
FROM KU;

INSERT INTO KUColumnStore
SELECT * FROM KUColumnStore
GO 4

--Darstellung:
--19.2M Datensätze -> [C1, C2, C3, ..., C18]
--300K Datensätze befinden sich im Deltastore

SELECT OrderID FROM KUColumnStore; --19.3M
--Kein Index
--Kosten: 1184, logische Lesevorgänge: 1570179, CPU-Zeit = 8656 ms, verstrichene Zeit = 58613 ms

SELECT OrderID FROM KUColumnStore;
--Normaler NC Index
--Kosten: 53, logische Lesevorgänge: 43122, CPU-Zeit = 3375 ms, verstrichene Zeit = 63942 ms

SELECT OrderID FROM KUColumnStore; --19.3M
--Columnstore Index
--Kosten: 2.1, logische LOB-Lesevorgänge: 15043, CPU-Zeit = 1313 ms, verstrichene Zeit = 58264 ms

SELECT  OBJECT_NAME(object_id), *
FROM sys.dm_db_index_physical_stats(DB_ID(), 0, -1, 0, 'DETAILED');

--Index auf häufig verwendete Abfragen anpassen
GO
CREATE PROC p_Test
AS
SELECT LastName, YEAR(OrderDate), MONTH(OrderDate), SUM(UnitPrice * Quantity)
FROM KU
WHERE Country = 'UK'
GROUP BY LastName, YEAR(OrderDate), MONTH(OrderDate)
ORDER BY 1, 2, 3;
GO

--Ohne Index
p_Test --Kosten 74, logische Lesevorgänge: 99608, CPU-Zeit = 434 ms, verstrichene Zeit = 135 ms

--Mit Index
p_Test --Kosten 2.05, logische Lesevorgänge: 2181, CPU-Zeit = 62 ms, verstrichene Zeit = 119 ms

--Indizes warten
--Über Zeit werden Indizes ungeordnet
--Reorganize oder Rebuild
---Avg. Fragmentation % senken (am besten bis 20% oder 0.2)
---Bei großen Tabellen ist oftmals ein Rebuild nötig
SELECT  OBJECT_NAME(object_id), *
FROM sys.dm_db_index_physical_stats(DB_ID(), 0, -1, 0, 'DETAILED')
WHERE index_type_desc LIKE '%INDEX%';

SELECT OBJECT_NAME(object_id), * FROM sys.indexes;

SELECT  OBJECT_NAME(p.object_id), i.name, p.*
FROM sys.dm_db_index_physical_stats(DB_ID(), 0, -1, 0, 'DETAILED') p
INNER JOIN sys.indexes i ON p.object_id = i.object_id
WHERE index_type_desc LIKE '%INDEX%' AND i.name IS NOT NULL;