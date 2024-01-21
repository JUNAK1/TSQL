USE [Vodafone]
GO
/****** Object:  StoredProcedure [dbo].[spRecordVodaFone]    Script Date: 22/09/2023 2:18:12 p. m. ******/
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

<Informacion de Modificacion>
User_NT:amorteguibarraza.5
Fecha: 2023-09-19
Descripcion: Se realizo la modificacion de agregar parametros de fechas para que solo traiga informacion de 
45 dias vencidos

<Informacion de Modificacion>
User_NT:E_1053871829
Fecha: 2023-09-22
Descripcion: Se realizo la modificacion de eliminar la tabla física [tbRecordVodafone] para volver a crearla con los campos organizados, tomando
como base el archivo de excel 'Estructura Final Record Upload'. Además, se modifico la tabla temporal #tmpConsolidadosRecordQA y el bloque de inserción
de datos a la tabla física para que los campos coincidan en su nuevo orden.

<Ejemplo>
Exec [dbo].[spRecordVodaFone] 
*/
ALTER PROCEDURE [dbo].[spRecordVodaFone]
(@startDate DATE = null, @endDate DATE = NULL)
AS

SET NOCOUNT ON;



    BEGIN
        BEGIN TRY
        /*===============Bloque declaracion de variables==========*/
		--Declare @startDate Date = null, @endDate Date = null
		SET @startDate	= ISNULL(@startDate, CAST(GETDATE()-45 AS DATE))
		SET @endDate	= ISNULL(@endDate, CAST(GETDATE() AS DATE))
        
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
            ,[Weight]					 INT
            ,[AvailableProductive]       NUMERIC
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
        , SUM(ISNULL([Offered],0)) AS [Weight]
        ,0 AS [Available productive] 
        ,CAST([fecha] AS DATE) AS [Fecha]
    FROM [TPCCP-DB08\SCDOM].[Vodafone].[dbo].[tbFlashreportVodafoneHistorico] WITH (NOLOCK)
	WHERE [fecha] BETWEEN @startDate AND @endDate
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
	  WHERE [fecha] BETWEEN @startDate AND @endDate
      GROUP BY 
         [Fecha]

    /*======================================== Creación y carga temporal #tmpConsolidadosRecordQA ======================================*/  
   IF OBJECT_ID('tempdb..#tmpConsolidadosRecordQA') IS NOT NULL 
    DROP TABLE #tmpConsolidadosRecordQA;
                
        CREATE TABLE  #tmpConsolidadosRecordQA
            (
          			
                 [IdClient]						INT
                ,[Date]							DATE
                ,[Avail]						NUMERIC
                ,[AuxProd]						INT
                ,[AuxNoProd]				    NUMERIC
                ,[TalkTime]					    NUMERIC
                ,[HoldTime]					    NUMERIC
                ,[ACWTime]						NUMERIC
                ,[RingTime]					    NUMERIC
                ,[RealInteractionsAnswered]		NUMERIC
                ,[RealInteractionsOffered]		INT
                ,[FCSTInteractionsAnswered]		DECIMAL
                ,[KPIValue]						NUMERIC
                ,[KPIprojection]				DECIMAL
                ,[SHKprojection]				DECIMAL
                ,[ABSprojection]				DECIMAL
                ,[AHTprojection]				DECIMAL
                ,[Weight]						INT
                ,[ReqHours]						DECIMAL
                ,[KPIWeight]					DECIMAL
                ,[FCSTStafftime]				DECIMAL
				,[AvailableProductive]			NUMERIC
                ,[LastUpdateDate]				DATETIME
  
            );
        
        INSERT INTO #tmpConsolidadosRecordQA
        SELECT
            1212 AS [IdClient]
            ,FR.[Fecha]						
            ,FR.[Avail]					
            ,FR.[AuxProd]					
            ,FR.[AuxNoProd]				
            ,FR.[TalkTime]					
            ,FR.[HoldTime]					
            ,FR.[ACWTime]					      
            ,FR.[RingTime]					
            ,FR.[RealInteractionsAnswered]	
            ,FR.[RealInteractionsOffered]	
            ,OA.[FCSTInteractionsAnswered]	
            ,FR.[KPIValue]					
            ,OA.[KPIprojection]			
            ,OA.[SHKprojection]			
            ,OA.[ABSprojection]			
            ,OA.[AHTprojection]			
            ,FR.[Weight]					
            ,OA.[ReqHours]					
            ,OA.[KPIWeight]				
            ,OA.[FCSTStafftime]			
			,FR.[AvailableProductive]		
            ,GETDATE()
    FROM #tmpFlashReportVodafoneHistorico AS FR WITH(NOLOCK)
    INNER JOIN #tmpOverAndUnder OA
    ON FR.[Fecha] = OA.[Fecha]
    /*======================================== Carga a la tabla fisica [dbo].[tbRecordVodafone] usando MERGE ======================================*/

    MERGE [dbo].[tbRecordVodafone] AS [tgt]
        USING
        (
              SELECT
                 						     
				 [IdClient]					                           
                ,[Date]						     
                ,[Avail]					     
                ,[AuxProd]					     
                ,[AuxNoProd]				     
                ,[TalkTime]					     
                ,[HoldTime]					
				,[ACWTime]					
                ,[RingTime]					     
                ,[RealInteractionsAnswered]	     
                ,[RealInteractionsOffered]	     
                ,[FCSTInteractionsAnswered]	
				,[KPIValue]					
                ,[KPIprojection]			     
                ,[SHKprojection]			     
                ,[ABSprojection]			     
                ,[AHTprojection]			     
                ,[Weight]					     
                ,[ReqHours]					     
                ,[KPIWeight]				     
                ,[FCSTStafftime]			
				,[AvailableProductive]		
                ,[LastUpdateDate]			     
            FROM #tmpConsolidadosRecordQA

        ) AS [src]
        ON
        (
           
            [src].[Avail] = [tgt].[Avail] AND [src].[AuxProd] = [tgt].[AuxProd] AND [src].[AuxNoProd] = [tgt].[AuxNoProd] AND  [src].[Date] = [tgt].[Date]
        )
        -- For updates
        WHEN MATCHED THEN
          UPDATE 
              SET
                 --									=[src].					    
                 [tgt].[IdClient]					= [src].[IdClient]					                          
                ,[tgt].[Date]						= [src].[Date]						    
                ,[tgt].[Avail]						= [src].[Avail]						    
                ,[tgt].[AuxProd]					= [src].[AuxProd]					    
                ,[tgt].[AuxNoProd]					= [src].[AuxNoProd]					    
                ,[tgt].[TalkTime]					= [src].[TalkTime]					    
                ,[tgt].[HoldTime]					= [src].[HoldTime]					
				,[tgt].[ACWTime]					= [src].[ACWTime]					
                ,[tgt].[RingTime]					= [src].[RingTime]					    
                ,[tgt].[RealInteractionsAnswered]	= [src].[RealInteractionsAnswered]	    
                ,[tgt].[RealInteractionsOffered]	= [src].[RealInteractionsOffered]	    
                ,[tgt].[FCSTInteractionsAnswered]	= [src].[FCSTInteractionsAnswered]	
				,[tgt].[KPIValue]					= [src].[KPIValue]					
                ,[tgt].[KPIprojection]				= [src].[KPIprojection]				    
                ,[tgt].[SHKprojection]				= [src].[SHKprojection]				    
                ,[tgt].[ABSprojection]				= [src].[ABSprojection]				    
                ,[tgt].[AHTprojection]				= [src].[AHTprojection]				    
                ,[tgt].[Weight]						= [src].[Weight]						    
                ,[tgt].[ReqHours]					= [src].[ReqHours]					    
                ,[tgt].[KPIWeight]					= [src].[KPIWeight]					    
                ,[tgt].[FCSTStafftime]				= [src].[FCSTStafftime]				
				,[tgt].[AvailableProductive]		= [src].[AvailableProductive]		
                ,[tgt].[LastUpdateDate]				= [src].[LastUpdateDate]				 

         --For Inserts
        WHEN NOT MATCHED THEN
            INSERT
            (	 					                          
                 [IdClient]					                           
                ,[Date]						     
                ,[Avail]						     
                ,[AuxProd]					     
                ,[AuxNoProd]					     
                ,[TalkTime]					     
                ,[HoldTime]					
				,[ACWTime]					
                ,[RingTime]					     
                ,[RealInteractionsAnswered]	     
                ,[RealInteractionsOffered]	     
                ,[FCSTInteractionsAnswered]	
				,[KPIValue]					
                ,[KPIprojection]				     
                ,[SHKprojection]				     
                ,[ABSprojection]				     
                ,[AHTprojection]				     
                ,[Weight]						     
                ,[ReqHours]					     
                ,[KPIWeight]					     
                ,[FCSTStafftime]				
				,[AvailableProductive]		
                ,[LastUpdateDate]				
            )
            VALUES
            (
                 [src].[IdClient]					                           
                ,[src].[Date]						     
                ,[src].[Avail]						     
                ,[src].[AuxProd]					     
                ,[src].[AuxNoProd]					     
                ,[src].[TalkTime]					     
                ,[src].[HoldTime]					
				,[src].[ACWTime]					
                ,[src].[RingTime]					     
                ,[src].[RealInteractionsAnswered]	     
                ,[src].[RealInteractionsOffered]	     
                ,[src].[FCSTInteractionsAnswered]	
				,[src].[KPIValue]					
                ,[src].[KPIprojection]				     
                ,[src].[SHKprojection]				     
                ,[src].[ABSprojection]				     
                ,[src].[AHTprojection]				     
                ,[src].[Weight]						     
                ,[src].[ReqHours]					     
                ,[src].[KPIWeight]					     
                ,[src].[FCSTStafftime]				
				,[src].[AvailableProductive]		
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