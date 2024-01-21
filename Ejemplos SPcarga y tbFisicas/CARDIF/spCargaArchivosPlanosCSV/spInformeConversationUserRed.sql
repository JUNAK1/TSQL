USE [Cardif]
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
User_NT: E_1233495216
Fecha: 9/22/2023  
Descripcion: Sp que extrae la información de un archivo .csv en la ruta \\TPCCP-DB20\Dropbox\Panamericano\Cardif\CortesAutoImport\InformeConversationsUserRed
y la inserta en la tabla [dbo].[tbInformeConversationsUserRed]

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
Carga la información del crudo sobre la tabla [dbo].[tbInformeConversationsUserRed]

<Ejemplo>
EXEC [dbo].[spInformeConversationUserRed]

 ];
*/

CREATE PROCEDURE [dbo].[spInformeConversationUserRed]
AS
SET NOCOUNT ON;
	
	BEGIN
	/*=======================Bloque para cargar el nombre de los archivos=========================*/
		IF OBJECT_ID('tempdb..#OuFiles') IS NOT NULL DROP TABLE #OuFiles;
		CREATE TABLE #OuFiles(a INT IDENTITY(1,1), s VARCHAR(1000));

		DECLARE @ruta VARCHAR(8000) = '\\TPCCP-DB20\Dropbox\Panamericano\Cardif\CortesAutoImport\InformeConversationsUserRed\';
            
		DECLARE @return_value INT=0;

		INSERT INTO #OuFiles
		SELECT REPLACE(Dir,@Ruta,'') FROM [TOOLBOX].[dbo].[GetFiles](@Ruta,'*.csv');

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
		/*============Bloque de definicion de temporales==============*/
		IF OBJECT_ID('tempdb..#tmpInformeConversationsUserRed') IS NOT NULL DROP TABLE #tmpInformeConversationsUserRed;
		CREATE TABLE #tmpInformeConversationsUserRed 
		(	 
			  [NombreConversations]		VARCHAR(100)
			 ,[NombreTP]	  VARCHAR(100)
			 ,[UsuarioRed]	  VARCHAR(50)

		);
	END;

	--Ciclo while para procesar todos archivos en una sola ejecución
	WHILE @i > 0 AND (SELECT TOP 1 S FROM #OuFiles) <> 'File Not Found'
	BEGIN
		BEGIN TRY	
			SET @file = (SELECT s FROM #OuFiles WHERE a = @i);
			SET @fnr = @Ruta + @file;
		
			SET ARITHABORT ON;
			EXEC('BULK INSERT #tmpInformeConversationsUserRed FROM ''' + @fnr + ''' WITH (DATAFILETYPE = ''char'',
			FIRSTROW = 2, FIELDTERMINATOR = '';'',ROWTERMINATOR = ''0x0A'',CODEPAGE = ''65001'' ,FORMAT = ''CSV'')');
			
			
			
			BEGIN 

			/*======Bloque de calidad o limpieza====*/



				--Sección de transofrmación de caracteres especiales

				UPDATE #tmpInformeConversationsUserRed
				SET [NombreConversations] = TRANSLATE([NombreConversations], 'áéíóúÁÉÍÓÚ', 'aeiouAEIOU');
				UPDATE #tmpInformeConversationsUserRed
				SET [NombreTP] = TRANSLATE([NombreTP], 'áéíóúÁÉÍÓÚ', 'aeiouAEIOU');

				UPDATE #tmpInformeConversationsUserRed
				SET NombreConversations = REPLACE(NombreConversations, N'ñ', 'ni');
				UPDATE #tmpInformeConversationsUserRed
				SET NombreConversations = REPLACE(NombreConversations, N'Ñ', 'NI');

				UPDATE #tmpInformeConversationsUserRed
				SET NombreTP = REPLACE(NombreTP, N'ñ', 'ni');
				UPDATE #tmpInformeConversationsUserRed
				SET NombreTP = REPLACE(NombreTP, N'Ñ', 'NI');


				
				IF OBJECT_ID('tempdb..#tmpInformeConversationsUserRedQA') IS NOT NULL DROP TABLE #tmpInformeConversationsUserRedQA;
				CREATE TABLE #tmpInformeConversationsUserRedQA
				(
					  [NombreConversations]			VARCHAR(100)
					 ,[NombreTP]					VARCHAR(100)
					 ,[UsuarioRed]					VARCHAR(50)
					 ,[LastUpdateDate]				DATETIME

				);

				INSERT INTO #tmpInformeConversationsUserRedQA
				SELECT 
					  [NombreConversations]
					 ,[NombreTP]	
					 ,[UsuarioRed]
					 ,GETDATE()			                            		   
				FROM #tmpInformeConversationsUserRed;
			END;	
		
			/*BEGIN ---------- SP CALIDAD -------------
				EXEC [Architecture].[dqa].[SpQAStatictisImportValidator] 'Capacitation','#tmpDatosNominalesPrevios1010083873Ejercicio2QA'
				,'tbDatosNominalesPrevios1010083873Ejercicio2','spDatosNominalesPrevios1010083873Ejercicio2';
			END;*/

			BEGIN ---------- Llave Borrado -------------

				WITH CTE AS
				(
					SELECT ROW_NUMBER() OVER (
						PARTITION BY [NombreConversations],[NombreTP],[UsuarioRed] 
						order by [NombreConversations],[NombreTP],[UsuarioRed] DESC
					) Rk  
					FROM #tmpInformeConversationsUserRedQA
				)
				DELETE FROM CTE WHERE Rk > 1;

				--control de registros duplicados en la tabla fisica e inserción en la tabla fisica
				
				MERGE [dbo].[tbInformeConversationsUserRed] AS [tgt]
				USING
				(
					  SELECT
						  [NombreConversations]
						 ,[NombreTP]	
						 ,[UsuarioRed]		       
						 ,[LastUpdateDate]                    
              
					FROM #tmpInformeConversationsUserRedQA

				) AS [src]
				ON
				(
					[src].[NombreConversations] = [tgt].[NombreConversations] AND [src].[NombreTP] = [tgt].[NombreTP] AND  [src].[UsuarioRed] = [tgt].[UsuarioRed]
				)
				-- For updates
				WHEN MATCHED THEN
				  UPDATE 
					  SET
						 --                              =[src].
						 [tgt].[NombreConversations]      = [src].[NombreConversations]                          
						,[tgt].[NombreTP]                 = [src].[NombreTP]                                          
						,[tgt].[UsuarioRed]               = [src].[UsuarioRed]                       
						,[tgt].[LastUpdateDate]           = [src].[LastUpdateDate]                              

				 --For Inserts
				WHEN NOT MATCHED THEN
					INSERT
					--Valores tgt
					(
						[NombreConversations]                           
						,[NombreTP]                                           
						,[UsuarioRed]                        
						,[LastUpdateDate]                      
					)
					VALUES
					(
						 [src].[NombreConversations]                           
						,[src].[NombreTP]                                           
						,[src].[UsuarioRed]                        
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
		
		TRUNCATE TABLE #tmpInformeConversationsUserRed;
		TRUNCATE TABLE #tmpInformeConversationsUserRedQA;

		--Se disminuye el número de archivos pendientes en 1
		SET @i = @i - 1;

	--Fin del ciclo

	END

	IF OBJECT_ID('tempdb..#OuFiles') IS NOT NULL DROP TABLE #OuFiles;
	IF OBJECT_ID('tempdb..#tmpInformeConversationsUserRed') IS NOT NULL DROP TABLE #tmpInformeConversationsUserRed;
	IF OBJECT_ID('tempdb..#tmpInformeConversationsUserRedQA') IS NOT NULL DROP TABLE #tmpInformeConversationsUserRedQA;
	
	IF @Severity = 1
	BEGIN
		RAISERROR('Error en Bloque Try',16,1);
	END

--Fin del procedimiento almacenado


EXEC [dbo].[spInformeConversationUserRed]





