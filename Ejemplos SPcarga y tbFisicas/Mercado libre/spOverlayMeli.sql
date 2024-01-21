USE [Mercadolibre]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
<Informacion Creacion>
User_NT:E_1233495216
Fecha: 2023-09-28
Descripcion: Se crea un sp de carga [spRecordMeli] en la cual crea una tabla fisica [tbOverlayMeli] la cual 
complementa su informacion a traves de varias tablas temporales las cuales fueron hechas a partir de vistas.
Se aplicaron varios filtros como : client = Mercado Libre Y el rango de fechas son HOY y MANANA

<Ejemplo>
      Exec [dbo].[spOverlayMeli] 
*/
ALTER PROCEDURE [dbo].[spOverlayMeli] 
AS

SET NOCOUNT ON;

    BEGIN
        BEGIN TRY

	/*===============Bloque declaracion de variables==========*/
        
        DECLARE @ERROR INT = 0;
       
    /*======================================== Truncate a la tabla fisica para insercion de nuevos datos   ======================================*/
            
            TRUNCATE TABLE tbOverlayMeli;
     
    /*======================================== Creación y carga tablas temporales proveniente de vistas   ======================================*/

            ---------------------- VW A ----------------------------------------------------
            IF OBJECT_ID('tempdb..#tmpSchedule') IS NOT NULL DROP TABLE #tmpSchedule;
            CREATE TABLE #tmpSchedule(
                [idSchedule]  INT
                ,[idccms]     INT 
                ,[dateDim]    DATE
            );

            INSERT INTO #tmpSchedule
            SELECT 
                [idSchedule]
                ,[idccms]
                ,CAST([dateDim] AS DATE)
            FROM [TPCCP-DB31\TPSATCRH].[MyTpProd].[PQ].[vwSchedule] WITH(NOLOCK)
            WHERE CAST([dateDim] AS DATE) BETWEEN GETDATE()-1 AND GETDATE() + 1;

            ------------------ VW B -------------------------------------------------------
            IF OBJECT_ID('tempdb..#tmpvwScheduleOverlay') IS NOT NULL DROP TABLE #tmpvwScheduleOverlay;

            CREATE TABLE #tmpvwScheduleOverlay(
                 [schedule]     INT
                ,[startTime]    TIME
                ,[endTime]      TIME
                ,[typeOv]       INT
                ,[hrsOv]        TIME
                ,[active]       INT
            );

            INSERT INTO #tmpvwScheduleOverlay
                SELECT 
                    [schedule],
                    CAST([startTime] AS TIME) AS starTime,
                    CAST([endTime] AS TIME) AS endTime,
                    [typeOv],
                    [hrsOv],
                    [active]
                FROM [TPCCP-DB31\TPSATCRH].[MyTpProd].[PQ].[vwScheduleOverlay] WITH (NOLOCK)
                WHERE CAST([startTime] AS DATE) BETWEEN GETDATE()-1 AND GETDATE() + 1;


            ------------------ vw F -------------------------------------------------------

            IF OBJECT_ID('tempdb..#tmpvwScheduleTypeDetail') IS NOT NULL DROP TABLE #tmpvwScheduleTypeDetail;
            CREATE TABLE #tmpvwScheduleTypeDetail
            (
                [idScheduleTypeDetail]         INT,
                [originalAuxName]       VARCHAR(100),
              
            );

            INSERT INTO #tmpvwScheduleTypeDetail
            SELECT
                [idScheduleTypeDetail],
                [originalAuxName]
            FROM [TPCCP-DB31\TPSATCRH].[MyTpProd].[PQ].[vwScheduleTypeDetail] WITH(NOLOCK);
            


            ---------------- vw C ---------------------------------------------------------
            IF OBJECT_ID('tempdb..#tmpEmployee') IS NOT NULL DROP TABLE #tmpEmployee;
            CREATE TABLE #tmpEmployee
            (
                 [idCcms]              INT
                ,[idccmsManager]       INT
                ,[program]             INT
            );

 
            INSERT INTO #tmpEmployee
            SELECT [idCcms] 
                  ,[idccmsManager]
                  ,[program]
            FROM [TPCCP-DB31\TPSATCRH].[MyTpProd].[PQ].[vwEmployee] WITH(NOLOCK);


            ---------------- VW   D -------------------------------------------------------
            IF OBJECT_ID('tempdb..#tmpProgramClient') IS NOT NULL DROP TABLE #tmpProgramClient;
            CREATE TABLE #tmpProgramClient
            (
                [idProgramCcms]     INT,
                [nameProgram]       VARCHAR(100),
                [cliente]           INT
            );

            INSERT INTO #tmpProgramClient
            SELECT
                [idProgramCcms],
                [nameProgram],
                [cliente]
            FROM [TPCCP-DB31\TPSATCRH].[MyTpProd].[PQ].[vwProgramClient] WITH(NOLOCK);


            -------------- vw E ---------------------------------------------------------------
            IF OBJECT_ID('tempdb..#tmpClient') IS NOT NULL DROP TABLE #tmpClient;
            CREATE TABLE #tmpClient(
                [idClientCCMS]    INT
                ,[client]         VARCHAR(100)    
            );

            INSERT INTO #tmpClient
            SELECT 
                [idClientCCMS]
                ,[client]
            FROM [TPCCP-DB31\TPSATCRH].[MyTpProd].[PQ].[vwClient]
            WHERE [client] = 'Mercado Libre';


            ------------  vw G AND H ----------------------------------------------------------

            IF OBJECT_ID('tempdb..#TMPEmployeeInfo') IS NOT NULL DROP TABLE #TMPEmployeeInfo;
            CREATE TABLE #TMPEmployeeInfo
            (   
                 [idCcms]                     INT
                ,[country]                    VARCHAR(30)
            );

            INSERT INTO #TMPEmployeeInfo
            SELECT
              [idCcms]
             ,[country]
            FROM [TPCCP-DB31\TPSATCRH].[MyTpProd].[PQ].[vEmployeeInfo] WITH (NOLOCK);

    /*======================================== Creación y carga temporal #tmpConsolidadosRecordQA ======================================*/ 
    
            IF OBJECT_ID('tempdb..#TMPOverlayMercadoLibreQA') IS NOT NULL DROP TABLE #TMPOverlayMercadoLibreQA;
            CREATE TABLE #TMPOverlayMercadoLibreQA
            (   
                 [idccms]           INT 
                ,[dateDim]          DATE
                ,[startTime]        TIME
                ,[endTime]          TIME
                ,[typeOv]           INT
                ,[originalAuxName]  VARCHAR(100)
                ,[hrsOv]            TIME
                ,[client]           VARCHAR(100)
                ,[nameProgram]      VARCHAR(100)
                ,[country]          VARCHAR(30)

            );

            INSERT INTO #TMPOverlayMercadoLibreQA
            SELECT 
                A.[idccms],
                A.[dateDim]   AS [dateTime],
                B.[startTime] AS [starTime],
                B.[endTime]   AS [endTime],
                B.[typeOv],
                F.[originalAuxName],
                B.[hrsOv],
                e.[client],
                D.[nameprogram],
                UPPER(LEFT(G.[country],1)) + LOWER(SUBSTRING(G.[country],2,LEN(G.[country]))) AS country
            FROM #tmpSchedule A 
                INNER JOIN #tmpvwScheduleOverlay B WITH (NOLOCK) ON A.[idSchedule] = B.[schedule]
                INNER JOIN #tmpvwScheduleTypeDetail F WITH (NOLOCK) ON b.[typeOv] = F.[idScheduleTypeDetail]
                INNER JOIN #tmpEmployee C WITH (NOLOCK) ON A.[idccms] = C.[idCcms]
                INNER JOIN #tmpProgramClient D WITH (NOLOCK) ON C.[program] = D.[idProgramCcms]
                INNER JOIN #tmpClient E WITH (NOLOCK) ON D.[cliente] = E.[idClientCCMS]
                INNER JOIN #TMPEmployeeInfo G WITH (NOLOCK) ON C.[idCcms] = G.[idCcms]
                    AND b.[active] = 1 
                    AND B.[typeOv] <> 1 
                    AND B.[typeOv] <> 5;
            
    /*======================================== Carga a la tabla fisica ======================================*/

            INSERT INTO tbOverlayMeli 
            SELECT 
				[idccms]           
                ,[dateDim]         
                ,[startTime]       
                ,[endTime]         
                ,[typeOv]          
                ,[originalAuxName]       
                ,[hrsOv]           
                ,[client]          
                ,[nameProgram]     
                ,[country]
                ,GETDATE() --> TimeStamp
            FROM #TMPOverlayMercadoLibreQA;

        END TRY
        
        BEGIN CATCH
            SET @Error = 1;
                PRINT ERROR_MESSAGE();
        END CATCH
        /*=======================Eliminacion de temporales=========================*/

        IF OBJECT_ID('tempdb..#tmpSchedule') IS NOT NULL DROP TABLE #tmpSchedule;
        IF OBJECT_ID('tempdb..#tmpvwScheduleOverlay') IS NOT NULL DROP TABLE #tmpvwScheduleOverlay;
        IF OBJECT_ID('tempdb..#tmpvwScheduleTypeDetail') IS NOT NULL DROP TABLE #tmpvwScheduleTypeDetail;
        IF OBJECT_ID('tempdb..#tmpEmployee') IS NOT NULL DROP TABLE #tmpEmployee;
        IF OBJECT_ID('tempdb..#tmpProgramClient') IS NOT NULL DROP TABLE #tmpProgramClient;
        IF OBJECT_ID('tempdb..#tmpClient') IS NOT NULL DROP TABLE #tmpClient;
        IF OBJECT_ID('tempdb..#TMPEmployeeInfo') IS NOT NULL DROP TABLE #TMPEmployeeInfo;
        IF OBJECT_ID('tempdb..#TMPOverlayMercadoLibreQA') IS NOT NULL DROP TABLE #TMPOverlayMercadoLibreQA;

     
    END



	