USE [Iberdrola]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
<Informacion Creacion>
User_NT: E_1105792917, E_1000687202, E_1014297790, E_1143864762, E_1053871829, E_1233493216, E_1088352987, E_1010083873
Fecha: 2023-10-05
Descripcion: Se crea un sp de carga [spRecordIberdrola] en base a las tablas [dbo].[tb_IberVentasCalculos] - [dbo].[tbVentasFCST] - [TPCCP-DB04\SCBACK].[TPSWeb].[dbo].[TPS_Data]
Al final se hace el Mergue en la tabla fisica [tbRecordIberdrola] para actualizar los registros existentes o insertar nuevos registros 




<Ejemplo>
Exec [dbo].[spRecordIberdrola]
*/
CREATE PROCEDURE [dbo].[spRecordIberdrola]
AS

SET NOCOUNT ON;

    BEGIN
        BEGIN TRY
        /*===============Bloque declaracion de variables==========*/
        
        DECLARE @ERROR INT =0;
        
        /*======================================== Creacion y carga temporal #tmpIberdrolaReal ======================================*/

        --[TPCCP-DB08\SCDOM].[Iberdrola].[dbo].[tb_IberVentasCalculos]

        

        IF OBJECT_ID('tempdb..#tmpIberdrolaReal') IS NOT NULL 
        DROP TABLE #tmpIberdrolaReal;

        CREATE TABLE #tmpIberdrolaReal
        (   
             [Avail]                        DECIMAL(18,3)
            ,[AuxProd]                      DECIMAL(18,3)
            ,[AuxNoProd]                    DECIMAL(18,3)
            ,[TalkTime]                     DECIMAL(18,3) 
            ,[HoldTime]                     DECIMAL(18,3) 
            ,[ACWTime]                      DECIMAL(18,3) 
            ,[RingTime]                     DECIMAL(18,3) 
            ,[RealInteractionsAnswered]     DECIMAL(18,3)
            ,[RealInteractionsOffered]      DECIMAL(18,3)  
            ,[KPIValue]                     DECIMAL(18,3)
            ,[Weight]                       DECIMAL(18,3) 
            ,[AvailableProductive]          DECIMAL(18,3) 
            ,[Fecha]                        DATE

        );

        INSERT INTO #tmpIberdrolaReal
        SELECT
            SUM(ISNULL(A.[DisponibleDec],0)) AS [Avail]
            ,SUM(ISNULL(A.[TiempoEfectivoDec],0) + ISNULL(A.[FormacionDec],0) + ISNULL(A.[CoachingSupervisorDec],0) + ISNULL(A.[CoachingQADec],0)) AS [AuxProd]
            ,SUM(ISNULL(A.[DescansoDec],0) + ISNULL(A.[PausaDec],0)) AS [AuxNoProd]
            ,SUM(ISNULL(A.[TalkTiempoDec],0)) AS [TalkTime]
            ,NULL AS [HoldTime]
            ,NULL AS [ACWTime] 
            ,NULL AS [RingTime] 
            ,SUM(ISNULL(A.[CONTACTOS_CERRADOS],0)) AS [RealInteractionsAnswered]
            ,NULL AS [RealInteractionsOffered]
            ,SUM(ISNULL(A.[VENTAS_NETAS],0)) AS [KPIValue] 
            ,CASE
                WHEN SUM(ISNULL(B.[VentasEnergia],0)) = 0 OR SUM(ISNULL(B.[VentasEnergia],0)) IS NULL
                    THEN 0
                ELSE SUM(ISNULL(A.[VENTAS_NETAS],0))/SUM(ISNULL(B.[VentasEnergia],0))
            END AS [Weight] 
            ,NULL AS [Available productive] 
            ,A.[Fecha]
        FROM [dbo].[tb_IberVentasCalculos] AS A WITH (NOLOCK)
        INNER JOIN  [dbo].[tbVentasFCST] AS B WITH (NOLOCK)
        ON A.[Fecha] = B.[Fecha]
        GROUP BY A.[Fecha]
        
/*======================================== Creacion y carga temporal #tmpOAUIberdrola ======================================*/                  

    IF OBJECT_ID('tempdb..#tmpOAUIberdrola') IS NOT NULL 
    DROP TABLE #tmpOAUIberdrola;
                
        CREATE TABLE #tmpOAUIberdrola --Practicamente todos los campos estan incompletos
            (
                 [FCSTInteractionsAnswered]		DECIMAL(18,3)                     
                ,[KPIprojection]				DECIMAL(18,3)
                ,[SHKprojection]				DECIMAL(18,3) 
                ,[ABSprojection]				DECIMAL(18,3)  
                ,[AHTprojection]				DECIMAL(18,3)  
                ,[KPIWeight]					INT 
                ,[ReqHours]						DECIMAL(18,3) 
                ,[FCSTStafftime]				INT
                ,[Fecha]						DATE
            );
        
        INSERT INTO #tmpOAUIberdrola
			SELECT 
				SUM(ISNULL(A.[VentasEnergia],0))	AS	[FCSTInteractionsAnswered]
				,100	AS	[KPIprojection]
				,SUM(ISNULL(B.[PvA_PlanTPShrink],0)+ISNULL(B.[PvA_PlanBreak],0))	AS	[SHKprojection]
				,SUM(ISNULL(B.[PvA_PlanLostLabor],0))	AS	[ABSprojection]
				,SUM(ISNULL(A.[AHT],0))	AS	[AHTprojection]
				,SUM(ISNULL(A.[VentasEnergia],0))	AS	[KPIWeight]
				,SUM(ISNULL(A.[HorasLogadas],0))	AS	[ReqHours]
				,SUM(ISNULL(A.[HorasLogadas],0))	AS	[FCSTStafftime]
				,A.[Fecha]
			FROM [dbo].[tbVentasFCST] AS A WITH (NOLOCK) 
			INNER JOIN  [TPCCP-DB04\SCBACK].[TPSWeb].[dbo].[TPS_Data] AS B WITH (NOLOCK)
			ON A.[Fecha] BETWEEN B.[record_date] AND DATEADD(WEEK,1,B.[record_date]) 
			WHERE B.[tps_sheet_ident] = '9006' and B.[record_scope] = 'W' AND B.[record_mode] <> 'Dark'
			GROUP BY A.[Fecha]

    /*======================================== Creacion y carga temporal #tmpRecordIberdrolaQA ======================================*/  
   IF OBJECT_ID('tempdb..#tmpRecordIberdrolaQA') IS NOT NULL 
    DROP TABLE #tmpRecordIberdrolaQA;
                
        CREATE TABLE  #tmpRecordIberdrolaQA
            (
                [IdClient]                      INT 
                ,[Fecha]                        DATE
                ,[Avail]                        DECIMAL(18,3)
                ,[AuxProd]                      DECIMAL(18,3)
                ,[AuxNoProd]                    DECIMAL(18,3)
                ,[TalkTime]                     DECIMAL(18,3)
                ,[HoldTime]                     DECIMAL(18,3)
                ,[ACWTime]                      DECIMAL(18,3)
                ,[RingTime]                     DECIMAL(18,3)
                ,[RealInteractionsAnswered]     DECIMAL(18,3)
                ,[RealInteractionsOffered]      DECIMAL(18,3) 
                ,[FCSTInteractionsAnswered]     DECIMAL(18,3)
                ,[KPIValue]                     DECIMAL(18,3)
                ,[KPIprojection]                DECIMAL(18,3)
                ,[SHKprojection]                DECIMAL(18,3)
                ,[ABSprojection]                DECIMAL(18,3)
                ,[AHTprojection]                DECIMAL(18,3)
                ,[Weight]                       DECIMAL(18,3) 
                ,[ReqHours]                     DECIMAL(18,3)
                ,[KPIWeight]                    INT
                ,[FCSTStafftime]                INT
                ,[AvailableProductive]          DECIMAL(18,3) 
                ,[LastUpdateDate]               DATETIME 
  
            );
        
        INSERT INTO #tmpRecordIberdrolaQA
        SELECT

             1323 AS [IdClient]
            ,OA.[Fecha]
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
    FROM #tmpIberdrolaReal AS FR WITH(NOLOCK)
        INNER JOIN #tmpOAUIberdrola AS OA
            ON FR.[Fecha] = OA.[Fecha];
    /*======================================== Carga a la tabla fisica [dbo].[tbRecordUploadIberdrola] usando MERGE ======================================*/

    MERGE [dbo].[tbRecordIberdrola] AS [tgt]
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

            FROM #tmpRecordIberdrolaQA

        ) AS [src]
        ON
        (
           
             [src].[Fecha] = [tgt].[Date]
        )
        -- For updates
        WHEN MATCHED THEN
          UPDATE 
              SET
                 --                              =[src].                        
                [tgt].[IdClient]                 = [src].[IdClient]
                ,[tgt].[Date]                    = [src].[Fecha]                                          
                ,[tgt].[Avail]                    = [src].[Avail]                       
                ,[tgt].[AuxProd]                  = [src].[AuxProd]                     
                ,[tgt].[AuxNoProd]                = [src].[AuxNoProd]                   
                ,[tgt].[TalkTime]                 = [src].[TalkTime]                    
                ,[tgt].[HoldTime]                 = [src].[HoldTime]                    
                ,[tgt].[ACWTime]                  = [src].[ACWTime] 
                ,[tgt].[RingTime]                 = [src].[RingTime] 
                ,[tgt].[RealInteractionsAnswered] = [src].[RealInteractionsAnswered]    
                ,[tgt].[RealInteractionsOffered]  = [src].[RealInteractionsOffered]
                ,[tgt].[FCSTInteractionsAnswered] = [src].[FCSTInteractionsAnswered]      
                ,[tgt].[KPIValue]                 = [src].[KPIValue]
                ,[tgt].[KPIprojection]            = [src].[KPIprojection]               
                ,[tgt].[SHKprojection]            = [src].[SHKprojection]               
                ,[tgt].[ABSprojection]            = [src].[ABSprojection]               
                ,[tgt].[AHTprojection]            = [src].[AHTprojection]                    
                ,[tgt].[Weight]                   = [src].[Weight] 
                ,[tgt].[ReqHours]                 = [src].[ReqHours]
                ,[tgt].[KPIWeight]                = [src].[KPIWeight]  
                ,[tgt].[FCSTStafftime]            = [src].[FCSTStafftime]
                ,[tgt].[AvailableProductive]      = [src].[AvailableProductive]
                ,[tgt].[LastUpdateDate]           = [src].[LastUpdateDate]           

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

        IF OBJECT_ID('tempdb..#tmpIberdrolaReal') IS NOT NULL
        DROP TABLE #tmpIberdrolaReal;

        IF OBJECT_ID('tempdb..#tmpOAUIberdrola') IS NOT NULL 
        DROP TABLE #tmpOAUIberdrola;

        IF OBJECT_ID('tempdb..#tmpRecordIberdrolaQA') IS NOT NULL 
        DROP TABLE #tmpRecordIberdrolaQA;
     
    END