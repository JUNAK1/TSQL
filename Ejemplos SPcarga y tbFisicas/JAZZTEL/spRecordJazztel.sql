USE [Orange]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
<Informacion Creacion>
User_NT:E_1015216308
Fecha: 2023-09-20
Descripcion:
Se crea un sp de carga [spRecordJazztel] con 3 temporales que son #tmpJazztelReal, #tmptbOAUJazztel y #tmpRecordJazztelQA
Al final se hace el Merge en la tabla fisica [tbRecordJazztel] para actualizar los registros existentes o insertar nuevos registros

<Ejemplo>
Exec [dbo].[spRecordJazztel] 
*/
ALTER PROCEDURE [dbo].[spRecordJazztel]
 @DateStart DATE = NULL
,@DateEnd  DATE = NULL
AS

SET NOCOUNT ON;

    BEGIN
        BEGIN TRY
        /*===============Bloque declaracion de variables==========*/
        
        DECLARE @ERROR INT = 0;
		SET   @DateStart = ISNULL(@DateStart,CAST(GETDATE()-45 AS DATE));
        SET   @DateEnd   = ISNULL(@DateEnd,CAST(GETDATE() AS DATE));
		
        
        /*======================================== Creación y carga temporal #tmpJazztelReal ======================================*/

        IF OBJECT_ID('tempdb..#tmpJazztelReal') IS NOT NULL 
        DROP TABLE #tmpJazztelReal;

        CREATE TABLE #tmpJazztelReal
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

        INSERT INTO #tmpJazztelReal
        SELECT
		 SUM(ISNULL([TiempoAvail],0)) AS [Avail]
		,NULL AS [AuxProd] 
		,SUM(ISNULL([TotalAux],0)) AS [AuxNoProd]
		,SUM(ISNULL([acdtime],0)) AS [TalkTime]
		,SUM(ISNULL([holdtime],0)) AS [HoldTime]
		,SUM(ISNULL([acwtime],0)) AS [ACWTime]
		,NULL AS [RingTime]
		,SUM(ISNULL([acdcalls],0)) AS [RealInteractionsAnswered]
		,SUM(ISNULL([callsoffered],0)) AS [RealInteractionsOffered]
		,CASE
			WHEN SUM([callsoffered]) = 0 OR SUM([callsoffered]) IS NULL
				THEN 0
			ELSE (SUM(ISNULL([acceptable],0))) / SUM([callsoffered]) 
				END AS  [KPIValue]
		,SUM(ISNULL([callsoffered],0)) AS [Weight]
		,NULL AS [Available productive]
		,[rowdate] AS [rowdate]
      
    FROM [TPCCP-DB08\SCDOM].[Orange].[dbo].[tbJazztelRecordUpLoad] WITH (NOLOCK)
	WHERE [rowdate] BETWEEN @DateStart AND @DateEnd
    GROUP BY 
    [rowdate]
		
	/*======================================== Creación y carga temporal #tmptbOAUJazztel ======================================*/

	IF OBJECT_ID('tempdb..#tmptbOAUJazztel') IS NOT NULL DROP TABLE #tmptbOAUJazztel;

   CREATE TABLE #tmptbOAUJazztel(

     [Fecha]                    DATE
    ,[FCSTInteractionsAnswered] DECIMAL
    ,[KPIprojection]            FLOAT
    ,[SHKprojection]            FLOAT
    ,[ABSprojection]            FLOAT
    ,[AHTprojection]            DECIMAL
    ,[KPIWeight]                DECIMAL
    ,[ReqHours]                 DECIMAL
    ,[FCSTStafftime]            FLOAT

)
INSERT INTO #tmptbOAUJazztel
SELECT
    
    [Fecha]                                             AS [Fecha]                      
    ,SUM(ISNULL([Volume],0))                            AS [FCSTInteractionsAnswered]    
    ,SUM(ISNULL(CAST([SL] AS FLOAT),0))                 AS [KPIprojection]          
    ,CASE
        WHEN SUM(ISNULL([Net Staff],0))=0 
            THEN 0
        ELSE
            (1-(SUM(ISNULL([Productive Staff],0))/SUM([Net Staff])))                            
        END                                             AS [SHKprojection]          
    ,CASE
        WHEN SUM(ISNULL([Scheduled Staff],0))=0
            THEN 0
        ELSE
            (1-(SUM(ISNULL([Net Staff],0))/SUM([Scheduled Staff])))                     
        END                                             AS [ABSprojection]          
    ,SUM(ISNULL([AHT],0))                               AS [AHTprojection]          
    ,SUM(ISNULL([Volume],0))                            AS [KPIWeight]              
    ,NULL                                               AS [ReqHours]                   
    ,SUM(ISNULL([Net Staff],0))/2                       AS [FCSTStafftime]  

FROM [dbo].[tbOAU] WITH (NOLOCK)
WHERE [Campaña]='Jazztel' AND [fecha] BETWEEN @DateStart AND @DateEnd
GROUP BY [Fecha];


    /*======================================== Creación y carga temporal #tmpRecordJazztelQA ======================================*/  
   IF OBJECT_ID('tempdb..#tmpRecordJazztelQA') IS NOT NULL DROP TABLE #tmpRecordJazztelQA;
                
        CREATE TABLE  #tmpRecordJazztelQA
            (
                 [Id]                            INT 
                ,[IdClient]                      INT
                ,[Avail]                         NUMERIC
                ,[AuxProd]                       INT
                ,[AuxNoProd]                     NUMERIC
                ,[TalkTime]                      NUMERIC
                ,[HoldTime]                      NUMERIC
                ,[ACWTime]                       NUMERIC
                ,[RingTime]                      NUMERIC --queda en NULL
                ,[RealInteractionsAnswered]      NUMERIC
                ,[RealInteractionsOffered]       INT
                ,[KPIValue]                      NUMERIC
				,[Weight]						 INT  
                ,[AvailableProductive]           NUMERIC --queda en NULL
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
        
        INSERT INTO #tmpRecordJazztelQA
        SELECT
            1214 AS [Id]
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
		    ,FR.[Weight]						
            ,FR.[AvailableProductive]
            ,OA.[FCSTInteractionsAnswered]
            ,OA.[KPIprojection]
            ,OA.[SHKprojection]
            ,OA.[ABSprojection]
            ,OA.[AHTprojection]
            ,OA.[KPIWeight]
            ,OA.[ReqHours]
            ,OA.[FCSTStafftime]
            ,FR.[Fecha]
            ,GETDATE()
    FROM #tmpJazztelReal AS FR WITH(NOLOCK)
    INNER JOIN #tmptbOAUJazztel OA
    ON FR.[Fecha] = OA.[Fecha]


    /*======================================== Carga a la tabla fisica [dbo].[tbRecordVodafone] usando MERGE ======================================*/

    MERGE [dbo].[tbRecordJazztel] AS [tgt]
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
				,[Weight]					
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
				
			FROM #tmpRecordJazztelQA
        ) AS [src]
        ON
        (
           
            [src].[Avail] = [tgt].[Avail] AND [src].[AuxNoProd] = [tgt].[AuxNoProd] AND  [src].[Fecha] = [tgt].[Fecha]
			--AND [src].[AuxProd] = [tgt].[AuxProd] 
			
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
                ,[tgt].[RingTime]                 = [src].[RingTime] 
                ,[tgt].[RealInteractionsAnswered] = [src].[RealInteractionsAnswered]    
                ,[tgt].[RealInteractionsOffered]  = [src].[RealInteractionsOffered]     
                ,[tgt].[KPIValue]                 = [src].[KPIValue] 
				,[tgt].[Weight]					  = [src].[Weight]	
                ,[tgt].[AvailableProductive]      = [src].[AvailableProductive]
                ,[tgt].[FCSTInteractionsAnswered] = [src].[FCSTInteractionsAnswered]    
                ,[tgt].[KPIprojection]            = [src].[KPIprojection]               
                ,[tgt].[SHKprojection]            = [src].[SHKprojection]               
                ,[tgt].[ABSprojection]            = [src].[ABSprojection]               
                ,[tgt].[AHTprojection]            = [src].[AHTprojection]               
                ,[tgt].[KPIWeight]                = [src].[KPIWeight]                   
                ,[tgt].[ReqHours]                 = [src].[ReqHours]                    
                ,[tgt].[FCSTStafftime]            = [src].[FCSTStafftime]
                ,[tgt].[Fecha]                    = [src].[Fecha]    
                ,[tgt].[LastUpdateDate]           = [src].[LastUpdateDate]           

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
					,[Weight]					
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
					,[src].[Weight]					
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

     IF OBJECT_ID('tempdb..#tmpRecordJazztelQA') IS NOT NULL DROP TABLE #tmpRecordJazztelQA;
     IF OBJECT_ID('tempdb..#tmptbOAUJazztel') IS NOT NULL DROP TABLE #tmptbOAUJazztel;
	 IF OBJECT_ID('tempdb..#tmpJazztelReal') IS NOT NULL DROP TABLE #tmpJazztelReal;
     
    END