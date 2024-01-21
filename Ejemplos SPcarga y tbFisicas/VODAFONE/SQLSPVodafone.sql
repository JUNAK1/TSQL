USE [Vodafone]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
<Informacion Creacion>
User_NT:E_1105792917
Fecha: 2023-09-19
Descripcion: Se crea un sp de carga [spRecordVodafone],
El script manipula tres tablas temporales
#tmpFlashReportVodafoneHistorico: Esta tabla temporal almacena datos históricos sobre distintas métricas como tiempo de disponibilidad (Avail), tiempo de conversación (TalkTime), tiempo en espera (HoldTime), etc., recogidos de la tabla tbFlashreportVodafoneHistorico. Los datos se agrupan por la fecha (Fecha) y se lleva a cabo algunas operaciones aritméticas (como sumas y multiplicaciones) sobre algunas columnas durante la inserción.
#tmpOverAndUnder: Esta tabla temporal almacena datos proyectados relacionados con las interacciones pronosticadas (FCSTInteractionsAnswered), proyecciones de KPI (KPIprojection), proyecciones de absentismo (ABSprojection), entre otros, tomados de la tabla tbOAU. Aquí también, algunos cálculos son realizados en el momento de la inserción de datos, y los datos son agrupados por la fecha (Fecha).
#tmpConsolidadosRecordQA: Esta tabla temporal actúa como una estructura intermedia que consolidará los datos provenientes de las dos tablas temporales mencionadas anteriormente (#tmpFlashReportVodafoneHistorico y #tmpOverAndUnder), asociando los datos por la fecha (Fecha). También se añaden dos columnas adicionales: Id e IdClient, que parecen ser identificadores estáticos.
Despues se hace el Mergue en la tabla fisica [tbRecordVodafone] para actualizar los registros existente o insertar nuevos registros

<Ejemplo>
Exec [dbo].[spRecordVodaFone] 
*/
ALTER PROCEDURE [dbo].[spRecordVodaFone]
AS

