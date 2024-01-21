USE [Mercadolibre]
GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[tbReporteAusentismoOAU](
    [Id]                    INT IDENTITY(1,1) NOT NULL
    ,[Page]                  VARCHAR(50)
    ,[Lob]                   VARCHAR(50)
    ,[Conca]                 VARCHAR(50)
    ,[ConcaTypeDay]          VARCHAR(50)
    ,[Year]                  NUMERIC
    ,[Month]                 NUMERIC
    ,[Weeknum]               NUMERIC
    ,[WDayName]              VARCHAR(50)
    ,[TypeDay]               VARCHAR(50)
    ,[Turno]                 VARCHAR(50)
    ,[CategoriaHrs]          VARCHAR(50)
    ,[RowDate]               DATE
    ,[Interval]              TIME
    ,[ScheduledStaff]        NUMERIC
    ,[NetStaff]              DECIMAL
    ,[ProductiveStaff]       DECIMAL(18,2)
    ,[Req]                   DECIMAL(18,2)
    ,[Volume]                DECIMAL(18,2)
    ,[Capacity]              DECIMAL(18,2)
    ,[ProductiveOU]          DECIMAL(18,2)
CONSTRAINT [pkReporteAusentismoOAU] PRIMARY KEY CLUSTERED 
(    [Id]
    
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO