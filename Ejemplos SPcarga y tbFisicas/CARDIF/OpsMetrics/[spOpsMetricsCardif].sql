USE [Cardif]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*
<Informacion Creacion>
User_NT:E_1015216308 , E_1105792917
Fecha: 2023-10-04
Descripcion:
Se crea un sp de carga [spOpsMetricsCardif] con 3 temporales que son #tmpCardifHSplit, #tmpAdherenceToDashboard y #tmpOpsMetricsCardifQA
Al final se hace el Merge en la tabla fisica [tbOpsMetricsCardif] para actualizar los registros existentes o insertar nuevos registros


<Ejemplo>
Exec [dbo].[spOpsMetricsCardif] 
*/
CREATE PROCEDURE [dbo].[spOpsMetricsCardif]
 @DateStart DATE = NULL
,@DateEnd  DATE = NULL
AS

SET NOCOUNT ON;

    BEGIN
        BEGIN TRY
        /*===============Bloque declaracion de variables==========*/

        DECLARE @ERROR INT = 0;
        SET   @DateStart = ISNULL(@DateStart,CAST(GETDATE()-60 AS DATE));
        SET   @DateEnd   = ISNULL(@DateEnd,CAST(GETDATE() AS DATE));
        
        
/*======================================== Creación y carga temporal #tmpCardifHSplit ======================================*/

        IF OBJECT_ID('tempdb..#tmpCardifHSplit') IS NOT NULL 
        DROP TABLE #tmpCardifHSplit;

        CREATE TABLE #tmpCardifHSplit
        (   
             [Year]                         INT
            ,[Month]                        INT
            ,[HoldTime]                     FLOAT
            ,[InteractionsAbandoned]        FLOAT
            ,[TalkTime]                     FLOAT
            ,[TotalInteractionsAnswered]    FLOAT
            ,[TotalInteractionsOffered]     FLOAT   
            ,[WaitTime]						INT
            ,[WrapUpTime]					FLOAT
        );
        INSERT INTO #tmpCardifHSplit
		SELECT 
             YEAR([row_date])
            ,MONTH([row_date])
            ,SUM(ISNULL([abncalls] ,0) - ISNULL([abncalls1] ,0) - ISNULL([abncalls2] ,0) - ISNULL([abncalls3] ,0) - ISNULL([abncalls4] ,0))      
            ,SUM(ISNULL([abncalls],0))                
            ,SUM(ISNULL([acdtime],0))      
            ,SUM(ISNULL([acdcalls],0))     
            ,SUM(ISNULL([acdcalls] ,0) + ISNULL([abncalls],0) + ISNULL([othercalls],0) - ISNULL([abncalls1],0) - ISNULL([abncalls2],0) - ISNULL([abncalls3],0))   
            ,SUM(ISNULL([anstime],0))     
            ,SUM(ISNULL([acwtime],0))
			
        FROM [10.151.230.21\SCOFFS].[WFM CMS].[dbo].[hsplit] WITH(NOLOCK)
		WHERE [row_date] BETWEEN @dateStart AND @dateEnd
        GROUP BY YEAR([row_date]) , MONTH([row_date]);
    
--======================Creación y carga temporal #tmpAdherenceToDashboard======================================*/
      IF OBJECT_ID('tempdb..#tmpAdherenceToDashboard') IS NOT NULL 
        DROP TABLE #tmpAdherenceToDashboard;

        CREATE TABLE #tmpAdherenceToDashboard
        (   
            [Year]                          INT
            ,[Month]                        INT
            ,[ActualSchedule]               FLOAT
            ,[ProductionHours]              FLOAT             
            ,[TargetSchedule]               FLOAT    
            ,[Client]                       VARCHAR(100)

        );

        INSERT INTO #tmpAdherenceToDashboard
        SELECT 
             YEAR([Date])
            ,MONTH([Date])
            ,SUM([WorkTotal])
            ,SUM([WorkTotal])
            ,SUM([HsDimIdeal])
            ,[Client]
             

        FROM [TPCCP-DB05\SCTRANS].[DataSet].[tpad].[tbAdherenceToDashboard]  WITH (NOLOCK)--Preguntar bien por la BD si usamos la misma que Ibedrola
        WHERE [Client] LIKE '%Cardif%' AND [Date] BETWEEN @DateStart AND @DateEnd 
        GROUP BY YEAR([Date]),MONTH([Date]),[Client];
