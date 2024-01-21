USE [Orange]
GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[tbRecordJazztel]( 

          [IdJazztel]					  INT NOT NULL IDENTITY(1,1)
		 ,[Id]                            INT 
         ,[IdClient]                      INT
         ,[Avail]                         NUMERIC
         ,[AuxProd]                       INT
         ,[AuxNoProd]                     NUMERIC
         ,[TalkTime]                      NUMERIC
         ,[HoldTime]                      NUMERIC
         ,[ACWTime]                       NUMERIC
         ,[RingTime]                      NUMERIC 
         ,[RealInteractionsAnswered]      NUMERIC
         ,[RealInteractionsOffered]       INT
         ,[KPIValue]                      NUMERIC
		 ,[Weight]						  INT 
         ,[AvailableProductive]           NUMERIC 
         ,[FCSTInteractionsAnswered]      DECIMAL
         ,[KPIprojection]                 DECIMAL
         ,[SHKprojection]                 DECIMAL
         ,[ABSprojection]                 DECIMAL
         ,[AHTprojection]                 DECIMAL
         ,[KPIWeight]                     DECIMAL
         ,[ReqHours]                      DECIMAL
         ,[FCSTStafftime]                 DECIMAL
         ,[Fecha]                         DATE
         ,[LastUpdateDate]                DATETIME
  
 
 
 CONSTRAINT [pkRecordJazztel] PRIMARY KEY CLUSTERED 
(   
      [IdJazztel]
   
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] 
GO
	        