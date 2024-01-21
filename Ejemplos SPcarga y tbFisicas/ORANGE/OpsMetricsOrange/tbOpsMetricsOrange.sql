USE [Orange]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[tbOpsMetricsOrange](
	
		[year]								INT 
		,[month]							INT
		,[Client]							NVARCHAR(400) NOT NULL
		,[idLobOPSMetrics]					INT
		,[CommitedFTE]						FLOAT
		,[FunctionalWorkstations]			INT
		,[ProductionHours]					FLOAT
		,[Contacts]							INT
		,[Completes]						INT
		,[FirstCallResolved]				INT
		,[TotalCustomerIssues]				INT
		,[FirstCallResolutionTarget]		INT
		,[BilledHours]						DECIMAL(17,2)
		,[PaidHours]						BIGINT
		,[TotalInteractionsOffered]			FLOAT
		,[TotalInteractionsAnswered]		FLOAT
		,[ServiceLevelTarget]				FLOAT
		,[WaitTime]							INT
		,[HoldTime]							FLOAT
		,[TalkTime]							FLOAT
		,[WrapUpTime]						FLOAT
		,[TargetHandleTime]					FLOAT
		,[InteractionsAbandoned]			FLOAT
		,[QAFatalError]						INT
		,[TargetSchedule]					FLOAT
		,[ActualSchedule]					FLOAT
		,[VolumeForecastClientTarget]		FLOAT
		,[VolumeForecastClientActual]		FLOAT

 CONSTRAINT [PK_tbOpsMetricsOrange] PRIMARY KEY CLUSTERED 
(
    [year],[month],[Client] 

)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

