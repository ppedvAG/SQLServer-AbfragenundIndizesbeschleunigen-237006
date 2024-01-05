USE Demo2;

--MAXDOP
--Maximum Degree of Parallelism
--Steuerung der Anzahl Prozessorkerne pro Abfrage/Datenbank
--Datenbank parallelisiert von alleine

--MAXDOP kann auf 3 Ebenen konfiguriert werden
--Query > DB > Server

--Cost Threshold for Parallelism
--Minimale Kosten laut Plan damit parallelisiert

SELECT freight, birthdate FROM KU WHERE Freight > (SELECT AVG(Freight) FROM KU);
--Diese Abfrage wird parallelisiert durch die Zwei schwarzen Pfeile in dem gelben Kreis

SET STATISTICS TIME, IO ON

SELECT freight, birthdate FROM KU WHERE Freight > (SELECT AVG(Freight) FROM KU);
--CPU-Zeit = 1309 ms, verstrichene Zeit = 1416 ms

SELECT freight, birthdate
FROM KU
WHERE Freight > (SELECT AVG(Freight) FROM KU)
OPTION(MAXDOP 1);
--CPU-Zeit = 672 ms, verstrichene Zeit = 2296 ms

SELECT freight, birthdate
FROM KU
WHERE Freight > (SELECT AVG(Freight) FROM KU)
OPTION(MAXDOP 2);
--CPU-Zeit = 861 ms, verstrichene Zeit = 1589 ms

SELECT freight, birthdate
FROM KU
WHERE Freight > (SELECT AVG(Freight) FROM KU)
OPTION(MAXDOP 4);
--CPU-Zeit = 875 ms, verstrichene Zeit = 1443 ms

SELECT freight, birthdate
FROM KU
WHERE Freight > (SELECT AVG(Freight) FROM KU)
OPTION(MAXDOP 8);
--CPU-Zeit = 1468 ms, verstrichene Zeit = 1544 ms

--Ergebnis: MAXDOP 4 am effizientesten