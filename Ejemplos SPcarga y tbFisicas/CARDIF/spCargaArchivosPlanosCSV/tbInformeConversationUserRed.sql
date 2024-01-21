--Tabla fisica
go
USE [Cardif]
go
DROP TABLE IF EXISTS [Cardif].[dbo].[tbInformeConversationsUserRed];
CREATE TABLE tbInformeConversationsUserRed
				(
					[IdInformeConversationUserRed] 		INT IDENTITY(1,1)
					,[NombreConversations]				VARCHAR(100)
					,[NombreTP]							VARCHAR(100)
					,[UsuarioRed]						VARCHAR(50)
					,[LastUpdateDate]						DATETIME


					 CONSTRAINT PK_ PRIMARY KEY ([IdInformeConversationUserRed])
				);


-- Verifica los resultados
SELECT * FROM [tbInformeConversationsUserRed];