USE [BBVA]
GO

/*
<Informacion Creacion>
User_NT:E_1000687202 , E_1014297790
Fecha: 2023-10-04
Descripcion: Se crea un sp de carga [spOpsMetricsBBVA] con 1 temporal (Se deja por el momento con una temporal, ya que no hay fuentes de los otros datos por el momento)
Al final se hace el Mergue en la tabla fisica [tbOpsMetricsBBVA] para actualizar los registros existentes o insertar nuevos registros.

<Ejemplo>
      Exec [dbo].[spOpsMetricsBBVA] 
*/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[spOpsMetricsBBVA] 
    @DateStart DATE = NULL
    ,@DateEnd  DATE = NULL
AS

SET NOCOUNT ON;

    BEGIN
        BEGIN TRY
        /*===============Bloque declaracion de variables==========*/

        DECLARE @ERROR INT =0;
        SET   @DateStart = ISNULL(@DateStart,CAST(GETDATE()-60 AS DATE));
        SET   @DateEnd   = ISNULL(@DateEnd,CAST(GETDATE() AS DATE));

/*======================================== Creación y carga temporal #tmpBBVAOpsMetrics ======================================*/
    IF OBJECT_ID('tempdb..#tmpBBVAOpsMetrics') IS NOT NULL DROP TABLE #tmpBBVAOpsMetrics;
    CREATE TABLE #tmpBBVAOpsMetrics
    (
        [Year]                          INT
        ,[Month]                        INT
        ,[HoldTime]                     FLOAT
        ,[InteractionsAbandoned]        FLOAT
        ,[ServiceLevelTarget]           FLOAT
        ,[TalkTime]                     FLOAT
        ,[TotalInteractionsAnswered]    FLOAT
        ,[TotalInteractionsOffered]     FLOAT
        ,[WaitTime]                     INT
        ,[WrapUpTime]                   FLOAT
    );
    
    INSERT INTO #tmpBBVAOpsMetrics
    SELECT
        YEAR([row_date])
        ,MONTH([row_date])
        ,SUM(ISNULL([Holdtime],0))
        ,SUM(ISNULL([abncalls], 0) + ISNULL([othercalls], 0) - ISNULL([abncalls1], 0) - ISNULL([abncalls2], 0) - ISNULL([abncalls3], 0))
        AS [InteractionsAbandoned]
		,CASE 
			WHEN SUM(ISNULL(acdcalls, 0) + ISNULL([abncalls], 0) + ISNULL([othercalls], 0) - ISNULL([abncalls1], 0) - ISNULL([abncalls2], 0) - ISNULL([abncalls3], 0)) = 0 
				THEN 0
			ELSE SUM(ISNULL([acceptable], 0)) / SUM(ISNULL([acdcalls], 0) + ISNULL([abncalls], 0) + ISNULL([othercalls], 0) - ISNULL([abncalls1], 0) - ISNULL([abncalls2], 0) - ISNULL([abncalls3], 0))
		END AS [ServiceLevelTarget]
        ,SUM(ISNULL([acdtime],0)) AS [TalkTime]
        ,SUM(ISNULL([acdcalls],0)) AS [TotalInteractionsAnswered]
        ,SUM(ISNULL(acdcalls, 0) + ISNULL(abncalls, 0) + ISNULL(othercalls, 0) - ISNULL(abncalls1, 0) - ISNULL(abncalls2, 0) - ISNULL(abncalls3, 0)) AS [TotalInteractionsOffered]
        ,SUM(ISNULL([anstime],0)) AS [WaitTime]
        ,SUM(ISNULL([acwtime],0)) AS [WrapUpTime]
                 
            FROM [dbo].[Hsplit] WITH (NOLOCK)
                GROUP BY YEAR([row_date]), MONTH([row_date]);

 /*======================================== Creación y carga temporal #tmpQA ======================================*/  
 IF OBJECT_ID('tempdb..#tmpOpsMetricsBBVAQA') IS NOT NULL 
    DROP TABLE #tmpOpsMetricsBBVAQA;
                
        CREATE TABLE  #tmpOpsMetricsBBVAQA
          (
                  [Year]							INT 
				 ,[Month]							INT
				 ,[Client]							NVARCHAR(400) 
				 ,[idLobOPSMetrics]					INT
				 ,[CommitedFTE]						FLOAT
				 ,[FunctionalWorkstations]			INT
				 ,[ProductionHours]					FLOAT
				 ,[Contacts]						INT
				 ,[Completes]						INT
				 ,[FirstCallResolved]				INT
				 ,[TotalCustomerIssues]				INT
				 ,[FirstCallResolutionTarget]		INT
				 ,[BilledHours]						DECIMAL(17,2)
				 ,[PaidHours]						BIGINT
				 ,[TotalInteractionsOffered]		FLOAT
				 ,[TotalInteractionsAnswered]		FLOAT
				 ,[ServiceLevelTarget]				FLOAT
				 ,[WaitTime]						INT
				 ,[HoldTime]						FLOAT
				 ,[TalkTime]						FLOAT
				 ,[WrapUpTime]						FLOAT
				 ,[TargetHandleTime]				FLOAT
				 ,[InteractionsAbandoned]			FLOAT
				 ,[QAFatalError]					INT
				 ,[TargetSchedule]					FLOAT
				 ,[ActualSchedule]					FLOAT
				 ,[VolumeForecastClientTarget]		FLOAT
				 ,[VolumeForecastClientActual]		FLOAT

           );
        
        INSERT INTO #tmpOpsMetricsBBVAQA
        SELECT

				A.[Year]                          
				,A.[Month] 						
				,NULL AS [Client]						
				,6915 AS [idLobOPSMetrics]					
				,NULL AS [CommitedFTE]					
				,NULL AS [FunctionalWorkstations]		
				,NULL AS [ProductionHours]				
				,NULL AS [Contacts]					
				,NULL AS [Completes]					
				,NULL AS [FirstCallResolved]			
				,NULL AS [TotalCustomerIssues]			
				,NULL AS [FirstCallResolutionTarget]	
				,NULL AS [BilledHours]					
				,NULL AS [PaidHours]					
				,A.[TotalInteractionsAnswered]
				,A.[TotalInteractionsOffered]	
				,A.[ServiceLevelTarget]			
				,A.[WaitTime]				
				,A.[HoldTime]					
				,A.[TalkTime]				
				,A.[WrapUpTime]					
				,NULL AS [TargetHandleTime]			
				,A.[InteractionsAbandoned]		
				,NULL AS [QAFatalError]				
				,NULL AS [TargetSchedule]				
				,NULL AS [ActualSchedule]				
				,NULL AS [VolumeForecastClientTarget]	
				,NULL AS [VolumeForecastClientActual]	
                  
        FROM #tmpBBVAOpsMetrics AS A

