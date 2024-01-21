USE [Iberdrola]
GO

/****** Object:  Table [dbo].[tbOverlayIberdrola]    Script Date: 13/10/2023 9:56:23 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[tbOverlayIberdrola](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[IdCcms] [int] NULL,
	[DateDim] [date] NULL,
	[StartTime] [time](7) NULL,
	[EndTime] [time](7) NULL,
	[TypeOv] [int] NULL,
	[DescAux] [varchar](100) NULL,
	[HrsOv] [time](7) NULL,
	[Client] [varchar](100) NULL,
	[NameProgram] [varchar](100) NULL,
	[Country] [varchar](30) NULL,
	[LastUpdateDate] [date] NULL,
 CONSTRAINT [pkOverlayIberdrola] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


