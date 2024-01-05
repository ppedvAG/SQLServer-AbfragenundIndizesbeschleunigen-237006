--Profiler
--Tools -> SQL Server Profiler

--Name: Dateiname
--Template: Tuning
--Save to File (wird sp�ter ben�tigt)
--File Rollover

--Events: Stored Procedure Events, TSQL Events
--ColumnFilter: DatabaseName LIKE <Name>

SELECT * FROM KundenUmsatz; --Abfrage im Profiler sichtbar

--Tuning Advisor
--Tools -> Tuning Advisor

--Ben�tigt entweder ein .trc File, eine Tabelle, den Plan Cache oder Query Store
--Datenbank f�r Workload ausw�hlen (tempdb)
--Datenbank(en) ausw�hlen f�r das Tuning

--Ausw�hlen, was optimiert werden soll (Indizes, Partitionen, ...)
--Start analysis

--Actions -> Apply Recommendations/Save Recommendations