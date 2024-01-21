USE [Orange]
GO

/****** Object:  Table [dbo].[tbRecordOrange]    Script Date: 9/20/2023 1:00:00 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[tbRecordOrange]( 
	[Id] [int] IDENTITY(1,1),
    [IdClient] [int] NOT NULL,
	[Fecha] [date] NOT NULL,
    [Avail] [numeric](20, 0) NULL,
    [AuxProd] [int] NULL, --------no existe
    [AuxNoProd] [numeric](20, 0) NULL,
    [TalkTime] [numeric](20, 0) NULL,
    [HoldTime] [numeric](20, 0) NULL,
    [ACWTime] [numeric](20, 0) NULL,
    [RingTime] [numeric](20, 0) NULL, ----- debe ir vacio
    [RealInteractionsAnswered] [numeric](20, 0) NULL,
    [RealInteractionsOffered] [int] NULL,
	[FCSTInteractionsAnswered] [decimal](20, 0) NULL,
    [KPIValue] [float] NULL,
	[KPIprojection] [decimal] NULL,
    [SHKprojection] [decimal](20, 0) NULL,
    [ABSprojection] [decimal](20, 0) NULL,
    [AHTprojection] [decimal](20, 0) NULL,
    [Weight] [int] NULL,
	[ReqHours] [decimal](20, 0) NULL, 
	[KPIWeight] [decimal](20, 0) NULL,
	[FCSTStafftime] [decimal](20, 0) NULL,
    [AvailableProductive] [numeric](20, 0) NULL, -------debe ir vacio
    [TimeStamp] [datetime] NULL,
 CONSTRAINT [pkRecordOrange] PRIMARY KEY CLUSTERED 
(
    [Id]

)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

