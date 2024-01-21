USE [TiendasMELI]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*
<Informacion Creacion>
User_NT: E_1019137609 ,E_1000687202, E_1233493216, E_1053871829
Fecha: 2023-10-19
Descripcion: Se crea un sp de carga [spRecordUploadTiendasMELI] en base a las tablas [dbo].[tbTiemposTiendasCruce] y 
[dbo].[tbNewFactTPClientWithCruce]. Al final se hace el Mergue en la tabla fisica [tbRecordUploadTiendasMELI] para 
actualizar los registros existentes o insertar nuevos registros. 


<Ejemplo>
Exec [dbo].[spRecordUploadTiendasMeli]
*/
CREATE PROCEDURE [dbo].[spRecordUploadTiendasMeli] @DateStart DATE = NULL, @DateEnd DATE = NULL
AS

SET NOCOUNT ON;

    BEGIN
        BEGIN TRY
        /*===============Bloque declaracion de variables==========*/
			DECLARE @ERROR INT = 0;
            SET   @DateStart = ISNULL(@DateStart,CAST(GETDATE()-45 AS DATE));
            SET   @DateEnd   = ISNULL(@DateEnd,CAST(GETDATE() AS DATE));            
/*======================================== Creacion y carga temporal #tmptbTiemposTiendasCruceAvail ======================================*/
			IF OBJECT_ID('tempdb..#tmptbTiemposTiendasCruceAvail') IS NOT NULL 
            DROP TABLE #tmptbTiemposTiendasCruceAvail;

            CREATE TABLE #tmptbTiemposTiendasCruceAvail
                (   
					 [Fecha]	    DATE
                    ,[Avail]	    DECIMAL (18, 3)
                );

            INSERT INTO #tmptbTiemposTiendasCruceAvail
				SELECT
					[Fecha]
					,SUM(ISNULL([tmpPausa],0))	AS [Avail]                             
				FROM [dbo].[tbTiemposTiendasCruce] WITH (NOLOCK)
				WHERE [TipoPausa] = 'Online / Atendiendo' 
                AND [Fecha] BETWEEN @DateStart AND @DateEnd
				GROUP BY [Fecha];
/*======================================== Creacion y carga temporal #tmptbTiemposTiendasCruceAuxNoProd ======================================*/
			IF OBJECT_ID('tempdb..#tmptbTiemposTiendasCruceAuxNoProd') IS NOT NULL 
            DROP TABLE #tmptbTiemposTiendasCruceAuxNoProd;

            CREATE TABLE #tmptbTiemposTiendasCruceAuxNoProd
                (   
					 [Fecha]		DATE
                    ,[AuxNoProd]	DECIMAL (18, 3)
                );

            INSERT INTO #tmptbTiemposTiendasCruceAuxNoProd
				SELECT
					[Fecha]
					,SUM(ISNULL([tmpPausa],0))	AS [AuxNoProd]                            
				FROM [dbo].[tbTiemposTiendasCruce] WITH (NOLOCK)
				WHERE [TipoPausa] = 'Descanso' 
                AND [Fecha] BETWEEN @DateStart AND @DateEnd
				GROUP BY [Fecha];
/*======================================== Creacion y carga temporal #tmptbNewFactTPClientWithCruce ======================================*/                  
			IF OBJECT_ID('tempdb..#tmptbNewFactTPClientWithCruce') IS NOT NULL 
            DROP TABLE #tmptbNewFactTPClientWithCruce;
                    
            CREATE TABLE #tmptbNewFactTPClientWithCruce
                (
                     [Date]		    DATE
					,[KPIValue]     DECIMAL(18,3)
                );
            
            INSERT INTO #tmptbNewFactTPClientWithCruce
                SELECT 
					[Date]
                    ,CASE
						WHEN SUM(ISNULL([NumerodeRegistros],0))=0
							THEN 0
						ELSE
							CAST(SUM(ISNULL([NumCumplimientoAjuste],0))*1.00 /SUM(ISNULL([NumerodeRegistros],0))AS FLOAT)
					END AS [KPIValue]
                FROM [dbo].[tbNewFactTPClientWithCruce] WITH (NOLOCK)
				WHERE [Date] BETWEEN @DateStart AND @DateEnd
                GROUP BY [Date];