SET NOCOUNT ON;

    BEGIN
        BEGIN TRY
        /*===============Bloque declaracion de variables==========*/
        
        DECLARE @ERROR INT =0;
        
        /*======================================== Creación y carga temporal #tmpFlashReportVodafoneHistorico ======================================*/

        IF OBJECT_ID('tempdb..#tmpFlashReportVodafoneHistorico') IS NOT NULL 
        DROP TABLE #tmpFlashReportVodafoneHistorico;

        CREATE TABLE #tmpFlashReportVodafoneHistorico
        (   
             [Avail]                     NUMERIC
            ,[AuxProd]                   INT
            ,[AuxNoProd]                 NUMERIC
            ,[TalkTime]                  NUMERIC
            ,[HoldTime]                  NUMERIC
            ,[ACWTime]                   NUMERIC
            ,[RingTime]                  NUMERIC
            ,[RealInteractionsAnswered]  NUMERIC
            ,[RealInteractionsOffered]   INT
            ,[KPIValue]                  NUMERIC
            ,[Offered]                   INT
            ,[AvailableProductive]      NUMERIC
            ,[Fecha]                     DATE
        );

        INSERT INTO #tmpFlashReportVodafoneHistorico
        SELECT
        (SUM(ISNULL([Avail],0))*60) AS [Avail]
        , 0 AS [AuxProd]
        , ((SUM(ISNULL([AuxForm%],0) + ISNULL([AuxBreak%],0) + ISNULL([AuxBOPersonal%],0) + ISNULL([AuxCoaching%],0) + ISNULL([AuxPVDPausa%],0) + ISNULL([AuxIndvCoachQA%],0) + ISNULL([AuxSalAdm%],0) + ISNULL([AuxSG%],0) + ISNULL([AuxAES%],0))) * SUM(ISNULL([Staffed Time Prod],0)))*60 AS [AuxNoProd]
        , SUM(ISNULL([TT],0))*60 AS [TalkTime]
        , SUM(ISNULL([HOLD],0))*60 AS [HoldTime]
        , SUM(ISNULL([Avg ACW],0))*SUM(ISNULL([Handled],0))*60 AS [ACWTime] 
        , 0 AS  [RingTime] 
        , SUM(ISNULL([FC],0)) AS [RealInteractionsAnswered]
        , SUM(ISNULL([Offered],0)) AS [RealInteractionsOffered]
        , SUM(ISNULL([SL' %],0))*100 AS [KPIValue] -- En excel SL''%
        , SUM(ISNULL([Offered],0)) AS [Offered]
        ,0 AS [Available productive] 
        ,CAST([fecha] AS DATE) AS Fecha
    FROM [TPCCP-DB08\SCDOM].[Vodafone].[dbo].[tbFlashreportVodafoneHistorico] WITH (NOLOCK)
    GROUP BY 
    [Fecha]
        
/*======================================== Creación y carga temporal #tmpOverAndUnder ======================================*/                  

    IF OBJECT_ID('tempdb..#tmpOverAndUnder') IS NOT NULL 
    DROP TABLE #tmpOverAndUnder;
                
        CREATE TABLE #tmpOverAndUnder
            (
                 [FCSTInteractionsAnswered]   DECIMAL                     
                ,[KPIprojection]              DECIMAL
                ,[SHKprojection]              DECIMAL  
                ,[ABSprojection]              DECIMAL  
                ,[AHTprojection]              DECIMAL  
                ,[KPIWeight]                  DECIMAL  
                ,[ReqHours]                   DECIMAL  
                ,[FCSTStafftime]              DECIMAL
                ,[Fecha]                      DATE
            );
        
        INSERT INTO #tmpOverAndUnder
       SELECT 
            SUM(ISNULL([Volume],0))                AS [FCSTInteractionsAnswered]
            ,SUM(ISNULL(CAST([SL] AS FLOAT),0))    AS [KPIprojection]
            ,CASE
                WHEN SUM([Net Staff]) = 0 OR SUM([Net Staff]) IS NULL
                    THEN 0
                ELSE (SUM([Net Staff]) - SUM(ISNULL([Productive Staff],0))) / SUM([Net Staff])
            END  AS [SHKprojection]
            ,CASE
                WHEN SUM([Scheduled Staff]) = 0 OR SUM([Scheduled Staff]) IS NULL
                    THEN 0
                ELSE (SUM([Scheduled Staff]) - SUM(ISNULL([Net Staff],0))) / SUM([Scheduled Staff])
            END  AS [ABSprojection]
            ,(SUM(ISNULL([AHT],0)) * 60)      AS [AHTprojection]
            ,(SUM(ISNULL([Volume],0)))        AS [KPIWeight]
            ,(SUM(ISNULL([Req],0)) / 2)       AS [ReqHours]
            ,(SUM(ISNULL([Net Staff],0)) / 2) AS [FCSTStafftime]
            ,[Fecha] AS Fecha
      FROM [TPCCP-DB08\SCDOM].[Vodafone].[dbo].[tbOAU] WITH (NOLOCK)
      GROUP BY 
         [Fecha]

    /*======================================== Creación y carga temporal #tmpConsolidadosRecordQA ======================================*/  
   IF OBJECT_ID('tempdb..#tmpConsolidadosRecordQA') IS NOT NULL 
    DROP TABLE #tmpConsolidadosRecordQA;
                
        CREATE TABLE  #tmpConsolidadosRecordQA
            (
                 [Id]                            INT 
                ,[IdClient]                      INT
                ,[Avail]                         NUMERIC
                ,[AuxProd]                       INT
                ,[AuxNoProd]                     NUMERIC
                ,[TalkTime]                      NUMERIC
                ,[HoldTime]                      NUMERIC
                ,[ACWTime]                       NUMERIC
                 ,[RingTime]                      NUMERIC
                ,[RealInteractionsAnswered]      NUMERIC
                ,[RealInteractionsOffered]       INT
                ,[KPIValue]                      NUMERIC
                ,[Offered]                       INT
                ,[AvailableProductive]          NUMERIC
                ,[FCSTInteractionsAnswered]      DECIMAL
                ,[KPIprojection]                 DECIMAL
                ,[SHKprojection]                 DECIMAL
                ,[ABSprojection]                 DECIMAL
                ,[AHTprojection]                 DECIMAL
                ,[KPIWeight]                     DECIMAL
                ,[ReqHours]                      DECIMAL
                ,[FCSTStafftime]                 DECIMAL
                ,[Fecha]                         DATE
                ,[LastUpdateDate]                DATETIME
  
            );
        
        INSERT INTO #tmpConsolidadosRecordQA
        SELECT
            1212 AS [Id]
            ,0 AS [IdClient]
            ,FR.[Avail]
            ,FR.[AuxProd]
            ,FR.[AuxNoProd]
            ,FR.[TalkTime]
            ,FR.[HoldTime]
            ,FR.[ACWTime]
            ,FR.[RingTime]                      
            ,FR.[RealInteractionsAnswered]
            ,FR.[RealInteractionsOffered]
            ,FR.[KPIValue]
            ,FR.[Offered]
            ,FR.[AvailableProductive]
            ,OA.[FCSTInteractionsAnswered]
            ,OA.[KPIprojection]
            ,OA.[SHKprojection]
            ,OA.[ABSprojection]
            ,OA.[AHTprojection]
            ,OA.[KPIWeight]
            ,OA.[ReqHours]
            ,OA.[FCSTStafftime]
            ,FR.Fecha
            ,GETDATE()
    FROM #tmpFlashReportVodafoneHistorico AS FR WITH(NOLOCK)
    INNER JOIN #tmpOverAndUnder OA
    ON FR.[Fecha] = OA.[Fecha]
    /*======================================== Carga a la tabla fisica [dbo].[tbRecordVodafone] usando MERGE ======================================*/

    MERGE [dbo].[tbRecordVodafone] AS [tgt]
        USING
        (
              SELECT
                 [Id]                           
                ,[IdClient]                                           
                ,[Avail]                        
                ,[AuxProd]                      
                ,[AuxNoProd]                    
                ,[TalkTime]                     
                ,[HoldTime]                     
                ,[ACWTime]
                ,[RingTime]
                ,[RealInteractionsAnswered]     
                ,[RealInteractionsOffered]      
                ,[KPIValue]                     
                ,[Offered]  
                ,[AvailableProductive]
                ,[FCSTInteractionsAnswered]     
                ,[KPIprojection]                
                ,[SHKprojection]                
                ,[ABSprojection]                
                ,[AHTprojection]                
                ,[KPIWeight]                    
                ,[ReqHours]                     
                ,[FCSTStafftime]
                ,[Fecha]
                ,[LastUpdateDate]               
            FROM #tmpConsolidadosRecordQA

        ) AS [src]
        ON
        (
           
            [src].[Avail] = [tgt].[Avail] AND [src].[AuxProd] = [tgt].[AuxProd] AND [src].[AuxNoProd] = [tgt].[AuxNoProd] AND  [src].[Fecha] = [tgt].[Fecha]
        )
        -- For updates
        WHEN MATCHED THEN
          UPDATE 
              SET
                 --                              =[src].
                 [tgt].[Id]                       = [src].[Id]                          
                ,[tgt].[IdClient]                 = [src].[IdClient]                                          
                ,[tgt].[Avail]                    = [src].[Avail]                       
                ,[tgt].[AuxProd]                  = [src].[AuxProd]                     
                ,[tgt].[AuxNoProd]                = [src].[AuxNoProd]                   
                ,[tgt].[TalkTime]                 = [src].[TalkTime]                    
                ,[tgt].[HoldTime]                 = [src].[HoldTime]                    
                ,[tgt].[ACWTime]                  = [src].[ACWTime] 
                ,[tgt].[RingTime]                  = [src].[RingTime] 
                ,[tgt].[RealInteractionsAnswered] = [src].[RealInteractionsAnswered]    
                ,[tgt].[RealInteractionsOffered]  = [src].[RealInteractionsOffered]     
                ,[tgt].[KPIValue]                 = [src].[KPIValue]                    
                ,[tgt].[Offered]                  = [src].[Offered]   
                ,[tgt].[AvailableProductive]      =[src].[AvailableProductive]
                ,[tgt].[FCSTInteractionsAnswered] = [src].[FCSTInteractionsAnswered]    
                ,[tgt].[KPIprojection]            = [src].[KPIprojection]               
                ,[tgt].[SHKprojection]            = [src].[SHKprojection]               
                ,[tgt].[ABSprojection]            = [src].[ABSprojection]               
                ,[tgt].[AHTprojection]            = [src].[AHTprojection]               
                ,[tgt].[KPIWeight]                = [src].[KPIWeight]                   
                ,[tgt].[ReqHours]                 = [src].[ReqHours]                    
                ,[tgt].[FCSTStafftime]            = [src].[FCSTStafftime]
                ,[tgt].[Fecha]                  = [src].[Fecha]    
                ,[tgt].[LastUpdateDate]           = [src].[LastUpdateDate]           

         --For Inserts
        WHEN NOT MATCHED THEN
            INSERT
            (
                [Id]                           
                ,[IdClient]                                           
                ,[Avail]                        
                ,[AuxProd]                      
                ,[AuxNoProd]                    
                ,[TalkTime]                     
                ,[HoldTime]                     
                ,[ACWTime] 
                ,[RingTime] 
                ,[RealInteractionsAnswered]     
                ,[RealInteractionsOffered]      
                ,[KPIValue]                     
                ,[Offered]
                ,[AvailableProductive]
                ,[FCSTInteractionsAnswered]     
                ,[KPIprojection]                
                ,[SHKprojection]                
                ,[ABSprojection]                
                ,[AHTprojection]                
                ,[KPIWeight]                    
                ,[ReqHours]                     
                ,[FCSTStafftime]
                ,[Fecha]
                ,[LastUpdateDate] 
            )
            VALUES
            (
                 [src].[Id]                           
                ,[src].[IdClient]                                           
                ,[src].[Avail]                        
                ,[src].[AuxProd]                      
                ,[src].[AuxNoProd]                    
                ,[src].[TalkTime]                     
                ,[src].[HoldTime]                     
                ,[src].[ACWTime]
                ,[src].[RingTime]
                ,[src].[RealInteractionsAnswered]     
                ,[src].[RealInteractionsOffered]      
                ,[src].[KPIValue]                     
                ,[src].[Offered] 
                ,[src].[AvailableProductive]
                ,[src].[FCSTInteractionsAnswered]     
                ,[src].[KPIprojection]                
                ,[src].[SHKprojection]                
                ,[src].[ABSprojection]                
                ,[src].[AHTprojection]                
                ,[src].[KPIWeight]                    
                ,[src].[ReqHours]                     
                ,[src].[FCSTStafftime] 
                ,[src].[Fecha] 
                ,[src].[LastUpdateDate] 
            );

     END TRY
        
        BEGIN CATCH
            SET @Error = 1;
            PRINT ERROR_MESSAGE();
        END CATCH
        /*=======================Eliminacion de temporales=========================*/

        IF OBJECT_ID('tempdb..#tmpFlashReportVodafoneHistorico') IS NOT NULL
        DROP TABLE #tmpFlashReportVodafoneHistorico;

        IF OBJECT_ID('tempdb..#tmpOverAndUnder') IS NOT NULL 
        DROP TABLE #tmpOverAndUnder;

        IF OBJECT_ID('tempdb..#tmpConsolidadosRecordQA') IS NOT NULL 
        DROP TABLE #tmpConsolidadosRecordQA;
     
    END