USE [MercadoLibre]
GO

--Tabla fisica

CREATE TABLE [dbo].[tbRepRTAuxMeli]
            (
                [Id]                        INT IDENTITY(1,1)
                ,[fecha]                    DATE
                ,[inicio]                   TIME
                ,[fin]                      TIME
                ,[conexionsec]              NUMERIC
                ,[UserLdap]                 NVARCHAR (100)
                ,[EstadoAgrupado]           VARCHAR  (100)
                ,[lob]                      VARCHAR  (100)
                ,[oldstatus]                VARCHAR  (100)
                ,[Online]                   NUMERIC
                ,[Break]                    NUMERIC
                ,[Event]                    FLOAT
                ,[PostContact]              NUMERIC 
                ,[HelpExclusive]            NUMERIC 
                ,[OperationalFailure]       NUMERIC 
                ,[SystematicFailure]        NUMERIC 
                ,[Training]                 NUMERIC 
                ,[Coaching]                 NUMERIC 
                ,[HelpLowPriority]      NUMERIC 
                ,[Teaching]                 FLOAT 
                ,[Shadowing]                FLOAT 
                ,[Nesting]                  FLOAT 
                ,[TiempoLog]                TIME
                ,[TL]                       VARCHAR(50)
                ,[ACM]                      VARCHAR(50)
                ,[Director]                 VARCHAR(50)
                ,[Clocktime]                TIME
                ,[LastUpdateDate]           DATETIME

                CONSTRAINT PK_IdConsolidadoFranjasEstadoRealTime PRIMARY KEY ([Id])
  
            );