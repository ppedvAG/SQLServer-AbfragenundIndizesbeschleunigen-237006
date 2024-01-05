--Query Store
--Erstellt Statistiken während dem Normalbetrieb
--Speichert Abfragen, Zeiten, Verbrauch, ...

--Rechtsklick auf DB -> Properties -> Query Store -> Operating Mode -> Read/Write
--Neuer Ordner auf der Datenbank (Query Store) mit vorgegebenen Statistiken

--Erstmal Einstellungen vornehmen -> Zeitintervall erhöhen, Alle Queries anzeigen

USE Demo2;

SELECT * FROM KundenUmsatz;
--Pläne: Was passiert hier im Hintergrund?
--Der Text der Abfrage wird gehasht, der Plan wird an diesen Hash angehängt
--Wenn die Abfrage sich auch nur minimal ändert, wird ein neuer Plan erstellt
--Besonders nützlich für Indizes

SELECT Txt.query_text_id, Txt.query_sql_text, Pl.plan_id, Qry.*  
FROM sys.query_store_plan AS Pl 
JOIN sys.query_store_query AS Qry ON Pl.query_id = Qry.query_id  
JOIN sys.query_store_query_text AS Txt ON Qry.query_text_id = Txt.query_text_id;

EXEC sys.sp_query_store_remove_query 135; --Plan löschen

SELECT UseCounts, Cacheobjtype, Objtype, TEXT, query_plan
FROM sys.dm_exec_cached_plans 
CROSS APPLY sys.dm_exec_sql_text(plan_handle)
CROSS APPLY sys.dm_exec_query_plan(plan_handle) --Pläne visualisieren