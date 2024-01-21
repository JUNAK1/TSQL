/*======================================== Fisica ======================================*/
--Tabla Fisica
USE [GrupoSura]
GO

/****** Object:  Table [dbo].[tb]    Script Date: 5/10/2023 11:00:00 AM ******/
SET ANSI_NULLS ON
GO
CREATE TABLE [dbo].[tbExcesoHoraMytpIpsSura](


            [Id]                          INT IDENTITY(1,1) NOT NULL
            ,[idccms]                     INT NULL
            ,[logid]                      INT NULL
            ,[NombreCompleto]             VARCHAR(50)
            ,[Supervisor]                 VARCHAR(50)
            ,[Cliente]                    VARCHAR(50)
            ,[Programa]                   VARCHAR(100)
            ,[Fecha]                      VARCHAR(40)
            ,[HoraEntrada]                VARCHAR(40)
            ,[HoraSalida]                 VARCHAR(40)
            ,[HoraInicioBreakOne]         VARCHAR(40)
            ,[HoraFinBreakOne]            VARCHAR(40)
            ,[HoraInicioBreakTwo]         VARCHAR(40)
            ,[HoraFinBreakTwo]            VARCHAR(40)
            ,[HoraInicioAlmuerzo]         VARCHAR(40)
            ,[HoraFinAlmuerzo]            VARCHAR(40)
            ,[LastUpdateDate]             DATETIME NULL


        CONSTRAINT [pkExcesoHoraMytpIpsSura] PRIMARY KEY CLUSTERED 
(
    [Id]

)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
