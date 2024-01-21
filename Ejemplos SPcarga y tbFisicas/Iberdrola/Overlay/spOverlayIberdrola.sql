USE [Iberdrola]
GO
/****** Object:  StoredProcedure [dbo].[spOverlayIberdrola]    Script Date: 13/10/2023 8:53:42 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
<Informacion Creacion>
User_NT:E_1143864762, E_1000687202, E_1016102870,E_1105792917, E_1053871829
Fecha: 2023-10-12
Descripcion: Se crea un sp de carga [spOverlayIberdrola] y la tabla fisica [tbOverlayIberdrola] la cual 
complementa su informacion a traves de varias tablas temporales las cuales fueron hechas a partir de vistas.
Se aplicó el filtro de client=Iberdrola y el rango de fechas son 3 meses atras.

<Ejemplo>
      Exec [dbo].[spOverlayIberdrola] 
*/
ALTER PROCEDURE [dbo].[spOverlayIberdrola] @DateStart DATE = NULL ,@DateEnd  DATE = NULL
AS
SET NOCOUNT ON;
    BEGIN
        BEGIN TRY
        /*===============Bloque declaracion de variables==========*/
            DECLARE @ERROR INT = 0;
            SET   @DateStart = ISNULL(@DateStart,CAST(GETDATE() -90 AS DATE));
			SET   @DateEnd   = ISNULL(@DateEnd,CAST(GETDATE() AS DATE));
        /*======================================== Creación y carga tablas temporales proveniente de vistas   ======================================*/
                ---------------------- VW A ----------------------------------------------------
            IF OBJECT_ID('tempdb..#tmpSchedule') IS NOT NULL DROP TABLE #tmpSchedule;
            CREATE TABLE #tmpSchedule(
                 [idSchedule]	INT
                ,[idccms]		INT 
                ,[dateDim]		DATE
            );

            INSERT INTO #tmpSchedule
                SELECT 
                     [idSchedule]
                    ,[idccms]
                    ,CAST([dateDim] AS DATE)
                FROM [TPCCP-DB31,5081].[MyTpProd].[PQ].[vwSchedule] WITH(NOLOCK)
                WHERE CAST([dateDim] AS DATE) BETWEEN @DateStart AND @DateEnd;

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
                     [schedule]
                    ,CAST([startTime] AS TIME)	AS [starTime]
                    ,CAST([endTime] AS TIME)	AS [endTime]
                    ,[typeOv]
                    ,[hrsOv]
                    ,[active]
                FROM [TPCCP-DB31,5081].[MyTpProd].[PQ].[vwScheduleOverlay] WITH (NOLOCK)
                WHERE CAST([startTime] AS DATE) BETWEEN @DateStart AND @DateEnd;
            ------------------ vw F -------------------------------------------------------
            IF OBJECT_ID('tempdb..#tmpvwScheduleTypeDetail') IS NOT NULL DROP TABLE #tmpvwScheduleTypeDetail;
            CREATE TABLE #tmpvwScheduleTypeDetail
            (
                 [idScheduleTypeDetail]  INT
                ,[originalAuxName]       VARCHAR(100)
                
            );

            INSERT INTO #tmpvwScheduleTypeDetail
                SELECT
                     [idScheduleTypeDetail]
                    ,[originalAuxName]
                FROM [TPCCP-DB31,5081].[MyTpProd].[PQ].[vwScheduleTypeDetail] WITH(NOLOCK);

            ---------------- vw C ---------------------------------------------------------
            IF OBJECT_ID('tempdb..#tmpEmployee') IS NOT NULL DROP TABLE #tmpEmployee;
            CREATE TABLE #tmpEmployee
            (
                 [idCcms]           INT
                ,[idccmsManager]    INT
                ,[program]          INT
            );

            INSERT INTO #tmpEmployee
                SELECT 
                     [idCcms] 
                    ,[idccmsManager]
                    ,[program]
                FROM [TPCCP-DB31,5081].[MyTpProd].[PQ].[vwEmployee] WITH(NOLOCK);
            ---------------- VW   D -------------------------------------------------------
            IF OBJECT_ID('tempdb..#tmpProgramClient') IS NOT NULL DROP TABLE #tmpProgramClient;
            CREATE TABLE #tmpProgramClient
            (
                 [idProgramCcms]     INT
                ,[nameProgram]       VARCHAR(100)
                ,[cliente]           INT
            );

            INSERT INTO #tmpProgramClient
                SELECT
                     [idProgramCcms]
                    ,[nameProgram]
                    ,[cliente]
               FROM [TPCCP-DB31,5081].[MyTpProd].[PQ].[vwProgramClient] WITH(NOLOCK);

            IF OBJECT_ID('tempdb..#tmpClient') IS NOT NULL DROP TABLE #tmpClient;
            CREATE TABLE #tmpClient(
                 [idClientCCMS]		INT
                ,[client]			VARCHAR(100)    
            );

            INSERT INTO #tmpClient
                SELECT 
                     [idClientCCMS]
                    ,[client]
                FROM [TPCCP-DB31,5081].[MyTpProd].[PQ].[vwClient] WITH(NOLOCK)
                WHERE [client] = 'IBERDROLA SOLUTIONS LLC';
            ------------  vw G AND H ---------------------------------------------------------
            IF OBJECT_ID('tempdb..#tmpEmployeeInfo') IS NOT NULL DROP TABLE #tmpEmployeeInfo;
            CREATE TABLE #tmpEmployeeInfo
            (   
                 [idCcms]	INT
                ,[country]	VARCHAR(30)
            );

            INSERT INTO #tmpEmployeeInfo
                SELECT
                     [idCcms]
                    ,[country]
                FROM [TPCCP-DB31,5081].[MyTpProd].[PQ].[vEmployeeInfo] WITH (NOLOCK);
        /*======================================== Creación y carga temporal #tmpOverlayIberdrolaQA ======================================*/     
            IF OBJECT_ID('tempdb..#tmpOverlayIberdrolaQA') IS NOT NULL DROP TABLE #tmpOverlayIberdrolaQA;
            CREATE TABLE #tmpOverlayIberdrolaQA
            (   
                 [IdCcms]           INT 
                ,[DateDim]          DATE
                ,[StartTime]        TIME
                ,[EndTime]          TIME
                ,[TypeOv]           INT
                ,[OriginalAuxName]  VARCHAR(100)
                ,[HrsOv]            TIME
                ,[Client]           VARCHAR(100)
                ,[NameProgram]      VARCHAR(100)
                ,[Country]          VARCHAR(30)
				,[LastUpdateDate]	DATE
            );

            INSERT INTO #tmpOverlayIberdrolaQA
                SELECT 
                     A.[idccms]					AS [IdCcms]  
                    ,A.[dateDim]				AS [DateTime]
                    ,B.[startTime]				AS [StartTime]
                    ,B.[endTime]				AS [EndTime]
                    ,B.[typeOv]					AS [TypeOv]
                    ,F.[originalAuxName]		AS [OriginalAuxName]
                    ,B.[hrsOv]					AS [HrsOv]
                    ,E.[client]					AS [Client]
                    ,D.[nameprogram]			AS [NameProgram]
                    ,UPPER(LEFT(G.[country],1)) + LOWER(SUBSTRING(G.[country],2,LEN(G.[country]))) AS [Country]
					,GETDATE()
                FROM #tmpSchedule A 
                INNER JOIN #tmpvwScheduleOverlay B WITH (NOLOCK) 
				ON A.[idSchedule] = B.[schedule]
                INNER JOIN #tmpvwScheduleTypeDetail F WITH (NOLOCK) 
				ON B.[typeOv] = F.[idScheduleTypeDetail]
                INNER JOIN #tmpEmployee C WITH (NOLOCK) 
				ON A.[idccms] = C.[idCcms]
                INNER JOIN #tmpProgramClient D WITH (NOLOCK) 
				ON C.[program] = D.[idProgramCcms]
                INNER JOIN #tmpClient E WITH (NOLOCK) 
				ON D.[cliente] = E.[idClientCCMS]
                INNER JOIN #tmpEmployeeInfo G WITH (NOLOCK) 
				ON C.[idCcms] = G.[idCcms]
                   AND B.[active] = 1 
                   AND B.[typeOv] <> 1 
                   AND B.[typeOv] <> 5;  
