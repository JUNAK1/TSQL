USE [Vodafone]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*======================================== Creación y carga tabla fisica [tbRecordVodafone] ======================================*/  

    CREATE   TABLE [dbo].[tbRecordVodafone]( 

                 [Id]                            INT  NOT NULL 
                ,[IdClient]                      INT   NOT NULL 
                ,[Avail]                         NUMERIC
                ,[AuxProd]                       NUMERIC
                ,[AuxNoProd]                     NUMERIC
                ,[TalkTime]                      NUMERIC
                ,[HoldTime]                      NUMERIC
                ,[ACWTime]                       NUMERIC
                ,[RingTime]                      NUMERIC --Lo quemamos en 0
                ,[RealInteractionsAnswered]      NUMERIC
                ,[RealInteractionsOffered]       INT
                ,[KPIValue]                      NUMERIC
                ,[Offered]                       INT
                ,[AvailableProductive]           NUMERIC  --Lo quemamos en 0
                ,[FCSTInteractionsAnswered]      DECIMAL
                ,[KPIprojection]                 FLOAT
                ,[SHKprojection]                 DECIMAL
                ,[ABSprojection]                 NUMERIC
                ,[AHTprojection]                 DECIMAL
                ,[KPIWeight]                     DECIMAL
                ,[ReqHours]                      DECIMAL
                ,[FCSTStafftime]                 DECIMAL
                ,[Fecha]                         DATE
                ,[LastUpdateDate]                DATETIME
 
 
 CONSTRAINT [pkRecordVodafone] PRIMARY KEY CLUSTERED 
(   
      [Id]                      
     ,[IdClient]
     ,[Fecha]
   
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] 
GO