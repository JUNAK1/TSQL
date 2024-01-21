USE [Cardif]
GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[tbRecordCardif]( 

         [Id]                           INT
        ,[IdClient]                     INT
		,[Date]							DATE
        ,[Avail]                        INT
        ,[AuxProd]                      INT
        ,[AuxNoProd]                    INT
        ,[TalkTime]                     INT
        ,[HoldTime]                     INT
        ,[ACWTime]                      INT
        ,[RingTime]                     INT
        ,[RealInteractionsAnswered]     INT
        ,[RealInteractionsOffered]      INT
        ,[KPIValue]                     FLOAT
        ,[Weight]                       INT
        ,[AvailableProductive]          INT
        ,[FCSTInteractionsAnswered]     DECIMAL
        ,[KPIprojection]                FLOAT
        ,[SHKprojection]                DECIMAL
        ,[ABSprojection]                DECIMAL
        ,[AHTprojection]                FLOAT
        ,[KPIWeight]                    DECIMAL
        ,[ReqHours]                     DECIMAL
        ,[FCSTStafftime]                DECIMAL
        ,[TimeStamp]                    DATETIME
 
 
 CONSTRAINT [pkConsolidadosRecord] PRIMARY KEY CLUSTERED 
(   
      [Id]                      
     ,[IdClient]                        
   
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] 
GO