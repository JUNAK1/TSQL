USE [Orange]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO		

CREATE TABLE [dbo].[tbImportDataOpsMetricsOrange](

				[Id]						INT IDENTITY(1,1) NOT NULL
				,[Mercado]						VARCHAR(100)
				,[LobId]						INT
				,[yyyy]							INT	
				,[mm]							INT
				,[CommittedFTE]					VARCHAR(100)
				,[FunctionalWorkstations]		VARCHAR(100)
				,[ProductionHours]				VARCHAR(100)
				,[Contacts]						VARCHAR(100)
				,[Completes]					VARCHAR(100)
				,[FirstCallResolved]			INT
				,[TotalCustomerIssues]			INT
				,[FirstCallResolutionTarget]	FLOAT
				,[BilledHours]					VARCHAR(100)
				,[PaidHours]					VARCHAR(100)
				,[TotalInteractionsOffered]		VARCHAR(100)
				,[TotalInteractionsAnswered]	VARCHAR(100)
				,[ServiceLevelTarget]			FLOAT
				,[WaitTime]						VARCHAR(100)
				,[HoldTime]						VARCHAR(100)
				,[TalkTime]						VARCHAR(100)
				,[WrapUpTime]					VARCHAR(100)
				,[TargetHandleTime]				VARCHAR(100)
				,[InteractionsAbandoned]		VARCHAR(100)
				,[QAFatalError]					INT
				,[TargetSchedule]				VARCHAR(100)
				,[ActualSchedule]				VARCHAR(100)
				,[VolumeForecastClientTarget]	VARCHAR(100)
				,[VolumeForecastClientActual]	VARCHAR(100)
				,[LastUpdateDate]				DATETIME


			CONSTRAINT [PKImportDataOpsMetricsOrangeQA] PRIMARY KEY CLUSTERED 
(
    [Id]

)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO