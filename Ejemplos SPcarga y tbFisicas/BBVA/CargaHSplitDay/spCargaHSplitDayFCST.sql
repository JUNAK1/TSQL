USE [BBVA]
GO

/*
 <Informacion Creacion>
 User_NT: E_1105792917, E_1015216308, E_1233493216, E_1053871829, E_1010083873
 Fecha: 2023-10-11
 Descripcion: Se crea un sp de carga [spCargaHSplitDayFCST] con 9 temporales.
 La información se trae de las tablas usadas en la vista con el nombre de [dbo].[vwBBVAHsplitVSOAU]
 Al final se hace el Mergue en la tabla fisica [tbCargaHSplitDayFCST] para actualizar los registros existentes o insertar nuevos registros.

 
 <Ejemplo>
 Exec [dbo].[spCargaHSplitDayFCST] 
 */


CREATE PROCEDURE [dbo].[spCargaHSplitDayFCST] 
AS
SET NOCOUNT ON;
    BEGIN 
        BEGIN TRY

/*===============Bloque declaracion de variables==========*/
			DECLARE @ERROR INT = 0,
			@DateStart DATE = NULL,
			@DateEnd DATE = NULL;

			SET
				@DateStart = ISNULL(@DateStart, CAST(GETDATE() -90 AS DATE));

			SET
				@DateEnd = ISNULL(@DateEnd, CAST(GETDATE() AS DATE));

/*======================================== creacion y carga temporal #tempSkillProductivos ======================================*/
            IF OBJECT_ID('tempdb..#tempSkillProductivos') IS NOT NULL DROP TABLE #tempSkillProductivos;
            CREATE TABLE #tempSkillProductivos(
                 [Campaña]          VARCHAR(120)    NULL
                ,[Lob]              VARCHAR(120)    NULL
                ,[skill]            INT             NULL
                ,[TipoSkill]        VARCHAR(120)    NULL
                ,[Lucent]           VARCHAR(120)    NULL
                ,[SLObj]            FLOAT           NULL
                ,[AHTObj]           FLOAT           NULL
                ,[STObj]            FLOAT           NULL
                ,[DetalleSkill]     VARCHAR(120)    NULL
                ,[Desde]            DATETIME        NULL 
                ,[Hasta]            DATETIME        NULL 
                ,[TPHObj]           FLOAT           NULL
                ,[Vertical]         VARCHAR(120)    NULL
                ,[Mercado]          VARCHAR(120)    NULL
            );  

            INSERT INTO #tempSkillProductivos
                SELECT
                    [Campaña]
                    ,CASE [Lob]
                        WHEN 'Banca Digital' THEN 'Banca Masiva'
                        WHEN 'Servicing' THEN 'Banca Masiva'
                        ELSE [Lob]
                    END as [Lob]
                    ,[skill]
                    ,[TipoSkill]
                    ,[Lucent]
                    ,[SLObj]
                    ,[AHTObj]
                    ,[STObj]
                    ,[DetalleSkill]
                    ,[Desde]
                    ,[Hasta]
                    ,[TPHObj]
                    ,[Vertical]
                    ,[Mercado]
                FROM [dbo].[tbLobSkillProductivos] WITH(NOLOCK);

/*======================================== creacion y carga temporal #tempHSP ======================================*/
            IF OBJECT_ID('tempdb..#tempHSP') IS NOT NULL DROP TABLE #tempHSP;
            CREATE TABLE #tempHSP(
                     [Fecha]          DATE NULL
                    ,[StartTime]      INT NULL
                    ,[Acd]            INT NULL
                    ,[Franja]         TIME NULL
                    ,[Split]          INT NULL
                    ,[AcdCalls]       INT NULL
                    ,[AcdTime]        INT NULL
                    ,[AcwTime]        INT NULL
                    ,[CallsOffered]   INT NULL
                    ,[AbnCalls]       INT NULL
                    ,[OtherCalls]     INT NULL
                    ,[AbnCallsOne]    INT NULL
                    ,[AbnCallsTwo]    INT NULL
                    ,[AbnCallsThree]  INT NULL
                    ,[Acceptable]     INT NULL
                    ,[AnsTime]        INT NULL
                    ,[AbnTime]        INT NULL
                    ,[Lob]            VARCHAR(120) NULL
            );

            INSERT INTO #tempHSP
                SELECT 
                    [row_date] AS Fecha
                    ,[StartTime]
                    ,[acd]
                    ,CONVERT(TIME(0), IIF(LEN([starttime]) = 1, '00:00', IIF(LEN([starttime]) = 2, '00:' + CAST([starttime] AS VARCHAR(4)),
                        IIF(LEN([starttime]) = 3, '0' + LEFT(CAST([starttime] AS VARCHAR(4)), 1) + ':' + RIGHT(CAST([starttime] AS VARCHAR(4)), 2), 
                        IIF(LEN([starttime]) = 4, LEFT(CAST([starttime] AS VARCHAR(4)), 2) + ':' + RIGHT(CAST([starttime] AS VARCHAR(4)), 2), ''))))) AS Franja
                    ,[split]
                    ,[acdcalls]
                    ,[acdtime]
                    ,[acwtime]
                    ,[callsoffered]
                    ,[abncalls]
                    ,[othercalls]
                    ,[abncalls1]
                    ,[abncalls2]
                    ,[abncalls3]
                    ,[acceptable]
                    ,[anstime]
                    ,[abntime]
                    ,B.[Lob]
                FROM [dbo].[hsplit] A WITH (NOLOCK)
                INNER JOIN #tempSkillProductivos B WITH (NOLOCK) 
                    ON A.[split] = B.[skill]
                WHERE ACD = '1' 
                    AND B.[TipoSkill] = 'Productivo' 
                    AND B.[Hasta] IS NULL 
                    AND [row_date] BETWEEN @DateStart AND @DateEnd;

/*======================================== creacion y carga temporal #tempHAG ======================================*/
            IF OBJECT_ID('tempdb..#tempHAG') IS NOT NULL DROP TABLE #tempHAG;
            CREATE TABLE #tempHAG(
                 [FAgent]           DATE NULL
                ,[Split]            INT NULL
                ,[StartTime]        INT NULL
                ,[TiStaffTime]      INT NULL
                ,[TiAvailTime]      INT NULL
                ,[TiAuxTime]        INT NULL
                ,[Acdtime]          INT NULL
                ,[Holdacdtime]      INT NULL
                ,[Transferred]      INT NULL
            );
            
            INSERT INTO #tempHAG
                SELECT 
                    [row_date]              AS [fagent]
                    ,[split]                AS [split]
                    ,[starttime]            AS [starttime]
                    ,sum(ti_stafftime)      AS [ti_stafftime]
                    ,sum(ti_availtime)      AS [ti_availtime]
                    ,sum(ti_auxtime)        AS [ti_auxtime]
                    ,sum(acdtime)           AS [acdtime]
                    ,sum(holdacdtime)       AS [holdacdtime]
                    ,sum(transferred)       AS [transferred]
                FROM [dbo].[hagent] WITH (NOLOCK)
                WHERE [acd] = 1
                GROUP BY [row_date]
                    ,[split]
                    ,[starttime];
            