/*======================================== Carga a la tabla fisica [dbo].[tbOverlayIberdrola] usando MERGE ======================================*/ 
			MERGE [dbo].[tbOverlayIberdrola] AS [tgt]
            USING
            (    
				SELECT
                     [IdCcms]           
                    ,[DateDim]         
                    ,[StartTime]       
                    ,[EndTime]         
                    ,[TypeOv]          
                    ,[OriginalAuxName]       
                    ,[HrsOv]           
                    ,[Client]          
                    ,[NameProgram]     
                    ,[Country]
					,[LastUpdateDate]
                FROM #tmpOverlayIberdrolaQA
            ) AS [src]
            ON([src].[IdCcms] = [tgt].[IdCcms] AND [src].[DateDim] = [tgt].[DateDim] 
				AND [src].[StartTime] = [tgt].[StartTime] AND [src].[EndTime] = [tgt].[EndTime]
            )
            -- For updates
            WHEN MATCHED THEN
            UPDATE 
                SET
                     [tgt].[IdCcms]                  =[src].[IdCcms]             
                    ,[tgt].[DateDim]                 =[src].[DateDim]         
                    ,[tgt].[StartTime]               =[src].[StartTime]       
                    ,[tgt].[EndTime]                 =[src].[EndTime]         
                    ,[tgt].[TypeOv]                  =[src].[TypeOv]          
                    ,[tgt].[DescAux]				 =[src].[OriginalAuxName] 
                    ,[tgt].[HrsOv]                   =[src].[HrsOv]           
                    ,[tgt].[Client]                  =[src].[Client]              
                    ,[tgt].[NameProgram]             =[src].[NameProgram]     
                    ,[tgt].[Country]				 =[src].[Country]
					,[tgt].[LastUpdateDate]			 =[src].[LastUpdateDate]

            WHEN NOT MATCHED THEN
                INSERT
                (
                     [IdCcms]           
                    ,[DateDim]         
                    ,[StartTime]       
                    ,[EndTime]         
                    ,[TypeOv]          
                    ,[DescAux]       
                    ,[HrsOv]           
                    ,[Client]          
                    ,[NameProgram]     
                    ,[Country]
					,[LastUpdateDate]
                )
                VALUES
                (
                     [src].[IdCcms]          
                    ,[src].[DateDim]         
                    ,[src].[StartTime]       
                    ,[src].[EndTime]         
                    ,[src].[TypeOv]          
                    ,[src].[OriginalAuxName] 
                    ,[src].[HrsOv]           
                    ,[src].[Client]          
                    ,[src].[NameProgram]     
                    ,[src].[Country]
					,[src].[LastUpdateDate]
                );            
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
        IF OBJECT_ID('tempdb..#tmpEmployeeInfo') IS NOT NULL DROP TABLE #tmpEmployeeInfo;
        IF OBJECT_ID('tempdb..#tmpOverlayIberdrolaQA') IS NOT NULL DROP TABLE #tmpOverlayIberdrolaQA;  
    
    END
