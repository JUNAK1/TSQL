USE [BBVA]


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
<Informacion Creacion>
User_NT: E_1012322897, E_1233493216, E_1016102870, E_1000687202, E_1010083873
Fecha: 10/02/2023
Descripcion: Se crea un sp de carga [spCortesHsplit] que carga información desde las tablas [Hsplit_day] y [Hagent_day] hacia la tabla física [tbCortesHsplit]
<Ejemplo>
EXEC [dbo].[spCortesHsplit]; 
*/
CREATE PROCEDURE [dbo].[spCortesHsplit]
AS

SET NOCOUNT ON;

    BEGIN
        BEGIN TRY
        /*===============Bloque declaracion de variables==========*/
        
        DECLARE @ERROR INT =0;

        /*======================================== Creacion y carga a la tabla temporal #tmpFiltroHsplitDay y #tmpHsplitDay ======================================*/

		IF OBJECT_ID('tempdb..#tmpFiltroHsplitDay') IS NOT NULL 
        DROP TABLE #tmpFiltroHsplitDay;

        CREATE TABLE #tmpFiltroHsplitDay(
			ID					VARCHAR(15)
		);

		INSERT INTO #tmpFiltroHsplitDay (ID) VALUES

		('1400'), ('1401'), ('1404'), ('1499'),

		('1408'), ('1411'), ('1410'), ('1419'),

		('1423'), ('1426'), ('1405'), ('5802'),

		('5801'), ('1406'), ('1436');

		IF OBJECT_ID('tempdb..#tmpHsplitDay') IS NOT NULL 
        DROP TABLE #tmpHsplitDay;

        CREATE TABLE #tmpHsplitDay
        (
		
			[Fecha]				DATE
			,[StartTime]		INT
			,[Skill]			INT
			,[Acd]				INT
			,[Ofrecidas]		INT
			,[Atendidas]		INT
			,[AbnCalls]			INT
			,[OtherCalls]		INT
			,[Abandonadas5]		INT
			,[Abandonadas10]	INT	
			,[Abandonadas15]	INT
			,[LlamadasNDS]		INT
			,[TiempoAtencion]	INT
			,[TiempoAbandono]	INT
		
		);
		INSERT INTO #tmpHsplitDay
			SELECT

				 A.row_date  
				,A.starttime
				,A.split 
				,A.acd
				,A.callsoffered
				,A.acdcalls 
				,A.abncalls 
				,A.othercalls
				,A.abncalls1 
				,A.abncalls2 
				,A.abncalls3 
				,A.acceptable 
				,A.anstime 
				,A.abntime 

			FROM [TPCCP-DB07\SCOFFS].[WFM CMS].[dbo].[Hsplit_day] AS A WITH(NOLOCK)
			INNER JOIN #tmpFiltroHsplitDay AS B
			ON A.split = B.ID
			Where A.ACD = '1'

		/*======================================== Creacion y carga a la tabla temporal #tmpHagentDay ======================================*/

		IF OBJECT_ID('tempdb..#tmpHagentDay ') IS NOT NULL 
        DROP TABLE #tmpHagentDay ;
		CREATE TABLE #tmpHagentDay(

			[Conexion]      INT
			,[Disponible]   INT
			,[Auxiliar]     INT
			,[Conversacion] INT
			,[Acw]          INT
			,[Hold]         INT     
			,[Transferidas] INT
			,[RowDate]		DATE
			,[StartTime]    INT
			,[Split]        INT
			,[ACD]          INT
		)
		INSERT INTO #tmpHagentDay
		SELECT

			 A.[ti_stafftime]  
			,A.[ti_availtime]  
			,A.[ti_auxtime]      
			,A.[acdtime]       
			,A.[acwtime]         
			,A.[holdacdtime]     
			,A.[transferred]   
			,A.[row_date]                     
			,A.[starttime]                    
			,A.[split]                        
			,A.[ACD]  
		FROM [TPCCP-DB07\SCOFFS].[WFM CMS].[dbo].[Hagent_day] AS A WITH(NOLOCK)
		INNER JOIN #tmpFiltroHsplitDay AS B
		ON A.split = B.ID
		WHERE A.[ACD] = '1'


        /*======================================== Creacion y carga de la tabla temporal de calidad (QA) ======================================*/

		IF OBJECT_ID('tempdb..#tmpPDCQA') IS NOT NULL 
		DROP TABLE #tmpPDCQA;
		CREATE TABLE #tmpPDCQA(

			 [Fecha]           DATE
			,[StartTime]       INT
			,[Skill]           INT
			,[Acd]             INT
			,[Ofrecidas]       INT
			,[Atendidas]       INT
			,[AbnCalls]        INT
			,[OtherCalls]      INT
			,[Abandonadas5]    INT
			,[Abandonadas10]   INT
			,[Abandonadas15]   INT
			,[LlamadasNDS]     INT
			,[TiempoAtencion]  INT
			,[TiempoAbandono]  INT
			,[Conexion]        INT
			,[Disponible]      INT
			,[Auxiliar]        INT
			,[Conversacion]    INT
			,[Acw]             INT
			,[Hold]            INT
			,[Transferidas]    INT
			,[LastUpDate]      DATETIME

		);
		INSERT INTO #tmpPDCQA
		SELECT	
			 B.[Fecha]           
			,B.[Starttime]       
			,B.[Skill]         
			,B.[Acd]               
			,B.[Ofrecidas]     
			,B.[Atendidas]     
			,B.[Abncalls]      
			,B.[Othercalls]    
			,B.[Abandonadas5]      
			,B.[Abandonadas10]   
			,B.[Abandonadas15]   
			,B.[LlamadasNDS]       
			,B.[Tiempoatencion]  
			,B.[Tiempoabandono]  
			,SUM(ISNULL(A.[Conexion],0))          
			,SUM(ISNULL(A.[Disponible],0))    
			,SUM(ISNULL(A.[Auxiliar],0))          
			,SUM(ISNULL(A.[Conversacion],0))      
			,SUM(ISNULL(A.[Acw],0))               
			,SUM(ISNULL(A.[Hold],0))              
			,SUM(ISNULL(A.[Transferidas],0))      
			,GETDATE()
		FROM #tmpHsplitDay AS B
		LEFT JOIN #tmpHagentDay AS A
		ON (B.Fecha=A.RowDate) 
		and (B.StartTime=A.StartTime) 
		and (B.Skill=A.Split) 
		and (B.Acd=A.ACD)
		group by 
			 B.Fecha
			,B.Skill
			,B.StartTime
			,B.Acd
			,B.Ofrecidas
			,B.Atendidas
			,B.AbnCalls
			,B.LlamadasNDS
			,B.TiempoAtencion
			,B.TiempoAbandono
			,B.othercalls
			,B.Abandonadas5
			,B.Abandonadas10
			,B.Abandonadas15


        /*======================================== Insercion a la tabla fisica ======================================*/

		TRUNCATE TABLE [dbo].[tbCortesHsplit];

		INSERT INTO [dbo].[tbCortesHsplit]
			SELECT	
				 [Fecha]           
				,[StartTime]       
				,[Skill]           
				,[Acd]             
				,[Ofrecidas]       
				,[Atendidas]       
				,[AbnCalls]        
				,[OtherCalls]      
				,[Abandonadas5]    
				,[Abandonadas10]   
				,[Abandonadas15]   
				,[LlamadasNDS]     
				,[TiempoAtencion]  
				,[TiempoAbandono]  
				,[Conexion]        
				,[Disponible]      
				,[Auxiliar]        
				,[Conversacion]    
				,[Acw]             
				,[Hold]            
				,[Transferidas]    
				,[LastUpDate]      
			FROM #tmpPDCQA

    END TRY
        
    BEGIN CATCH
        SET @Error = 1;
        PRINT ERROR_MESSAGE();
    END CATCH;
        /*=======================Eliminacion de temporales=========================*/

		IF OBJECT_ID('tempdb..#tmpFiltroHsplitDay') IS NOT NULL DROP TABLE #tmpFiltroHsplitDay
		IF OBJECT_ID('tempdb..#tmpHsplitDay') IS NOT NULL DROP TABLE #tmpHsplitDay
		IF OBJECT_ID('tempdb..#tmpHagentDay') IS NOT NULL DROP TABLE #tmpHagentDay
		IF OBJECT_ID('tempdb..#tmpPDCQA') IS NOT NULL DROP TABLE #tmpPDCQA
   
    END;


	




