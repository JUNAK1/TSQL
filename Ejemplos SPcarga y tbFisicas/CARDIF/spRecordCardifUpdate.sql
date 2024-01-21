USE [Cardif]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
<Informacion Creacion>
User_NT:E_1010083873 
Fecha: 2023-09-18
Descripcion: Se crea sp en la cual se extraen datos de 4 tablas ( [10.151.230.21\SCOFFS].[WFM CMS].[dbo].[hagent], [10.151.230.21\SCOFFS].[WFM CMS].[dbo].[hsplit], [TPCCP-DB10].[Cardif].[dbo].[tbLobSkillProductivos] y [TPCCP-DB10].[Cardif].[dbo].[tboau]).
Creando a su vez 4 tablas temporales que contienen los datos de cada tabla (#TMPHagent, #TMPHsplit, #TMPLobSkill, #TMPOverAndUnder) con sus respectivos controles de nulos en los cálculos implicados
Se crea una quinta tabla temporal (#TMPConsolidadosRecordQA) la cual será la unificación de las columnas de las 4 anteriores tablas temporales
Por ultimo se realiza un MERGE para realizar la inserción a la tabla física ([TPCCP-DB10].[Cardif].[tbRecordCardif])   el cual actualiza los datos de un registro si varios datos se encuentran identicos, si son diferentes se insertan como nuevos registros.
Se realiza el try-catch de errores y por ultimo se hace la eliminación de todas las tablas temporales empleadas
y los carga en [tbRecordCardif]

<Update> 2023-09-20
User_NT:pachon.11
Tps:N/A
descripcion: Se reestrura la logica del Procedure, adicionando pk y nuevas temporales, se adiciona parametros de @dateStart y @dateEnd, adicional se elimina el nombre del servidor del merge 
			y se adicionan la precisión y la escala de los tios de datos DECIMAL, se cambian los campos para la llave primaria..

<Update> "2023-09-22"
User_NT:E_1007346583
Tps:N/A
descripcion: se ordenan los campos, y se cambia el campo [timestamp] por [lastUpdateDate]

<Update> "2023-10-20"
User_NT:E_1000687202
Tps:N/A
Descripcion: Se aplican buenas practicas, se agrega el campo [Date] al Merge, adicional se quitan los Inner Join de los Linked Server y se adicionan en nuevas temporales

<Ejemplo>
Exec [dbo].[spRecordCardif] 
*/
ALTER PROCEDURE [dbo].[spRecordCardif] (@dateStart DATE=NULL,@dateEnd DATE=NULL)
AS

SET NOCOUNT ON;

    BEGIN
		BEGIN TRY
	/*===============Bloque declaracion de variables==========*/
        DECLARE @ERROR INT = 0;
		SET @dateStart    = ISNULL(@dateStart, CAST(GETDATE()- 45 AS DATE))
        SET @dateEnd    = ISNULL(@dateEnd, CAST(GETDATE()-1 AS DATE))

	/*======================================== Creación y carga temporal #TMPHagentsincalulos ======================================*/
        IF OBJECT_ID('tempdb..#TMPHagentsincalulos') IS NOT NULL DROP TABLE #TMPHagentsincalulos;
        CREATE TABLE #TMPHagentsincalulos
        (   
            [rowdate]						DATE
            ,[Avail]                        INT
            ,[tiauxtime]					INT
            ,[tiauxtime6]					INT
			,[TalkTime]                     INT
            ,[HoldTime]                     INT
            ,[ACWTime]                      INT
            ,[RingTime]                     INT
			,[split]						INT
			,[cms]							VARCHAR(100)
        );

        INSERT INTO #TMPHagentsincalulos
			SELECT
				 A.[row_date]				AS [rowdate]
				,A.[ti_availtime]			AS [Avail]
				,A.[ti_auxtime]				AS [tiauxtime]
				,A.[ti_auxtime6]			AS [tiauxtime6]
				,A.[i_acdtime]				AS [TalkTime]
				,A.[holdacdtime]			AS [HoldTime]
				,A.[i_acwtime]				AS [ACWTime]
				,A.[ringtime]				AS [RingTime]
				,A.[split]
				,A.[cms]
			FROM [10.151.230.21\SCOFFS].[WFM CMS].[dbo].[hagent] AS A WITH(NOLOCK)
			WHERE A.[row_date] BETWEEN @dateStart AND @dateEnd;

	/*======================================== Creación y carga temporal #TMPLobSkillProductivosHagent ======================================*/
			IF OBJECT_ID('tempdb..#TMPLobSkillProductivosHagent') IS NOT NULL DROP TABLE #TMPLobSkillProductivosHagent;
			CREATE TABLE #TMPLobSkillProductivosHagent
			(   
				[rowdate]						DATE
				,[Avail]                        INT
				,[tiauxtime]					INT
				,[tiauxtime6]					INT
				,[TalkTime]                     INT
				,[HoldTime]                     INT
				,[ACWTime]                      INT
				,[RingTime]                     INT
			);

			INSERT INTO #TMPLobSkillProductivosHagent
				SELECT
					 [rowdate]
					,[Avail]
					,[tiauxtime]
					,[tiauxtime6]
					,[TalkTime]
					,[HoldTime]
					,[ACWTime]
					,[RingTime]
				FROM #TMPHagentsincalulos AS A WITH(NOLOCK)
				INNER JOIN [Cardif].[dbo].[tbLobSkillProductivos] AS B WITH(NOLOCK)
				ON  A.[split] = B.[skill] AND A.[cms] = B.[Lucent]
				WHERE [rowdate] BETWEEN @dateStart AND @dateEnd;

	/*======================================== Creación y carga temporal #TMPHagent ======================================*/
		IF OBJECT_ID('tempdb..#TMPHagent') IS NOT NULL DROP TABLE #TMPHagent;
        CREATE TABLE #TMPHagent
        (   
            [rowdate]						DATE
            ,[Avail]                        INT
            ,[AuxProd]                      INT
            ,[AuxNoProd]                    INT
            ,[TalkTime]                     INT
            ,[HoldTime]                     INT
            ,[ACWTime]                      INT
            ,[RingTime]                     INT
        );

        INSERT INTO #TMPHagent
			SELECT
				C.[rowdate]
				,SUM(C.[Avail])				AS [Avail]
				, 0 AS [AuxProd]
				,(SUM(ISNULL(C.[tiauxtime],0)) - SUM(ISNULL(C.[tiauxtime6],0)) ) AS [AuxNoProd]
				,SUM(C.[TalkTime])			AS [TalkTime]
				,SUM(C.[HoldTime])			AS [HoldTime]
				,SUM(C.[ACWTime])			AS [ACWTime]
				,SUM(C.[ringtime])			AS [RingTime]
			FROM #TMPHagentsincalulos		AS C 
			WHERE C.[rowdate] BETWEEN @dateStart AND @dateEnd
			GROUP BY C.[rowdate];

	/*======================================== Creación y carga temporal #TMPHsplitsincalculos ======================================*/    
		IF OBJECT_ID('tempdb..#TMPHsplitsincalculos') IS NOT NULL DROP TABLE #TMPHsplitsincalculos;
		CREATE TABLE #TMPHsplitsincalculos
            (
                [rowdate]					DATE
                ,[acdcalls]					INT
                ,[callsoffered]				DECIMAL(18,5)
                ,[acceptable]				DECIMAL(18,5)
				,[split]					INT
				,[cms]						VARCHAR(100)
            );

            INSERT INTO #TMPHsplitsincalculos
				SELECT
					D.[row_date]			AS [rowdate]
					,D.[acdcalls]			AS [acdcalls]
					,D.[callsoffered]		AS [callsoffered]
					,D.[acceptable]			AS [acceptable]
					,D.[split]
					,D.[cms]
				FROM [10.151.230.21\SCOFFS].[WFM CMS].[dbo].[hsplit] AS D WITH(NOLOCK)
				WHERE D.[row_date] BETWEEN @dateStart AND @dateEnd;

	/*======================================== Creación y carga temporal #TMPLobSkillProductivosHsplit ======================================*/    
			IF OBJECT_ID('tempdb..#TMPLobSkillProductivosHsplit') IS NOT NULL DROP TABLE #TMPLobSkillProductivosHsplit;
			CREATE TABLE #TMPLobSkillProductivosHsplit
				(
					[rowdate]					DATE
					,[acdcalls]					INT
					,[callsoffered]				DECIMAL(18,5)
					,[acceptable]				DECIMAL(18,5)
				);

				INSERT INTO #TMPLobSkillProductivosHsplit
					SELECT
						[rowdate]
						,[acdcalls]
						,[callsoffered]
						,[acceptable]
					FROM #TMPHsplitsincalculos AS D WITH(NOLOCK)
					INNER JOIN [Cardif].[dbo].[tbLobSkillProductivos] AS E WITH(NOLOCK)
					ON  D.[split] = E.[skill] AND D.[cms] = E.[Lucent]
					WHERE [rowdate] BETWEEN @dateStart AND @dateEnd;
			
	/*======================================== Creación y carga temporal #TMPHsplit ======================================*/    
        IF OBJECT_ID('tempdb..#TMPHsplit') IS NOT NULL DROP TABLE #TMPHsplit;
		CREATE TABLE #TMPHsplit
            (
                [rowdate]						DATE
                ,[RealInteractionsAnswered]     INT
                ,[RealInteractionsOffered]      INT
                ,[KPIValue]                     DECIMAL(18,5)
                ,[Weight]                       INT
                ,[AvailableProductive]          INT
            );

            INSERT INTO #TMPHsplit 
				SELECT
					F.[rowdate]					AS [rowdate]
					,SUM(F.[acdcalls])			AS [RealInteractionsAnswered]
					,SUM(F.[callsoffered])		AS [RealInteractionsOffered]
					,CASE
					  WHEN    SUM(F.[callsoffered]) = 0 OR SUM(F.[callsoffered]) IS NULL
						 THEN 0
					  ELSE  SUM(ISNULL(F.[acceptable],0)) /  SUM(F.[callsoffered])
					END							AS [KPIValue]
					,SUM(F.[callsoffered])		AS [Weight]
					, 0 AS [AvailableProductive]
				FROM #TMPHsplitsincalculos		AS F WITH(NOLOCK)
				WHERE F.[rowdate] BETWEEN @dateStart AND @dateEnd
				GROUP BY F.[rowdate];

	/*======================================== Creación y carga temporal #TMPOverAndUnder ======================================*/   
		IF OBJECT_ID('tempdb..#TMPOverAndUnder') IS NOT NULL DROP TABLE #TMPOverAndUnder;
        CREATE TABLE #TMPOverAndUnder
            (
                 [Fecha]                        DATE
                ,[FCSTInteractionsAnswered]     DECIMAL(18,0)
                ,[KPIprojection]                FLOAT
                ,[SHKprojection]                DECIMAL(18,5) 
                ,[ABSprojection]                DECIMAL(18,5) 
                ,[AHTprojection]                FLOAT
                ,[KPIWeight]                    DECIMAL(18,0) 
                ,[ReqHours]                     DECIMAL(18,0) 
                ,[FCSTStafftime]                DECIMAL(18,0) 
            );
        
        INSERT INTO #TMPOverAndUnder
			SELECT 
				[Fecha]																		AS [Fecha]
				,SUM(ISNULL([NetCapacity],0))												AS [FCSTInteractionsAnswered]
				,SUM(ISNULL(CAST([SL] AS FLOAT),0))											AS [KPIprojection]
				,CASE
					WHEN SUM([NetStaff]) = 0 OR SUM([NetStaff]) IS NULL
						THEN 0
					ELSE  1-(SUM(ISNULL([ProductiveStaff],0)) /  SUM([NetStaff]))
				END																			AS [SHKprojection]
				,CASE
					WHEN  SUM([ScheduledStaff]) = 0 OR  SUM([ScheduledStaff]) IS NULL
						THEN 0
					ELSE 1-(SUM(ISNULL([NetStaff],0)) / SUM([ScheduledStaff]))
				END																			AS [ABSprojection]
				,SUM(ISNULL([AHT],0))*60													AS [AHTprojection]
				,SUM(ISNULL([NetCapacity],0))												AS [KPIWeight]
				,(SUM(ISNULL([Req],0))*1800)/3600											AS [ReqHours]
				,(SUM(ISNULL([netStaff],0))*1800)/3600										AS [FCSTStafftime]
			FROM [Cardif].[dbo].[tboau]  WITH(NOLOCK)
			WHERE [Fecha] BETWEEN @dateStart AND @dateEnd
			GROUP BY [Fecha];

	/*======================================== Creación y carga temporal #TMPConsolidadosRecordQA ======================================*/  
		IF OBJECT_ID('tempdb..#TMPConsolidadosRecordQA') IS NOT NULL DROP TABLE #TMPConsolidadosRecordQA;
        CREATE TABLE #TMPConsolidadosRecordQA
            (
                [IdClient]                      INT NOT NULL
                ,[Date]                         DATE NOT NULL
                ,[Avail]                        INT
                ,[AuxProd]                      INT
                ,[AuxNoProd]                    INT
                ,[TalkTime]                     INT
                ,[HoldTime]                     INT
                ,[ACWTime]                      INT
                ,[RingTime]                     INT
                ,[RealInteractionsAnswered]     INT
                ,[RealInteractionsOffered]      INT
                ,[KPIValue]                     FLOAT
                ,[Weight]                       INT
                ,[AvailableProductive]          INT
                ,[FCSTInteractionsAnswered]     DECIMAL(18,0)
                ,[KPIprojection]                FLOAT
                ,[SHKprojection]                DECIMAL(18,5)
                ,[ABSprojection]                DECIMAL(18,5)
                ,[AHTprojection]                FLOAT
                ,[KPIWeight]                    DECIMAL(18,0)
                ,[ReqHours]                     DECIMAL(18,0)
                ,[FCSTStafftime]                DECIMAL(18,0)
                ,[lastUpdateDate]               DATETIME 
            );

		 INSERT INTO #TMPConsolidadosRecordQA
			SELECT  
				1421			AS [IdClient]
				,HA.[rowdate]	AS [Date]
				,HA.[Avail]                       
				,HA.[AuxProd]                     
				,HA.[AuxNoProd]                   
				,HA.[TalkTime]                    
				,HA.[HoldTime]                    
				,HA.[ACWTime]                     
				,HA.[RingTime]                    
				,HS.[RealInteractionsAnswered]    
				,HS.[RealInteractionsOffered]     
				,HS.[KPIValue]                     
				,HS.[Weight]                      
				,HS.[AvailableProductive]         
				,TB.[FCSTInteractionsAnswered]     
				,TB.[KPIprojection]                
				,TB.[SHKprojection]                
				,TB.[ABSprojection]                
				,TB.[AHTprojection]               
				,TB.[KPIWeight]                    
				,TB.[ReqHours]                     
				,TB.[FCSTStafftime]   
				,GETDATE() 
			FROM #TMPHagent  AS HA 
			INNER JOIN #TMPHsplit AS HS 
			ON HS.[rowdate] = HA.[rowdate]
			INNER JOIN #TMPOverAndUnder TB
			ON TB.[Fecha] = HA.[rowdate]
			WHERE HA.[rowdate] BETWEEN @dateStart AND @dateEnd;

	/*************************Merge a la tabla fisica********************/
		MERGE  [Cardif].[dbo].[tbRecordCardif] AS [tgt]
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
					,[lastUpdateDate]
				FROM #TMPConsolidadosRecordQA 

        ) AS [src]
        ON
        (
            [src].[Date] = [tgt].[Date] AND [src].[Avail] = [tgt].[Avail] AND [src].[AuxProd] = [tgt].[AuxProd] AND [src].[AuxNoProd] = [tgt].[AuxNoProd]
        )
        -- For updates
        WHEN MATCHED THEN
          UPDATE 
              SET
                 --									=[src].
                 [tgt].[IdClient]					=[src].[IdClient]
                ,[tgt].[Date]						=[src].[Date]
                ,[tgt].[Avail]						=[src].[Avail]
                ,[tgt].[AuxProd]					=[src].[AuxProd]
                ,[tgt].[AuxNoProd]					=[src].[AuxNoProd]
                ,[tgt].[TalkTime]					=[src].[TalkTime]
                ,[tgt].[HoldTime]					=[src].[HoldTime]
                ,[tgt].[ACWTime]					=[src].[ACWTime]
                ,[tgt].[RingTime]					=[src].[RingTime]
                ,[tgt].[RealInteractionsAnswered]	=[src].[RealInteractionsAnswered]
                ,[tgt].[RealInteractionsOffered]	=[src].[RealInteractionsOffered]
                ,[tgt].[FCSTInteractionsAnswered]	=[src].[FCSTInteractionsAnswered]
                ,[tgt].[KPIValue]					=[src].[KPIValue]
                ,[tgt].[KPIprojection]				=[src].[KPIprojection]
                ,[tgt].[SHKprojection]				=[src].[SHKprojection]
                ,[tgt].[ABSprojection]				=[src].[ABSprojection]
                ,[tgt].[AHTprojection]				=[src].[AHTprojection]
                ,[tgt].[Weight]						=[src].[Weight]
                ,[tgt].[ReqHours]					=[src].[ReqHours]
                ,[tgt].[KPIWeight]					=[src].[KPIWeight]
                ,[tgt].[FCSTStafftime]				=[src].[FCSTStafftime]
                ,[tgt].[AvailableProductive]		=[src].[AvailableProductive]
                ,[tgt].[lastUpdateDate]				=[src].[lastUpdateDate]

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
                ,[lastUpdateDate]
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
                ,[src].[lastUpdateDate]
            );

		END TRY
        
        BEGIN CATCH
            SET @Error = 1;
            PRINT ERROR_MESSAGE();
        END CATCH
	/*=======================Eliminacion de temporales=========================*/
	    IF OBJECT_ID('tempdb..#TMPHsplitsincalculos') IS NOT NULL DROP TABLE #TMPHsplitsincalculos;
		IF OBJECT_ID('tempdb..#TMPLobSkillProductivosHsplit') IS NOT NULL DROP TABLE #TMPLobSkillProductivosHsplit;
        IF OBJECT_ID('tempdb..#TMPHagentsincalulos') IS NOT NULL DROP TABLE #TMPHagentsincalulos;
		IF OBJECT_ID('tempdb..#TMPLobSkillProductivosHagent') IS NOT NULL DROP TABLE #TMPLobSkillProductivosHagent;
        IF OBJECT_ID('tempdb..#TMPHagent') IS NOT NULL DROP TABLE #TMPHagent;
        IF OBJECT_ID('tempdb..#TMPHsplit') IS NOT NULL DROP TABLE #TMPHsplit;
        IF OBJECT_ID('tempdb..#TMPOverAndUnder') IS NOT NULL DROP TABLE #TMPOverAndUnder;
        IF OBJECT_ID('tempdb..#TMPConsolidadosRecordQA') IS NOT NULL DROP TABLE #TMPConsolidadosRecordQA;
		
     
    END
