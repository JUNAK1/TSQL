USE [Iberdrola]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Crear un importador de la ruta \\TPCCP-DB20\dropbox\OffShore\Iberdrola\Ventas

*/


/* ---------------------------
<Información Creación>
User_NT: E_1053871829, E_1233493216, E_1105792917, E_1088352987, E_1012322897, E_1143864762, E_1016102870, E_1010083873
Fecha: 4/10/2023  
Descripcion: Sp que extrae la información de un archivo .csv en la ruta \\TPCCP-DB20\dropbox\OffShore\Iberdrola\Ventas
y la inserta en la tabla [dbo].[tbVentasFCST]

<Ejemplo>
EXEC [dbo].[spVentasFCST]

 ];
*/

CREATE PROCEDURE [dbo].[spVentasFCST]
AS
SET NOCOUNT ON;
	
	BEGIN
	/*=======================Bloque para cargar el nombre de los archivos=========================*/
		IF OBJECT_ID('tempdb..#OuFiles') IS NOT NULL DROP TABLE #OuFiles;
		CREATE TABLE #OuFiles(a INT IDENTITY(1,1), s VARCHAR(1000));

		DECLARE @ruta VARCHAR(8000) = '\\TPCCP-DB20\dropbox\OffShore\Iberdrola\Ventas\';
            
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
		IF OBJECT_ID('tempdb..#tmpVentasFCST') IS NOT NULL DROP TABLE #tmpVentasFCST;
		CREATE TABLE #tmpVentasFCST
		(	 
			  [Mes]					VARCHAR(10)
			  ,[Proveedor]			VARCHAR(50)
			  ,[Site]				VARCHAR(50)
			  ,[TipoSite]			VARCHAR(50)
			  ,[Campania]			VARCHAR(50)
			  ,[Fecha]				VARCHAR(50)
			  ,[DiaLaborable]		VARCHAR(50)
			  ,[HorasLogadas]		VARCHAR(50)
			  ,[HorasEfectivas]		VARCHAR(50)
			  ,[SPH]				NVARCHAR(50)
			  ,[VentasEnergia]		VARCHAR(50)
			  ,[AHT]				VARCHAR(50)

		);
	END;

	--Ciclo while para procesar todos archivos en una sola ejecución
	WHILE @i > 0 AND (SELECT TOP 1 S FROM #OuFiles) <> 'File Not Found'
	BEGIN
		BEGIN TRY	
			SET @file = (SELECT s FROM #OuFiles WHERE a = @i);
			SET @fnr = @Ruta + @file;
		
			SET ARITHABORT ON;
				EXEC('BULK INSERT #tmpVentasFCST FROM '+''''+@fnr+'''' +' 
				 WITH(FIRSTROW =2,CODEPAGE = ''ACP'',
				 FIELDTERMINATOR ='+'''\;'''+',
				 ROWTERMINATOR ='+'''\n'''+',KEEPNULLS)');
	
			
	
			BEGIN 

			/*======Bloque de calidad o limpieza====*/
			
				UPDATE #tmpVentasFCST
				SET [AHT] = TRIM(TRANSLATE([AHT], ';', ' '));

				UPDATE #tmpVentasFCST
				SET [AHT] = REPLACE([AHT], N'.', '');

				UPDATE #tmpVentasFCST
				SET [SPH] = REPLACE([SPH], N',', '.');

				UPDATE #tmpVentasFCST
				SET [AHT] = NULL
				WHERE RTRIM(LTRIM([AHT])) = '';



				
				IF OBJECT_ID('tempdb..#tmpVentasFCSTQA') IS NOT NULL DROP TABLE #tmpVentasFCSTQA;
				CREATE TABLE #tmpVentasFCSTQA
				(
					  [Mes]					VARCHAR(30)
					  ,[Proveedor]			VARCHAR(50)
					  ,[Site]				VARCHAR(50)
					  ,[TipoSite]			VARCHAR(50)
					  ,[Campania]			VARCHAR(50)
					  ,[Fecha]				DATE
					  ,[DiaLaborable]		INT
					  ,[HorasLogadas]		INT
					  ,[HorasEfectivas]		INT
					  ,[SPH]				FLOAT
					  ,[VentasEnergia]		INT
					  ,[AHT]				INT
					  ,[LastUpdateDate]		DATE

						);


				INSERT INTO #tmpVentasFCSTQA
				SELECT 
					   [Mes]			
					  ,[Proveedor]		
					  ,[Site]			
					  ,[TipoSite]		
					  ,[Campania]		
					  ,CONVERT(DATE,[Fecha],103)			
					  ,CAST([DiaLaborable] AS INT)	
					  ,CAST([HorasLogadas] AS INT)	
					  ,CAST([HorasEfectivas] AS INT)	
					  ,CAST([SPH]AS FLOAT) 		
					  ,CAST([VentasEnergia] AS INT)	
					  ,CAST([AHT] AS INT)			
					  ,GETDATE()			                            		   
				FROM #tmpVentasFCST;
			END;	
		


			BEGIN ---------- Llave Borrado -------------

				WITH CTE AS
				(
					SELECT ROW_NUMBER() OVER (
						PARTITION BY [Fecha]
						order by [Fecha] DESC
					) Rk  
					FROM #tmpVentasFCSTQA
				)
				DELETE FROM CTE WHERE Rk > 1;

				--control de registros duplicados en la tabla fisica e inserción en la tabla fisica
				
				MERGE [dbo].[tbVentasFCST] AS [tgt]
				USING
				(
					  SELECT
							 [Mes]				
							,[Proveedor]		
							,[Site]			
							,[TipoSite]		
							,[Campania]		
							,[Fecha]			
							,[DiaLaborable]	
							,[HorasLogadas]	
							,[HorasEfectivas]	
							,[SPH]			
							,[VentasEnergia]	
							,[AHT]			
							,[LastUpdateDate]	
					FROM #tmpVentasFCSTQA

				) AS [src]
				ON
				(
					[src].[Fecha] = [tgt].[Fecha] 
				)
				-- For updates
				WHEN MATCHED THEN
				  UPDATE 
					  SET
						 --                              =[src].


						 [tgt].[Mes]				=		[src].[Mes]			
						 ,[tgt].[Proveedor]			=		[src].[Proveedor]	
						 ,[tgt].[Site]				=		[src].[Site]			
						 ,[tgt].[TipoSite]			=		[src].[TipoSite]		
						 ,[tgt].[Campania]			=		[src].[Campania]		
						 ,[tgt].[Fecha]				=		[src].[Fecha]		 
						 ,[tgt].[DiaLaborable]		=		[src].[DiaLaborable]	 
						 ,[tgt].[HorasLogadas]		=		[src].[HorasLogadas]	
						 ,[tgt].[HorasEfectivas]	=		[src].[HorasEfectivas]
						 ,[tgt].[SPH]				=		[src].[SPH]			
						 ,[tgt].[VentasEnergia]		=		[src].[VentasEnergia]
						 ,[tgt].[AHT]				=		[src].[AHT]			
						 ,[tgt].[LastUpdateDate]	=		[src].[LastUpdateDate]
                     

				 --For Inserts
				WHEN NOT MATCHED THEN
					INSERT
					--Valores tgt
					(
							 [Mes]				
							,[Proveedor]		
							,[Site]			
							,[TipoSite]		
							,[Campania]		
							,[Fecha]			
							,[DiaLaborable]	
							,[HorasLogadas]	
							,[HorasEfectivas]	
							,[SPH]			
							,[VentasEnergia]	
							,[AHT]			
							,[LastUpdateDate]
					)
					VALUES
					(
						 [src].[Mes]			
						 ,[src].[Proveedor]	
						 ,[src].[Site]			
						 ,[src].[TipoSite]		
						 ,[src].[Campania]		
						 ,[src].[Fecha]		 
						 ,[src].[DiaLaborable]	
						 ,[src].[HorasLogadas]	
						 ,[src].[HorasEfectivas]
						 ,[src].[SPH]			
						 ,[src].[VentasEnergia]
						 ,[src].[AHT]			
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
		
		TRUNCATE TABLE #tmpVentasFCST;
		TRUNCATE TABLE #tmpVentasFCSTQA;

		--Se disminuye el número de archivos pendientes en 1
		SET @i = @i - 1;

	--Fin del ciclo

	END

	IF OBJECT_ID('tempdb..#OuFiles') IS NOT NULL DROP TABLE #OuFiles;
	IF OBJECT_ID('tempdb..#tmpVentasFCST') IS NOT NULL DROP TABLE #tmpVentasFCST;
	IF OBJECT_ID('tempdb..#tmpVentasFCSTQA') IS NOT NULL DROP TABLE #tmpVentasFCSTQA;
	
	IF @Severity = 1
	BEGIN
		RAISERROR('Error en Bloque Try',16,1);
	END

--Fin del procedimiento almacenado