/*======================================== creacion y carga temporal #tempOA ======================================*/
            IF OBJECT_ID('tempdb..#tempOA') IS NOT NULL DROP TABLE #tempOA;
            CREATE TABLE #tempOA(
                 [Campaña]          VARCHAR(120) NULL
                ,[Lob]              VARCHAR(120) NULL
                ,[Fecha]            DATE NULL
                ,[Franja]           TIME NULL
                ,[ScheduledStaff]   INT NULL
                ,[NetStaff]         FLOAT NULL
                ,[ProductiveStaff]  FLOAT NULL
                ,[Req]              FLOAT NULL
                ,[Volume]           FLOAT NULL
                ,[AHT]              FLOAT NULL
            );
            
            INSERT INTO #tempOA
                SELECT 
                    [Campaña]                   AS [Campaña]
                    ,CASE [Lob]
                        WHEN 'Banca Digital' THEN 'Banca Masiva'
                        WHEN 'Servicing' THEN 'Banca Masiva'
                        ELSE [Lob]
                    END AS [Lob]
                    ,[Fecha]                    AS [Fecha]
                    ,[Franja]                   AS [Franja]
                    ,SUM([Scheduled Staff])     AS [Scheduled Staff]
                    ,SUM([Net Staff])           AS [Net Staff]
                    ,SUM([Productive Staff])    AS [Productive Staff]
                    ,SUM([Req])                 AS [Req]
                    ,SUM([Volume])              AS [Volume]
                    ,SUM([AHT])                 AS [AHT]
                FROM [dbo].[tbOAU] WITH (NOLOCK)
                WHERE [Fecha] BETWEEN @DateStart AND @DateEnd
                GROUP BY [Campaña]
                    ,[Lob]
                    ,[Fecha]
                    ,[Franja];
            
            /*======================================== creacion y carga temporal #tempOAREQDAY ======================================*/
            IF OBJECT_ID('tempdb..#tempOAREQDAY') IS NOT NULL DROP TABLE #tempOAREQDAY;
            CREATE TABLE #tempOAREQDAY(
                 [Lob]          VARCHAR(120) NULL
                ,[Fecha]        DATE         NULL
                ,[ReqDay]       FLOAT        NULL
            );

            INSERT INTO #tempOAREQDAY
                SELECT
                    CASE [Lob]
                        WHEN 'Banca Digital' THEN 'Banca Masiva'
                        WHEN 'Servicing' THEN 'Banca Masiva'
                        ELSE [Lob]
                    END                 AS [Lob]
                    ,[Fecha]            AS [Fecha]
                    ,SUM([Req])         AS [ReqDay]
                FROM [dbo].[tbOAU] WITH (NOLOCK)
                WHERE [Fecha] BETWEEN @DateStart AND @DateEnd
                GROUP BY [Lob]
                ,[Fecha];

                    /*======================================== creacion y carga temporal #tempREQUERIDOSDay ======================================*/
            IF OBJECT_ID('tempdb..#tempREQUERIDOSDay') IS NOT NULL DROP TABLE #tempREQUERIDOSDay;
            CREATE TABLE #tempREQUERIDOSDay(
                 [Fecha]                DATE         NULL
                ,[Franja]               INT          NULL
                ,[Segmento]             VARCHAR(120) NULL
                ,[Requerido]            FLOAT        NULL
                ,[EstimadoNeto]         FLOAT        NULL
                ,[FinalRequerido]       FLOAT        NULL
            );

            INSERT INTO #tempREQUERIDOSDay
                SELECT 
                    [Fecha]
                    ,'0' AS [Franja]
                    ,[Segmento]
                    ,[Requerido]
                    ,[EstimadoNeto]
                    ,[FinalRequerido]
                FROM [dbo].[tbwfmRequeridos] WITH (NOLOCK)
                WHERE [Fecha] BETWEEN @DateStart AND @DateEnd;

        /*======================================== creacion y carga temporal #tempOAREQDAY ======================================*/

            IF OBJECT_ID('tempdb..#tempREQUERIDOSIntervalo') IS NOT NULL DROP TABLE #tempREQUERIDOSIntervalo;
            CREATE TABLE #tempREQUERIDOSIntervalo(
                 [Fecha]           DATE         NULL
                ,[Segmento]        VARCHAR(120) NULL
                ,[FinalRequerido]  FLOAT        NULL
            );

            INSERT INTO #tempREQUERIDOSIntervalo
                SELECT 
                     [Fecha]
                    ,[Segmento]
                    ,[FinalRequerido]
                FROM [dbo].[tbwfmRequeridos] WITH (NOLOCK)
                WHERE [Fecha] BETWEEN @DateStart AND @DateEnd;
            

            /*======================================== creacion y carga temporal #tempFinalPreAgrupacion======================================*/
            IF OBJECT_ID('tempdb..#tempFinalPreAgrupacion') IS NOT NULL DROP TABLE #tempFinalPreAgrupacion;
            CREATE TABLE #tempFinalPreAgrupacion(
					 [fecha]			DATE
                    ,[starttime]		INT
                    ,[acd]				INT
                    ,[split]			INT
                    ,[Franja]			TIME
                    ,[acdcalls]			INT
                    ,[acdtime]			INT
                    ,[acwtime]			INT
                    ,[callsoffered]		INT
                    ,[abncalls]			INT
                    ,[othercalls]		INT
                    ,[abncallsOne]		INT
                    ,[abncallsTwo]		INT
                    ,[abncallsThree]	INT
                    ,[acceptable]		INT
                    ,[anstime]			INT
                    ,[abntime]			INT
                    ,[NetStaff]			FLOAT
                    ,[Lob]				VARCHAR(200)
                    ,[LobskillProd]		VARCHAR(200)
                    ,[AHT]				FLOAT
                    ,[Campaña]			VARCHAR(200)
                    ,[ProductiveStaff]	INT
                    ,[Req]				FLOAT
                    ,[ScheduledStaff]	INT
                    ,[Volume]			FLOAT
                    ,[HAholdacdtime]	INT
                    ,[tiavailtime]		INT
                    ,[tiauxtime]		INT
                    ,[tistafftime]		INT
                    ,[HAtransferred]	INT
                    ,[TiemposC]			FLOAT
                    ,[ReqNetoDay]		INT
                    ,[ReqNetoIntervalo]	INT
                    ,[ReqDay]			FLOAT
            );
                INSERT INTO #tempFinalPreAgrupacion
                SELECT 
                     H.[fecha]                          AS [fecha]
                    ,H.[starttime]                      AS [starttime]
                    ,H.[acd]                            AS [acd] 
                    ,H.[split]                          AS [split]
                    ,o.[Franja]                         AS [Franja]
                    ,H.[acdcalls]                       AS [acdcalls]
                    ,H.[acdtime]                        AS [acdtime]
                    ,H.[acwtime]                        AS [acwtime]
                    ,H.[callsoffered]                   AS [callsoffered]
                    ,H.[abncalls]                       AS [abncalls]
                    ,H.[othercalls]                     AS [othercalls]
                    ,H.[abncallsOne]                    AS [abncallsOne]
                    ,H.[abncallsTwo]                    AS [abncallsTwo]
                    ,H.[abncallsThree]                  AS [abncallsThree]
                    ,H.[acceptable]                     AS [acceptable]
                    ,H.[anstime]                        AS [anstime]
                    ,H.[abntime]                        AS [abntime]
                    ,O.[NetStaff]                       AS [NetStaff]
                    ,O.[Lob]                            AS [Lob]
                    ,H.[Lob]                            AS [LobskillProd]
                    ,O.[AHT]                            AS [AHT]
                    ,O.[Campaña]                        AS [Campaña]
                    ,O.[ProductiveStaff]                AS [ProductiveStaff]
                    ,O.[Req]                            AS [Req]
                    ,O.[ScheduledStaff]                 AS [ScheduledStaff]
                    ,O.[Volume]                         AS [Volume]
                    ,HA.[holdacdtime]                   AS [HAholdacdtime]
                    ,HA.[tiavailtime]                   AS [tiavailtime]
                    ,HA.[tiauxtime]                     AS [tiauxtime]
                    ,HA.[tistafftime]                   AS [tistafftime]
                    ,HA.[transferred]                   AS [HAtransferred]
                    ,(O.[AHT] * O.[Volume] * 60)        AS [TiemposC]
                    ,REQ.[FinalRequerido]               AS [ReqNetoDay]
                    ,REQINT.[FinalRequerido]            AS [ReqNetoIntervalo]
                    ,OAREQDAY.[ReqDay]                  AS [ReqDay]
                    
                FROM #tempHSP AS H
                LEFT JOIN #tempOA AS O 
                    ON H.[Fecha] = o.[Fecha] AND h.[Franja] = O.[Franja] AND H.[LOB] = O.[Lob]
                LEFT JOIN #tempREQUERIDOSDay AS REQ
                    ON H.[Fecha] = REQ.[Fecha] AND h.[starttime] = REQ.[Franja] AND H.[LOB] = REQ.[Segmento]
                LEFT JOIN #tempREQUERIDOSIntervalo AS REQINT
                    ON H.[Fecha] = REQINT.[Fecha] AND H.[LOB] = REQINT.[Segmento]
                LEFT JOIN #tempOAREQDAY AS OAREQDAY 
                    ON H.[Fecha] = OAREQDAY.[Fecha] AND H.[LOB] = OAREQDAY.[Lob]
                LEFT JOIN #tempHAG HA 
                    ON HA.[fagent] = H.[Fecha] AND HA.[split] = H.[split] AND ha.[starttime] = h.[starttime]
                WHERE H.[fecha] BETWEEN @DateStart AND @DateEnd;


        /*======================================== Creacion y carga temporal #tempFinalPosAgrupacion ======================================*/

            IF OBJECT_ID('tempdb..#tempFinalPosAgrupacion') IS NOT NULL DROP TABLE #tempFinalPosAgrupacion;
            CREATE TABLE #tempFinalPosAgrupacion(
					 [fecha]					DATE
                    ,[Lob]						VARCHAR(200)
                    ,[AHT]						FLOAT
                    ,[Volume]					FLOAT
                    ,[starttime]				FLOAT
                    ,[NetStaff]					FLOAT
                    ,[TiemposC]					FLOAT			
                    ,[ScheduledStaff]			FLOAT
                    ,[ReqNetoDay]				FLOAT
                    ,[Req]						FLOAT
                    ,[ReqNetoIntervalo]			FLOAT
                    ,[ReqDay]					FLOAT
                    ,[Atendidas]				FLOAT
                    ,[conversacion]				FLOAT
                    ,[acw]						FLOAT
                    ,[Ofrecidas]				FLOAT
                    ,[abncalls]					FLOAT
                    ,[othercalls]				FLOAT
                    ,[Abandonadas5]				FLOAT
                    ,[Abandonadas10]			FLOAT
                    ,[Abandonas15]				FLOAT
                    ,[LlamadasNDS]				FLOAT
                    ,[tiempoatencion]			FLOAT
                    ,[tiempoabandono]			FLOAT
                    ,[hold]						FLOAT
                    ,[disponible]				FLOAT
                    ,[auxiliar]					FLOAT
                    ,[conexion]					FLOAT
                    ,[Transfer]					FLOAT
					,[NSCorregido]				FLOAT
                    ,[NACorregido]				FLOAT

            );

           		INSERT INTO #tempFinalPosAgrupacion
                    SELECT 
                     [fecha]                AS [fecha]
                    ,[LobskillProd]         AS [Lob]
                    ,[AHT]                  AS [AHT] 
                    ,[Volume]               AS [Volume]
                    ,[starttime]            AS [starttime]
                    ,[NetStaff]             AS [NetStaff]
                    ,[TiemposC]             AS [TiemposC] 
                    ,[ScheduledStaff]       AS [ScheduledStaff] 
                    ,[ReqNetoDay]           AS [ReqNetoDay]
                    ,[Req]                  AS [Req]
                    ,[ReqNetoIntervalo]     AS [ReqNetoIntervalo]
                    ,[ReqDay]               AS [ReqDay]
                    ,sum([acdcalls])        AS [Atendidas]
                    ,sum([acdtime])         AS [conversacion]
                    ,sum([acwtime])         AS [acw]
                    ,sum([callsoffered])    AS [Ofrecidas]
                    ,sum([abncalls])        AS [abncalls]
                    ,sum([othercalls])      AS [othercalls]
                    ,sum([abncallsOne])     AS [Abandonadas5]
                    ,sum([abncallsTwo])     AS [Abandonadas10]
                    ,sum([abncallsThree])   AS [Abandonadas15]
                    ,sum([acceptable])      AS [LlamadasNDS]
                    ,sum([anstime])         AS [tiempoatencion]
                    ,sum([abntime])         AS [tiempoabandono]
                    ,sum([HAholdacdtime])   AS [hold]
                    ,sum([tiavailtime])     AS [disponible]
                    ,sum([tiauxtime])       AS [auxiliar]
                    ,sum([tistafftime])     AS [conexion]
                    ,sum([HAtransferred])   AS [Transferidas]
                    ,CASE [LobskillProd]
                        WHEN 'Banca Premium' THEN 0.80
                        ELSE 0.70
                    END AS [NSCorregido]
                    ,CASE [LobskillProd]
                        WHEN 'Banca Premium' THEN 0.98
                        ELSE 0.95
                    END AS [NACorregido]
                FROM #tempFinalPreAgrupacion with(nolock)
                GROUP BY  
                     [fecha] 
                    ,[LobskillProd] 
                    ,[AHT] 
                    ,[Volume] 
                    ,[starttime] 
                    ,[NetStaff] 
                    ,[TiemposC] 
                    ,[ScheduledStaff] 
                    ,[ReqNetoDay] 
                    ,[Req] 
                    ,[ReqNetoIntervalo] 
                    ,[ReqDay];

