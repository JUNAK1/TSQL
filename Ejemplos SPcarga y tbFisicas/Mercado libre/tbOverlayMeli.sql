--Tabla Fisica
USE [Mercadolibre]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE tbOverlayMeli
(   
     [Id]               INT IDENTITY(1,1) NOT NULL
    ,[idccms]           INT 
    ,[dateDim]          DATE
    ,[startTime]        TIME
    ,[endTime]          TIME
    ,[typeOv]           INT
    ,[descAux]          VARCHAR(100)
    ,[hrsOv]            TIME
    ,[client]           VARCHAR(100)
    ,[nameProgram]      VARCHAR(100)
    ,[country]          VARCHAR(30)
    ,[lastUpdateDate]   DATE


 CONSTRAINT [pkOverlayMeli] PRIMARY KEY CLUSTERED 
(
    [Id]

)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO