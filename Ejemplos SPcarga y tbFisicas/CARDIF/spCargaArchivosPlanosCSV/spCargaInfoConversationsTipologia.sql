USE [Cardif]
GO
/* 
*/

/* ---------------------------
<Información Creación>
User_NT:E_1143864762 
Fecha:2023-09-14
Descripcion: Se carga informacio del crudo Informe Conversations Tipologia.csv hacia la tabla fisica 
[dbo].[tbInformeConversationsTipologia] aplicando la respectiva limpieza y manejo de duplicados
------------------------------*/

/* ---------------------------
<Descripción>

<Tipo_SP>
Transformacion Y carga de archivo plano (csv)

<Área> 
Pipeline

<Parámetros>
    
<Tipo_Resultado>
Insercion a tabla fisica

<Resultado>
Carga la información del crudo sobre la tabla [dbo].[tbInformeConversationsTipologia].

<Ejemplo>
EXEC [dbo].[spCargaInfoConversationsTipologia]
*/

ALTER PROCEDURE [dbo].[spCargaInfoConversationsTipologia]
AS
SET NOCOUNT ON;
    
    BEGIN
        IF OBJECT_ID('tempdb..#OuFiles') IS NOT NULL DROP TABLE #OuFiles;
        CREATE TABLE #OuFiles(a INT IDENTITY(1,1), s VARCHAR(1000));
        DECLARE @ruta VARCHAR(8000) = '\\TPCCP-DB20\Dropbox\Panamericano\Cardif\CortesAutoImport\InformeConversationsTipologia\';
            
        DECLARE @return_value INT=0;

        INSERT INTO #OuFiles
        SELECT REPLACE(Dir,@Ruta,'') FROM [TOOLBOX].[dbo].[GetFiles](@Ruta,'*.csv');
        --print(@Ruta)

        DECLARE @i INT = (SELECT COUNT(*) FROM #OuFiles WHERE s IS NOT NULL); 
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
    DROP TABLE IF EXISTS #tbInformeConversationsTipologia;

    -- Temporal global
    CREATE TABLE #tbInformeConversationsTipologia
    ( 
         TipologiaConversation NVARCHAR(500)
        ,Motivo                NVARCHAR(100)
    );
    END;

    --Ciclo while para procesar todos archivos en una sola ejecución
    WHILE @i > 0 AND (SELECT TOP 1 S FROM #OuFiles) <> 'File Not Found'
    BEGIN
        BEGIN TRY   
            SET @file = (SELECT s FROM #OuFiles WHERE a = @i);
            SET @fnr = @Ruta + @file;
        
            SET ARITHABORT ON;
            EXEC('BULK INSERT #tbInformeConversationsTipologia FROM ''' + @fnr + ''' WITH (DATAFILETYPE = ''char'',
            FIRSTROW = 2, FIELDTERMINATOR = '';'',ROWTERMINATOR = ''0x0A'',CODEPAGE = ''65001'' ,FORMAT = ''CSV'')');
    
            BEGIN ---------- Limpieza de Datos -----------

            --Crear temporales para limpieza (Local)
            DROP TABLE IF EXISTS #tbInformeConversationsTipologiaQA;
            CREATE TABLE #tbInformeConversationsTipologiaQA(
                 TipologiaConversation NVARCHAR(500)
                ,Motivo NVARCHAR(100)
                ,[TimeStamp] DATETIME
            );


            INSERT INTO #tbInformeConversationsTipologiaQA
            SELECT

                 TRANSLATE( TipologiaConversation, 'ÁÉÍÓÚ', 'AEIOU') AS [TipologiaConversation] 
                ,TRANSLATE( Motivo, 'ÁÉÍÓÚ', 'AEIOU')  AS [Motivo] 
                ,GETDATE() AS [TimeStamp]

            FROM #tbInformeConversationsTipologia;

            END;    
        
            --BEGIN ---------- SP CALIDAD -------------
            --    --EXEC [Architecture].[dqa].[SpQAStatictisImportValidator] 'BD','#tmpNameTBQA','NameTB','NameSP'; original
            --    --EXEC [Architecture].[dqa].[SpQAStatictisImportValidator] '','#tmpNameTBQA','NameTB','NameSP'; original
            --    EXEC [Architecture].[dqa].[SpQAStatictisImportValidator] '','#tmpNameTBQA','NameTB','NameSP';
            --END;

            BEGIN ---------- Llave Borrado -------------


                WITH InformeConversationsTipologiaQACTE AS (
                    SELECT 
                        [TipologiaConversation]
                        ,[Motivo]
                        ,ROW_NUMBER() OVER(PARTITION BY [TipologiaConversation], [Motivo]
                                                        ORDER BY [TipologiaConversation] ASC) AS duplicatedData
                    FROM #tbInformeConversationsTipologiaQA

                )
                DELETE FROM InformeConversationsTipologiaQACTE WHERE duplicatedData > 1 ;

            END;

            BEGIN ---------- Inserción a tabla fisica -----------
               
             -- Merge tabla fisica con tabla temporal QA

             MERGE [dbo].[tbInformeConversationsTipologia] AS [tgt]
                    USING
                    (
                        SELECT
                            [TipologiaConversation]
                            ,[Motivo]
                            ,[TimeStamp]
                        FROM #tbInformeConversationsTipologiaQA

                    ) AS [src]
                    ON
                    (
           
                        [src].[TipologiaConversation] = [tgt].[TipologiaConversation] AND [src].[Motivo] = [tgt].[Motivo]  
                    )
                    -- For updates
                    WHEN MATCHED THEN
                      UPDATE 
                          SET
                             --                              =[src].
                             [tgt].[TipologiaConversation]  = [src].[TipologiaConversation]                          
                            ,[tgt].[Motivo]                 = [src].[Motivo]                                          
                            ,[tgt].[TimeStamp]              = [src].[TimeStamp]                                                   

                     --For Inserts
                    WHEN NOT MATCHED THEN
                        INSERT
                        (
                            [TipologiaConversation]                           
                            ,[Motivo]                                           
                            ,[TimeStamp]                                             
    
                        )
                        VALUES
                        (
                             [src].[TipologiaConversation]                           
                            ,[src].[Motivo]                                           
                            ,[src].[TimeStamp]                        

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
        
        TRUNCATE TABLE #tbInformeConversationsTipologia;

        --Se disminuye el número de archivos pendientes en 1
        SET @i = @i - 1;

    --Fin del ciclo
    END
    IF OBJECT_ID('tempdb..#OuFiles') IS NOT NULL DROP TABLE #OuFiles;
    IF OBJECT_ID('tempdb..#tbInformeConversationsTipologia;') IS NOT NULL DROP TABLE #tbInformeConversationsTipologia;
    IF OBJECT_ID('tempdb..#tbInformeConversationsTipologiaQA') IS NOT NULL DROP TABLE #tbInformeConversationsTipologiaQA;
    
    IF @Severity = 1
    BEGIN
        RAISERROR('Error en Bloque Try',16,1);
    END