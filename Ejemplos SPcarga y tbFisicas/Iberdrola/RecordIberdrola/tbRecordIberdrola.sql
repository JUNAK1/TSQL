USE [Iberdrola]
GO

/****** Object:  Table [dbo].[tbRecordUploadIberdrola]    Script Date: 04/10/2023 2:16:58 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbRecordIberdrola](
	[Id] [INT] IDENTITY(1,1),
    [IdClient] [INT] NOT NULL,
	[Date] [DATE] NOT NULL,
    [Avail] [DECIMAL](18, 3) NULL,
    [AuxProd] [DECIMAL](18, 3) NULL, 
    [AuxNoProd] [DECIMAL](18, 3) NULL,
    [TalkTime] [DECIMAL](18, 3) NULL,
    [HoldTime] [DECIMAL](18, 3) NULL,
    [ACWTime] [DECIMAL](18, 3) NULL,
    [RingTime] [DECIMAL](18, 3) NULL, 
    [RealInteractionsAnswered] [DECIMAL](18, 3) NULL,
    [RealInteractionsOffered] [DECIMAL](18, 3) NULL,
	[FCSTInteractionsAnswered] [DECIMAL](18, 3) NULL,
    [KPIValue] [DECIMAL](18, 3) NULL,
	[KPIprojection] [DECIMAL](18, 3) NULL,
    [SHKprojection] [DECIMAL](18, 3) NULL,
    [ABSprojection] [DECIMAL](18, 3) NULL,
    [AHTprojection] [DECIMAL](18, 3) NULL,
    [Weight] [DECIMAL](18, 3) NULL,
	[ReqHours] [DECIMAL](18, 3) NULL, 
	[KPIWeight] [INT] NULL,
	[FCSTStafftime] [INT] NULL,
    [AvailableProductive] [DECIMAL](18, 3) NULL, 
	[LastUpdateDate] [DATETIME] NULL,
	
 CONSTRAINT [pkRecordUploadIberdrola] PRIMARY KEY CLUSTERED 
(
	[Id] 

)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO