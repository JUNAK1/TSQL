USE [GrupoSura]
GO

/****** Object:  StoredProcedure [dbo].[spExcesoHoraMytpIpsSura]    Script Date: 5/10/2023 1:15:00 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*
<Informacion Creacion>
User_NT: E_1000687202, E_1012322897, E_1143864762, E_1016102870, E_1233493216, E_1015216308, E_1088352987, E_1105792917, E_1010083873
Fecha: 2023-10-05
Descripcion: 
Se crea un sp de carga [spExcesoHoraMytpIpsSura] con 3 temporales que son #tmpSuraone, #tmpHeadCountTotal y #tmpHeadCountTotalQA 
Se realiza un insert a la tabla fisica tbExcesoHoraMytp con los respectivos filtros de fecha y cliente 

<Ejemplo>
Exec [dbo].[spExcesoHoraMytpIpsSura] 
*/
CREATE PROCEDURE [dbo].[spExcesoHoraMytpIpsSura]
AS

SET NOCOUNT ON;

    BEGIN
        BEGIN TRY
        /*===============Bloque declaracion de variables==========*/

        DECLARE @ERROR INT = 0;
        
/*======================================== Creación y carga temporal #tmpSuraone ======================================*/
        IF OBJECT_ID('tempdb..#tmpSuraone') IS NOT NULL 
        DROP TABLE #tmpSuraone;

        CREATE TABLE #tmpSuraone
        (   
             [idccms]                     INT
            ,[Fecha]                      DATE	
            ,[HoraEntrada]                TIME
            ,[HoraSalida]                 TIME
            ,[HoraInicioBreakOne]         TIME
            ,[HoraFinBreakOne]            TIME
            ,[HoraInicioBreakTwo]         TIME
            ,[HoraFinBreakTwo]            TIME
            ,[HoraInicioAlmuerzo]         TIME
            ,[HoraFinAlmuerzo]            TIME
        );

       INSERT INTO #tmpSuraone
       SELECT

			A.[idccms]				AS [idccms]
            ,A.[FechaDim]			AS [Fecha]
            ,A.[Inicio Turno]		AS [HoraEntrada]
            ,A.[Fin turno]			AS [HoraSalida]
            ,A.[Inicio Seg aux]		AS [HoraInicioBreakOne]
            ,A.[Fin Seg aux]		AS [HoraFinBreakOne]
            ,A.[Inicio Prim aux]	AS [HoraInicioBreakTwo]
            ,A.[Fin Prim aux]		AS [HoraFinBreakTwo]
            ,A.[Inicio alm]			AS [HoraInicioAlmuerzo]
            ,A.[Fin alm]			AS [HoraFinAlmuerzo]
        
        FROM [TPCCP-DB05\SCTRANS].[AdHocReports].[dbo].[Vwturnos] AS A WITH (NOLOCK)
        WHERE [FechaDim] BETWEEN CONVERT(DATE, GETDATE()-20) AND CONVERT(DATE, GETDATE()+6);
        
/*======================================== Creación y carga temporal #tmpHeadCountTotal ======================================*/

        IF OBJECT_ID('tempdb..#tmpHeadCountTotal') IS NOT NULL 
        DROP TABLE #tmpHeadCountTotal;

        CREATE TABLE #tmpHeadCountTotal
        (   --Cambiar los tipos de variables
             [LoginACD]                    INT
            ,[idccms]                      INT
            ,[NombreAgente]                VARCHAR(50)
            ,[Cliente]                     VARCHAR(50)
            ,[Programa]                    VARCHAR(100)
            ,[Supervisor]                  VARCHAR(50)
            ,[ACM]                         VARCHAR(50)
            
        );

        INSERT INTO #tmpHeadCountTotal
        SELECT 
         
             [phoneID]                  AS LoginACD
            ,[Ident]                    AS idccms
            ,[Nombre Completo]          AS NombreAgente
            ,[Cliente]                  AS Cliente
            ,[Nombre_Largo_Programa]    AS Programa
            ,[Nombre Superv]            AS Supervisor
            ,[Nombre ACM]               AS ACM
        FROM [TPCCP-DB05\SCTRANS].[tpStaffStatus].[dpa].[TbHeadCountTotal] WITH (NOLOCK)
        GROUP BY 
            [phoneID] 
            ,[Ident] 
            ,[Nombre Completo] 
            ,[Cliente] 
            ,[Nombre_Largo_Programa] 
            ,[Nombre Superv]        
            ,[Nombre ACM]; 

 /*======================================== Creación y carga temporal #tmpHorasConexQA ======================================*/
        IF OBJECT_ID('tempdb..#tmpHeadCountTotalQA ') IS NOT NULL 
        DROP TABLE #tmpHeadCountTotalQA ;

        CREATE TABLE #tmpHeadCountTotalQA 
        (   
            [idccms]                     INT NULL
            ,[logid]                      INT NULL
            ,[NombreCompleto]               VARCHAR(50)
            ,[Supervisor]                 VARCHAR(50)
            ,[Cliente]                    VARCHAR(50)
            ,[Programa]                   VARCHAR(100)
            ,[ACM]                        VARCHAR(50)
            ,[Fecha]                      VARCHAR(40)
            ,[HoraEntrada]                VARCHAR(40)
            ,[HoraSalida]                 VARCHAR(40)
            ,[HoraInicioBreakOne]         VARCHAR(40)
            ,[HoraFinBreakOne]            VARCHAR(40)
            ,[HoraInicioBreakTwo]         VARCHAR(40)
            ,[HoraFinBreakTwo]            VARCHAR(40)
            ,[HoraInicioAlmuerzo]         VARCHAR(40)
            ,[HoraFinAlmuerzo]            VARCHAR(40)
            ,[LastUpdateDate]             DATETIME NULL
        );

		INSERT INTO #tmpHeadCountTotalQA
        SELECT 
             A.[idccms]
            ,B.[LoginACD]
            ,B.[NombreAgente]   
            ,B.[Supervisor]
            ,B.[Cliente]
            ,B.[Programa]
            ,B.[ACM]
            ,CONVERT (VARCHAR,CONVERT (DATE,A.[Fecha]),103)                          
            ,CONVERT (VARCHAR,CONVERT (TIME,A.[HoraEntrada]),108)                
            ,CONVERT (VARCHAR,CONVERT (TIME,A.[HoraSalida]),108)                
            ,CONVERT (VARCHAR,CONVERT (TIME,A.[HoraInicioBreakOne]),108)       
            ,CONVERT (VARCHAR,CONVERT (TIME,A.[HoraFinBreakOne]),108)            
            ,CONVERT (VARCHAR,CONVERT (TIME,A.[HoraInicioBreakTwo]),108)      
            ,CONVERT (VARCHAR,CONVERT (TIME,A.[HoraFinBreakTwo]),108)          
            ,CONVERT (VARCHAR,CONVERT (TIME,A.[HoraInicioAlmuerzo]),108)         
            ,CONVERT (VARCHAR,CONVERT (TIME,A.[HoraFinAlmuerzo]),108) 
            ,GETDATE ()            
        FROM #tmpSuraone AS A
            LEFT JOIN #tmpHeadCountTotal AS B 
                ON (A.[idccms] = B.[idccms])
            WHERE B.Cliente = 'IPS SURA';

		/*=======================Control de duplicados=========================*/
			--WITH CTE AS 
			--(
			--	SELECT  
			--		[idccms] 
			--		,ROW_NUMBER()
			--		OVER
			--		(
			--			PARTITION BY 
			--			[idccms]
			--			,[Fecha]
			--			,[HoraEntrada]
			--			,[HoraSalida]
			--			ORDER BY [idccms]
			--		)REPETIDOS 
			--	FROM #tmpHeadCountTotalQA)

			-- DELETE FROM CTE WHERE REPETIDOS >1

			/*=======================Truncate e Insert=========================*/
        TRUNCATE TABLE [tbExcesoHoraMytpIpsSura]
        INSERT INTO [tbExcesoHoraMytpIpsSura]
            SELECT
		         [idccms]             
                ,[logid]             
                ,[NombreCompleto]      
                ,[Supervisor]        
                ,[Cliente]           
                ,[Programa]                   
                ,[Fecha]             
                ,[HoraEntrada]       
                ,[HoraSalida]        
                ,[HoraInicioBreakOne]
                ,[HoraFinBreakOne]   
                ,[HoraInicioBreakTwo]
                ,[HoraFinBreakTwo]   
                ,[HoraInicioAlmuerzo]
                ,[HoraFinAlmuerzo]   
                ,[LastUpdateDate]    
            FROM #tmpHeadCountTotalQA;
       

		END TRY

        BEGIN CATCH
            SET @Error = 1;
            PRINT ERROR_MESSAGE();
        END CATCH
        /*=======================Eliminacion de temporales=========================*/

     IF OBJECT_ID('tempdb..#tmpSuraone') IS NOT NULL 
        DROP TABLE #tmpSuraone;
     IF OBJECT_ID('tempdb..#tmpHeadCountTotal') IS NOT NULL 
        DROP TABLE #tmpHeadCountTotal;
	 IF OBJECT_ID('tempdb..#tmpHeadCountTotalQA') IS NOT NULL 
        DROP TABLE #tmpHeadCountTotalQA;
     
  END
