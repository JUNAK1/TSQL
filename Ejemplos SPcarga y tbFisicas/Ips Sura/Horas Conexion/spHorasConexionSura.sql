USE [GrupoSura]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
<Informacion Creacion>
User_NT:E_1088352987, E_1053871829
Fecha: 2023-10-05
Descripcion: Se crea un sp de carga [spHorasConexionIPSSura] con 3 temporales que son #tmphagentSura, #tmphaglogSura, #tmpTbHeadCountTotalSura
Al final se hace una inserción en la tabla fisica [tbHorasConexionSura].


<Ejemplo>
      Exec [dbo].[spHorasConexionIPSSura]
*/
CREATE PROCEDURE [dbo].[spHorasConexionIPSSura] 
    @DateStart DATE = NULL
    ,@DateEnd DATE = NULL
AS

SET NOCOUNT ON;

    BEGIN
		BEGIN TRY
			/*===============Bloque declaracion de variables==========*/
			--DECLARE @DateStart DATE = NULL, @DateEnd  DATE = NULL;
			DECLARE @ERROR INT =0;
			SET   @DateStart = ISNULL(@DateStart,CAST(GETDATE()-20 AS DATE));
			SET   @DateEnd   = ISNULL(@DateEnd,CAST(GETDATE() AS DATE));    
   
	/*======================================== Creación y carga temporal #tmphagentSura ======================================*/

			IF OBJECT_ID('tempdb..#tmphagentSura') IS NOT NULL 
			DROP TABLE #tmphagentSura;

			CREATE TABLE #tmphagentSura(
				[row_date]      DATE
				,[logid]        INT
				,[T_Logueado]   INT
			);

			INSERT INTO #tmphagentSura
			SELECT 
				[row_date]
				,[logid]
				,SUM([ti_stafftime]) AS [T_Logueado]
			FROM [TPCCP-DB07\SCOFFS].[WFM CMS].[dbo].[hagent] WITH(NOLOCK)
			WHERE [row_date] BETWEEN @DateStart AND @DateEnd 
			GROUP BY [row_date],[logid];
		

	/*======================================== Creación y carga temporal #tmphaglogSura================================================*/


			IF OBJECT_ID('tempdb..#tmphaglogSura') IS NOT NULL 
			DROP TABLE #tmphaglogSura;

			CREATE TABLE #tmphaglogSura(
				[FechaConexion]	DATE
				,[Login]        INT
				,[HoraConx]     VARCHAR(50)
				,[HoraDesc]     VARCHAR(50)
			);
            
			INSERT INTO #tmphaglogSura
			SELECT 
				[ROW_DATE] AS [FechaConexion]
				,[LOGID]   AS [Login]
				,CONVERT (VARCHAR,DATEADD(SECOND,MIN([LOGIN]),CAST('1970-01-01 00:00:00.000' AS TIME)),108)	AS [HoraConx]
				,CONVERT (VARCHAR,DATEADD(SECOND,MAX([LOGOUT]),CAST('1970-01-01 00:00:00.000' AS TIME)),108) AS [HoraDesc]
			FROM [TPCCP-DB07\SCOFFS].[WFM CMS].[dbo].[haglog] WITH(NOLOCK) 
			WHERE [ROW_DATE] >='2021-11-22'
			GROUP BY [ROW_DATE], [LOGID];


	/*======================================== Creación y carga temporal #tmpTbHeadCountTotalSura ======================================*/
			IF OBJECT_ID('tempdb..#tmpTbHeadCountTotalSura') IS NOT NULL 
			DROP TABLE #tmpTbHeadCountTotalSura;

			CREATE TABLE #tmpTbHeadCountTotalSura(
				[phoneID]			INT
				,[CCMSID]			INT
				,[Nombre_Agente]	VARCHAR(100)
				,[Cliente]			VARCHAR(50)
				,[Programa]			VARCHAR(200)
				,[Supervisor]		VARCHAR(50)
				,[ACM]				VARCHAR(50)
			);

			INSERT INTO #tmpTbHeadCountTotalSura
			SELECT 
				[phoneID]
				,[Ident]					AS [CCMSID]
				,[Nombre Completo]			AS [Nombre_Agente]
				,[Cliente]					AS [Cliente] 
				,[Nombre_Largo_Programa]	AS [Programa]
				,[Nombre Superv]			AS [Supervisor]
				,[Nombre ACM]				AS [ACM]
			FROM [TPCCP-DB05\SCTRANS].[tpStaffStatus].[dpa].[TbHeadCountTotal] WITH (NOLOCK)
			WHERE [Cliente] in ('EPS SURA','IPS SURA','ARP SURA','Dinamica IPS')
			GROUP BY [phoneID],[Ident],[Nombre Completo],[Cliente],[Nombre_Largo_Programa],[Nombre Superv],[Nombre ACM];

		/*======================================== Creación y carga temporal #tmptbHorasConexionIPSSuraQA======================================*/  
			IF OBJECT_ID('tempdb..#tmptbHorasConexionIPSSuraQA') IS NOT NULL 
			DROP TABLE #tmptbHorasConexionIPSSuraQA;
                
			CREATE TABLE  #tmptbHorasConexionIPSSuraQA(
				
				[row_date]			VARCHAR(30)
				,[logid]			INT
				,[CCMSID]			INT
				,[Nombre_Agente]	VARCHAR(100)
				,[Cliente]			VARCHAR(50)
				,[Programa]			VARCHAR(200)
				,[Supervisor]		VARCHAR(50)
				,[ACM]				VARCHAR(50)
				,[T_Logueado]		INT
				,[HoraConx]			VARCHAR(50)
				,[HoraDesc]			VARCHAR(50)
			);
        
			INSERT INTO #tmptbHorasConexionIPSSuraQA
			SELECT
				CONVERT (VARCHAR,CONVERT(DATE, A.[row_date]),103) AS [row_date]
				,A.[logid]			
				,E.[CCMSID]			
				,E.[Nombre_Agente]	
				,E.[Cliente]			
				,E.[Programa]			
				,E.[Supervisor]		
				,E.[ACM]				
				,A.[T_Logueado]					
				,L.[HoraConx]			
				,L.[HoraDesc]			
			FROM #tmphagentSura AS A
			LEFT JOIN #tmphaglogSura AS L 
			ON L.[Login] = A.[logid] and A.[row_date] = L.[FechaConexion]
			LEFT JOIN #tmpTbHeadCountTotalSura AS E 
			ON A.[Logid] = E.[phoneID]
			WHERE E.[Cliente]='ARP SURA'
			GROUP BY A.[row_date], A.[logid], L.[HoraConx], L.[FechaConexion], L.[HoraDesc], E.[Nombre_Agente]
					,E.[Cliente], E.[Programa], E.[Supervisor], E.[ACM], E.[CCMSID],A.[T_Logueado];


		/*======================================== Truncate a la tabla fisica para insercion de nuevos datos   ======================================*/
            
            TRUNCATE TABLE tbHorasConexionIPSSura;

		/*========================================================= Carga a la tabla fisica ==========================================================*/
			
            INSERT INTO tbHorasConexionIPSSura 
            SELECT 
				[row_date]		
                ,[logid]		
                ,[CCMSID]		
                ,[Nombre_Agente]
                ,[Cliente]		
                ,[Programa]		 
                ,[Supervisor]	
                ,[ACM]			
                ,[T_Logueado]	
                ,[HoraConx]		
                ,[HoraDesc]
            FROM #tmptbHorasConexionIPSSuraQA;
		
		END TRY
        
        BEGIN CATCH
            SET @Error = 1;
            PRINT ERROR_MESSAGE();
        END CATCH
        /*=======================Eliminacion de temporales=========================*/

		IF OBJECT_ID('tempdb..#tmphagentSura') IS NOT NULL 
        DROP TABLE #tmphagentSura;

        IF OBJECT_ID('tempdb..#tmphaglogSura') IS NOT NULL
        DROP TABLE #tmphaglogSura;

        IF OBJECT_ID('tempdb..#tmptbHorasConexionIPSSuraQA') IS NOT NULL 
        DROP TABLE #tmptbHorasConexionIPSSuraQA;
     
    END