/*======================================== Carga a la tabla fisica [dbo].[tbRecordVodafone] usando MERGE ======================================*/

     MERGE [dbo].[tbOpsMetricsBBVA] AS [tgt]
        USING
        (
              SELECT 
                 [Year]						
                ,[Month]						
                ,[Client]						
                ,[idLobOPSMetrics]				
                ,[CommitedFTE]					
                ,[FunctionalWorkstations]		
                ,[ProductionHours]				
                ,[Contacts]					
                ,[Completes]					
                ,[FirstCallResolved]			
                ,[TotalCustomerIssues]			
                ,[FirstCallResolutionTarget]
                ,[BilledHours]					
                ,[PaidHours]					
                ,[TotalInteractionsOffered]	
                ,[TotalInteractionsAnswered]
                ,[ServiceLevelTarget]			
                ,[WaitTime]					
                ,[HoldTime]					
                ,[TalkTime]					
                ,[WrapUpTime]					
                ,[TargetHandleTime]			
                ,[InteractionsAbandoned]		
                ,[QAFatalError]				
                ,[TargetSchedule]				
                ,[ActualSchedule]				
                ,[VolumeForecastClientTarget]
                ,[VolumeForecastClientActual]
             FROM #tmpOpsMetricsBBVAQA
        ) AS [src]
        ON
        
      (
            [src].[year] = [tgt].[year]  AND [src].[month] = [tgt].[month] 
  
        )
        -- For updates
        WHEN MATCHED THEN
          UPDATE 
              SET
                       
                 [tgt].[Year]						            =[src].[Year]						 
                ,[tgt].[Month]						            =[src].[Month]						
                ,[tgt].[Client]						            =[src].[Client]						
                ,[tgt].[idLobOPSMetrics]				        =[src].[idLobOPSMetrics]				
                ,[tgt].[CommitedFTE]					        =[src].[CommitedFTE]					
                ,[tgt].[FunctionalWorkstations]		            =[src].[FunctionalWorkstations]		
                ,[tgt].[ProductionHours]				        =[src].[ProductionHours]				
                ,[tgt].[Contacts]					            =[src].[Contacts]					  
                ,[tgt].[Completes]					            =[src].[Completes]					
                ,[tgt].[FirstCallResolved]			            =[src].[FirstCallResolved]			
                ,[tgt].[TotalCustomerIssues]			        =[src].[TotalCustomerIssues]			
                ,[tgt].[FirstCallResolutionTarget]				=[src].[FirstCallResolutionTarget]
                ,[tgt].[BilledHours]					        =[src].[BilledHours]					
                ,[tgt].[PaidHours]					            =[src].[PaidHours]					
                ,[tgt].[TotalInteractionsOffered]	            =[src].[TotalInteractionsOffered]	  
                ,[tgt].[TotalInteractionsAnswered]				=[src].[TotalInteractionsAnswered]
                ,[tgt].[ServiceLevelTarget]			            =[src].[ServiceLevelTarget]			
                ,[tgt].[WaitTime]					            =[src].[WaitTime]					  
                ,[tgt].[HoldTime]					            =[src].[HoldTime]					  
                ,[tgt].[TalkTime]					            =[src].[TalkTime]					  
                ,[tgt].[WrapUpTime]					            =[src].[WrapUpTime]					
                ,[tgt].[TargetHandleTime]			            =[src].[TargetHandleTime]			  
                ,[tgt].[InteractionsAbandoned]		            =[src].[InteractionsAbandoned]		
                ,[tgt].[QAFatalError]				            =[src].[QAFatalError]				  
                ,[tgt].[TargetSchedule]				            =[src].[TargetSchedule]				
                ,[tgt].[ActualSchedule]				            =[src].[ActualSchedule]				
                ,[tgt].[VolumeForecastClientTarget]				=[src].[VolumeForecastClientTarget]
                ,[tgt].[VolumeForecastClientActual]				=[src].[VolumeForecastClientActual]
                

        WHEN NOT MATCHED THEN
            INSERT
            (
                    [Year]						
                   ,[Month]						
                   ,[Client]						
                   ,[idLobOPSMetrics]				
                   ,[CommitedFTE]					
                   ,[FunctionalWorkstations]		
                   ,[ProductionHours]				
                   ,[Contacts]					
                   ,[Completes]					
                   ,[FirstCallResolved]			
                   ,[TotalCustomerIssues]			
                   ,[FirstCallResolutionTarget]
                   ,[BilledHours]					
                   ,[PaidHours]					
                   ,[TotalInteractionsOffered]	
                   ,[TotalInteractionsAnswered]
                   ,[ServiceLevelTarget]			
                   ,[WaitTime]					
                   ,[HoldTime]					
                   ,[TalkTime]					
                   ,[WrapUpTime]					
                   ,[TargetHandleTime]			
                   ,[InteractionsAbandoned]		
                   ,[QAFatalError]				
                   ,[TargetSchedule]				
                   ,[ActualSchedule]				
                   ,[VolumeForecastClientTarget]
                   ,[VolumeForecastClientActual]        
            )
            VALUES
            (
                    [src].[Year]						
                   ,[src].[Month]						
                   ,[src].[Client]						
                   ,[src].[idLobOPSMetrics]				
                   ,[src].[CommitedFTE]					
                   ,[src].[FunctionalWorkstations]		
                   ,[src].[ProductionHours]				
                   ,[src].[Contacts]					
                   ,[src].[Completes]					
                   ,[src].[FirstCallResolved]			
                   ,[src].[TotalCustomerIssues]			
                   ,[src].[FirstCallResolutionTarget]
                   ,[src].[BilledHours]					
                   ,[src].[PaidHours]					
                   ,[src].[TotalInteractionsOffered]	
                   ,[src].[TotalInteractionsAnswered]
                   ,[src].[ServiceLevelTarget]			
                   ,[src].[WaitTime]					
                   ,[src].[HoldTime]					
                   ,[src].[TalkTime]					
                   ,[src].[WrapUpTime]					
                   ,[src].[TargetHandleTime]			
                   ,[src].[InteractionsAbandoned]		
                   ,[src].[QAFatalError]				
                   ,[src].[TargetSchedule]				
                   ,[src].[ActualSchedule]				
                   ,[src].[VolumeForecastClientTarget]
                   ,[src].[VolumeForecastClientActual]
            );

     END TRY
        
        BEGIN CATCH
            SET @Error = 1;
            PRINT ERROR_MESSAGE();
        END CATCH
        /*=======================Eliminacion de temporales=========================*/

        IF OBJECT_ID('tempdb..#tmpBBVAOpsMetrics') IS NOT NULL
        DROP TABLE #tmpBBVAOpsMetrics;

        IF OBJECT_ID('tempdb..#tmpOpsMetricsBBVAQA') IS NOT NULL 
        DROP TABLE #tmpOpsMetricsBBVAQA;
     
    END