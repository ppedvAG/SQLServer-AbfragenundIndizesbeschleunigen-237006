USE Demo2;

CREATE PARTITION FUNCTION pf_Date(date) AS
RANGE LEFT FOR VALUES ('2020-12-31', '2021-12-31',  '2022-12-31')

CREATE PARTITION SCHEME sch_Date AS
PARTITION pf_Date TO (D1, D2, D3, D4)

CREATE TABLE Umsatzdaten (ID int identity, Datum date, Umsatz float)
ON sch_Date(Datum);

BEGIN TRAN;
DECLARE @i int = 0;
WHILE @i < 100000
BEGIN
	INSERT INTO Umsatzdaten VALUES
	(DATEADD(DAY, FLOOR(RAND() * 1461), '20200101'), RAND() * 1000);
	SET @i += 1;
END
COMMIT;

SELECT * FROM Umsatzdaten ORDER BY Datum;

SELECT
$partition.pf_Date(Datum),
AVG(Umsatz),
COUNT(*)
FROM Umsatzdaten
GROUP BY $partition.pf_Date(Datum)

dbcc showcontig('Umsatzdaten')