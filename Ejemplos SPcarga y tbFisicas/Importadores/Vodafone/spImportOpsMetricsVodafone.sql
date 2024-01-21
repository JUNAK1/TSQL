USE [Vodafone]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/* ---------------------------
<Información Creación>
User_NT: E_1000687202, E_1012322897, E_1105792917 , E_1233493216
Fecha:  2023-10-06      
Descripcion:  Sp que extrae la información de un archivo .csv en la ruta \\TPCCP-DB20\Dropbox\OffShore\Vodafone\OpsMetrics\
y la inserta en la tabla [dbo].[tbImportOpsMetricsVodafone]   

EXEC [dbo].[spImportOpsMetricsVodafone];
SELECT * [dbo].[tbImportOpsMetricsVodafone]
--------------------------- */

CREATE PROCEDURE [dbo].[spImportOpsMetricsVodafone] 
AS

SET NOCOUNT ON; 

    /* ============== Bloque de Creacion de Tabla de Archivos ============== */
    -- Creacion de tabla temporal para los archivos.    
    
    DROP TABLE IF EXISTS #OuFiles;
    CREATE TABLE #OuFiles(a INT IDENTITY(1, 1), s VARCHAR(1000));
    
    DECLARE @returnValue INT = 0;
    DECLARE @OuPath VARCHAR(8000) = '\\TPCCP-DB20\Dropbox\OffShore\Vodafone\OpsMetrics\';
    
    INSERT INTO #OuFiles
        SELECT REPLACE(DIR, @OuPath,'') FROM
            [TOOLBOX].[DBO].[GetFiles](@OuPath, '*.csv');
            
    DECLARE @i INT;
    SET @i = (
        SELECT COUNT(*) FROM #OuFiles WHERE s IS NOT NULL AND s NOT LIKE '%File Not Found%'
    );

    DECLARE @fnr VARCHAR(350); 
    DECLARE @file VARCHAR(350);
    DECLARE @query VARCHAR(4000);
    DECLARE @error int = 0;
    DECLARE @severity int = 0;

        /* ================ Bloque de Bucle de Carga de Archivos =============== */
    WHILE @i > 0 and (SELECT TOP 1 s FROM #Oufiles) <> 'File Not Found'
    BEGIN
    BEGIN TRY

        SET @file = (SELECT s FROM #OuFiles WHERE a = @i);
        SET @fnr = @OuPath + @file;


    /* ============== Bloque de Creacion de Tablas Temporales ============== */  
    DROP TABLE IF EXISTS [dbo].[#tmpImportOpsMetricsVodafone];
    CREATE TABLE [dbo].[#tmpImportOpsMetricsVodafone] (  

            [lobId]                                       VARCHAR(100)   
            ,[yyyy]                                       VARCHAR(100) 
            ,[mm]                                         VARCHAR(100) 
            ,[CommittedFTE]                               VARCHAR(100) 
            ,[ExplanationCommentaryFTEVariance]           VARCHAR(100) 
            ,[FunctionalWorkstations]                     VARCHAR(100) 
            ,[ProductionHours]                            VARCHAR(100) 
            ,[Contacts]                                   VARCHAR(100) 
            ,[Completes]                                  VARCHAR(100) 
            ,[FirstCallResolved]                          VARCHAR(100) 
            ,[TotalCustomerIssues]                        VARCHAR(100) 
            ,[FirstCallResolutionTarget]                  VARCHAR(100) 
            ,[BilledHours]                                VARCHAR(100) 
            ,[PaidHours]                                  VARCHAR(100) 
            ,[TotalInteractionsOffered]                   VARCHAR(100) 
            ,[TotalInteractionsAnswered]                  VARCHAR(100) 
            ,[ServiceLevelTarget]                         VARCHAR(100) 
            ,[WaitTime]                                   VARCHAR(100) 
            ,[HoldTime]                                   VARCHAR(100) 
            ,[TalkTime]                                   VARCHAR(100)
            ,[WrapUpTime]                                 VARCHAR(100)
            ,[TargetHandleTime]                           VARCHAR(100)
            ,[InteractionsAbandoned]                      VARCHAR(100)                        
            ,[QAFatalError]                               VARCHAR(100)                
            ,[TargetSchedule]                             VARCHAR(100)                
            ,[ActualSchedule]                             VARCHAR(100)                               
            ,[VolumeForecastClientTarget]                 VARCHAR(100)
            ,[VolumeForecastClientActual]                 VARCHAR(100)  
            
    );
    -- Creacion de tabla temporal del importador para datos limpios. 
    DROP TABLE IF EXISTS [dbo].[#tmpImportOpsMetricsVodafoneQA];
    CREATE TABLE [dbo].[#tmpImportOpsMetricsVodafoneQA] (

            [lobId]                              INT
            ,[yyyy]                              INT
            ,[mm]                                INT
            ,[CommittedFTE]                      VARCHAR(100)
            ,[ExplanationCommentaryFTEVariance]  VARCHAR(100)
            ,[FunctionalWorkstations]            VARCHAR(100)
            ,[ProductionHours]                   VARCHAR(100)
            ,[Contacts]                          FLOAT
            ,[Completes]                         FLOAT
            ,[FirstCallResolved]                 FLOAT
            ,[TotalCustomerIssues]               FLOAT
            ,[FirstCallResolutionTarget]         FLOAT
            ,[BilledHours]                       VARCHAR(100)
            ,[PaidHours]                         VARCHAR(100)
            ,[TotalInteractionsOffered]          FLOAT
            ,[TotalInteractionsAnswered]         FLOAT
            ,[ServiceLevelTarget]                FLOAT
            ,[WaitTime]                          FLOAT
            ,[HoldTime]                          FLOAT
            ,[TalkTime]                          FLOAT
            ,[WrapUpTime]                        FLOAT
            ,[TargetHandleTime]                  FLOAT
            ,[InteractionsAbandoned]             FLOAT
            ,[QAFatalError]                      FLOAT
            ,[TargetSchedule]                    FLOAT
            ,[ActualSchedule]                    FLOAT
            ,[VolumeForecastClientTarget]        VARCHAR(100)
            ,[VolumeForecastClientActual]        VARCHAR(100)
            ,[TimeStamp]                         DATETIME        
    
    );

    
        -- Carga de archivo a tabla temporal de crudo
        EXEC(
            'BULK INSERT [dbo].[#tmpImportOpsMetricsVodafone] from ''' + @fnr + '''
                WITH (
                    FIRSTROW = 2,
                    CODEPAGE = ''65001'',
                    DATAFILETYPE = ''char'',
                    FIELDTERMINATOR ='+'''\;'''+',
                    ROWTERMINATOR ='+'''\n'''+',
                    KEEPNULLS,
                    BATCHSIZE=1000
                )'
        );

        
        /* ============ Bloque de Eliminacion de Datos no Utiles =========== */
        DELETE FROM [#tmpImportOpsMetricsVodafone] WHERE [lobId] IS NULL AND [yyyy] IS NULL AND [mm] IS NULL;
        

        /* ========== Bloque de Limpieza de Datos Repetidos de Tabla Temporal ======== */
        
        WITH CTE AS (
            SELECT
                ROW_NUMBER() OVER (
                    PARTITION BY [lobId], [yyyy], [mm]
                    ORDER BY [lobId]
                ) AS Rk
                FROM #tmpImportOpsMetricsVodafone
        ) DELETE FROM CTE
            WHERE Rk > 1; 
     
        /* ===================== Ejecucion SP Calidad ====================== */

        /* == Bloque de Importacion de Datos de Tabla Temporal a Tabla QA == */
        INSERT INTO [dbo].[#tmpImportOpsMetricsVodafoneQA] (
            [lobId]                              
            ,[yyyy]                              
            ,[mm]                                
            ,[CommittedFTE]                      
            ,[ExplanationCommentaryFTEVariance]  
            ,[FunctionalWorkstations]            
            ,[ProductionHours]                   
            ,[Contacts]                          
            ,[Completes]                         
            ,[FirstCallResolved]                 
            ,[TotalCustomerIssues]               
            ,[FirstCallResolutionTarget]         
            ,[BilledHours]                       
            ,[PaidHours]                         
            ,[TotalInteractionsOffered]          
            ,[TotalInteractionsAnswered]         
            ,[ServiceLevelTarget]                
            ,[WaitTime]                          
            ,[HoldTime]                          
            ,[TalkTime]                          
            ,[WrapUpTime]                        
            ,[TargetHandleTime]                  
            ,[InteractionsAbandoned]             
            ,[QAFatalError]                      
            ,[TargetSchedule]                    
            ,[ActualSchedule]                    
            ,[VolumeForecastClientTarget]        
            ,[VolumeForecastClientActual]
            ,[TimeStamp]  
        
        )
    
        SELECT

            CAST([lobId] AS INT)                         AS [lobId]
            ,CAST([yyyy] AS INT)                         AS [yyyy]
            ,CAST([mm] AS INT)                           AS [mm]
            ,[CommittedFTE]                      
            ,[ExplanationCommentaryFTEVariance]  
            ,[FunctionalWorkstations]            
            ,[ProductionHours]
            ,CAST([Contacts]  AS FLOAT)                  AS [Contacts]
            ,CAST([Completes] AS FLOAT)                  AS [Completes]
            ,CAST([FirstCallResolved]   AS FLOAT)        AS [FirstCallResolved]
            ,CAST([TotalCustomerIssues] AS FLOAT)        AS [TotalCustomerIssues]
            ,CAST(REPLACE([FirstCallResolutionTarget],',', '.') AS FLOAT)  AS [FirstCallResolutionTarget]
            ,[BilledHours]
            ,[PaidHours]
            ,CAST([TotalInteractionsOffered] AS FLOAT)   AS [TotalInteractionsOffered]       
            ,CAST([TotalInteractionsAnswered]  AS FLOAT) AS [TotalInteractionsAnswered]       
            ,CAST([ServiceLevelTarget] AS FLOAT)         AS [ServiceLevelTarget]       
            ,CAST([WaitTime] AS FLOAT)                   AS [WaitTime]       
            ,CAST([HoldTime] AS FLOAT)                   AS [HoldTime]       
            ,CAST([TalkTime] AS FLOAT)                   AS [TalkTime]       
            ,CAST([WrapUpTime]   AS FLOAT)               AS [WrapUpTime]       
            ,CAST([TargetHandleTime]  AS FLOAT)          AS [TargetHandleTime]       
            ,CAST([InteractionsAbandoned] AS FLOAT)      AS [InteractionsAbandoned]       
            ,CAST([QAFatalError] AS FLOAT)               AS [QAFatalError]       
            ,CAST(REPLACE([TargetSchedule], ',', '.') AS FLOAT)             AS [TargetSchedule]       
            ,CAST([ActualSchedule] AS FLOAT)             AS [ActualSchedule]       
            ,[VolumeForecastClientTarget]
            ,REPLACE([VolumeForecastClientActual], ';', '') AS [VolumeForecastClientActual]
            ,GETDATE()
        
        FROM [dbo].[#tmpImportOpsMetricsVodafone];

        UPDATE [#tmpImportOpsMetricsVodafoneQA]
        SET VolumeForecastClientActual = NULL
        WHERE TRIM([VolumeForecastClientActual]) = ''


       
        /* ========= Insercion de Tabla Temporal QA a Tabla Fisica Usando Merge========= */
        MERGE [dbo].[tbImportOpsMetricsVodafone] AS tgt
        USING [dbo].[#tmpImportOpsMetricsVodafoneQA] AS src
        ON (
            tgt.[lobId]     = src.[lobId] AND    
            tgt.[yyyy]      = src.[yyyy] AND
            tgt.[mm]        = src.[mm] 
                 
        ) WHEN MATCHED THEN
            UPDATE SET
            
            [lobId]                             = src.[lobId]                            
            ,[yyyy]                                 = src.[yyyy]                                    
            ,[mm]                                   = src.[mm]                                     
            ,[CommittedFTE]                         = src.[CommittedFTE]                           
            ,[ExplanationCommentaryFTEVariance]     = src.[ExplanationCommentaryFTEVariance]       
            ,[FunctionalWorkstations]               = src.[FunctionalWorkstations]                 
            ,[ProductionHours]                      = src.[ProductionHours]                     
            ,[Contacts]                             = src.[Contacts]                               
            ,[Completes]                            = src.[Completes]                           
            ,[FirstCallResolved]                    = src.[FirstCallResolved]                   
            ,[TotalCustomerIssues]                  = src.[TotalCustomerIssues]                    
            ,[FirstCallResolutionTarget]            = src.[FirstCallResolutionTarget]           
            ,[BilledHours]                          = src.[BilledHours]                         
            ,[PaidHours]                            = src.[PaidHours]                           
            ,[TotalInteractionsOffered]             = src.[TotalInteractionsOffered]            
            ,[TotalInteractionsAnswered]            = src.[TotalInteractionsAnswered]           
            ,[ServiceLevelTarget]                   = src.[ServiceLevelTarget]                  
            ,[WaitTime]                             = src.[WaitTime]                            
            ,[HoldTime]                             = src.[HoldTime]                            
            ,[TalkTime]                             = src.[TalkTime]                            
            ,[WrapUpTime]                           = src.[WrapUpTime]                          
            ,[TargetHandleTime]                     = src.[TargetHandleTime]                    
            ,[InteractionsAbandoned]                = src.[InteractionsAbandoned]               
            ,[QAFatalError]                         = src.[QAFatalError]                        
            ,[TargetSchedule]                       = src.[TargetSchedule]                      
            ,[ActualSchedule]                       = src.[ActualSchedule]                      
            ,[VolumeForecastClientTarget]           = src.[VolumeForecastClientTarget]          
            ,[VolumeForecastClientActual]           = src.[VolumeForecastClientActual]      
            ,[TimeStamp]                            = src.[TimeStamp]

        WHEN NOT MATCHED THEN
            INSERT (
            [lobId]                         
            ,[yyyy]                             
            ,[mm]                               
            ,[CommittedFTE]                     
            ,[ExplanationCommentaryFTEVariance] 
            ,[FunctionalWorkstations]           
            ,[ProductionHours]                  
            ,[Contacts]                         
            ,[Completes]                        
            ,[FirstCallResolved]                
            ,[TotalCustomerIssues]              
            ,[FirstCallResolutionTarget]        
            ,[BilledHours]                      
            ,[PaidHours]                        
            ,[TotalInteractionsOffered]         
            ,[TotalInteractionsAnswered]        
            ,[ServiceLevelTarget]               
            ,[WaitTime]                         
            ,[HoldTime]                         
            ,[TalkTime]                         
            ,[WrapUpTime]                       
            ,[TargetHandleTime]                 
            ,[InteractionsAbandoned]            
            ,[QAFatalError]                     
            ,[TargetSchedule]                   
            ,[ActualSchedule]                   
            ,[VolumeForecastClientTarget]       
            ,[VolumeForecastClientActual]       
            ,[TimeStamp]                        

            ) VALUES (
                
            src.[lobId]                            
            ,src.[yyyy]                            
            ,src.[mm]                              
            ,src.[CommittedFTE]                    
            ,src.[ExplanationCommentaryFTEVariance]
            ,src.[FunctionalWorkstations]          
            ,src.[ProductionHours]                 
            ,src.[Contacts]                        
            ,src.[Completes]                       
            ,src.[FirstCallResolved]               
            ,src.[TotalCustomerIssues]             
            ,src.[FirstCallResolutionTarget]       
            ,src.[BilledHours]                     
            ,src.[PaidHours]                       
            ,src.[TotalInteractionsOffered]        
            ,src.[TotalInteractionsAnswered]       
            ,src.[ServiceLevelTarget]              
            ,src.[WaitTime]                        
            ,src.[HoldTime]                        
            ,src.[TalkTime]                        
            ,src.[WrapUpTime]                      
            ,src.[TargetHandleTime]                
            ,src.[InteractionsAbandoned]           
            ,src.[QAFatalError]                    
            ,src.[TargetSchedule]                  
            ,src.[ActualSchedule]                  
            ,src.[VolumeForecastClientTarget]      
            ,src.[VolumeForecastClientActual]       
            ,src.[TimeStamp]                        
            );

        -- Truncado de tablas temporales
        TRUNCATE TABLE [dbo].[#tmpImportOpsMetricsVodafone];
        TRUNCATE TABLE [dbo].[#tmpImportOpsMetricsVodafoneQA];

        --Se disminuye el número de archivos pendientes en 1
        
    END TRY
    /* ========================== Manejo de Errores ============================ */
    BEGIN CATCH 
        SET @error = 1;
        PRINT error_message();
        SET @severity=1;
    END CATCH

    DECLARE @Renombre VARCHAR(2000);
    DECLARE @Rutanueva VARCHAR(2000);

    IF @error = 0 
        BEGIN 
        --============================Renombra el archivo============================
            SET @Renombre = FORMAT(getdate(),N'yyyyMMddHHmmss') + '_' + @File; 
            SET @returnValue = [TOOLBOX].[dbo].[Rename](@OuPath+@File,@File,@Renombre); 

        --============================Mover Archivo================================
            SET @Rutanueva = @OuPath + 'Procesados\';
            EXEC [TOOLBOX].[dbo].[spMoveFiles] @sourcePath = @OuPath
                                                        ,@targetPath = @RutaNueva
                                                        ,@fileName = @Renombre;

        --===========================Comprime el archivo===========================
            SET @returnValue = [TOOLBOX].[dbo].[ZipFiles](@Rutanueva,@Renombre);
        END 
    ELSE 
        BEGIN 
        --============================Renombra el archivo============================
            SET @Renombre = FORMAT(getdate(),N'yyyyMMddHHmmss') + '_' + @File; 
            SET @returnValue = [TOOLBOX].[dbo].[Rename](@OuPath+@File,@File,@Renombre); 

        --============================Mover Archivo================================
            SET @Rutanueva = @OuPath + 'Error\';
            EXEC [TOOLBOX].[dbo].[spMoveFiles] @sourcePath = @OuPath
                                                        ,@targetPath = @RutaNueva
                                                        ,@fileName = @Renombre;

        --===========================Comprime el archivo===========================
            SET @returnValue = [TOOLBOX].[dbo].[ZipFiles](@Rutanueva,@Renombre);
            SET @error=0;
        END     

    IF @severity = 1
    BEGIN
        RAISERROR('Error en bloque TRY', 16, 1);
    END;

    /* ============== Bloque de eliminacion de tablas temporales =============== */
    DROP TABLE IF EXISTS [dbo].[#ImportOpsMetricsVodafone];
    DROP TABLE IF EXISTS [dbo].[#tmpImportOpsMetricsVodafoneQA];
    SET @i -= 1
    END
GO