--Profiler
--Tools -> SQL Server Profiler

--Name: Dateiname
--Template: Tuning
--Save to File (wird später benötigt)
--File Rollover

--Events: Stored Procedure Events, TSQL Events
--ColumnFilter: DatabaseName LIKE <Name>

SELECT * FROM KundenUmsatz; --Abfrage im Profiler sichtbar

--Tuning Advisor
--Tools -> Tuning Advisor

--Benötigt entweder ein .trc File, eine Tabelle, den Plan Cache oder Query Store
--Datenbank für Workload auswählen (tempdb)
--Datenbank(en) auswählen für das Tuning

--Auswählen, was optimiert werden soll (Indizes, Partitionen, ...)
--Start analysis

--Actions -> Apply Recommendations/Save Recommendations