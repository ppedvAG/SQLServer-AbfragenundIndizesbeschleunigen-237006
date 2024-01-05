/*
	Normalerweise:
	1. Jede Zelle sollte genau einen Wert haben
	2. Jeder Datensatz sollte einen Primärschlüssel haben
	3. Keine Beziehungen zwischen nicht-Schlüssel Spalten

	Redundanz verringern (Daten nicht doppelt speichern)
	-> Beziehungen zwischen Tabellen
	-> Große Tabellen in mehrere kleine Tabellen aufteilen
	
	Kundentabelle: 1 Mio. DS
	Bestellungen: 100 Mio. DS
	Kunden <-> Beziehung <-> Bestellungen
*/

/*
	Seite:
	8192B (8KB) Größe
	132B sind für Management Daten
	8060B für tatsächliche Daten

	Seiten werden immer 1:1 von der Datenbank geladen (keine halben Seiten)

	Max. 700DS pro Seite
	Datensätze müssen auf eine Seite passen
	Leerer Raum darf existieren, sollte aber vermieden werden
*/

CREATE DATABASE Demo2;
USE Demo2;

CREATE TABLE T1 (id int identity, test char(4100)); --Absichtlich ineffiziente Tabelle

INSERT INTO T1
SELECT 'XYZ'
GO 20000 --GO <Anzahl>: Befehl X-mal ausführen

SELECT * FROM T1;

--dbcc: Database Console Commands
dbcc showcontig('T1')

--20000 Seiten obwohl nur 7 Byte pro Datensatz (4 für ID, 3 für Text)
--char hat eine fixe Länge (hier 4100B)
CREATE TABLE T2 (id int identity, test varchar(4100));

INSERT INTO T2
SELECT 'XYZ'
GO 20000

dbcc showcontig('T2') --Hier nur 52 Seiten mit 95.01% Füllrate
--Hier wurde das Limit getroffen

CREATE TABLE T3 (id int identity, test nvarchar(MAX));

INSERT INTO T3
SELECT 'XYZ'
GO 20000

dbcc showcontig('T3') --logische Lesevorgänge: 60

CREATE TABLE T4 (id int identity, test varchar(MAX));

INSERT INTO T4
SELECT 'XYZ'
GO 20000

dbcc showcontig('T3') --logische Lesevorgänge: 52

------------------------------------------------------------------------------------------------------

--Statistiken zu Zeit und Leistung aktivieren
SET STATISTICS time, io ON --oder OFF zum ausschalten

SELECT * FROM T1; --logische Lesevorgänge: 20000, CPU-Zeit = 109 ms, verstrichene Zeit = 660 ms
SELECT * FROM T2; --logische Lesevorgänge: 52, CPU-Zeit = 0 ms, verstrichene Zeit = 102 ms

SELECT OBJECT_NAME(object_id), * FROM sys.dm_db_index_physical_stats(DB_ID(), 0, -1, 0, 'DETAILED');
--OBJECT_NAME(ID): Über eine ID den Namen dahinter herausfinden

SELECT OBJECT_ID('T1'); --Andere Richtung von OBJECT_NAME: Name -> ID

USE Northwind;
SELECT OBJECT_NAME(object_id), * FROM sys.dm_db_index_physical_stats(DB_ID(), 0, -1, 0, 'DETAILED')
WHERE index_type_desc = 'CLUSTERED INDEX';

--Northwind
--Customers Tabelle
--97% Füllgrad -> Sehr Gut (wenn über 70% akzeptabel, über 80% gut, über 90% sehr gut)
--Spalten mit n sind Unicode -> weniger effizient als ohne n
--n vor char Typen sollte nur verwendet werden wenn notwendig
--nvarchar: 16 Byte pro Datensatz, varchar: 8 Byte pro Datensatz
--Country, Phone und Fax werden nur ASCII Character enthalten
--> Weniger Seiten, weniger Laden, weniger Dauer, mehr Performance
dbcc showcontig('Customers')

USE Northwind;

--INFORMATION_SCHEMA: Enthält viele Informationen zur gesamten Datenbank
SELECT * FROM INFORMATION_SCHEMA.COLUMNS;
SELECT * FROM INFORMATION_SCHEMA.TABLES;

--TOP
USE Demo2;
SELECT * FROM T1 WHERE id = 100; --logische Lesevorgänge: 20000
--Nachdem id ein PK ist, kann nur ein DS mit id 100 vorkommen

SELECT TOP 1 * FROM T1 WHERE id = 100; --logische Lesevorgänge: 100
--Mit TOP wird beim 1. DS aufgehört -> 100 Lesevorgänge statt 20000

CREATE TABLE T5 (id int identity unique, test char(4100));

INSERT INTO T5
SELECT 'XYZ'
GO 20000

SELECT * FROM T5 WHERE id = 100; --Auch unique sorgt dafür, das die Datenbank beim 1. DS aufhört

CREATE TABLE T6 (id int identity primary key, test char(4100));

INSERT INTO T6
SELECT 'XYZ'
GO 20000

SELECT * FROM T6 WHERE id = 100; --Auch PK sorgt dafür, das die Datenbank beim 1. DS aufhört

--Datentyp
--char: fixe Länge (1B pro Zeichen)
--varchar: variable Länge (1B pro Zeichen)
--mit n doppelter Speicherverbrauch weil Unicode (2B pro Zeichen)
--text: nicht verwenden, stattdessen VARCHAR(MAX)

--Numerische Datentypen
--int: 4B, häufig für Schlüsselspalten verwendet (möglicherweise ineffizient)
--tinyint: 1B, smallint: 2B, bigint: 8B -> In die Zukunft schauen/Vorhersagen treffen

--money, smallmoney: 8 Byte vs. 4 Byte

--float: 4B bei kleinen Zahlen, 8B bei großen Zahlen
--decimal(X, Y): je weniger Platz desto weniger Speicherverbrauch

--Datumswerte
--Datetime: 8B
--Date: 3B
--Time: 3B-5B (wenn Nanosekunden existieren)

--Files hinter der Datenbank
--C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA
--Tabellen können auf verschiedene Files und in weiterer Folge auf verschiedene Datenträger gelegt werden

CREATE DATABASE Demo3
USE Demo3;
CREATE TABLE T(id int identity primary key, text char(4100))

begin transaction;
INSERT INTO T
SELECT 'XYZ'
GO 20000
commit; --7s

begin transaction;
declare @i int;
SET @i = 0;
while @i < 20000
BEGIN
	INSERT INTO T SELECT 'XYZ';
	SET @i = @i + 1;
END
commit;

TRUNCATE TABLE T;

SELECT * FROM T;