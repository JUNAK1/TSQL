USE [TiendasMELI]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[tbRecordUploadTiendasMeli](
    [Id]                            INT IDENTITY(1,1)
    ,[IdClient]                     INT
    ,[Date]                         DATE
    ,[Avail]                        DECIMAL(18,3)
    ,[AuxProd]                      DECIMAL(18,3) 
    ,[AuxNoProd]                    DECIMAL(18,3)
    ,[TalkTime]                     DECIMAL(18,3)
    ,[HoldTime]                     DECIMAL(18,3)
    ,[ACWTime]                      DECIMAL(18,3)
    ,[RingTime]                     DECIMAL(18,3)
    ,[RealInteractionsAnswered]     DECIMAL(18,3)
    ,[RealInteractionsOffered]      DECIMAL(18,3) 
    ,[FCSTInteractionsAnswered]     DECIMAL(18,3)
    ,[KPIValue]                     DECIMAL(18,3)
    ,[KPIprojection]                DECIMAL(18,3)
    ,[SHKprojection]                DECIMAL(18,3)
    ,[ABSprojection]                DECIMAL(18,3)
    ,[AHTprojection]                DECIMAL(18,3)
    ,[Weight]                       DECIMAL(18,3) 
    ,[ReqHours]                     DECIMAL(18,3)
    ,[KPIWeight]                    INT
    ,[FCSTStafftime]                INT
    ,[AvailableProductive]          DECIMAL(18,3)
    ,[LastUpdateDate]               DATE

 CONSTRAINT [pkRecordUploadTiendasMeli] PRIMARY KEY CLUSTERED 
(
    [Id]
    
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
