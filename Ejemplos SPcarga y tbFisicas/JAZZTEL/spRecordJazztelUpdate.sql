USE [Orange]
GO

/****** Object:  StoredProcedure [dbo].[spRecordJazztel]    Script Date: 22/09/2023 12:04:18 p. m. ******/
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

<Update> 2023-09-20
User_NT:pachon.11
Tps:N/A
descripcion: Se adicionan la precisión y la escala de los tios de datos Decimal y numeric, se adiciona el campo idhc en la Temp #tmptbOAUJazztel ya que es el mismo id cliente quemado.

<Update> 2023-09-22
User_NT: E_1088352987
Tps: 
descripcion: Se realizo la modificacion de eliminar la tabla física [dbo].[tbRecordJazztel] para volver a crearla con los campos organizados, tomando como base el archivo de excel 'Estructura Final Record Upload'. 
Además, se modifico la tabla temporal #tmpRecordJazztelQA y el bloque de inserción de datos a la tabla física para que los campos coincidan en su nuevo orden.

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
           		--DECLARE @dateStart DATE=NULL,@dateEnd DATE=NULL

        DECLARE @ERROR INT = 0;
		SET   @DateStart = ISNULL(@DateStart,CAST(GETDATE()-45 AS DATE));
        SET   @DateEnd   = ISNULL(@DateEnd,CAST(GETDATE() AS DATE));
		
        
        /*======================================== Creación y carga temporal #tmpJazztelReal ======================================*/

        IF OBJECT_ID('tempdb..#tmpJazztelReal') IS NOT NULL 
        DROP TABLE #tmpJazztelReal;

        CREATE TABLE #tmpJazztelReal
        (   
             [Avail]                     NUMERIC(18,0)
            ,[AuxProd]                   INT
            ,[AuxNoProd]                 NUMERIC(18,0)
            ,[TalkTime]                  NUMERIC(18,0)
            ,[HoldTime]                  NUMERIC(18,0)
            ,[ACWTime]                   NUMERIC(18,0)
            ,[RingTime]                  NUMERIC(18,0)
            ,[RealInteractionsAnswered]  NUMERIC(18,0)
            ,[RealInteractionsOffered]   INT
            ,[KPIValue]                  NUMERIC(18,0)
			,[Weight]					 INT 
            ,[AvailableProductive]       NUMERIC(18,0) 
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
    ,[Id]						INT
	,[FCSTInteractionsAnswered] DECIMAL(18,0)
    ,[KPIprojection]            FLOAT
    ,[SHKprojection]            FLOAT
    ,[ABSprojection]            FLOAT
    ,[AHTprojection]            DECIMAL(18,0)
    ,[KPIWeight]                DECIMAL(18,0)
    ,[ReqHours]                 DECIMAL(18,0)
    ,[FCSTStafftime]            FLOAT

)
INSERT INTO #tmptbOAUJazztel
SELECT
    
    [Fecha]                                             AS [Fecha]                      
    ,[IdHC]												AS [Id]
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
	,CASE
		 WHEN SUM([Scheduled Staff]) = 0 OR SUM([Scheduled Staff]) IS NULL
			THEN 0 
			ELSE (SUM(ISNULL([Volume],0)) * SUM(ISNULL([AHT],0)) * (1-SUM(ISNULL([Net Staff],0))/SUM(ISNULL([Scheduled Staff],0))) * (1-0.15)/3600)
		END																   AS [ReqHours]
    ,SUM(ISNULL([Net Staff],0))/2                       AS [FCSTStafftime]  

FROM [dbo].[tbOAU] WITH (NOLOCK)
WHERE [Campaña]='Jazztel' AND [fecha] BETWEEN @DateStart AND @DateEnd
GROUP BY [Fecha],[IdHC];


    /*======================================== Creación y carga temporal #tmpRecordJazztelQA ======================================*/  
   IF OBJECT_ID('tempdb..#tmpRecordJazztelQA') IS NOT NULL DROP TABLE #tmpRecordJazztelQA;
                
        CREATE TABLE  #tmpRecordJazztelQA
            (
                 [Id]                            INT 
                ,[IdClient]                      INT
				,[Fecha]                         DATE
                ,[Avail]                         NUMERIC(18,0)
                ,[AuxProd]                       INT
                ,[AuxNoProd]                     NUMERIC(18,0)
                ,[TalkTime]                      NUMERIC(18,0)
                ,[HoldTime]                      NUMERIC(18,0)
                ,[ACWTime]                       NUMERIC(18,0)
                ,[RingTime]                      NUMERIC(18,0) 
                ,[RealInteractionsAnswered]      NUMERIC(18,0)
                ,[RealInteractionsOffered]       INT
				,[FCSTInteractionsAnswered]      DECIMAL(18,0)
                ,[KPIValue]                      NUMERIC(18,0)
				,[KPIprojection]                 DECIMAL(18,0)
				,[SHKprojection]                 DECIMAL(18,0)
                ,[ABSprojection]                 DECIMAL(18,0)
				,[AHTprojection]                 DECIMAL(18,0)
				,[Weight]						 INT  
				,[ReqHours]                      DECIMAL(18,0)
                ,[KPIWeight]                     DECIMAL(18,0)      
                ,[FCSTStafftime]                 DECIMAL(18,0)
                ,[AvailableProductive]           NUMERIC(18,0) 
                ,[LastUpdateDate]                DATETIME
            );
        
        INSERT INTO #tmpRecordJazztelQA
        SELECT
            OA.[Id] AS [Id]
            ,1214 AS [IdClient]
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
    FROM #tmpJazztelReal AS FR WITH(NOLOCK)
    INNER JOIN #tmptbOAUJazztel OA
    ON FR.[Fecha] = OA.[Fecha]


    /*======================================== Carga a la tabla fisica [dbo].[tbRecordVodafone] usando MERGE ======================================*/

    MERGE [dbo].[tbRecordJazztel] AS [tgt]
        USING
        (
              SELECT                     
				[IdClient]                 
				,[Fecha]                    
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
                [tgt].[IdClient]					=[src].[IdClient]                                    
                ,[tgt].[Fecha]						= [src].[Fecha]           
                ,[tgt].[Avail] 						= [src].[Avail]            
                ,[tgt].[AuxProd]					= [src].[AuxProd]          
                ,[tgt].[AuxNoProd]					= [src].[AuxNoProd]           
                ,[tgt].[TalkTime]					= [src].[TalkTime]        
                ,[tgt].[HoldTime]					= [src].[HoldTime]
                ,[tgt].[ACWTime]					= [src].[ACWTime]
                ,[tgt].[RingTime]					= [src].[RingTime] 
                ,[tgt].[RealInteractionsAnswered]	= [src].[RealInteractionsAnswered]
                ,[tgt].[RealInteractionsOffered]	= [src].[RealInteractionsOffered]
				,[tgt].[FCSTInteractionsAnswered] 	= [src].[FCSTInteractionsAnswered] 
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

        WHEN NOT MATCHED THEN
            INSERT
            (
                 	[IdClient]                 
					,[Fecha]                    
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
					,[src].[Fecha]                    
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

     IF OBJECT_ID('tempdb..#tmpRecordJazztelQA') IS NOT NULL DROP TABLE #tmpRecordJazztelQA;
     IF OBJECT_ID('tempdb..#tmptbOAUJazztel') IS NOT NULL DROP TABLE #tmptbOAUJazztel;
	 IF OBJECT_ID('tempdb..#tmpJazztelReal') IS NOT NULL DROP TABLE #tmpJazztelReal;
     
    END
GO