/*======================================== creacion y carga temporal #tempFinalPosAgrupacionQA======================================*/
            IF OBJECT_ID('tempdb..#tempFinalPosAgrupacionQA') IS NOT NULL DROP TABLE #tempFinalPosAgrupacionQA;
            CREATE TABLE #tempFinalPosAgrupacionQA(
					 [Fecha]					DATE
                    ,[Lob]						VARCHAR(200)
                    ,[FCST]						FLOAT
                    ,[Entrantes]				INT
                    ,[Atendidas]				INT
                    ,[NoventaFCST]				FLOAT
					,[GarantiasDeEventos]		FLOAT
					,[AtendidasReales]			FLOAT
					,[AHTFACDOS]				FLOAT
					,[TimeStamp]				DATETIME
            );

			INSERT INTO #tempFinalPosAgrupacionQA 
                SELECT 
                        [fecha]
                        ,[Lob]
                        ,SUM(Volume)            AS [FCST]
                        ,SUM(Ofrecidas)         AS [ENTRANTES]
                        ,SUM([Atendidas])       AS [ATENDIDAS]
                        ,(SUM(Volume) * 0.90)   AS [NoventaFCST]
                        ,CASE
                            WHEN ISNULL((SUM(Volume) * 0.90),0) > ISNULL(SUM(Ofrecidas),0)
                            THEN ISNULL((SUM(Volume) * 0.90),0) - ISNULL(SUM(Ofrecidas),0)
                            ELSE 0
                        END AS [GarantiasDeEventos]
                        ,CASE
                            WHEN ISNULL((SUM(Volume) * 0.90),0) > ISNULL(SUM(Ofrecidas),0)
                            THEN (ISNULL(ISNULL((SUM(Volume) * 0.90),0) - ISNULL(SUM(Ofrecidas),0),0) + ISNULL(SUM([Atendidas]),0)) 
                            ELSE ISNULL(SUM([Atendidas]),0)
                            END AS [AtendidasReales]
                        ,CASE
                            WHEN SUM([Atendidas]) = 0 OR SUM([Atendidas]) IS NULL
                            THEN 0
                            ELSE (ISNULL(SUM(conversacion),0) + ISNULL(SUM(hold),0)) / SUM([Atendidas])
                        END  AS [AHTFACDOS]
                        ,GETDATE()
                    FROM #tempFinalPosAgrupacion
                    GROUP BY [fecha], [Lob]
                    ORDER BY [Fecha],[Lob];

/*======================================== Carga a la tabla fisica [dbo].[tbCargaHSplitDayFCST] usando MERGE ======================================*/
				
				MERGE [dbo].[tbCargaHSplitDayFCST] AS [tgt] USING (
					SELECT
						[Fecha],
						[Lob],
						[FCST],
						[Entrantes],
						[Atendidas],
						[NoventaFCST],
						[GarantiasDeEventos],
						[AtendidasReales],
						[AHTFACDOS],
						[TimeStamp]
					FROM #tempFinalPosAgrupacionQA
				) AS [src] ON (
					 [src].[Fecha]  = [tgt].[Fecha] AND  [src].[Lob]    = [tgt].[Lob] COLLATE SQL_Latin1_General_CP1_CI_AS
					
				) -- For updates
				WHEN MATCHED THEN
				UPDATE
				SET
					--                            = [src].        
					[tgt].[Fecha]                 = [src].[Fecha],
					[tgt].[Lob]                   = [src].[Lob],
					[tgt].[FCST]                  = [src].[FCST],
					[tgt].[Entrantes]             = [src].[Entrantes],
					[tgt].[Atendidas]             = [src].[Atendidas],
					[tgt].[NoventaFCST]           = [src].[NoventaFCST],
					[tgt].[GarantiasDeEventos]    = [src].[GarantiasDeEventos],
					[tgt].[AtendidasReales]       = [src].[AtendidasReales],
					[tgt].[AHTFACDOS]             = [src].[AHTFACDOS],
					[tgt].[TimeStamp]             = [src].[TimeStamp]
					WHEN NOT MATCHED THEN
				INSERT
					(
						[Fecha],
						[Lob],
						[FCST],
						[Entrantes],
						[Atendidas],
						[NoventaFCST],
						[GarantiasDeEventos],
						[AtendidasReales],
						[AHTFACDOS],
						[TimeStamp]
					)
				VALUES
					(
						[src].[Fecha],
						[src].[Lob],
						[src].[FCST],
						[src].[Entrantes],
						[src].[Atendidas],
						[src].[NoventaFCST],
						[src].[GarantiasDeEventos],
						[src].[AtendidasReales],
						[src].[AHTFACDOS],
						[src].[TimeStamp]
					);

		END TRY 
		BEGIN CATCH
			SET
				@Error = 1;

			PRINT ERROR_MESSAGE();

		END CATCH
    /*=======================Eliminacion de temporales=========================*/
    
    IF OBJECT_ID('tempdb..#tempSkillProductivos') IS NOT NULL DROP TABLE #tempSkillProductivos;
    IF OBJECT_ID('tempdb..#tempHSP') IS NOT NULL DROP TABLE #tempHSP;
    IF OBJECT_ID('tempdb..#tempHAG') IS NOT NULL DROP TABLE #tempHAG;
    IF OBJECT_ID('tempdb..#tempOA') IS NOT NULL DROP TABLE #tempOA;
    IF OBJECT_ID('tempdb..#tempOAREQDAY') IS NOT NULL DROP TABLE #tempOAREQDAY;
	IF OBJECT_ID('tempdb..#tempREQUERIDOSDay') IS NOT NULL DROP TABLE #tempREQUERIDOSDay;
	IF OBJECT_ID('tempdb..#tempREQUERIDOSIntervalo') IS NOT NULL DROP TABLE #tempREQUERIDOSIntervalo;
    IF OBJECT_ID('tempdb..#tempFinalPreAgrupacion') IS NOT NULL DROP TABLE #tempFinalPreAgrupacion;
    IF OBJECT_ID('tempdb..#tempFinalPosAgrupacion') IS NOT NULL DROP TABLE #tempFinalPosAgrupacion;
	IF OBJECT_ID('tempdb..#tempFinalPosAgrupacionQA') IS NOT NULL DROP TABLE #tempFinalPosAgrupacionQA;
END;

