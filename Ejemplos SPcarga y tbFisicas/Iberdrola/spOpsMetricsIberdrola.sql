USE [Iberdrola]
GO



SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
<Informacion Creacion>
User_NT:E_1053871829, E_1016102870, E_1105792917, E_1012322897, E_1088352987, E_1000687202, E_1143864762, E_1015216308, E_1010083873, E_1014297790   
Fecha: 2023-09-29
Descripcion: Se crea un sp de carga [spOpsMetricsIberdrola] con 2 temporales.
Al final se hace el Mergue en la tabla fisica [tbOpsMetricsIberdrola] para actualizar los registros existentes o insertar nuevos registros.

<Ejemplo>
      Exec [dbo].[spOpsMetricsIberdrola] 
*/
CREATE PROCEDURE [dbo].[spOpsMetricsIberdrola] 
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

        
     
/*======================================== Creación y carga temporal #tmpOrangeSCTrans ======================================*/

        IF OBJECT_ID('tempdb..#tmpIberdrolaSCTransOpsMetrics') IS NOT NULL 
        DROP TABLE #tmpIberdrolaSCTransOpsMetrics;

        CREATE TABLE #tmpIberdrolaSCTransOpsMetrics
        (   
			[Year]							INT
			,[Month]						INT
            ,[ActualSchedule]				FLOAT
            ,[ProductionHours]				FLOAT             
            ,[TargetSchedule]				FLOAT          

        );

		INSERT INTO #tmpIberdrolaSCTransOpsMetrics
		SELECT 
			YEAR([Date])
			,MONTH([Date])
			,SUM([HsDim])
			,SUM([WorkTotal])
			,SUM([HsDimIdeal])
             

		FROM [TPCCP-DB05\SCTRANS].[DataSet].[tpad].[tbAdherenceToDashboard] WITH (NOLOCK)
		WHERE [Client] = 'IBERDROLA SOLUTIONS LLC' and [Date] BETWEEN @DateStart AND @DateEnd 
		GROUP BY YEAR([Date]),MONTH([Date]);

   IF OBJECT_ID('tempdb..#tmpOpsMetricsIberdrolaQA') IS NOT NULL 
    DROP TABLE #tmpOpsMetricsIberdrolaQA;
                
        CREATE TABLE  #tmpOpsMetricsIberdrolaQA
            (
                 [year]								INT 
				 ,[month]							INT
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
        
        INSERT INTO #tmpOpsMetricsIberdrolaQA
        SELECT

			      A.[year]							
				 ,A.[month]							
				 ,'IBERDROLA SOLUTIONS LLC' AS [Client]						
				 ,13260 AS [idLobOPSMetrics]				
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
				 ,NULL AS [TotalInteractionsOffered]		
				 ,NULL AS [TotalInteractionsAnswered]		
				 ,NULL AS [ServiceLevelTarget]				
				 ,NULL AS [WaitTime]						
				 ,NULL AS [HoldTime]						
				 ,NULL AS [TalkTime]						
				 ,NULL AS [WrapUpTime]						
				 ,NULL AS [TargetHandleTime]				
				 ,NULL AS [InteractionsAbandoned]			
				 ,NULL AS [QAFatalError]					
				 ,A.[TargetSchedule]				
				 ,A.[ActualSchedule]				
				 ,NULL AS [VolumeForecastClientTarget]	
				 ,NULL AS [VolumeForecastClientActual]	

		FROM #tmpIberdrolaSCTransOpsMetrics AS A; 

    /*======================================== Carga a la tabla fisica [dbo].[tbRecordVodafone] usando MERGE ======================================*/

     MERGE [dbo].[tbOpsMetricsIberdrola] AS [tgt]
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
             FROM #tmpOpsMetricsIberdrolaQA
        ) AS [src]
        ON
        (
           
            [src].[year] = [tgt].[year] AND [src].[month] = [tgt].[month] AND  [src].[Client] = [tgt].[Client] AND  [src].[idLobOPSMetrics] = [tgt].[idLobOPSMetrics]
            
            
        )
        -- For updates
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

        IF OBJECT_ID('tempdb..#tmpIberdrolaSCTransOpsMetrics') IS NOT NULL
        DROP TABLE #tmpIberdrolaSCTransOpsMetrics;

        IF OBJECT_ID('tempdb..#tmpOpsMetricsIberdrolaQA') IS NOT NULL 
        DROP TABLE #tmpOpsMetricsIberdrolaQA;
     
    END