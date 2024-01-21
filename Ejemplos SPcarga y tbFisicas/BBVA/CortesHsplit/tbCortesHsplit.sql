USE [BBVA]
GO

/****** Object:  Table [dbo].[tb]    Script Date: 10/02/2023 10:20:00 AM ******/
SET ANSI_NULLS ON
GO
        
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[tbCortesHsplit](

    [Id] INT IDENTITY(1,1),
    [Fecha] DATE NOT NULL,
    [StartTime] INT NOT NULL,
    [Skill] INT NULL,
    [Acd] INT NULL,
    [Ofrecidas] INT NULL, 
    [Atendidas] INT NULL,
    [AbnCalls] INT NULL,
    [OtherCalls] INT NULL,
    [Abandonadas5] INT NULL, 
    [Abandonadas10] INT NULL,
    [Abandonadas15] INT NULL,
    [LlamadasNDS] INT NULL,
    [TiempoAtencion] INT NULL,
    [TiempoAbandono] INT NULL, 
    [Conexion] INT NULL,
    [Disponible] INT NULL,
    [Auxiliar] INT NULL,
    [Conversacion] INT NULL,
    [Acw] INT NULL,
    [Hold] INT NULL,
    [Transferidas] INT NULL,
    [LastUpdateDate] DATETIME NULL, 

 CONSTRAINT [pkCortesHsplit] PRIMARY KEY CLUSTERED 
(
    [Id]

)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO