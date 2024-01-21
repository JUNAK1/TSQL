USE [MercadoLibre]
GO


/*
<Informacion Creacion>
User_NT:E_1000687202 ,E_1019137609 , E_1010083873
Fecha: 10/09/2023
Descripcion: Se crea un sp de carga [spReporteAusentismoMeLi] con 10 temporales
en base a una query con información de los ultimops 5 días, se inserta en la tabla tbReporteAusentismoMeLi

<Ejemplo>
      Exec [dbo].[spReporteAusentismoMeLi] 
*/


CREATE PROCEDURE [dbo].[spReporteAusentismoMeLi] 
AS

SET NOCOUNT ON;


 BEGIN
        BEGIN TRY


        /*===============Bloque declaracion de variables==========*/   
        DECLARE @ERROR INT =0;
        -- SET   @DateStart = ISNULL(@DateStart,CAST(GETDATE()-5 DATE)); 
        -- SET   @DateEnd   = ISNULL(@DateEnd,CAST(GETDATE() AS DATE));


/*======================================== Creación y carga temporal #tempHcNominaFiltrada ======================================*/

	IF OBJECT_ID('tempdb..#tempHcNominaFiltrada') IS NOT NULL DROP TABLE #tempHcNominaFiltrada;
	CREATE TABLE #tempHcNominaFiltrada(    
		[CeduLa] VARCHAR(100) NULL
		,[MaxCatorcenaLiq] INT NULL
	);

	INSERT INTO #tempHcNominaFiltrada
		SELECT 
			[CeduLa]
			,MAX([Catorcena]) AS [MaxCatorcenaLiq] 
		FROM [TPCCP-DB88\SQL2016STD].[Nomina].[dbo].[tbHcNomina] A WITH (NOLOCK)
		WHERE [Nceco] LIKE '%MERCADO L%' AND [TipoLiq] LIKE '%OPERATIV%'
			AND [Año] = YEAR(GETDATE()) 
		GROUP BY [Cedula];

/*======================================== Creación y carga temporal #tempNominaEmployees ======================================*/

    IF OBJECT_ID('tempdb..#tempNominaEmployees') IS NOT NULL DROP TABLE #tempNominaEmployees;
	CREATE TABLE #tempNominaEmployees(
		[Ident] VARCHAR(100) NULL
		,[IdFiscal] VARCHAR(100) NULL
	);

    INSERT INTO #tempNominaEmployees
        SELECT 
            [Ident]
            ,[IdFiscal]
        FROM [TPCCP-DB88\SQL2016STD].[Nomina].[dbo].[tbNominaEmployees] WITH (NOLOCK);

/*======================================== Creación y carga temporal #tempHcNomina ======================================*/

    IF OBJECT_ID('tempdb..#tempHcNomina') IS NOT NULL DROP TABLE #tempHcNomina;
    CREATE TABLE #tempHcNomina(
        [Cedula] VARCHAR(100) NULL
        ,[Ceco] INT NULL 
        ,[NCeco] VARCHAR(120) NULL
        ,[Cargo] VARCHAR(150) NULL
        ,[IntHoraria] INT NULL
        ,[Catorcena] INT NULL 
        ,[Año] INT NULL 
        ,[TipoLiq] VARCHAR(100) NULL
        ,[CecoRel] VARCHAR(100) NULL
    )

    INSERT INTO #tempHcNomina
        SELECT
            [Cedula]
            ,[Ceco]
            ,[NCeco]
            ,[Cargo]
            ,[Inthoraria]
            ,[Catorcena]
            ,[Año]
            ,[TipoLiq]
            ,[Ceco_Rel]
        FROM [TPCCP-DB88\SQL2016STD].[Nomina].[dbo].[tbHcNomina] A WITH (NOLOCK)
		WHERE [Año] = YEAR(GETDATE()) AND [NCeco] LIKE '%MERCADO L%'
			AND [TipoLiq] LIKE '%OPERATIV%';

/*======================================== Creación y carga temporal #tempNominaFinal ======================================*/

	IF OBJECT_ID('tempdb..#tempNominaFinal') IS NOT NULL DROP TABLE #tempNominaFinal;
	CREATE TABLE #tempNominaFinal(
		[Cedula] VARCHAR(100) NULL
		,[IDCCM] INT NULL
        ,[Ceco] INT NULL 
        ,[NCeco] VARCHAR(120) NULL
        ,[Cargo] VARCHAR(150) NULL
        ,[IntHoraria] INT NULL
        ,[Catorcena] INT NULL 
        ,[Año] INT NULL 
        ,[TipoLiq] VARCHAR(100) NULL
        ,[CecoRel] VARCHAR(100) NULL
	)

	INSERT INTO #tempNominaFinal
		SELECT
            A.[cedula]
            ,B.[IDENT] AS [IDCCM]
			,[Ceco]
            ,[NCeco]
            ,[Cargo]
            ,[Inthoraria]
            ,[Catorcena]
            ,[Año]
            ,[TipoLiq]
            ,[CecoRel]
        FROM #tempHcNomina A WITH (NOLOCK) 
        LEFT JOIN #tempHcNominaFiltrada  C 
			ON A.[Cedula] = C.[Cedula]
        LEFT JOIN #tempNominaEmployees B 
			ON CAST(A.[CEDULA] AS VARCHAR)= CAST(B.[IDFISCAL] AS VARCHAR)
        WHERE [NCeco] LIKE '%MERCADO L%' AND [TipoLiq] LIKE '%OPERATIV%'
        AND [Año] = YEAR(GETDATE())
        AND [Catorcena] = [MaxCatorcenaLiq]

/*======================================== Creación y carga temporal #tempRawLiloTimeClock ======================================*/

	IF OBJECT_ID('tempdb..#tempRawLiloTimeClock') IS NOT NULL DROP TABLE #tempRawLiloTimeClock;
	CREATE TABLE #tempRawLiloTimeClock(
		[Ccms] INT NULL
		,[FechaStaff] DATE NULL
		,[Login] DATETIME NULL
		,[Estado] VARCHAR(50) NULL
		,[DateTime] DATETIME NULL
		,[Status] INT NULL
	);

	INSERT INTO #tempRawLiloTimeClock
		SELECT
			[Ccms]
			,[FechaStaff]
			,[Login]
			,[Estado]
			,[DateTime]
			,[Status]
		FROM [TPCCP-DB88\SQL2016STD].[Nomina].[dbo].[tbRawLiloTimeClock24_bk] A WITH(NOLOCK)
		WHERE CAST([FechaStaff] AS DATE) >= CAST(GETDATE()-5 AS DATE);

		/*======================================== Creación y carga temporal #tempRawLiloTimeClockLogOut ======================================*/

	IF OBJECT_ID('tempdb..#tempRawLiloTimeClockLogOut') IS NOT NULL DROP TABLE #tempRawLiloTimeClockLogOut;
	CREATE TABLE #tempRawLiloTimeClockLogOut(
		[Ccms] INT NULL
		,[FechaStaff] DATE NULL
        ,[Logout] DATETIME NULL
		,[Estado] VARCHAR(50) NULL
		,[DateTime] DATETIME NULL
		,[Status] INT NULL
	);

	INSERT INTO #tempRawLiloTimeClockLogOut
		SELECT
			[Ccms]
			,[FechaStaff]
            ,[Logout]
			,[Estado]
			,[DateTime]
			,[Status]
		FROM [TPCCP-DB88\SQL2016STD].[Nomina].[dbo].[tbRawLiloTimeClock24_bk] A WITH(NOLOCK)
		WHERE CAST([FechaStaff] AS DATE) >= CAST(GETDATE()-5 AS DATE);

/*======================================== Creación y carga temporal #tempLilosLoginCruzada ======================================*/
	IF OBJECT_ID('tempdb..#tempLilosLoginCruzada') IS NOT NULL DROP TABLE #tempLilosLoginCruzada;
	CREATE TABLE #tempLilosLoginCruzada(
		[Ccms] INT NULL
		,[FechaStaff]  DATE NULL
		,[TypeLog] VARCHAR(20) NULL
		,[Login]  DATETIME NULL
		,[Estado] VARCHAR(50) NULL
		,[NCeco]  VARCHAR(120) NULL
	);

	INSERT INTO #tempLilosLoginCruzada
		SELECT 
		   [Ccms]
		  ,[FechaStaff]
		  ,CASE
			WHEN [Ccms] > 0 
				THEN 'Login' 
			end AS [TypeLog]
		  ,[Login]
		  ,[Estado]
		  ,[NCeco]
		FROM #tempRawLiloTimeClock A WITH (NOLOCK)
		INNER JOIN #tempNominaFinal B 
		ON A.[CCMS] = B.[IDCCM]
        


/*======================================== Creación y carga temporal #tempLilosLogOutCruzada ======================================*/
	IF OBJECT_ID('tempdb..#tempLilosLogOutCruzada') IS NOT NULL DROP TABLE #tempLilosLogOutCruzada;
	CREATE TABLE #tempLilosLogOutCruzada(
		[Ccms] INT NULL
		,[FechaStaff]  DATE NULL
		,[TypeLog] VARCHAR(20) NULL
		,[Logout]  DATETIME NULL
		,[Estado] VARCHAR(50) NULL
		,[NCeco]  VARCHAR(120) NULL
	);

	INSERT INTO #tempLilosLogOutCruzada
		SELECT 
		   [Ccms]
		  ,[FechaStaff]
		  ,CASE
			WHEN [Ccms] > 0 
				THEN 'Logout' 
			end AS [TypeLog]
		  ,[Logout]
		  ,[Estado]
		  ,[NCeco]
		FROM ##tempRawLiloTimeClockLogOut A WITH (NOLOCK)
		INNER JOIN #tempNominaFinal B 
		ON A.[CCMS] = B.[IDCCM]

/*======================================== Creación y carga temporal #tempLilosFinal ======================================*/

	IF OBJECT_ID('tempdb..#tempLilosFinal') IS NOT NULL DROP TABLE #tempLilosFinal;
	CREATE TABLE #tempLilosFinal(
		[Ccms] INT NULL
		,[FechaStaff]  DATE NULL
		,[TypeLog] VARCHAR(20) NULL
		,[Login]  DATETIME NULL
		,[Logout] DATETIME NULL
		,[Estado] VARCHAR(50) NULL
		,[NCeco]  VARCHAR(120) NULL
	);

	INSERT INTO #tempLilosFinal --Funciona así o hay que especificar las columnas ?
		SELECT 
            [Ccms]
            ,[FechaStaff]  
            ,[TypeLog] 
            ,[Login]  
			,NULL
            ,[Estado] 
            ,[NCeco]  
        FROM #tempLilosLoginCruzada
    
	INSERT INTO #tempLilosFinal
        SELECT 
            [Ccms] 
            ,[FechaStaff]  
            ,[TypeLog] 
			,NULL
            ,[Logout]  
            ,[Estado] 
            ,[NCeco]  
        FROM #tempLilosLogOutCruzada

/*======================================== Creación y carga temporal #tempDiscrminacionInicioFin  ======================================*/

	IF OBJECT_ID('tempdb..#tempDiscriminacionInicioFin') IS NOT NULL DROP TABLE #tempDiscriminacionInicioFin;
	CREATE TABLE #tempDiscriminacionInicioFin(
		[Ccms] INT NULL
		,[NCeco]  VARCHAR(120) NULL
		,[FechaStaff]  DATE NULL
		,[TypeLog] VARCHAR(20) NULL
		,[Login]  DATETIME NULL
		,[FLAGTurno] VARCHAR(15)		
	);

	INSERT INTO #tempDiscriminacionInicioFin 
        SELECT 
            [Ccms] 
			,[NCeco] 
            ,[FechaStaff]  
            ,[TypeLog] 
            ,[Login]
			,CASE 
				WHEN 
					(TypeLog ='Logout' AND CAST((DATEDIFF_BIG(ss,LEAD([Login],1,0) OVER(ORDER BY CCMS),[Login])*1.00)/3600 AS DECIMAL(18,5)) < - 10) 
					OR (TypeLog ='Logout' AND CAST((DATEDIFF_BIG(ss,LEAD([Login],1,0) OVER(ORDER BY [CCMS]),[Login])*1.00)/3600 AS DECIMAL(18,5)) > 8) 
				THEN 'FinTurno'
				WHEN 
					(TypeLog ='Login' AND CAST((DATEDIFF_BIG(ss,LAG([Login],1,0) OVER(ORDER BY CCMS),[Login])*1.00)/3600 AS DECIMAL(18,5)) < -10) 
					OR (TypeLog ='Login' AND CAST((DATEDIFF_BIG(ss,LAG([Login],1,0) OVER(ORDER BY [CCMS]),[Login])*1.00)/3600 AS DECIMAL(18,5)) > 9) 
				THEN 'IniTurno'
			END AS [FLAGTurno]   
        FROM #tempLilosFinal
		WHERE [Estado] = 'On Switch'


		SELECT 
			[Ccms] 
			,[NCeco] 
			,[FechaStaff]  
			,[TypeLog] 
			,[Login]
			,[FLAGTurno] 
		FROM #tempDiscriminacionInicioFin
		WHERE [FLAGTurno] IS NOT NULL



/*======================================== Creación y carga temporal #tempDiscrminacionInicioFinQA  ======================================*/

	IF OBJECT_ID('tempdb..#tempDiscriminacionInicioFinQA') IS NOT NULL DROP TABLE #tempDiscriminacionInicioFinQA;
	CREATE TABLE #tempDiscriminacionInicioFinQA(
		[Ccms] INT NULL
		,[NCeco]  VARCHAR(120) NULL
		,[FechaStaff]  DATE NULL
		,[TypeLog] VARCHAR(20) NULL
		,[Login]  DATETIME NULL
		,[FLAGTurno] VARCHAR(15)	
		,[TimeStamp] DATETIME
			
	);
	INSERT INTO #tempDiscriminacionInicioFinQA
	SELECT
		[Ccms] 
		,[NCeco]  
		,[FechaStaff]  
		,[TypeLog] 
		,[Login]  
		,[FLAGTurno]
		,GETDATE () 	

	FROM #tempDiscriminacionInicioFin

/*======================================== Insercion a la tabla fisica ======================================*/

		TRUNCATE TABLE [dbo].[tbReporteAusentismoMeLi];

		INSERT INTO [dbo].[tbReporteAusentismoMeLi]
			SELECT	
				 [Ccms] 
				,[NCeco]  
				,[FechaStaff]  
				,[TypeLog] 
				,[Login] 
				,[FLAGTurno] 	
				,[TimeStamp]     
			FROM #tempDiscriminacionInicioFinQA

END TRY

        BEGIN CATCH
            SET @Error = 1;
            PRINT ERROR_MESSAGE();
        END CATCH
        /*=======================Eliminacion de temporales=========================*/

    IF OBJECT_ID('tempdb..#tempHcNominaFiltrada') IS NOT NULL 
	 	DROP TABLE #tempHcNominaFiltrada;

    IF OBJECT_ID('tempdb..#tempNominaEmployees') IS NOT NULL 
	 	DROP TABLE #tempNominaEmployees;

	IF OBJECT_ID('tempdb..#tempHcNomina') IS NOT NULL 
	 	DROP TABLE #tempHcNomina;

	IF OBJECT_ID('tempdb..#tempNominaFinal') IS NOT NULL 
	 	DROP TABLE #tempNominaFinal;

    IF OBJECT_ID('tempdb..#tempRawLiloTimeClock') IS NOT NULL 
	 	DROP TABLE #tempRawLiloTimeClock;

	IF OBJECT_ID('tempdb..#tempLilosLoginCruzada') IS NOT NULL 
	 	DROP TABLE #tempLilosLoginCruzada;

	IF OBJECT_ID('tempdb..#tempLilosLogOutCruzada') IS NOT NULL 
	 	DROP TABLE #tempLilosLogOutCruzada;

    IF OBJECT_ID('tempdb..#tempRawLiloTimeClockLogOut') IS NOT NULL 
	 	DROP TABLE #tempRawLiloTimeClockLogOut;
		
	IF OBJECT_ID('tempdb..#tempLilosFinal') IS NOT NULL 
	 	DROP TABLE #tempLilosFinal;
		
	IF OBJECT_ID('tempdb..#tempDiscriminacionInicioFin') IS NOT NULL 
	 	DROP TABLE #tempDiscriminacionInicioFin;
		
	IF OBJECT_ID('tempdb..#tempDiscriminacionInicioFinQA') IS NOT NULL 
	 	DROP TABLE #tempDiscriminacionInicioFinQA;

END;