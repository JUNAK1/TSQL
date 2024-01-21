--Tabla Fisica
USE [GrupoSura]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[tbHorasConexionIPSSura](
     [row_date]         VARCHAR(30)
    ,[logid]            INT
    ,[CCMSID]           INT
    ,[Nombre_Agente]    VARCHAR(100)
    ,[Cliente]          VARCHAR(50)
    ,[Programa]         VARCHAR(200)
    ,[Supervisor]       VARCHAR(50)
    ,[ACM]              VARCHAR(50)
    ,[T_Logueado]       INT
    ,[HoraConx]         VARCHAR(50)
    ,[HoraDesc]	        VARCHAR(50)
	CONSTRAINT [pkHorasConexionIPSSura] PRIMARY KEY CLUSTERED 
(
    [row_date],[logid]
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO