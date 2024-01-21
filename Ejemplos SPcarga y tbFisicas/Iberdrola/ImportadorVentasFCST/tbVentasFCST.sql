USE [Iberdrola]
GO

/****** Object:  Table [dbo].[tbVentasFCST]    Script Date: 04/10/2023 5:00:58 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbVentasFCST](
    [Id] [int] IDENTITY(1,1) NOT NULL,
    [Mes] [varchar](20) NOT NULL,
    [Proveedor] [varchar](50) NULL,
    [Site] [varchar](50) NULL,
    [TipoSite] [varchar](50) NULL,
    [Campania] [varchar](50) NULL,
    [Fecha] [date] NULL,
    [DiaLaborable] [int] NULL,
    [HorasLogadas] [int] NULL,
    [HorasEfectivas] [int] NULL,
    [SPH] [float] NULL,
    [VentasEnergia] [int] NULL,
    [AHT] [int] NULL,
    [LastUpdateDate] [datetime] NULL,
 CONSTRAINT [pkVentasFCST] PRIMARY KEY CLUSTERED 
(
    [Id]

)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO