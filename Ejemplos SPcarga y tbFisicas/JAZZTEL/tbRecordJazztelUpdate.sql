USE [Orange]
GO

/****** Object:  Table [dbo].[tbRecordJazztel]    Script Date: 22/09/2023 11:40:25 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[tbRecordJazztel](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[IdClient] [int] NOT NULL,
	[Fecha] [date] NOT NULL,
	[Avail] [numeric](18, 0) NULL,
	[AuxProd] [int] NULL,
	[AuxNoProd] [numeric](18, 0) NULL,
	[TalkTime] [numeric](18, 0) NULL,
	[HoldTime] [numeric](18, 0) NULL,
	[ACWTime] [numeric](18, 0) NULL,
	[RingTime] [numeric](18, 0) NULL,
	[RealInteractionsAnswered] [numeric](18, 0) NULL,
	[RealInteractionsOffered] [int] NULL,
	[FCSTInteractionsAnswered] [decimal](18, 0) NULL,
	[KPIValue] [numeric](18, 0) NULL,
	[KPIprojection] [decimal](18, 0) NULL,
	[SHKprojection] [decimal](18, 0) NULL,
	[ABSprojection] [decimal](18, 0) NULL,
	[AHTprojection] [decimal](18, 0) NULL,
	[Weight] [int] NULL,
	[ReqHours] [decimal](18, 0) NULL,
	[KPIWeight] [decimal](18, 0) NULL,
	[FCSTStafftime] [decimal](18, 0) NULL,
	[AvailableProductive] [numeric](18, 0) NULL,
	[LastUpdateDate] [datetime] NULL,
 CONSTRAINT [PK_tbRecordJazztel] PRIMARY KEY CLUSTERED 
(
	[Id]
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


