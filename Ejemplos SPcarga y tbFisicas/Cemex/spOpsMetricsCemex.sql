USE [Cemex]
GO
/*
<Informacion Creacion>
User_NT:E_1000687202 , E_1143864762, E_1233493216, E_1110286091, E_1053871829,E_1016102870, E_1010083873
Fecha: 2023-10-12
Descripcion: Se crea un sp de carga [spOpsMetricsCemex] con 3 temporales que extraen la información de diferentes servidores o diferentes bases
Al final se hace el Mergue en la tabla fisica [tbOpsMetricsCemex] para actualizar los registros existentes o insertar nuevos registros.

<Ejemplo>
      Exec [dbo].[spOpsMetricsCemex] '2023-01-01'
*/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[spOpsMetricsCemex] @DateStart DATE = NULL ,@DateEnd  DATE = NULL
AS

SET NOCOUNT ON;
    BEGIN
        BEGIN TRY
/*====================Bloque declaracion de variables==========*/
            DECLARE @ERROR INT =0;
            SET   @DateStart = ISNULL(@DateStart,CAST(GETDATE() AS DATE));
			SET   @DateEnd   = ISNULL(@DateEnd,CAST(GETDATE() AS DATE));
/*======================================== Creación y carga temporal #tmpCemexOpsMetrics ======================================*/  
            IF OBJECT_ID('tempdb..#tmpCemexOpsMetrics') IS NOT NULL DROP TABLE #tmpCemexOpsMetrics;
            CREATE TABLE #tmpCemexOpsMetrics
            (
                [Complete]                      INT
                ,[Contacts]                     INT
                ,[HoldTime]                     FLOAT
                ,[InteractionsAbandoned]        FLOAT
                ,[TalkTime]                     FLOAT
                ,[TotalInteractionsAnswered]    FLOAT
                ,[TotalInteractionsOffered]     FLOAT
                ,[WaitTime]                     INT
                ,[WrapUpTime]                  FLOAT
                ,[Year]                         INT
                ,[Month]                        INT
            );
            
            INSERT INTO #tmpCemexOpsMetrics
                SELECT 
                    SUM([AUXOUTCALLS])       AS  [Complete],
                    SUM([AUXOUTCALLS])       AS  [Contacts],
                    SUM([HOLDTIME])          AS  [HoldTime],
                    SUM([ABNCALLS])          AS  [InteractionsAbandoned],
                    SUM([ACDTIME])           AS  [TalkTime],
                    SUM([ACDCALLS])          AS  [TotalInteractionsAnswered],
                    SUM([CALLSOFFERED])      AS  [TotalInteractionsOffered],
                    SUM([ANSTIME])           AS  [WaitTime],
                    SUM([ACWTIME])           AS  [WrapUpTime],
                    YEAR([row_date])         AS  [Year],   
                    MONTH([row_date])        AS  [Month]
                FROM [WFM CMS].[dbo].[HSPLIT] WITH (NOLOCK) 
                WHERE
                    [SPLIT] IN ('1061','1086','1034','1053','1029','1021','1009','993','991','1077','1093','1025','1089','6608','1066','1060','994','1014','1097','1067','1111',
                    '1035','1022','1084','1004','989','1031','1015','1028','6607','995','6601','1020','1087','992','1082','6609','1059','1070','996','1030','1027','1043',
                    '1068','1079','6600','1096','1013','1045','1039','6606','1058','1055','1098','1005','997','1088','1051','1054','1036','1044','1032','1017','1062','1003',
                    '6605','1075','998','1091','1081','1057','1083','1012','6604','1046','999','1016','1019','1092','1037','1071','1048','1085','1023','1069','1056','1010',
                    '1000','1047','1072','1050','1011','1099','1040','1078','1033','1006','1052','1064','1002','1024','1080','1095','1049','1038','1065','1001','1018','6603',
                    '1063','1113','1007','1094','1090','1074','1008','1073','1112','1042','990','1115','1026','6602') 
                AND [ACD] = '1' AND YEAR([row_date]) BETWEEN YEAR(@DateStart) AND YEAR(@DateEnd)
				AND MONTH([row_date]) BETWEEN MONTH(@DateStart) AND MONTH(@DateEnd)
                GROUP BY YEAR([row_date]), MONTH([row_date]);
 /*======================================== Creación y carga temporal #tmpCemexOpsMetricsOAU ======================================*/  
            IF OBJECT_ID('tempdb..#tmpCemexOpsMetricsOAU') IS NOT NULL DROP TABLE #tmpCemexOpsMetricsOAU;              
            CREATE TABLE #tmpCemexOpsMetricsOAU
            (
                [Year]                          INT
                ,[Month]                        INT							
                ,[VolumeForecastClientActual]	FLOAT
                ,[VolumeForecastClientTarget]	FLOAT
            );

            INSERT INTO #tmpCemexOpsMetricsOAU
                SELECT
                    YEAR([Fecha])   AS  [Year]  
                    ,MONTH([Fecha]) AS  [Month]
                    ,SUM (VOLUME)   AS [VolumeForecastClientActual]
                    ,SUM (VOLUME)   AS [VolumeForecastClientTarget]
                FROM [Cemex].[dbo].[tbOAU] WITH(NOLOCK)
                WHERE YEAR([Fecha]) BETWEEN YEAR(@DateStart) AND YEAR(@DateEnd)
				AND MONTH([Fecha]) BETWEEN MONTH(@DateStart) AND MONTH(@DateEnd)
                GROUP BY YEAR([Fecha]) ,MONTH([Fecha]);
 /*======================================== Creación y carga temporal #tmpAdherenceToDashboard ======================================*/  
            IF OBJECT_ID('tempdb..#tmpAdherenceToDashboard') IS NOT NULL DROP TABLE #tmpAdherenceToDashboard;
            CREATE TABLE #tmpAdherenceToDashboard
            (
                [Year]					INT
                ,[Month]				INT
                ,[ActualSchedule]		FLOAT
                ,[ProductionHours]		FLOAT
                ,[TargetSchedule]		FLOAT
                ,[Client]				VARCHAR(100)
            );

            INSERT INTO #tmpAdherenceToDashboard
                SELECT
                    YEAR([date])                AS [Year]
                    ,MONTH([date])              AS [Month]
                    ,SUM([WorkTotal])           AS [ActualSchedule]
                    ,SUM([WorkTotal])           AS [ProductionHours]
                    ,SUM([progscheduletotal])   AS [TargetSchedule]
                    ,[Client]
                FROM [TPCCP-DB05\SCTRANS].[DataSet].[tpad].[tbAdherenceToDashboard] WITH(NOLOCK) 
                WHERE [Client] = 'Cemex Colombia' AND YEAR([date]) BETWEEN YEAR(@DateStart) AND YEAR(@DateEnd)
				AND MONTH([date]) BETWEEN MONTH(@DateStart) AND MONTH(@DateEnd)
                GROUP BY YEAR([date]),MONTH([date]), [Client];           
 /*======================================== Creación y carga temporal #tmpOpsMetricsCemexQA ======================================*/  
            IF OBJECT_ID('tempdb..#tmpOpsMetricsCemexQA') IS NOT NULL DROP TABLE #tmpOpsMetricsCemexQA;
            CREATE TABLE  #tmpOpsMetricsCemexQA
            (   
                [Year]							INT 
                ,[Month]				        INT
                ,[Client]						NVARCHAR(400) 
                ,[IdLobOPSMetrics]				INT
                ,[CommitedFTE]					FLOAT
                ,[FunctionalWorkstations]	    INT
                ,[ProductionHours]				FLOAT
                ,[Contacts]						INT
                ,[Completes]					INT
                ,[FirstCallResolved]			INT
                ,[TotalCustomerIssues]			INT
                ,[FirstCallResolutionTarget]	INT
                ,[BilledHours]					DECIMAL(17,2)
                ,[PaidHours]					BIGINT
                ,[TotalInteractionsOffered]		FLOAT
                ,[TotalInteractionsAnswered]	FLOAT
                ,[ServiceLevelTarget]			FLOAT
                ,[WaitTime]						INT
                ,[HoldTime]						FLOAT
                ,[TalkTime]						FLOAT
                ,[WrapUpTime]					FLOAT
                ,[TargetHandleTime]				FLOAT
                ,[InteractionsAbandoned]		FLOAT
                ,[QAFatalError]					INT
                ,[TargetSchedule]				FLOAT
                ,[ActualSchedule]				FLOAT
                ,[VolumeForecastClientTarget]	FLOAT
                ,[VolumeForecastClientActual]	FLOAT
            );
                
            INSERT INTO #tmpOpsMetricsCemexQA
                SELECT
                    A.[Year]                          
                    ,A.[Month] 						
                    ,'Cemex Colombia'				AS [Client]						
                    ,5058							AS [IdLobOPSMetrics]					
                    ,NULL							AS [CommitedFTE]			
                    ,NULL							AS [FunctionalWorkstations]		
                    ,C.[ProductionHours]		
                    ,A.[Contacts]					AS [Contacts]					
                    ,A.[Complete]					AS [Completes]					 
                    ,NULL							AS [FirstCallResolved]		
                    ,NULL							AS [TotalCustomerIssues]			
                    ,0.80							AS [FirstCallResolutionTarget]	
                    ,NULL							AS [BilledHours]					
                    ,NULL							AS [PaidHours]				
                    ,A.[TotalInteractionsAnswered]
                    ,A.[TotalInteractionsOffered]	
                    ,0.83							AS [ServiceLevelTarget]	
                    ,A.[WaitTime]				
                    ,A.[HoldTime]					
                    ,A.[TalkTime]				
                    ,A.[WrapUpTime]					
                    ,424							AS [TargetHandleTime]		
                    ,A.[InteractionsAbandoned]		
                    ,NULL							AS [QAFatalError]				
                    ,C.[TargetSchedule]				
                    ,C.[ActualSchedule]	
                    ,B.[VolumeForecastClientTarget]	
                    ,B.[VolumeForecastClientActual]	        
                FROM #tmpCemexOpsMetrics AS A
                INNER JOIN  #tmpAdherenceToDashboard AS C 
                ON A.[Year]=C.[Year] AND A.[Month]=C.[Month]
                INNER JOIN #tmpCemexOpsMetricsOAU AS B 
                ON A.[Year]=B.[Year] AND A.[Month]=B.[Month];
/*======================================== Carga a la tabla fisica [dbo].[tbOpsMetricsCemex] usando MERGE ======================================*/
            MERGE [dbo].[tbOpsMetricsCemex] AS [tgt]
            USING
            (
                SELECT 
                    [Year]						
                    ,[Month]						
                    ,[Client]						
                    ,[IdLobOPSMetrics]				
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
                FROM #tmpOpsMetricsCemexQA
            ) AS [src]
            ON    
            (
                [src].[year] = [tgt].[year]  AND [src].[month] = [tgt].[month] 
            )
            -- For updates
            WHEN MATCHED 
            THEN UPDATE 
                SET 
                    [tgt].[Year]						            =[src].[Year]						 
                    ,[tgt].[Month]						            =[src].[Month]						
                    ,[tgt].[Client]						            =[src].[Client]						
                    ,[tgt].[IdLobOPSMetrics]				        =[src].[IdLobOPSMetrics]				
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
                        
            WHEN NOT MATCHED 
            THEN INSERT
                (
                    [Year]						
                    ,[Month]						
                    ,[Client]						
                    ,[IdLobOPSMetrics]				
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
                    ,[src].[IdLobOPSMetrics]				
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
    IF OBJECT_ID('tempdb..#tmpCemexOpsMetrics') IS NOT NULL DROP TABLE #tmpCemexOpsMetrics;
    IF OBJECT_ID('tempdb..#tmpCemexOpsMetricsOAU') IS NOT NULL DROP TABLE #tmpCemexOpsMetricsOAU;
    IF OBJECT_ID('tempdb..#tmpAdherenceToDashboard') IS NOT NULL DROP TABLE #tmpAdherenceToDashboard;
    IF OBJECT_ID('tempdb..#tmpOpsMetricsCemexQA') IS NOT NULL DROP TABLE #tmpOpsMetricsCemexQA;
     
    END