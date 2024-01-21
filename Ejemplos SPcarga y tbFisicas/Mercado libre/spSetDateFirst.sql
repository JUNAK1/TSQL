USE [Mercadolibre]
GO
/****** Object:  StoredProcedure [dbo].[spReporteAusentismoOAU]    Script Date: 10/4/2023 6:07:05 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
<Informacion Creacion>
User_NT:E_1143864762,E_1019137609
Fecha: 2023-10-4
Descripcion: Creación de un sp de carga que toma datos de las tablas [tbOAU]  [tbLobMeli]
y los carga en [tbReporteAusentismoOAU]
<Ejemplo>
Exec [dbo].[spReporteAusentismoOAU] 
*/
CREATE PROCEDURE [dbo].[spReporteAusentismoOAU]
AS

 

SET NOCOUNT ON;
Set datefirst 1 ;
 

    BEGIN
        BEGIN TRY
        /*===============Bloque declaracion de variables==========*/
        
        DECLARE @ERROR INT =0;
        
        /*======================================== Creación y carga temporal #tmpLobMeli ======================================*/
        
    
 

        IF OBJECT_ID('tempdb..#tmpLobMeli') IS NOT NULL DROP TABLE #tmpLobMeli;
        CREATE TABLE #tmpLobMeli
        (   
             Lob                         VARCHAR(100)
            ,Page                        VARCHAR(100)
           
        );

 
        INSERT INTO #tmpLobMeli
        SELECT  
            [Lob]
           ,[Page]
        FROM [Mercadolibre].[dbo].[tbLobMeli] WITH (NOLOCK)
        GROUP BY 
            Lob,
            Page;
 

 

