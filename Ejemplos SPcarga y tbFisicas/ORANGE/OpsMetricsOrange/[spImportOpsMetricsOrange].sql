USE [Orange]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Crear un importador de la ruta \\TPCCP-DB20\Dropbox\Panamericano\Cardif\CortesAutoImport\InformeConversationsUserRed 

*/


/* ---------------------------
<Información Creación>
User_NT: E_1053871829, E_1010083873, E_1019137609
Fecha: 2023-10-06  
Descripcion: [spImportOpsMetricsOrange] que extrae la información de un archivo .csv en la ruta \\TPCCP-DB20\Dropbox\OffShore\Orange\Opsmetrics\
y la inserta en la tabla [dbo].[tbImportDataOpsMetricsOrange]

<Update> 
User_NT:    
Fecha:      
SD:     
Descrip:    
------------------------------*/

/* ---------------------------
<Descripción>
Transformacion y carga de los datos del crudo 

<Tipo_SP>
Importación

<Área> 
Pipeline

<Parámetros>
    
<Tipo_Resultado>
MERGE

<Resultado>
Carga la información del crudo sobre la tabla [dbo].[tbImportDataOpsMetricsOrange]

<Ejemplo>
EXEC [dbo].[spImportOpsMetricsOrange]

 ];
*/

ALTER PROCEDURE [dbo].[spImportOpsMetricsOrange]
AS
SET NOCOUNT ON;
    
    BEGIN
    /*=======================Bloque para cargar el nombre de los archivos=========================*/
        IF OBJECT_ID('tempdb..#OuFilesImportOrange') IS NOT NULL DROP TABLE #OuFilesImportOrange;
        CREATE TABLE #OuFilesImportOrange(a INT IDENTITY(1,1), s VARCHAR(1000));

        DECLARE @ruta VARCHAR(8000) = '\\TPCCP-DB20\Dropbox\OffShore\Orange\Opsmetrics\';
            
        DECLARE @return_value INT=0;

        INSERT INTO #OuFilesImportOrange
        SELECT REPLACE(Dir,@Ruta,'') FROM [TOOLBOX].[dbo].[GetFiles](@Ruta,'*.csv');

        DECLARE @i INT = (SELECT COUNT(*) FROM #OuFilesImportOrange WHERE s IS NOT NULL); 
        DECLARE @cmd VARCHAR(8000);
        DECLARE @fnr VARCHAR(350);
        DECLARE @file VARCHAR(350);
        DECLARE @error int = 0;
        DECLARE @query Varchar(8000);
        DECLARE @severity int=0;
        DECLARE @Renombre VARCHAR(1000);
        DECLARE @Rutanueva VARCHAR(1000);
    END;



    BEGIN
        /*============Bloque de definicion de temporales==============*/
        IF OBJECT_ID('tempdb..#tmpImportDataOpsMetricsOrange') IS NOT NULL DROP TABLE #tmpImportDataOpsMetricsOrange;
        CREATE TABLE #tmpImportDataOpsMetricsOrange 
        (    
            [Mercado]                       VARCHAR(50)
            ,[lobId]                        VARCHAR(50)
            ,[yyyy]                         VARCHAR(50)
            ,[mm]                           VARCHAR(30)
            ,[CommittedFTE]                 VARCHAR(100)
            ,[FunctionalWorkstations]       VARCHAR(100)
            ,[ProductionHours]              VARCHAR(100)
            ,[Contacts]                     VARCHAR(100)
            ,[Completes]                    VARCHAR(100)
            ,[FirstCallResolved]            VARCHAR(50)
            ,[TotalCustomerIssues]          VARCHAR(50)
            ,[FirstCallResolutionTarget]    VARCHAR(50)
            ,[BilledHours]                  VARCHAR(100)
            ,[PaidHours]                    VARCHAR(100)
            ,[TotalInteractionsOffered]     VARCHAR(100)
            ,[TotalInteractionsAnswered]    VARCHAR(100)
            ,[ServiceLevelTarget]           VARCHAR(100)
            ,[WaitTime]                     VARCHAR(100)
            ,[HoldTime]                     VARCHAR(100)
            ,[TalkTime]                     VARCHAR(100)
            ,[WrapUpTime]                   VARCHAR(100)
            ,[TargetHandleTime]             VARCHAR(100)
            ,[InteractionsAbandoned]        VARCHAR(100)
            ,[QAFatalError]                 VARCHAR(50)
            ,[TargetSchedule]               VARCHAR(100)
            ,[ActualSchedule]               VARCHAR(100)
            ,[VolumeForecastClientTarget]   VARCHAR(100)
            ,[VolumeForecastClientActual]   VARCHAR(100)
        );
    END;

    --Ciclo while para procesar todos archivos en una sola ejecución
    WHILE @i > 0 AND (SELECT TOP 1 S FROM #OuFilesImportOrange) <> 'File Not Found'
    BEGIN
        BEGIN TRY   
            SET @file = (SELECT s FROM #OuFilesImportOrange WHERE a = @i);
            SET @fnr = @Ruta + @file;
        
            SET ARITHABORT ON;
            EXEC('BULK INSERT #tmpImportDataOpsMetricsOrange FROM ''' + @fnr + ''' WITH (DATAFILETYPE = ''char'',
            FIRSTROW = 2, FIELDTERMINATOR = '';'',ROWTERMINATOR = ''\n'',CODEPAGE = ''65001'' ,FORMAT = ''CSV'')');
            
            
            
        BEGIN 
            /*======Bloque de Limpieza de Datos ====*/



				DELETE FROM #tmpImportDataOpsMetricsOrange 
				WHERE Mercado IS NULL AND yyyy IS NULL and mm IS NULL;


                UPDATE #tmpImportDataOpsMetricsOrange
                SET [FirstCallResolutionTarget] = REPLACE([FirstCallResolutionTarget], N',', '.');

                UPDATE #tmpImportDataOpsMetricsOrange
                SET [ServiceLevelTarget] = REPLACE([ServiceLevelTarget], N',', '.');
                


            /*======Bloque de calidad ====*/
                    
            IF OBJECT_ID('tempdb..#tmpImportDataOpsMetricsOrangeQA') IS NOT NULL DROP TABLE #tmpImportDataOpsMetricsOrangeQA;
            CREATE TABLE #tmpImportDataOpsMetricsOrangeQA
            (

                [Mercado]                       VARCHAR(100)
                ,[LobId]                        INT
                ,[yyyy]                         INT 
                ,[mm]                           INT
                ,[CommittedFTE]                 VARCHAR(100)
                ,[FunctionalWorkstations]       VARCHAR(100)
                ,[ProductionHours]              VARCHAR(100)
                ,[Contacts]                     VARCHAR(100)
                ,[Completes]                    VARCHAR(100)
                ,[FirstCallResolved]            INT
                ,[TotalCustomerIssues]          INT
                ,[FirstCallResolutionTarget]    FLOAT
                ,[BilledHours]                  VARCHAR(100)
                ,[PaidHours]                    VARCHAR(100)
                ,[TotalInteractionsOffered]     VARCHAR(100)
                ,[TotalInteractionsAnswered]    VARCHAR(100)
                ,[ServiceLevelTarget]           FLOAT
                ,[WaitTime]                     VARCHAR(100)
                ,[HoldTime]                     VARCHAR(100)
                ,[TalkTime]                     VARCHAR(100)
                ,[WrapUpTime]                   VARCHAR(100)
                ,[TargetHandleTime]             VARCHAR(100)
                ,[InteractionsAbandoned]        VARCHAR(100)
                ,[QAFatalError]                 INT
                ,[TargetSchedule]               VARCHAR(100)
                ,[ActualSchedule]               VARCHAR(100)
                ,[VolumeForecastClientTarget]   VARCHAR(100)
                ,[VolumeForecastClientActual]   VARCHAR(100)
                ,[LastUpdateDate]               DATETIME

            );
            INSERT INTO #tmpImportDataOpsMetricsOrangeQA
            SELECT 
                    [Mercado]                       
                    ,CAST([lobId] AS INT)                       
                    ,CAST([yyyy] AS INT)                            
                    ,CAST([mm] AS INT)                          
                    ,[CommittedFTE]                 
                    ,[FunctionalWorkstations]       
                    ,[ProductionHours]              
                    ,[Contacts]                     
                    ,[Completes]                    
                    ,CAST([FirstCallResolved] AS INT)       
                    ,CAST([TotalCustomerIssues] AS INT) 
                    ,CAST([FirstCallResolutionTarget] AS FLOAT) 
                    ,[BilledHours]          
                    ,[PaidHours]                    
                    ,[TotalInteractionsOffered]     
                    ,[TotalInteractionsAnswered]    
                    ,CAST([ServiceLevelTarget] AS FLOAT)        
                    ,[WaitTime]                     
                    ,[HoldTime]                     
                    ,[TalkTime]                     
                    ,[WrapUpTime]                   
                    ,[TargetHandleTime]             
                    ,[InteractionsAbandoned]        
                    ,CAST([QAFatalError] AS INT)                    
                    ,[TargetSchedule]               
                    ,[ActualSchedule]               
                    ,[VolumeForecastClientTarget]   
                    ,[VolumeForecastClientActual]   
                    ,GETDATE()    
            FROM #tmpImportDataOpsMetricsOrange;
        END;    
        
            BEGIN ---------- SP CALIDAD -------------
                EXEC [Architecture].[dqa].[SpQAStatictisImportValidator] 'Orange','#tmpImportDataOpsMetricsOrangeQA'
                ,'tbImportDataOpsMetricsOrange','spImportOpsMetricsOrange';
            END;

            BEGIN ---------- Llave Borrado -------------

                WITH CTE AS
                (
                    SELECT ROW_NUMBER() OVER (
                        PARTITION BY [Mercado],[yyyy],[mm]
                        order by [Mercado],[yyyy],[mm] 
                    ) Rk  
                    FROM #tmpImportDataOpsMetricsOrangeQA
                )
                DELETE FROM CTE WHERE Rk > 1;

                --control de registros duplicados en la tabla fisica e inserción en la tabla fisica
                
                MERGE [dbo].[tbImportDataOpsMetricsOrange] AS [tgt]
                USING
                (
                      SELECT
                          [Mercado]                   
                          ,[LobId]                    
                          ,[yyyy]                     
                          ,[mm]                       
                          ,[CommittedFTE]             
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
                          ,[LastUpdateDate]    
              
                    FROM #tmpImportDataOpsMetricsOrangeQA

                ) AS [src]
                ON
                (
                    [src].[Mercado] = [tgt].[Mercado] AND [src].[yyyy] = [tgt].[yyyy] AND [src].[mm] = [tgt].[mm]
                )
                -- For updates
                WHEN MATCHED THEN
                  UPDATE 
                      SET
                         
                         [tgt].[Mercado]                    =[src].[Mercado]                                               
                        ,[tgt].[LobId]                      =[src].[LobId]                                                     
                        ,[tgt].[yyyy]                       =[src].[yyyy]                                     
                        ,[tgt].[mm]                         =[src].[mm]                          
                        ,[tgt].[CommittedFTE]               =[src].[CommittedFTE]             
                        ,[tgt].[FunctionalWorkstations]     =[src].[FunctionalWorkstations]   
                        ,[tgt].[ProductionHours]            =[src].[ProductionHours]          
                        ,[tgt].[Contacts]                   =[src].[Contacts]                 
                        ,[tgt].[Completes]                  =[src].[Completes]                
                        ,[tgt].[FirstCallResolved]          =[src].[FirstCallResolved]        
                        ,[tgt].[TotalCustomerIssues]        =[src].[TotalCustomerIssues]      
                        ,[tgt].[FirstCallResolutionTarget]  =[src].[FirstCallResolutionTarget]
                        ,[tgt].[BilledHours]                =[src].[BilledHours]              
                        ,[tgt].[PaidHours]                  =[src].[PaidHours]                
                        ,[tgt].[TotalInteractionsOffered]   =[src].[TotalInteractionsOffered] 
                        ,[tgt].[TotalInteractionsAnswered]  =[src].[TotalInteractionsAnswered]
                        ,[tgt].[ServiceLevelTarget]         =[src].[ServiceLevelTarget]       
                        ,[tgt].[WaitTime]                   =[src].[WaitTime]                 
                        ,[tgt].[HoldTime]                   =[src].[HoldTime]                 
                        ,[tgt].[TalkTime]                   =[src].[TalkTime]                 
                        ,[tgt].[WrapUpTime]                 =[src].[WrapUpTime]               
                        ,[tgt].[TargetHandleTime]           =[src].[TargetHandleTime]         
                        ,[tgt].[InteractionsAbandoned]      =[src].[InteractionsAbandoned]    
                        ,[tgt].[QAFatalError]               =[src].[QAFatalError]             
                        ,[tgt].[TargetSchedule]             =[src].[TargetSchedule]           
                        ,[tgt].[ActualSchedule]             =[src].[ActualSchedule]           
                        ,[tgt].[VolumeForecastClientTarget] =[src].[VolumeForecastClientTarget]
                        ,[tgt].[VolumeForecastClientActual] =[src].[VolumeForecastClientActual]
                        ,[tgt].[LastUpdateDate]             =[src].[LastUpdateDate]         

                 --For Inserts
                WHEN NOT MATCHED THEN
                    INSERT
                    --Valores tgt
                    (
                        [Mercado]                  
                        ,[LobId]                    
                        ,[yyyy]                     
                        ,[mm]                       
                        ,[CommittedFTE]             
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
                        ,[LastUpdateDate]
            
                    )
                    VALUES
                    (
                         [src].[Mercado]                                             
                        ,[src].[LobId]                                                    
                        ,[src].[yyyy]                                    
                        ,[src].[mm]                        
                        ,[src].[CommittedFTE]             
                        ,[src].[FunctionalWorkstations]   
                        ,[src].[ProductionHours]          
                        ,[src].[Contacts]                 
                        ,[src].[Completes]                
                        ,[src].[FirstCallResolved]        
                        ,[src].[TotalCustomerIssues]      
                        ,[src].[FirstCallResolutionTarget]
                        ,[src].[BilledHours]              
                        ,[src].[PaidHours]                
                        ,[src].[TotalInteractionsOffered] 
                        ,[src].[TotalInteractionsAnswered]
                        ,[src].[ServiceLevelTarget]       
                        ,[src].[WaitTime]                 
                        ,[src].[HoldTime]                 
                        ,[src].[TalkTime]                 
                        ,[src].[WrapUpTime]               
                        ,[src].[TargetHandleTime]         
                        ,[src].[InteractionsAbandoned]    
                        ,[src].[QAFatalError]             
                        ,[src].[TargetSchedule]           
                        ,[src].[ActualSchedule]           
                        ,[src].[VolumeForecastClientTarget]
                        ,[src].[VolumeForecastClientActual]
                        ,[src].[LastUpdateDate]  

                    );

            END;
        
        END TRY

        BEGIN CATCH
            SET @error = 1;
            SET @severity = 0;
            PRINT ERROR_MESSAGE();
        END CATCH

        /*=======================Manejo de Errores=========================*/


        IF @error = 0 
        BEGIN 
        --============================Renombra el archivo============================
            SET @Renombre = FORMAT(getdate(),N'yyyyMMddHHmmss') + '_' + @File; 
            SET @return_value = [TOOLBOX].[dbo].[Rename](@Ruta+@File,@File,@Renombre);  

        --============================Mover Archivo================================
            SET @Rutanueva = @Ruta + 'Procesados\';
            EXEC [TOOLBOX].[dbo].[spMoveFiles] @sourcePath = @Ruta
                                                        ,@targetPath = @RutaNueva
                                                        ,@fileName = @Renombre;

        --===========================Comprime el archivo===========================
            SET @return_value = [TOOLBOX].[dbo].[ZipFiles](@Rutanueva,@Renombre);
        END 

        ELSE 
        BEGIN 
        --============================Renombra el archivo============================
            SET @Renombre = FORMAT(getdate(),N'yyyyMMddHHmmss') + '_' + @File; 
            SET @return_value = [TOOLBOX].[dbo].[Rename](@Ruta+@File,@File,@Renombre);  

        --============================Mover Archivo================================
            SET @Rutanueva = @Ruta + 'Error\';
            EXEC [TOOLBOX].[dbo].[spMoveFiles] @sourcePath = @Ruta
                                                        ,@targetPath = @RutaNueva
                                                        ,@fileName = @Renombre;

        --===========================Comprime el archivo===========================
            SET @return_value = [TOOLBOX].[dbo].[ZipFiles](@Rutanueva,@Renombre);
            SET @error = 0;

        END;    
        
        TRUNCATE TABLE #tmpImportDataOpsMetricsOrange;
        TRUNCATE TABLE #tmpImportDataOpsMetricsOrangeQA;

        --Se disminuye el número de archivos pendientes en 1
        SET @i = @i - 1;

    --Fin del ciclo

    END

    IF OBJECT_ID('tempdb..#OuFilesImportOrange') IS NOT NULL DROP TABLE #OuFilesImportOrange;
    IF OBJECT_ID('tempdb..#tmpImportDataOpsMetricsOrange') IS NOT NULL DROP TABLE #tmpImportDataOpsMetricsOrange;
    IF OBJECT_ID('tempdb..#tmpImportDataOpsMetricsOrangeQA') IS NOT NULL DROP TABLE #tmpImportDataOpsMetricsOrangeQA;
    
    IF @Severity = 1
    BEGIN
        RAISERROR('Error en Bloque Try',16,1);
    END

--Fin del procedimiento almacenado

