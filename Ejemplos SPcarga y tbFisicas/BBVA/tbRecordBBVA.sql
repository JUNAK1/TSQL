--Tabla Fisica
USE [BBVA]
GO

/****** Object:  Table [dbo].[tbRecordBBVA]    Script Date: 9/22/2023 1:00:00 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[tbRecordBBVA](
    [Id] INT IDENTITY(1,1),
    [IdClient] INT NOT NULL,
    [Date] DATE NOT NULL,
    [Avail] INT NULL,
    [AuxProd] INT NULL, --0
    [AuxNoProd] INT NULL, --Preguntar
    [TalkTime] INT NULL,
    [HoldTime] INT NULL,
    [ACWTime] INT NULL,
    [RingTime] INT NULL, 
    [RealInteractionsAnswered] INT NULL,
    [RealInteractionsOffered] INT NULL,
    [FCSTInteractionsAnswered] DECIMAL(18, 2) NULL,
    [KPIValue] INT NULL,
    [KPIprojection] FLOAT NULL, --Preguntar
    [SHKprojection] FLOAT NULL,
    [ABSprojection] FLOAT NULL,
    [AHTprojection] FLOAT NULL,
    [Weight] INT NULL,
    [ReqHours] DECIMAL(18, 2) NULL,
    [KPIWeight] DECIMAL(18, 2) NULL,
    [FCSTStafftime] DECIMAL(18, 2) NULL,
    [AvailableProductive] INT NULL, --0
    [LastUpdateDate] DATETIME NULL, 
 CONSTRAINT [pkRecordOrange] PRIMARY KEY CLUSTERED 
(
    [Id]

)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
