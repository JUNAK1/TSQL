USE [GrupoSura]
GO

/****** Object:  View [dbo].[vwPDCOAUIPSSura]    Script Date: 10/6/2023 1:38:53 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




/* --------------------  
<Informacion Creacion>

User_NT: E_1105792917,E_1012322897
Fecha: 2023-10-06 
Descripcion: 
Se crea la vista [dbo].[vwPDCOAUIPSSura] para la consulta de los datos de la tabla [GrupoSura].[dbo].[tbOAU]
La vista se crea segun el query extraido  del documento de excel 
<Area> pipeline
<Tipo_Resultado> Vista
*/
CREATE VIEW [dbo].[vwPDCOAUIPSSura]  WITH SCHEMABINDING
AS 
SELECT
     CONVERT(VARCHAR,Fecha,103) AS [Fecha]
    ,[Campaña]
    ,[Lob]
    ,CONVERT(VARCHAR,CONVERT(TIME,Franja),108) AS [Franja]
    ,[Volume]
    ,[AHT]
FROM [dbo].[tbOAU] WITH(NOLOCK)
WHERE [Fecha] >= '2023-05-01'
AND [Campaña] = 'GrupoSura';
GO