/*======================================== Creación y carga temporal #tmpOpsMetricsCardifQA ======================================*/
		IF OBJECT_ID('tempdb..#tmpOpsMetricsCardifQA') IS NOT NULL DROP TABLE #tmpOpsMetricsCardifQA;
        CREATE TABLE #tmpOpsMetricsCardifQA(
               
             [year]                             INT                    
            ,[month]                            INT
            ,[Client]                           NVARCHAR(400)
            ,[idLobOPSMetrics]                  INT
            ,[CommitedFTE]                      FLOAT
            ,[FunctionalWorkstations]           INT
            ,[ProductionHours]                  FLOAT
            ,[Contacts]                         INT
            ,[Completes]                        INT
            ,[FirstCallResolved]                INT
            ,[TotalCustomerIssues]              INT
            ,[FirstCallResolutionTarget]        INT
            ,[BilledHours]                      DECIMAL(17,2)
            ,[PaidHours]                        BIGINT
            ,[TotalInteractionsOffered]         FLOAT
            ,[TotalInteractionsAnswered]        FLOAT
            ,[ServiceLevelTarget]               FLOAT
            ,[WaitTime]                         INT
            ,[HoldTime]                         FLOAT
            ,[TalkTime]                         FLOAT
            ,[WrapUpTime]                       FLOAT
            ,[TargetHandleTime]                 FLOAT
            ,[InteractionsAbandoned]            FLOAT
            ,[QAFatalError]                     INT
            ,[TargetSchedule]                   FLOAT
            ,[ActualSchedule]                   FLOAT
            ,[VolumeForecastClientTarget]       FLOAT
            ,[VolumeForecastClientActual]       FLOAT
           
           );
		 INSERT INTO #tmpOpsMetricsCardifQA
			SELECT
                  A.[year]                          
                 ,A.[month]                         
                 ,'Cardif' AS [Client]                          
                 ,19138 AS [idLobOPSMetrics]                 
                 ,NULL AS [CommitedFTE]                     
                 ,NULL AS [FunctionalWorkstations]          
                 ,A.[ProductionHours]               
                 ,NULL AS [Contacts]                        
                 ,NULL AS [Completes]                       
                 ,NULL AS [FirstCallResolved]               
                 ,NULL AS [TotalCustomerIssues]             
                 ,NULL AS [FirstCallResolutionTarget]       
                 ,NULL AS [BilledHours]                     
                 ,NULL AS [PaidHours]                       
                 ,B.[TotalInteractionsOffered]      
                 ,B.[TotalInteractionsAnswered]     
                 ,NULL AS [ServiceLevelTarget]              
                 ,B.[WaitTime]                        
                 ,B.[HoldTime]                      
                 ,B.[TalkTime]                      
                 ,B.[WrapUpTime]                      
                 ,NULL AS [TargetHandleTime]                
                 ,B.[InteractionsAbandoned]         
                 ,NULL AS [QAFatalError]                    
                 ,A.[TargetSchedule]                
                 ,A.[ActualSchedule]                
                 ,NULL AS [VolumeForecastClientTarget]    
                 ,NULL AS [VolumeForecastClientActual]  
                
    
		FROM #tmpAdherenceToDashboard  AS A WITH(NOLOCK)
		INNER JOIN #tmpCardifHSplit AS B WITH (NOLOCK)
		ON A.[Year] = B.[Year] and A.[Month] = B.[Month];
   

/*======================================== Carga a la tabla fisica [dbo].[tbOpsMetricsCardif] usando MERGE ======================================*/

		MERGE [dbo].[tbOpsMetricsCardif] AS [tgt]
        USING
			(
              SELECT 
                 [year]                      
                ,[month]                    
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
             FROM #tmpOpsMetricsCardifQA
        ) AS [src]
        ON
        (
            [src].[year] = [tgt].[year] AND [src].[month] = [tgt].[month] AND  [src].[Client] = [tgt].[Client] AND  [src].[idLobOPSMetrics] = [tgt].[idLobOPSMetrics]
                       
        )
        WHEN MATCHED THEN
          UPDATE 
              SET
                       
                 [tgt].[year]                                  =[src].[year]                       
                ,[tgt].[month]                                 =[src].[month]                   
                ,[tgt].[Client]                                =[src].[Client]                  
                ,[tgt].[idLobOPSMetrics]                       =[src].[idLobOPSMetrics]         
                ,[tgt].[CommitedFTE]                           =[src].[CommitedFTE]             
                ,[tgt].[FunctionalWorkstations]                =[src].[FunctionalWorkstations]  
                ,[tgt].[ProductionHours]                       =[src].[ProductionHours]         
                ,[tgt].[Contacts]                              =[src].[Contacts]                    
                ,[tgt].[Completes]                             =[src].[Completes]               
                ,[tgt].[FirstCallResolved]                     =[src].[FirstCallResolved]       
                ,[tgt].[TotalCustomerIssues]                   =[src].[TotalCustomerIssues]     
                ,[tgt].[FirstCallResolutionTarget]             =[src].[FirstCallResolutionTarget]
                ,[tgt].[BilledHours]                           =[src].[BilledHours]             
                ,[tgt].[PaidHours]                             =[src].[PaidHours]               
                ,[tgt].[TotalInteractionsOffered]              =[src].[TotalInteractionsOffered]    
                ,[tgt].[TotalInteractionsAnswered]             =[src].[TotalInteractionsAnswered]
                ,[tgt].[ServiceLevelTarget]                    =[src].[ServiceLevelTarget]      
                ,[tgt].[WaitTime]                              =[src].[WaitTime]                    
                ,[tgt].[HoldTime]                              =[src].[HoldTime]                    
                ,[tgt].[TalkTime]                              =[src].[TalkTime]                    
                ,[tgt].[WrapUpTime]                            =[src].[WrapUpTime]              
                ,[tgt].[TargetHandleTime]                      =[src].[TargetHandleTime]            
                ,[tgt].[InteractionsAbandoned]                 =[src].[InteractionsAbandoned]   
                ,[tgt].[QAFatalError]                          =[src].[QAFatalError]                
                ,[tgt].[TargetSchedule]                        =[src].[TargetSchedule]          
                ,[tgt].[ActualSchedule]                        =[src].[ActualSchedule]          
                ,[tgt].[VolumeForecastClientTarget]            =[src].[VolumeForecastClientTarget]
                ,[tgt].[VolumeForecastClientActual]            =[src].[VolumeForecastClientActual]
                

        WHEN NOT MATCHED THEN
            INSERT
            (
                    [year]                       
                   ,[month]                 
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
                    [src].[year]                       
                   ,[src].[month]                   
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

     IF OBJECT_ID('tempdb..#tmpCardifHSplit') IS NOT NULL DROP TABLE #tmpCardifHSplit;
     IF OBJECT_ID('tempdb..#tmpAdherenceToDashboard') IS NOT NULL DROP TABLE #tmpAdherenceToDashboard;
     IF OBJECT_ID('tempdb..#tmpOpsMetricsCardifQA') IS NOT NULL DROP TABLE #tmpOpsMetricsCardifQA;
     
  END