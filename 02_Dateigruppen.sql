/*
	Dateigruppen:
	Erm�glichen, das Aufteilen der Datenbank auf verschiedene Dateien, und weitergehend auf verschiedene Datentr�ger
	[PRIMARY]: Hauptgruppe, enth�lt standardm��ig alle Files, kann nicht entfernt werden
	Die Primary Gruppe kann allerdings keine Files enthalten
	Das File unter der Primary hat die Endung .mdf (Master Database File)
	
	Es k�nnen weitere Dateigruppen erstellt werden, diese enthalten Files mit der Endung .ndf (Non-Master Database File)
*/

USE Demo2;

--Rechtsklick auf DB -> Properties -> File Groups
--Add Filegroup, ben�tigt ein File

--Files -> Add
--Pfad + Name, Initialgr��e + Wachstumsrate
--Ein File kann zu einer Filegroup hinzugef�gt werden

CREATE TABLE FG3 (id int primary key identity, test char(4100))
ON [AKTIV2]; --Hier bei CREATE TABLE eine Filegruppe angeben

INSERT INTO FG1
SELECT 'XYZ'
GO 20000

SELECT * FROM FG1;

--Wie bewegt man eine Tabelle auf eine andere Filegruppe?

--Neue Tabelle erstellen und Daten kopieren
CREATE TABLE FG2 (id int primary key identity, test char(4100)) ON [PRIMARY];

INSERT INTO FG2
SELECT * FROM FG1

DROP TABLE FG1

--Tabellenstruktur kopieren
SELECT *
INTO FG2 ON [PRIMARY]
FROM FG1

DROP TABLE FG1

--Salamitaktik
--Gro�e Tabellen in kleine Tabellen aufteilen
--Nur die Daten die auch wirklich ben�tigt werden angreifen

CREATE TABLE Umsatz
(
	Datum date,
	Umsatz float
)

DECLARE @i int = 0;
WHILE @i < 100000
BEGIN
	INSERT INTO Umsatz VALUES
	(DATEADD(DAY, FLOOR(RAND()*1096), '20200101'), RAND() * 1000);
	SET @i += 1;
END

SET STATISTICS TIME, IO ON

dbcc showcontig('Umsatz')

SELECT * FROM Umsatz
WHERE YEAR(Datum) = 2022
ORDER BY Datum;
--Hier m�ssen alle Seiten durchgeschaut werden, um die 2022 DS zu finden

CREATE TABLE Umsatz2020
(
	Datum date,
	Umsatz float
);

CREATE TABLE Umsatz2021
(
	Datum date,
	Umsatz float
);

CREATE TABLE Umsatz2022
(
	Datum date,
	Umsatz float
);

INSERT INTO Umsatz2020
SELECT * FROM Umsatz
WHERE YEAR(Datum) = 2020

INSERT INTO Umsatz2021
SELECT * FROM Umsatz
WHERE YEAR(Datum) = 2021

INSERT INTO Umsatz2022
SELECT * FROM Umsatz
WHERE YEAR(Datum) = 2022

SELECT * FROM Umsatz2022;
--83 LV -> Schneller

--Problem: Jetzt die Datens�tze separat
--Wir wollen alle Umsatzdaten finden bei denen der Umsatz > 750 ist

--> View mit Gesamtdarstellung
GO

CREATE VIEW UmsatzGesamt AS
SELECT * FROM Umsatz2020
UNION ALL --UNION ohne ALL macht eine Filterung auf Duplikate -> ineffizient
SELECT * FROM Umsatz2021
UNION ALL --UNION ALL filtert keine Duplikate
SELECT * FROM Umsatz2022

GO

SELECT * FROM UmsatzGesamt
WHERE Umsatz > 750 --Alle unterliegenden Tabellen m�ssen angegriffen werden

SELECT * FROM UmsatzGesamt
WHERE YEAR(Datum) = 2022 --Alle unterliegenden Tabellen m�ssen angegriffen werden
--Nur Umsatz2022 enth�lt die 2022 Daten

/*
	Pl�ne:
	Zeigt den genauen Ablauf einer Abfrage an
	Aktivieren mit dem Button Include Actual Execution Plan (Strg + M)
	Wichtige Werte:
	- Costs: Beschreiben prozentual die Kosten des Teils der Abfrage
	- Number of Rows Read: Anzahl geladene Zeilen
*/

--Indizierte Sicht
--Bei der Indizierten Sicht werden kleine Tabellen wieder zusammengebaut
--�ber ein CHECK Constraint kann die Bedingung f�r das Lesen der unterliegenden Tabellen festgelegt werden

--Constraints:
--Geben vor, welche Daten in die Tabelle hinein geschrieben werden k�nnen
--PRIMARY KEY und FOREIGN KEY
--CHECK Constraint

DROP TABLE Umsatz2020;
DROP TABLE Umsatz2021;
DROP TABLE Umsatz2022;

CREATE TABLE Umsatz2020
(
	Datum date,
	Umsatz float,
	CONSTRAINT chk_2020 CHECK (YEAR(Datum) = 2020) --CHECK Constraint: F�gt eine Einschr�nkung auf die Daten hinzu (nur 2020 Daten k�nnen hier hinein)
);

CREATE TABLE Umsatz2021
(
	Datum date,
	Umsatz float,
	CONSTRAINT chk_2021 CHECK (YEAR(Datum) = 2021)
);

CREATE TABLE Umsatz2022
(
	Datum date,
	Umsatz float,
	CONSTRAINT chk_2022 CHECK (YEAR(Datum) = 2022)
);

DROP VIEW UmsatzGesamt;
GO

CREATE VIEW UmsatzGesamt AS
SELECT * FROM Umsatz2020
UNION ALL --UNION ohne ALL macht eine Filterung auf Duplikate -> ineffizient
SELECT * FROM Umsatz2021
UNION ALL --UNION ALL filtert keine Duplikate
SELECT * FROM Umsatz2022
GO

SELECT * FROM UmsatzGesamt WHERE YEAR(Datum) = 2020;