USE [Cardif]
GO

SET ANSI_NULLS ON 
GO
SET QUOTED_IDENTIFIER ON 
GO
/* ---------------------------
<Informacion Creacion>
User NT: E_1000687202
Fecha: 2023-09-21
Descripcion: 
Creacion de vista [[vwCortIndicDiaCardifHTbouau]] 
que trae los datos solicitados del Excel de la tabla [dbo].[tboau]
------------------------*/

CREATE VIEW [dbo].[vwCortIndicDiaCardifHTbouau] WITH SCHEMABINDING 
AS
    SELECT
         A.[Lob]
        ,A.[ScheduledStaff]
        ,A.[NetStaff]
        ,A.[Fecha]
        ,A.[Franja]
        ,A.[Volume]
        ,A.[AHT]
FROM dbo.tboau AS A WITH(NOLOCK)
WHERE Fecha between '2023-07-01' and '2023-07-31';
GO