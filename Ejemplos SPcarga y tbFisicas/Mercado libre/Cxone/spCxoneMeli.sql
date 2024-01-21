USE [Mercadolibre]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* --------------------
<Informacion Creacion>

User_NT: E_1016102870, E_1053871829
Fecha: 2023-10-04
Descripcion:  Se crea un sp de carga [spCxoneMeli] con 2 temporales  #tmpvwConsolaEstados y #tmpvwConsolaEstadosQA
Al final se hace una inserción en la tabla fisica [tbCxoneMeli].
<Ejemplo>
      Exec [dbo].[spCxoneMeli] 
*/
CREATE PROCEDURE [dbo].[spCxoneMeli] 

AS

SET NOCOUNT ON;

    BEGIN
		BEGIN TRY
        /*===============Bloque declaracion de variables==========*/

     

		DECLARE @ERROR INT =0;
       

		/*======================================== Creación y carga temporal #tmpvwConsolaEstados ======================================*/

		IF OBJECT_ID('tempdb..#tmpvwConsolaEstados') IS NOT NULL 
			DROP TABLE #tmpvwConsolaEstados;
		CREATE TABLE #tmpvwConsolaEstados
		(
			[USERLDAP]          NVARCHAR(200)
			,[LOB]              VARCHAR(100)
			,[status]           NVARCHAR(200)
			,[startdate]        DATETIME
			,[FlagIniFinTurno]  VARCHAR(100)
			,[DateDim]          DATE
		);

		INSERT INTO #tmpvwConsolaEstados
		SELECT
			[USERLDAP]          
			,[LOB]              
			,[status]           
			,[startdate]        
			,CASE 
			WHEN [status] <> 'Offline' AND ABS(CAST((DATEDIFF_BIG(ss,LAG( [startdate],1,0) 
			OVER(ORDER BY [userldap], [startdate]),[startdate])*1.00)/3600 AS DECIMAL(18,5))) > 1.5

			THEN 'IniTurno'

			WHEN [status] = 'Offline' AND ABS(CAST((DATEDIFF_BIG(ss,LEAD([startdate],1,0) 
			OVER(ORDER BY [userldap], [startdate]) ,[startdate])*1.00)/3600 AS DECIMAL(18,5))) > 1.5

			THEN 'FinTurno'

			END AS 'FlagIniFinTurno'

			,CAST(CASE WHEN 
				(
						CASE WHEN [status] <> 'Offline' AND ABS(CAST((DATEDIFF_BIG(ss,LAG( [startdate],1,0) 
						OVER(ORDER BY [userldap], [startdate]),[startdate])*1.00)/3600 AS DECIMAL(18,5))) > 1.5
						THEN 'IniTurno'
						WHEN [status] = 'Offline' AND ABS(CAST((DATEDIFF_BIG(ss,LEAD([startdate],1,0) OVER(ORDER BY [userldap], [startdate]) ,[startdate])*1.00)/3600 AS DECIMAL(18,5))) > 1.5
						THEN 'FinTurno'
						END
				) = 'IniTurno'

				THEN CAST([startdate] AS DATE)
				WHEN 
				(
							CASE WHEN [status] <> 'Offline' AND ABS(CAST((DATEDIFF_BIG(ss,LAG( [startdate],1,0) OVER(ORDER BY [userldap], [startdate]),[startdate])*1.00)/3600 AS DECIMAL(18,5))) > 1.5
							THEN 'IniTurno'

							WHEN [status] = 'Offline' AND ABS(CAST((DATEDIFF_BIG(ss,LEAD([startdate],1,0) OVER(ORDER BY [userldap], [startdate]) ,[startdate])*1.00)/3600 AS DECIMAL(18,5))) > 1.5
							THEN 'FinTurno'
							END
				) = 'finTurno'

			THEN CASE WHEN LAG( [startdate],1,0) OVER(ORDER BY [userldap], [startdate] ASC) = 0 THEN CAST(GETDATE() AS DATE) ELSE LAG( [startdate],1,0) OVER(ORDER BY [userldap], [startdate] ASC)  END 
			END AS DATE) AS [DateDim]

		FROM [Mercadolibre].[dbo].[vwConsolaEstados] WITH(NOLOCK);

		/*======================================== Creación y carga temporal #tmpvwConsolaEstadosQA ======================================*/  
		IF OBJECT_ID('tempdb..#tmpvwConsolaEstadosQA') IS NOT NULL 
		DROP TABLE #tmpvwConsolaEstadosQA;

		CREATE TABLE #tmpvwConsolaEstadosQA
		(
			[USERLDAP]          NVARCHAR(200)
			,[LOB]              VARCHAR(100)
			,[status]           NVARCHAR(200)
			,[startdate]        DATETIME
			,[FlagIniFinTurno]  VARCHAR(100)
			,[DateDim]          DATE
			,[test]             SMALLINT
		);


		INSERT INTO #tmpvwConsolaEstadosQA
		SELECT 
			[USERLDAP]          
			,[LOB]              
			,[status]           
			,[startdate]        
			,[FlagIniFinTurno]  
			,[DateDim]                      
			,ROW_NUMBER() OVER( PARTITION BY [USERLDAP] ORDER BY [startdate]) AS [test]
		FROM #tmpvwConsolaEstados
		WHERE [FlagIniFinTurno] IS NOT NULL AND [DateDim] = CAST(GETDATE() AS DATE);

		/*======================================== Carga a la tabla fisica [dbo].[tbCxoneMeli] ======================================*/
		TRUNCATE TABLE [dbo].[tbCxoneMeli];
		INSERT INTO [dbo].[tbCxoneMeli]
			SELECT                          
				[USERLDAP]        
				,[LOB]            
				,[status]         
				,[startdate]      
				,[FlagIniFinTurno]
				,[DateDim]        
				,[test]           

			FROM #tmpvwConsolaEstadosQA;

			
		 END TRY
        
			BEGIN CATCH
				SET @Error = 1;
				PRINT ERROR_MESSAGE();
			END CATCH
		/*=======================Eliminacion de temporales=========================*/

        IF OBJECT_ID('tempdb..#tmpvwConsolaEstados') IS NOT NULL
        DROP TABLE #tmpvwConsolaEstados;

        IF OBJECT_ID('tempdb..#tmpvwConsolaEstadosQA') IS NOT NULL 
        DROP TABLE #tmpvwConsolaEstadosQA;
     
    END




