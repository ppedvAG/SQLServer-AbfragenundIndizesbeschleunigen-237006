--Partitionierung
--Ermöglicht, die automatische Aufteilung in "mehrere" Tabellen
--> Aufteilung in logische Partitionen

--Benötigt eine Partition und ein Schema

--Partitionsfunktion
--Nimmt einen Wert als Parameter und findet die Partition in den dieser Wert hinein kommen würde

USE Demo2;

CREATE PARTITION FUNCTION pf_ID(int) AS --Name: pf_ID + Datentyp (kann int, date, varchar, ... sein)
RANGE LEFT FOR VALUES (100, 200); --Mit RANGE LEFT/RIGHT die Funktion links oder rechts orientieren

--Partitionsfunktion testen
SELECT $partition.pf_ID(10); --Partition 1
SELECT $partition.pf_ID(110); --Partition 2
SELECT $partition.pf_ID(210); --Partition 3
SELECT $partition.pf_ID(-10); --Partition 1
SELECT $partition.pf_ID(NULL); --Partition 1

--Partitionsschema
--Ermöglicht die tatsächliche Partitionierung der Datensätze
--Bei INSERT, UPDATE wird das Schema befragt, welche Partition den DS enthalten soll
--Das Schema befragt die Funktion
--Tabellen können auf das Schema gelegt werden

--Das Partitionsschema benötigt Dateigruppen
CREATE PARTITION SCHEME sch_ID AS
PARTITION pf_ID TO (R1, R2, R3) --Hier muss immer eine Dateigruppe mehr angegeben werden als die Partitionsfunktion vorgibt
--bis 100
--100 bis 200
--ab 200

--Partitionierung anwenden
CREATE TABLE pTable (id int identity, test char(5000))
ON sch_ID(id); --Hier bei Erstellung der Tabelle das Partitionsschema vorgeben

INSERT INTO pTable
SELECT 'XYZ'
GO 20000

--R1 und R2 sind 8MB groß, R3 ist 200MB groß

SET STATISTICS TIME, IO ON;

SELECT * FROM pTable WHERE id = 50 --Nur Partition 1 wurde durchsucht, weil 50 nur in P1 sein kann
SELECT * FROM pTable WHERE id = 150 --Nur Partition 2 wurde durchsucht, weil 150 nur in P2 sein kann
SELECT * FROM pTable WHERE id = 250 --Partition 3 wurde durchsucht, logische Lesevorgänge: 19800

SELECT * FROM pTable WHERE test = 'aaa' --20000

ALTER PARTITION SCHEME sch_ID NEXT USED R4; --Schema muss vor der Partition angepasst werden
ALTER PARTITION FUNCTION pf_ID() SPLIT RANGE (300) --Neuen Bereich hinzufügen

SELECT $partition.pf_ID(500); --4

SELECT * FROM pTable WHERE id = 250

SELECT COUNT(*) FROM pTable GROUP BY $partition.pf_ID(ID) --Anzahl DS pro Partition einsehen
SELECT * FROM pTable WHERE $partition.pf_ID(ID) = 2 --Datensätze in einer entsprechenden Partition suchen

DELETE
FROM pTable
WHERE id IN(SELECT *
			FROM pTable
			WHERE $partition.pf_ID(ID) = 2) --Datensätze einer Partition löschen

--Archiv Tabelle
--Muss auf der selben Partition liegen
--Muss leer sein
SELECT TOP 0 *
INTO Archiv ON R2
FROM pTable;

ALTER TABLE pTable SWITCH PARTITION 1 TO Archiv;

--Alternative
INSERT INTO Archiv
SELECT * FROM pTable
WHERE $partition.pf_ID(ID) = 1;

DELETE FROM pTable
WHERE $partition.pf_ID(ID) = 1;

CREATE TABLE Archiv
(
	id int,
	test char(5100)
);

--Prozedur
GO
CREATE PROC move_data @part int AS
BEGIN

INSERT INTO Archiv
SELECT * FROM pTable
WHERE $partition.pf_ID(ID) = @part;

DELETE FROM pTable
WHERE $partition.pf_ID(ID) = @part;

ALTER DATABASE Demo2
REMOVE FILEGROUP R1;

ALTER DATABASE Demo2
REMOVE FILE R1;

END
GO

EXEC move_data @part = 1