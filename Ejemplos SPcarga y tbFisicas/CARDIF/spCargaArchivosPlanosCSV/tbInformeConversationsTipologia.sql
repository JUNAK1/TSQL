IF OBJECT_ID ('[tbInformeConversationsTipologia]') IS NOT NULL 
    DROP TABLE [tbInformeConversationsTipologia]

    CREATE TABLE [dbo].[tbInformeConversationsTipologia](
[Id] INT IDENTITY(1,1),
[TipologiaConversation] [varchar] (500) NOT NULL,
[Motivo] [varchar](100) NOT NULL,
[TimeStamp] [datetime] NOT NULL,
CONSTRAINT [Pk_tbInformeConversationsTipologia] PRIMARY KEY CLUSTERED
(
[Id]
))