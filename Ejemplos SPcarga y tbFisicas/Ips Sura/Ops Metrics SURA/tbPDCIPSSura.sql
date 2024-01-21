/*======================================== Fisica ======================================*/
--Tabla Fisica
USE [GrupoSura]
GO

/****** Object:  Table [dbo].[tb]    Script Date: 5/10/2023 11:00:00 AM ******/
SET ANSI_NULLS ON
GO
CREATE TABLE [dbo].[tbPDCIpsSura](

         [IdPDCIpsSura]               INT IDENTITY(1,1) NOT NULL
        ,[Split]                      INT
        ,[Fecha]                      VARCHAR(50)	
        ,[ACD]                        INT
        ,[starttime]                  DATETIME
        ,[LlamadasOfrecidas]          INT
        ,[LlamadasACD]                INT
        ,[ACDDentroNivel]             INT
        ,[LlamadasAbandonadas]        INT
        ,[TiempoLogueado]             INT
        ,[TiempoAvail]                INT
        ,[TiempoACD]                  INT
        ,[TiempoACW]                  INT
        ,[TiempoHold]                 INT
        ,[LlamadasSalida]             INT
        ,[Aux1]                       INT
        ,[Aux2]                       INT
        ,[Aux3]                       INT
        ,[Aux4]                       INT
        ,[Aux5]                       INT
        ,[Aux6]                       INT
        ,[Aux7]                       INT
        ,[Aux8]                       INT
        ,[Aux9]                       INT


        CONSTRAINT [pktbPDCIpsSura] PRIMARY KEY CLUSTERED 
(
    [IdPDCIpsSura]

)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO