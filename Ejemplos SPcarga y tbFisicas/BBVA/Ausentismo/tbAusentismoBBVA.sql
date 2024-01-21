USE [BBVA]
GO

/****** Object:  Table [dbo].[tbAusentismosBBVA]    Script Date: 10/3/2023 8:29:27 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[tbAusentismoBBVA](
    [Id] [int] IDENTITY(1,1) NOT NULL,
    [Supervisor] [varchar](100) NULL,
    [AgentName] [varchar](100) NULL,
    [idccms] [int] NULL,
    [Location] [varchar](20) NULL,
    [StartShift] [datetime] NULL,
    [EndOfShift] [datetime] NULL,
    [StartOfRest] [time](7) NULL,
    [EndOfRest] [time](7) NULL,
    [ScheduledTime] [int] NULL,
    [Login] [datetime] NULL,
    [Logout] [datetime] NULL,
    [TimeLoginHH] [float] NULL,
    [Status] [varchar](100) NULL,
    [StatusLogOut] [varchar](100) NULL,
    [SourceLogin] [varchar](100) NULL,
    [HoursAbsent] [float] NULL,
    [HoursTardy] [int] NULL,
    [HoursEarly] [int] NULL,
    [TypeJust] [varchar](100) NULL,
    [Justification] [varchar](500) NULL,
    [Observation] [varchar](500) NULL,
    [LastUpdateDate] [datetime] NULL,

 CONSTRAINT [pktbAusentismosBBVA] PRIMARY KEY CLUSTERED 
(
    [Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO