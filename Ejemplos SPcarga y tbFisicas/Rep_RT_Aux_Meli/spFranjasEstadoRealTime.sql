USE [Mercadolibre]
GO
/****** Object:  StoredProcedure [dbo].[spFranjasEstadoRealTime]    Script Date: 28/09/2023 12:44:49 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
<Informacion Creacion>
User_NT: E_1143864762, E_1010083873, E_1000687202, E_1105792917, E_1016102870
Fecha: 2023-09-28
Descripcion: 
Se crea un sp [spFranjasEstadoRealTime] que trae información de tbFranjasEstadoRealTime y desde [TPCCP-DB141\SQL2016STD,5081].[AdHocReports].[dbo].[tbHeadCountFullView] 
la cual consolida la información en la tabla fisica tbRepRTAuxMeli, que es utilizada para realizar la vista vwRepRTAuxMeli
<Ejemplo>
EXEC [dbo].[spFranjasEstadoRealTime]

<Update> 
User_NT:E_1143864762, E_1010083873, E_1000687202, E_1105792917, E_1016102870
Fecha: 2023-09-29
Descripcion: Se realizo la modificacion de agregar las columnas [FullName],[FullName ACCM],[FullNameSupervisor],[AM].
Adicionalmente se eliminó la vista asocaida debido a redundancia, por ultimo se anexaron todas las personas involucradas
en la creación del sp.
                                                                    
*/

ALTER PROCEDURE [dbo].[spFranjasEstadoRealTime]
AS

SET NOCOUNT ON;

    BEGIN
        BEGIN TRY
        /*======================================== Truncate a la tabla fisica para insercion de nuevos datos   ======================================*/
            
            TRUNCATE TABLE tbRepRTAuxMeli

        /*===============Bloque declaracion de variables==========*/
        
        DECLARE @ERROR INT =0;
        
        /*======================================== Creación y carga temporal #tmpCalculosFranjasEstadoRealTime ======================================*/

        IF OBJECT_ID('tempdb..#tmpCalculosFranjasEstadoRealTime') IS NOT NULL 
        DROP TABLE #tmpCalculosFranjasEstadoRealTime;

        CREATE TABLE #tmpCalculosFranjasEstadoRealTime
        (   
                [fecha]                     DATE
                ,[inicio]                   TIME
                ,[fin]                      TIME
                ,[conexionsec]              NUMERIC
                ,[UserLdap]                 NVARCHAR (100)
                ,[EstadoAgrupado]           VARCHAR  (100)
                ,[lob]                      VARCHAR  (100)
                ,[oldstatus]                VARCHAR  (100)
                ,[Online]                   NUMERIC
                ,[Break]                    NUMERIC
                ,[Event]                    FLOAT
                ,[Help Exclusive]           NUMERIC 
                ,[Operational Failure]      NUMERIC 
                ,[Systematic Failure]       NUMERIC 
                ,[Training]                 NUMERIC 
                ,[Coaching]                 NUMERIC 
                ,[Help Low Priority]        NUMERIC 
                ,[Teaching]                 FLOAT 
                ,[Shadowing]                FLOAT 
                ,[Nesting]                  FLOAT 
                ,[Tiempo Log]               TIME
            
        );

        INSERT INTO #tmpCalculosFranjasEstadoRealTime
        SELECT
            [fecha]
            ,[inicio]
            ,[fin]
            ,[conexionsec]
            ,[UserLdap]
            ,[EstadoAgrupado]
            ,[lob]
            ,[oldstatus]     
            ,CASE
            WHEN oldstatus = 'Online' THEN ISNULL(conexionsec,0)*1
            ELSE 0
            END AS [Online]
            ,CASE
                WHEN oldstatus = 'Break' THEN ISNULL(conexionsec,0)*1
                ELSE 0
            END AS [Break]
            ,CASE
                WHEN oldstatus = 'Event' THEN ISNULL(conexionsec,0)/86400
                ELSE 0
            END AS [Event]
            ,CASE
                WHEN oldstatus = 'Help Exclusive' THEN ISNULL(conexionsec,0)*1
                ELSE 0
            END AS [Help Exclusive]
            ,CASE
                WHEN oldstatus = 'Operational Failure' THEN ISNULL(conexionsec,0)*1
                ELSE 0
            END AS [Operational Failure]
            ,CASE
                WHEN oldstatus = 'Systematic Failure' THEN ISNULL(conexionsec,0)*1
                ELSE 0
            END AS [Systematic Failure]
            ,CASE
                WHEN oldstatus = 'Training' THEN ISNULL(conexionsec,0)*1
                ELSE 0
            END AS [Training]
            ,CASE
                WHEN oldstatus = 'Coaching' THEN ISNULL(conexionsec,0)*1
                ELSE 0
            END AS [Coaching]
            ,CASE
                WHEN oldstatus = 'Help Low Priority' THEN ISNULL(conexionsec,0)*1
                ELSE 0
            END AS [Help Low Priority]
            ,CASE
                WHEN oldstatus= 'Teaching' THEN ISNULL(conexionsec,0)/86400
                ELSE 0
            END AS [Teaching]
            ,CASE
                WHEN oldstatus = 'Shadowing' THEN ISNULL(conexionsec,0)/86400
                ELSE 0
            END AS [Shadowing]
            ,CASE
                WHEN oldstatus = 'Nesting' THEN ISNULL(conexionsec,0)/86400
                ELSE 0
            END AS [Nesting]
            ,CONVERT(varchar(15), CAST(CONVERT(TIME, DATEADD(SECOND, ISNULL(conexionsec,0), '00:00:00')) AS TIME), 22) AS [Tiempo Log]
            

        FROM tbFranjasEstadoRealTime WITH (NOLOCK);
    

		        /*======================================== Creación y carga temporales calculo supervisor ======================================*/

        IF OBJECT_ID('tempdb..#tmpCalculoSupervisor') IS NOT NULL 
        DROP TABLE #tmpCalculoSupervisor;

        CREATE TABLE #tmpCalculoSupervisor
        (   
				    CCMSAgent				VARCHAR(100)
					,[FullName]				VARCHAR(100)
					,[FullName ACCM]		VARCHAR(100)
					,[FullNameSupervisor]	VARCHAR(100)
					,[GeneralId]			VARCHAR(100)
                
        );

        INSERT INTO #tmpCalculoSupervisor
        SELECT 
		    CCMSAgent
			,UPPER([FullName])
			,UPPER([FullName ACCM])
			,UPPER([FullNameSupervisor])
			,[GeneralId]		
			
       FROM [TPCCP-DB141\SQL2016STD,5081].[AdHocReports].[dbo].[tbHeadCountFullView]  WITH(NOLOCK)
       WHERE [Client] = 'Mercado Libre'


	    IF OBJECT_ID('tempdb..#tmpCalculoSupervisorTwo') IS NOT NULL 
        DROP TABLE #tmpCalculoSupervisorTwo;

        CREATE TABLE #tmpCalculoSupervisorTwo
        (   
				    CCMSAgent				VARCHAR(100)
					,[FullName]				VARCHAR(100)
					,[FullNameSupervisor]	VARCHAR(100)
                
        );

        INSERT INTO #tmpCalculoSupervisorTwo
        SELECT 
		    CCMSAgent
			,UPPER(SUBSTRING([FullName], CHARINDEX(',', [FullName]) + 2, LEN([FullName])) + ' ' + LEFT([FullName], CHARINDEX(',', [FullName]) - 1)) AS [FullName]
			,UPPER([FullNameSupervisor])
			
       FROM [TPCCP-DB141\SQL2016STD,5081].[AdHocReports].[dbo].[tbHeadCountFullView]  WITH(NOLOCK)
       WHERE [Client] = 'Mercado Libre' and [Role] = 'Ejecutivo de Cuenta'


    
        /*======================================== Creación y carga temporal #tmpNamesFranjasEstadoRealTime ======================================*/

        IF OBJECT_ID('tempdb..#tmpNamesFranjasEstadoRealTime') IS NOT NULL 
        DROP TABLE #tmpNamesFranjasEstadoRealTime;

        CREATE TABLE #tmpNamesFranjasEstadoRealTime
        (   
                 [TL]						VARCHAR(50)
                ,[ACM]						VARCHAR(50)
                ,[Director]					VARCHAR(50)
                ,[GeneralId]				VARCHAR(100)

                
        );

        INSERT INTO #tmpNamesFranjasEstadoRealTime
        SELECT 
                 a.[FullName] AS[TL]
				,b.[FullName] AS[ACM]
				,B.[FullNameSupervisor] AS [Director]
				,A.[GeneralId]
			
       FROM #tmpCalculoSupervisor AS A WITH(NOLOCK)
	   INNER JOIN #tmpCalculoSupervisorTWO AS B 
	   ON A.[FullName ACCM] = B.[FullName]
        



    /*======================================== Creación y carga temporal #tmpConsolidadoFranjasEstadoRealTimeQA ======================================*/  
    IF OBJECT_ID('tempdb..#tmpConsolidadoFranjasEstadoRealTimeQA') IS NOT NULL 
    DROP TABLE #tmpConsolidadoFranjasEstadoRealTimeQA;
                
        CREATE TABLE #tmpConsolidadoFranjasEstadoRealTimeQA
            (
                [fecha]                   DATE
                ,[inicio]                 TIME
                ,[fin]                    TIME
                ,[conexionsec]            NUMERIC
                ,[UserLdap]               NVARCHAR (100)
                ,[EstadoAgrupado]         VARCHAR  (100)
                ,[lob]                    VARCHAR  (100)
                ,[oldstatus]              VARCHAR  (100)
                ,[Online]                 NUMERIC
                ,[Break]                  NUMERIC
                ,[Event]                  FLOAT
                ,[Post-Contact]           NUMERIC 
                ,[Help Exclusive]         NUMERIC 
                ,[Operational Failure]    NUMERIC 
                ,[Systematic Failure]     NUMERIC 
                ,[Training]               NUMERIC 
                ,[Coaching]               NUMERIC 
                ,[Help Low Priority]      NUMERIC 
                ,[Teaching]               FLOAT 
                ,[Shadowing]              FLOAT 
                ,[Nesting]                FLOAT 
                ,[Tiempo Log]             TIME
                ,[TL]                     VARCHAR(50)
                ,[ACM]                    VARCHAR(50)
                ,[Director]               VARCHAR(50)
                ,[Clocktime]              TIME

  
            );

     INSERT INTO #tmpConsolidadoFranjasEstadoRealTimeQA
        SELECT 
                A.[fecha]                   
                ,A.[inicio]                 
                ,A.[fin]                    
                ,A.[conexionsec]            
                ,A.[UserLdap]               
                ,A.[EstadoAgrupado]         
                ,A.[lob]                    
                ,A.[oldstatus]              
                ,A.[Online]               
                ,A.[Break]                 
                ,A.[Event]                 
                ,CASE
             WHEN A.[oldstatus] = LEAD(CAST(A.[Online] AS VARCHAR)) OVER (ORDER BY A.[oldstatus])  THEN ISNULL(A.[conexionsec],0)*1
             ELSE 0
        END AS [PostContact]         
                ,A.[Help Exclusive]        
                ,A.[Operational Failure]   
                ,A.[Systematic Failure]    
                ,A.[Training]              
                ,A.[Coaching]              
                ,A.[Help Low Priority]     
                ,A.[Teaching]              
                ,A.[Shadowing]             
                ,A.[Nesting]               
                ,A.[Tiempo Log]
                ,B.[TL]                  
                ,B.[ACM]                   
                ,B.[Director]
                ,A.[inicio] AS [Clocktime]
               




            FROM #tmpCalculosFranjasEstadoRealTime AS A WITH(NOLOCK)
            INNER JOIN #tmpNamesFranjasEstadoRealTime AS B WITH(NOLOCK)
            ON A.[UserLdap] COLLATE SQL_Latin1_General_CP1_CI_AS = B.[GeneralId];
        

        /*======================================== Carga a la tabla fisica ======================================*/

            INSERT INTO [dbo].[tbRepRTAuxMeli] 
            SELECT                        
                 [fecha]                
                ,[inicio]               
                ,[fin]                  
                ,[conexionsec]          
                ,[UserLdap]            
                ,[EstadoAgrupado]       
                ,[lob]                  
                ,[oldstatus]            
                ,[Online]               
                ,[Break]                
                ,[Event]                
                ,[Post-Contact]          
                ,[Help Exclusive]        
                ,[Operational Failure]   
                ,[Systematic Failure]    
                ,[Training]             
                ,[Coaching]             
                ,[Help Low Priority]      
                ,[Teaching]             
                ,[Shadowing]            
                ,[Nesting]              
                ,[Tiempo Log]            
                ,[TL]                   
                ,[ACM]                  
                ,[Director]             
                ,[Clocktime]        
                ,GETDATE()
                  



            FROM #tmpConsolidadoFranjasEstadoRealTimeQA;

        END TRY
        
        BEGIN CATCH
            SET @Error = 1;
            PRINT ERROR_MESSAGE();
        END CATCH
        /*=======================Eliminacion de temporales=========================*/

        IF OBJECT_ID('tempdb..#tmpCalculosFranjasEstadoRealTime') IS NOT NULL 
            DROP TABLE #tmpCalculosFranjasEstadoRealTime;
		IF OBJECT_ID('tempdb..#tmpCalculoSupervisor') IS NOT NULL 
            DROP TABLE #tmpCalculoSupervisor;
		IF OBJECT_ID('tempdb..#tmpCalculoSupervisorTwo') IS NOT NULL 
            DROP TABLE #tmpCalculoSupervisorTwo;
        IF OBJECT_ID('tempdb..#tmpNamesFranjasEstadoRealTime') IS NOT NULL 
            DROP TABLE #tmpNamesFranjasEstadoRealTime;
        IF OBJECT_ID('tempdb..#tmpConsolidadoFranjasEstadoRealTimeQA') IS NOT NULL 
            DROP TABLE #tmpConsolidadoFranjasEstadoRealTimeQA;
     
    END

