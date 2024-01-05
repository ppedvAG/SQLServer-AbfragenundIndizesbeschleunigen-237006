CREATE TABLE Umsatz2022
(
	ID int,
	Datum date,
	Umsatz float,
	Jahr smallint

	CONSTRAINT PK_U22 PRIMARY KEY (ID, Jahr),
	CONSTRAINT CHK_Year2022 CHECK (Jahr=2022)
);

INSERT INTO Umsatz2022
SELECT NEXT VALUE FOR PK_Seq, Datum, Umsatz, 2022 FROM Demo2.dbo.Umsatz WHERE YEAR(Datum) = 2022;

CREATE TABLE Umsatz2020
(
	ID int,
	Datum date,
	Umsatz float,
	Jahr smallint

	CONSTRAINT PK_U20 PRIMARY KEY (ID, Jahr),
	CONSTRAINT CHK_Year2020 CHECK (Jahr=2020)
);

INSERT INTO Umsatz2020
SELECT NEXT VALUE FOR PK_Seq, *, 2020 FROM Demo2.dbo.Umsatz WHERE YEAR(Datum) = 2020;

CREATE TABLE Umsatz2021
(
	ID int,
	Datum date,
	Umsatz float,
	Jahr smallint

	CONSTRAINT PK_U21 PRIMARY KEY (ID, Jahr),
	CONSTRAINT CHK_Year2021 CHECK (Jahr=2021)
);

INSERT INTO Umsatz2021
SELECT NEXT VALUE FOR PK_Seq, *, 2021 FROM Demo2.dbo.Umsatz WHERE YEAR(Datum) = 2021;

--Indizierte Sicht
--View die über CHECK-Constraints nur auf die benötigten unterliegenden Tabellen zugreift

GO
CREATE VIEW UmsatzGesamt
AS
	SELECT * FROM Umsatz2020
	UNION ALL --UNION filtert Duplikate, UNION ALL filtert keine Duplikate
	SELECT * FROM Umsatz2021
	UNION ALL
	SELECT * FROM Umsatz2022
GO

SELECT * FROM UmsatzGesamt WHERE Jahr = 2021;
SELECT * FROM UmsatzGesamt WHERE Jahr = 2020 OR Jahr = 2021;

INSERT INTO UmsatzGesamt (ID, Datum, Umsatz, Jahr) VALUES
(22222222, '2021-01-01', 123, 2021);

DELETE FROM UmsatzGesamt WHERE ID = 22222222