/*======================================== Creación y carga temporal #tmptbOAU ======================================*/    
        IF OBJECT_ID('tempdb..#tmptbOAU') IS NOT NULL DROP TABLE #tmptbOAU;
        
        CREATE TABLE #tmptbOAU
            (
                     [Page]                  VARCHAR(100)
                    ,[Year]                  NUMERIC
                    ,[Month]                 NUMERIC
                    ,[Weeknum]               NUMERIC
                    ,[WDayName]              VARCHAR(50)
                    ,[TypeDay]               VARCHAR(50)
                    ,[Turno]                 VARCHAR(50)
                    ,[CategoriaHrs]          VARCHAR(50)
                    ,[RowDate]               DATE
                    ,[Interval]              TIME
                    ,[ScheduledStaff]        NUMERIC
                    ,[NetStaff]              DECIMAL(18,2)
                    ,[ProductiveStaff]       DECIMAL(18,2)
                    ,[Req]                   DECIMAL(18,2)
                    ,[Volume]                DECIMAL(18,2)
                    ,[Capacity]              DECIMAL(18,2)
                    ,[ProductiveOU]          DECIMAL(18,2)
            );
        
            INSERT INTO #tmptbOAU
        
                SELECT 
                     [Page]
                    ,datepart(YEAR,[RowDate]) AS [#Year]
                    ,datepart(Month,[RowDate]) AS [Month]
                    ,datepart([WEEK],[RowDate]) AS [Weeknum]
                    ,CONCAT(cASt(datepart(WEEKDAY,[RowDate]) AS int),substring(DATEname(WEEKDAY, [RowDate]),1,3)) AS [#WDayName]
                    ,CASE
                        WHEN DATENAME(dw,[RowDate]) <> 'Saturday' and DATENAME(dw,[RowDate]) <> 'Sunday' THEN '1Weekday' 
                        WHEN DATENAME(dw,[RowDate]) = 'Saturday' THEN '2Saturday' 
                        WHEN DATENAME(dw,[RowDate]) = 'Sunday' THEN '3Sunday' 
                     END AS [TypeDay]
                    ,CASE
                        WHEN DATEPART([hour],Interval)>=6 and DATEPART([hour],Interval)<12 THEN '1TM' 
                        WHEN DATEPART([hour],Interval)>=12 and DATEPART([hour],Interval)<21 THEN '2TT' ELSE '3TN'
                     END AS [Turno]
                    ,CASE
                        WHEN DATENAME(dw,[RowDate]) <> 'Sunday' and (DATEPART([hour],Interval) >=6 and DATEPART([hour],Interval) <21) THEN 'OrdinariAS'
                        WHEN DATENAME(dw,[RowDate]) <> 'Sunday' and (DATEPART([hour],Interval) < 6 or  DATEPART([hour],Interval) >=21) THEN 'NocturnASOrdinariAS'
                        WHEN DATENAME(dw,[RowDate]) = 'Sunday'  and (DATEPART([hour],Interval) >=6 and DATEPART([hour],Interval) <21    )THEN 'DominicalesOrdinariAS'
                        WHEN DATENAME(dw,[RowDate]) = 'Sunday'  and (DATEPART([hour],Interval) < 6 or  DATEPART([hour],Interval) >=21) THEN 'DominicalesNocturnAS'
                     END AS [CategoriaHrs]
                    ,[RowDate]
                    ,[Interval]
                    ,[ScheduledStaff]   
                    ,[NetStaff]         
                    ,[ProductiveStaff]  
                    ,[Req]              
                    ,[Volume]           
                    ,[Capacity]
                    ,[ProductiveOU] -1 AS [Productive OU]
            FROM [Mercadolibre].[dbo].[tbOAU]  WITH (NOLOCK)
            GROUP BY            
                     [Page]         
                    ,[RowDate]
                    ,[Interval]
                    ,[ScheduledStaff]   
                    ,[NetStaff]         
                    ,[ProductiveStaff]  
                    ,[Req]              
                    ,[Volume]           
                    ,[Capacity]
                    ,[ProductiveOU];


    
    
/*======================================== Creación y carga temporal #tmpConsolidadosRecordQA ======================================*/  
    IF OBJECT_ID('tempdb..#tmpConsolidadosRecordQA') IS NOT NULL DROP TABLE #tmpConsolidadosRecordQA;

        CREATE TABLE #tmpConsolidadosRecordQA
            (       
                     [Page]                  VARCHAR(50)
                    ,[Lob]                   VARCHAR(50)
                    ,[Conca]                 VARCHAR(50)
                    ,[ConcaTypeDay]          VARCHAR(50)
                    ,[Year]                  NUMERIC
                    ,[Month]                 NUMERIC
                    ,[Weeknum]               NUMERIC
                    ,[WDayName]              VARCHAR(50)
                    ,[TypeDay]               VARCHAR(50)
                    ,[Turno]                 VARCHAR(50)
                    ,[CategoriaHrs]          VARCHAR(50)
                    ,[RowDate]               DATE
                    ,[Interval]              TIME
                    ,[ScheduledStaff]        NUMERIC
                    ,[NetStaff]              DECIMAL(18,2)
                    ,[ProductiveStaff]       DECIMAL(18,2)
                    ,[Req]                   DECIMAL(18,2)
                    ,[Volume]                DECIMAL(18,2)
                    ,[Capacity]              DECIMAL(18,2)
                    ,[ProductiveOU]          DECIMAL(18,2)
             );

    INSERT INTO  #tmpConsolidadosRecordQA
        SELECT
             B.[Page]           
            ,B.[Lob]                
            ,CONCAT(lob,
                CASE
                    WHEN DATEPART([hour],Interval)>=6 and DATEPART([hour],Interval)<12 THEN '1TM' 
                    WHEN DATEPART([hour],Interval)>=12 and DATEPART([hour],Interval)<21 THEN '2TT' ELSE '3TN'
                END ) AS [Conca]        
            ,CONCAT(lob,
                CASE
                    WHEN DATENAME(dw,[RowDate]) <> 'Saturday' and DATENAME(dw,[RowDate]) <> 'Sunday' THEN '1Weekday' 
                    WHEN DATENAME(dw,[RowDate]) = 'Saturday' THEN '2Saturday' 
                    WHEN DATENAME(dw,[RowDate]) = 'Sunday' THEN '3Sunday' 

                END) AS [ConcaTypeDay]
            ,A.[Year]           
            ,A.[Month]          
            ,A.[Weeknum]        
            ,A.[WDayName]       
            ,A.[TypeDay]        
            ,A.[Turno]          
            ,A.[CategoriaHrs]   
            ,A.[RowDate]            
            ,A.[Interval]           
            ,A.[ScheduledStaff] 
            ,A.[NetStaff]           
            ,A.[ProductiveStaff]    
            ,A.[Req]                
            ,A.[Volume]         
            ,A.[Capacity]           
            ,A.[ProductiveOU]     
       
            FROM #tmptbOAU AS A 
            LEFT JOIN #tmpLobMeli B 
                ON A.[page] = B.[page]
            WHERE A.[RowDate] >=  GETDATE()-2;
/*************************Merge tabla fisica********************/
    TRUNCATE TABLE [tbReporteAusentismoOAU]
    INSERT INTO [tbReporteAusentismoOAU]
        SELECT
             [Page]             
            ,[Lob]              
            ,[Conca]            
            ,[ConcaTypeDay]     
            ,[Year]             
            ,[Month]            
            ,[Weeknum]          
            ,[WDayName]         
            ,[TypeDay]          
            ,[Turno]            
            ,[CategoriaHrs]     
            ,[RowDate]          
            ,[Interval]         
            ,[ScheduledStaff]   
            ,[NetStaff]         
            ,[ProductiveStaff]  
            ,[Req]              
            ,[Volume]           
            ,[Capacity]         
            ,[ProductiveOU]
        FROM #tmpConsolidadosRecordQA;
        
 

 

        END TRY

        BEGIN CATCH
            SET @Error = 1;
            PRINT ERROR_MESSAGE();
        END CATCH
        /*=======================Eliminacion de temporales=========================*/

 

        IF OBJECT_ID('tempdb..#tmpLobMeli') IS NOT NULL DROP TABLE #tmpLobMeli;
        IF OBJECT_ID('tempdb..#tmptbOAU') IS NOT NULL DROP TABLE #tmptbOAU;
        IF OBJECT_ID('tempdb..#TMPConsolidadosRecordQA') IS NOT NULL DROP TABLE #TMPConsolidadosRecordQA;

    END