/*======================================== Creacion y carga temporal #tmpRecordUploadMeliTiendaQA ======================================*/  
            IF OBJECT_ID('tempdb..#tmpRecordUploadMeliTiendaQA') IS NOT NULL 
            DROP TABLE #tmpRecordUploadMeliTiendaQA;
                        
            CREATE TABLE  #tmpRecordUploadMeliTiendaQA
                (
                     [IdClient]                     INT
                    ,[Date]							DATE
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
                    ,[LastUpdateDate]               DATE
                );
        
            INSERT INTO #tmpRecordUploadMeliTiendaQA
                SELECT
                    1439			AS [IdClient]
                    ,A.[Fecha]		AS [Date]
                    ,A.[Avail]
                    ,0				AS [AuxProd]
                    ,B.[AuxNoProd]
                    ,0				AS [TalkTime]
                    ,0				AS [HoldTime]
                    ,0				AS [ACWTime]
                    ,0				AS [RingTime]                      
                    ,0				AS [RealInteractionsAnswered]
                    ,0				AS [RealInteractionsOffered]
                    ,0				AS [FCSTInteractionsAnswered]
                    ,C.[KPIValue]
                    ,0				AS [KPIprojection]
                    ,0.083			AS [SHKprojection]
                    ,0				AS [ABSprojection]
                    ,0				AS [AHTprojection]
                    ,0.9			AS [Weight]
                    ,0				AS [ReqHours]
                    ,0				AS [KPIWeight]
                    ,0				AS [FCSTStafftime]
                    ,0				AS [AvailableProductive]
                    ,GETDATE()		AS [LastUpdateDate]
                FROM #tmptbTiemposTiendasCruceAvail AS A 
                INNER JOIN #tmptbTiemposTiendasCruceAuxNoProd AS B
                ON A.[Fecha] = B.[Fecha]
                INNER JOIN #tmptbNewFactTPClientWithCruce AS C
                ON A.[Fecha]=C.[Date];
/*======================================== Carga a la tabla fisica [dbo].[tbRecordUploadTiendasMELI] usando MERGE ======================================*/
            MERGE [dbo].[tbRecordUploadTiendasMeli] AS [tgt]
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
                    FROM #tmpRecordUploadMeliTiendaQA
                ) AS [src]
                ON
                ( 
						[src].[Date]		= [tgt].[Date]
					AND [src].[Avail]		= [tgt].[Avail]
					AND [src].[AuxNoProd]	= [tgt].[AuxNoProd] 
					AND [src].[KPIValue]	= [tgt].[KPIValue]
                )
                -- For updates
                WHEN MATCHED THEN
                UPDATE 
                    SET                       
                         [tgt].[IdClient]                 = [src].[IdClient]
                        ,[tgt].[Date]                     = [src].[Date]                                          
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
						,[tgt].[LastUpdateDate]			  = [src].[LastUpdateDate]
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

        IF OBJECT_ID('tempdb..#tmptbTiemposTiendasCruceAvail') IS NOT NULL
        DROP TABLE #tmptbTiemposTiendasCruceAvail;
        
        IF OBJECT_ID('tempdb..#tmptbTiemposTiendasCruceAuxNoProd') IS NOT NULL 
        DROP TABLE #tmptbTiemposTiendasCruceAuxNoProd;

        IF OBJECT_ID('tempdb..#tmptbNewFactTPClientWithCruce') IS NOT NULL 
        DROP TABLE #tmptbNewFactTPClientWithCruce;
     
        IF OBJECT_ID('tempdb..#tmpRecordUploadMeliTiendaQA') IS NOT NULL 
        DROP TABLE #tmpRecordUploadMeliTiendaQA;
    END
GO