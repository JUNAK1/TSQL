USE [BBVA]
GO
SET
    ANSI_NULLS ON
GO
SET
    QUOTED_IDENTIFIER ON
GO
/*
<Informacion Creacion>
User_NT: E_1143864762, E_1053871829, E_1105792917
Fecha: 10/03/2023
Descripcion: Se trae informacion de las tablas y servidores [TPCCP-DB05\SCTRANS].[tpStaffStatus].[ssw].[tbStaffStatus] y
[TPCCP-DB05\SCTRANS].[tpStaffStatus].[ssw].[tbAgentLoginTotal] uniendolas en una tabla fisica [dbo].[tbAusentismoBBVA]
con su llave de union [LogID] en ambas tablas trayendo un historico de cada agente 
     
<Ejemplo>

EXEC PROCEDURE [dbo].[spAusentismoBBVA] 
TABLA FISICA:    [dbo].[tbAusentismoBBVA]
     
*/
ALTER PROCEDURE [dbo].[spAusentismoBBVA] 
    AS
SET
    NOCOUNT ON;

BEGIN 
    BEGIN TRY
        /*===============Bloque declaracion de variables==========*/
        DECLARE @ERROR INT = 0;
		Declare @DateStart DATE = GETDATE()-1;
		Declare @DateEnd DATE = GETDATE();

        /*======================================== Creación y carga tabla temporal #tmpStaffStatus   ======================================*/
        IF OBJECT_ID('tempdb..#tmpStaffStatus') IS NOT NULL DROP TABLE #tmpStaffStatus;
        CREATE TABLE #tmpStaffStatus
        (
            [LogID]                     INT,
            [SupervisorName]            VARCHAR(100),
            [Employeename]              VARCHAR(100),
            [idccms]                    INT, 
            [Location]                  VARCHAR(20),
            [RecalculationStartshift]   DATETIME,
            [RecalculationEndofshift]   DATETIME,
            [TimeStartofrest]           TIME,
            [TimeEndofrest]             TIME,
            [ScheduledSeconds]          INT,
            [Login]                     DATETIME,
            [Logout]                    DATETIME,
            [Status]                    VARCHAR(100),
            [StatusLogOut]              VARCHAR(100),
            [SourceLogin2]              VARCHAR(100),
            [absenteeism]               INT,
            [Tardy]                     INT,
            [Early]                     INT,
            [TypeJustification]         VARCHAR (100),
            [Justification]             VARCHAR (500),
            [Observation]               VARCHAR (500),
            [Enable]                    INT,
        );

        INSERT INTO
            #tmpStaffStatus
        SELECT
            [LogID],
            [SupervisorName]            AS [Supervisor],
            [Employeename]              AS [Agent Name],
            [idccms]                    AS [idccms],
            [Location]                  AS [Location],
            [RecalculationEndofshift]   AS [Endofshift],
            [RecalculationStartshift]   AS [Startshift],
            [TimeStartofrest]           AS [Startofrest],
            [TimeEndofrest]             AS [Endofrest],
            [ScheduledSeconds]          AS [Scheduled time],
            [Login]                     AS [Login],
            [Logout]                    AS [Logout],
            [Status]                    AS [Status],
            [StatusLogOut]              AS [StatusLogOut],
            [SourceLogin2]              AS [Source Login],
            [absenteeism]               AS [Hours absent],
            [Tardy]                     AS [Hours tardy],
            [Early]                     AS [Hours early],
            [TypeJustification]         AS [Type Just],
            [Justification]             AS [Justification],
            [Observation]               AS [Observation],
            [Enable]
						
        FROM [TPCCP-DB05\SCTRANS].[tpStaffStatus].[ssw].[tbStaffStatus] WITH (NOLOCK)
		WHERE [Startshift] BETWEEN @DateStart AND @DateEnd; 

        /*======================================== Creación y carga tabla temporal #tmpStaffStatusQA  ======================================*/
        IF OBJECT_ID('tempdb..#tmpStaffStatusQA') IS NOT NULL DROP TABLE #tmpStaffStatusQA;
        CREATE TABLE #tmpStaffStatusQA
        (
            [Supervisor]        VARCHAR(100),
            [AgentName]         VARCHAR(100),
            [Idccms]           INT,
            [Location]          VARCHAR(20),
            [StartShift]        DATETIME,
            [EndOfShift]        DATETIME,
            [StartOfRest]       TIME,
            [EndOfRest]         TIME,
            [ScheduledTime]     INT,
            [Login]             DATETIME,
            [Logout]            DATETIME,
            [TimeLoginHH]       FLOAT,
            [Status]            VARCHAR(100),
            [StatusLogOut]      VARCHAR(100),
            [SourceLogin]       VARCHAR(100),
            [HoursAbsent]       FLOAT,
            [HoursTardy]        INT,
            [HoursEarly]        INT,
            [TypeJust]          VARCHAR (100),
            [Justification]     VARCHAR (500),
            [Observation]       VARCHAR (500),
            [LastUpdateDate]    DATETIME
        );

        INSERT INTO
            #tmpStaffStatusQA
        SELECT
            A.[SupervisorName] AS [Supervisor],
            A.[Employeename]   AS [AgentName],
            A.[idccms],
            A.[Location],
            A.[RecalculationStartshift] AS [Startshift],
            A.[RecalculationEndofshift] AS [Endofshift],
            A.[TimeStartofrest] AS [StartOfRest],
            A.[TimeStartofrest] AS [EndOfRest],
            CASE
                WHEN A.[Enable] = 1 THEN SUM(A.[ScheduledSeconds]) / 3600
                ELSE 0
            END AS [ScheduledTime],
            A.[Login],
            A.[Logout],
            SUM(B.[TimeLoginSS] / 3600) AS [TimeLoginHH],
            A.[Status],
            A.[StatusLogOut],
            A.[SourceLogin2] AS [SourceLogin],
            CASE
                WHEN A.[Enable] = 1 THEN SUM(A.absenteeism) / 3600
                ELSE 0
            END AS [HoursAbsent],
            CASE
                WHEN A.[Enable] = 1 THEN SUM(A.[Tardy]) / 3600
                ELSE 0
            END AS [HoursTardy],
            CASE
                WHEN A.[Enable] = 1 THEN SUM(A.[Early]) / 3600
                ELSE 0
            END AS [HoursEarly],
            A.[TypeJustification] AS [TypeJust],
            A.[Justification],
            A.[Observation],
            GETDATE()
        FROM
            #tmpStaffStatus A
            INNER JOIN [TPCCP-DB05\SCTRANS].[tpStaffStatus].[ssw].[tbAgentLoginTotal] B 
                ON A.[LogID] = B.[LogID]
        GROUP BY
            A.[SupervisorName],
            A.[Employeename],
            A.[idccms],
            A.[Location],
            A.[RecalculationStartshift],
            A.[RecalculationEndofshift],
            A.[TimeStartofrest],
            A.[TimeEndofrest],
            A.[Enable],
            A.[Login],
            A.[Logout],
            A.[Status],
            A.[StatusLogOut],
            A.[SourceLogin2],
            A.[TypeJustification],
            A.[Justification],
            A.[Observation];


        /*======================================== Carga a la tabla fisica [dbo].[tbAusentismoBBVA] usando Truncate y luego insert ======================================*/

        TRUNCATE TABLE [dbo].[tbAusentismoBBVA]

		INSERT INTO [dbo].[tbAusentismoBBVA]	
			SELECT 

					[Supervisor]        
					,[AgentName]         
					,[Idccms]           
					,[Location]          
					,[StartShift]        
					,[EndOfShift]        
					,[StartOfRest]       
					,[EndOfRest]         
					,[ScheduledTime]     
					,[Login]             
					,[Logout]            
					,[TimeLoginHH]       
					,[Status]            
					,[StatusLogOut]      
					,[SourceLogin]       
					,[HoursAbsent]       
					,[HoursTardy]        
					,[HoursEarly]        
					,[TypeJust]          
					,[Justification]     
					,[Observation]       
					,[LastUpdateDate]    

			FROM #tmpStaffStatusQA

    END TRY 
    BEGIN CATCH
        SET @Error = 1;
        PRINT ERROR_MESSAGE();
    END CATCH

    /*=======================Eliminacion de temporales=========================*/
    IF OBJECT_ID('tempdb..#tmpStaffStatus') IS NOT NULL   DROP TABLE #tmpStaffStatus;
    IF OBJECT_ID('tempdb..#tmpStaffStatusQA') IS NOT NULL DROP TABLE #tmpStaffStatusQA;
END




