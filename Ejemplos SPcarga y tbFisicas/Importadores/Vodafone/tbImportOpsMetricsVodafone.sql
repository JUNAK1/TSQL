USE [Vodafone]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE  TABLE [tbImportOpsMetricsVodafone]
(
            [Id]                                 INT IDENTITY (1,1)  
            ,[lobId]                             INT
            ,[yyyy]                              INT
            ,[mm]                                INT
            ,[CommittedFTE]                      VARCHAR(100)
            ,[ExplanationCommentaryFTEVariance]  VARCHAR(100)
            ,[FunctionalWorkstations]            VARCHAR(100)
            ,[ProductionHours]                   VARCHAR(100)
            ,[Contacts]                          FLOAT
            ,[Completes]                         FLOAT
            ,[FirstCallResolved]                 FLOAT
            ,[TotalCustomerIssues]               FLOAT
            ,[FirstCallResolutionTarget]         FLOAT
            ,[BilledHours]                       VARCHAR(100)
            ,[PaidHours]                         VARCHAR(100)
            ,[TotalInteractionsOffered]          FLOAT
            ,[TotalInteractionsAnswered]         FLOAT
            ,[ServiceLevelTarget]                FLOAT
            ,[WaitTime]                          FLOAT
            ,[HoldTime]                          FLOAT
            ,[TalkTime]                          FLOAT
            ,[WrapUpTime]                        FLOAT
            ,[TargetHandleTime]                  FLOAT
            ,[InteractionsAbandoned]             FLOAT
            ,[QAFatalError]                      FLOAT
            ,[TargetSchedule]                    FLOAT
            ,[ActualSchedule]                    FLOAT
            ,[VolumeForecastClientTarget]        VARCHAR(100)
            ,[VolumeForecastClientActual]        VARCHAR(100)
            ,[TimeStamp]                         DATETIME
    CONSTRAINT [pkImportOpsMetricsVodafone] 
    PRIMARY KEY CLUSTERED ( 
       [Id]
    )
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]) 
ON [PRIMARY]
GO