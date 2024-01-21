USE [Orange]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
<Informacion Creacion>
User_NT:E_1000687202
Fecha: 2023-09-20
Descripcion: Se crea un sp de carga [spRecordOrange] con 3 temporales que son #tmpOrangeRecordUpLoad, #tmpOverAndUnder y #tmpConsolidadosRecordQA
Al final se hace el Mergue en la tabla fisica [tbRecordOrange] para actualizar los registros existentes o insertar nuevos registros

<Update> 2023-09-22
User_NT:E_1000687202
Fecha: 2023-09-22
Descripcion: Se realizo la modificacion de eliminar la tabla física [tbRecordOrange] para volver a crearla con los campos organizados, tomando
como base el archivo de excel 'Estructura Final Record Upload'. Además, se modifico la tabla temporal #tmpConsolidadosRecordQA y el bloque de inserción
de datos a la tabla física para que los campos coincidan en su nuevo orden y se corrige origen de datos [reqHours]

<Ejemplo>
      Exec [dbo].[spRecordOrange]
*/
ALTER PROCEDURE [dbo].[spRecordOrange] 
    @DateStart DATE = NULL
    ,@DateEnd  DATE = NULL
AS

SET NOCOUNT ON;

    BEGIN
        BEGIN TRY
        /*===============Bloque declaracion de variables==========*/

        --DECLARE @DateStart DATE = '2023-08-15',@DateEnd DATE = '2023-08-20';
        DECLARE @ERROR INT =0;
        SET   @DateStart = ISNULL(@DateStart,CAST(GETDATE()-45 AS DATE));
        SET   @DateEnd   = ISNULL(@DateEnd,CAST(GETDATE() AS DATE));
        PRINT @DateStart
        PRINT @DateEnd
        
     
/*======================================== Creación y carga temporal #tmpOrangeRecordUpLoad ======================================*/

        IF OBJECT_ID('tempdb..#tmpOrangeRecordUpLoad') IS NOT NULL 
        DROP TABLE #tmpOrangeRecordUpLoad;

        CREATE TABLE #tmpOrangeRecordUpLoad
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
            ,[KPIValue]                  FLOAT
            ,[Weight]                    INT
            ,[AvailableProductive]      NUMERIC
            ,[Fecha]                     DATE
        );

       INSERT INTO #tmpOrangeRecordUpLoad
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
                WHEN SUM(ISNULL([callsoffered],0)) = 0 OR SUM(ISNULL([callsoffered],0)) IS NULL
                    THEN 0
                ELSE SUM(ISNULL([acceptable],0))/SUM(ISNULL([callsoffered],0))
            END AS [KPIValue]
            ,SUM(ISNULL([callsoffered],0)) AS [Weight]
            ,NULL AS [AvailableProductive]
            ,[rowdate] AS [Fecha]
    FROM [TPCCP-DB08\SCDOM].[Orange].[dbo].[tbOrangeRecordUpLoad] WITH (NOLOCK)
    WHERE [rowdate] BETWEEN @DateStart AND @DateEnd
    
    GROUP BY 
    [rowdate]
        
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
        
        INSERT INTO   #tmpOverAndUnder
       SELECT 
         SUM(ISNULL([Volume],0))                                            AS [FCSTInteractionsAnswered]
        ,SUM(ISNULL(CAST([SL] AS FLOAT),0))                                 AS [KPIprojection]
        ,CASE
         WHEN SUM([Net Staff]) = 0 OR SUM([Net Staff]) IS NULL
             THEN 0
             ELSE (1-(SUM(ISNULL([Productive Staff],0))/SUM([Net Staff])))
         END                                                               AS [SHKprojection]
         ,CASE
         WHEN SUM([Scheduled Staff]) = 0 OR SUM([Scheduled Staff]) IS NULL
             THEN 0
             ELSE (1-(SUM(ISNULL([Net Staff],0))/SUM([Scheduled Staff])))
         END                                                               AS  [ABSprojection]  
         ,SUM(ISNULL([AHT],0))                                             AS  [AHTprojection]
         ,SUM(ISNULL([Volume],0))                                          AS  [KPIWeight]
         ,CASE
		 WHEN SUM([Scheduled Staff]) = 0 OR SUM([Scheduled Staff]) IS NULL
			THEN 0 
			ELSE (SUM(ISNULL([Volume],0)) * SUM(ISNULL([AHT],0)) * (1-SUM(ISNULL([Net Staff],0))/SUM(ISNULL([Scheduled Staff],0))) * (1-0.15)/3600)
		END																   AS [ReqHours]
         ,(SUM(ISNULL([Net Staff],0))/2)                                   AS  [FCSTStafftime]  
         ,[Fecha]                                                          AS  [Fecha]

FROM [TPCCP-DB08\SCDOM].[Orange].[dbo].[tbOAU] WITH (NOLOCK)
WHERE [Campaña] = 'Orange' AND [fecha] BETWEEN @DateStart AND @DateEnd
GROUP BY [Fecha]

    /*======================================== Creación y carga temporal #tmpConsolidadosRecordQA ======================================*/  
   IF OBJECT_ID('tempdb..#tmpConsolidadosRecordQA') IS NOT NULL 
    DROP TABLE #tmpConsolidadosRecordQA;
                
        CREATE TABLE  #tmpConsolidadosRecordQA
            (
                [IdClient]                      INT
				,[Fecha]                         DATE
                ,[Avail]                         NUMERIC
                ,[AuxProd]                       INT
                ,[AuxNoProd]                     NUMERIC
                ,[TalkTime]                      NUMERIC
                ,[HoldTime]                      NUMERIC
                ,[ACWTime]                       NUMERIC
                ,[RingTime]                      NUMERIC
                ,[RealInteractionsAnswered]      NUMERIC
                ,[RealInteractionsOffered]       INT
				,[FCSTInteractionsAnswered]      DECIMAL
                ,[KPIValue]                      NUMERIC
				,[KPIprojection]                 DECIMAL
                ,[SHKprojection]                 DECIMAL
                ,[ABSprojection]                 DECIMAL
                ,[AHTprojection]                 DECIMAL
                ,[Weight]                       INT
				,[ReqHours]                      DECIMAL
				,[KPIWeight]                     DECIMAL
				,[FCSTStafftime]                 DECIMAL
                ,[AvailableProductive]          NUMERIC
                ,[LastUpdateDate]                DATETIME
  
            );
        
        INSERT INTO #tmpConsolidadosRecordQA
        SELECT
            1121 AS [IdClient]
			,FR.Fecha
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
    FROM #tmpOrangeRecordUpLoad AS FR WITH(NOLOCK)
    INNER JOIN #tmpOverAndUnder OA
    ON FR.[Fecha] = OA.[Fecha]
    /*======================================== Carga a la tabla fisica [dbo].[tbRecordVodafone] usando MERGE ======================================*/

    MERGE [dbo].[tbRecordOrange] AS [tgt]
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
                               
            FROM #tmpConsolidadosRecordQA

        ) AS [src]
        ON
        (
            [src].[Avail] = [tgt].[Avail] AND [src].[AuxNoProd] = [tgt].[AuxNoProd] AND  [src].[Fecha] = [tgt].[Fecha]
        )
        -- For updates
        WHEN MATCHED THEN
          UPDATE 
              SET
                 --                              =[src].                         
                [tgt].[IdClient]                 = [src].[IdClient]
				,[tgt].[Fecha]                  = [src].[Fecha]  
                ,[tgt].[Avail]                    = [src].[Avail]                       
                ,[tgt].[AuxProd]                  = [src].[AuxProd]                     
                ,[tgt].[AuxNoProd]                = [src].[AuxNoProd]                   
                ,[tgt].[TalkTime]                 = [src].[TalkTime]                    
                ,[tgt].[HoldTime]                 = [src].[HoldTime]                    
                ,[tgt].[ACWTime]                  = [src].[ACWTime] 
                ,[tgt].[RingTime]                  = [src].[RingTime] 
                ,[tgt].[RealInteractionsAnswered] = [src].[RealInteractionsAnswered]    
                ,[tgt].[RealInteractionsOffered]  = [src].[RealInteractionsOffered]
                ,[tgt].[FCSTInteractionsAnswered] = [src].[FCSTInteractionsAnswered]  
                ,[tgt].[KPIValue]                 = [src].[KPIValue]
				,[tgt].[KPIprojection]            = [src].[KPIprojection] 
				,[tgt].[SHKprojection]            = [src].[SHKprojection]               
                ,[tgt].[ABSprojection]            = [src].[ABSprojection]               
                ,[tgt].[AHTprojection]            = [src].[AHTprojection]
				,[tgt].[Weight]                  = [src].[Weight] 
				,[tgt].[ReqHours]                 = [src].[ReqHours]  
				,[tgt].[KPIWeight]                = [src].[KPIWeight] 
				,[tgt].[FCSTStafftime]            = [src].[FCSTStafftime]
                ,[tgt].[AvailableProductive]      =[src].[AvailableProductive]   
				,[tgt].[TimeStamp]           = [src].[LastUpdateDate]           

         --For Inserts
        WHEN NOT MATCHED THEN
            INSERT
            --Valores tgt
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
                ,[TimeStamp] 
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

        IF OBJECT_ID('tempdb..#tmpOrangeRecordUpLoad') IS NOT NULL
        DROP TABLE #tmpOrangeRecordUpLoad;

        IF OBJECT_ID('tempdb..#tmpOverAndUnder') IS NOT NULL 
        DROP TABLE #tmpOverAndUnder;

        IF OBJECT_ID('tempdb..#tmpConsolidadosRecordQA') IS NOT NULL 
        DROP TABLE #tmpConsolidadosRecordQA;
     
    END