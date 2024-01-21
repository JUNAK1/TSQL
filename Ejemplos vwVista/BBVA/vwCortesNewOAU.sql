USE [BBVA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* --------------------
<Informacion Creacion>

User_NT: E_1015216308, E_1016102870, E_1105792917, E_1000687202
Fecha: 2023-10-02
Descripcion: 
Se crea la vista [dbo].[vwCortesNewOAU] para la consulta de los datos de la tabla [BBVA].[dbo].[tbOAU]
La vista se crea segun el query extraido  del documento de excel 
con el  nombre 2.1 PDC Cortes New
<Area> pipeline
<Tipo_Resultado> Vista
*/
CREATE VIEW [dbo].[vwCortesNewOAU] --WITH SCHEMABINDING
AS 
    SELECT
        [Lob],
        [Scheduled Staff],
        [Net Staff],
        [Fecha],
        [Franja],
        [Volume],
        [AHT],
        [Req]

FROM [BBVA].[dbo].[tbOAU] WITH(NOLOCK)
WHERE Fecha >= '2023-03-01'
GO