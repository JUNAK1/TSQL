USE [BBVA]
GO

/****** Object:  StoredProcedure [dbo].[spRecordJazztel]    Script Date: 22/09/2023 12:04:18 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*
<Informacion Creacion>
User_NT:E_1143864762
Fecha: 2023-09-22
Descripcion:
Se crea un sp de carga [spRecordBBVA] con 3 temporales que son #TMPHsplit, #tmptbOAUBBVA y #tmpRecordBBVAQA
Al final se hace el Merge en la tabla fisica [tbRecordBBVA] para actualizar los registros existentes o insertar nuevos registros


<Ejemplo>
Exec [dbo].[spRecord] 
*/
ALTER PROCEDURE [dbo].[spRecordBBVA]
 @DateStart DATE = NULL
,@DateEnd  DATE = NULL
AS

SET NOCOUNT ON;

    BEGIN
        BEGIN TRY
        /*===============Bloque declaracion de variables==========*/
           		--DECLARE @dateStart DATE=NULL,@dateEnd DATE=NULL

        DECLARE @ERROR INT = 0;
		SET   @DateStart = ISNULL(@DateStart,CAST(GETDATE()-45 AS DATE));
        SET   @DateEnd   = ISNULL(@DateEnd,CAST(GETDATE() AS DATE));
		
        
/*======================================== Creación y carga temporal #TMPHsplit ======================================*/

        IF OBJECT_ID('tempdb..#TMPHsplit') IS NOT NULL DROP TABLE #TMPHsplit;
        CREATE TABLE #TMPHsplit
        (   
             [split]                        INT
            ,[cms]                          VARCHAR(50)
            ,[row_date]                     DATE
            ,[Avail]                        INT
            ,[AuxProd]                      INT
            ,[AuxNoProd]                    INT
            ,[TalkTime]                     INT
            ,[HoldTime]                     INT
            ,[ACWTime]                      INT
            ,[RingTime]                     INT
            ,[RealInteractionsAnswered]     INT
            ,[RealInteractionsOffered]      INT
            ,[KPIValue]                     INT
            ,[Weight]                       INT
            ,[AvailableProductive]          INT

        );

        INSERT INTO #TMPHsplit
        SELECT
             B.[split]
            ,B.[cms]
            ,B.row_date
            ,SUM(B.[i_availtime])  AS [Avail]
            , 0 AS [AuxProd]
            ,SUM([i_auxtime0] + [i_auxtime1]+[i_auxtime2]+[i_auxtime3]+[i_auxtime4]+[i_auxtime5]+[i_auxtime7]+[i_auxtime8]+[i_auxtime9]+[i_auxtime10]
                +[i_auxtime11]+[i_auxtime12]+[i_auxtime13]+[i_auxtime14]+[i_auxtime15]+[i_auxtime16]+[i_auxtime17]+[i_auxtime18]+[i_auxtime19]+[i_auxtime20]
                +[i_auxtime21]+[i_auxtime22]+[i_auxtime23]+[i_auxtime24]+[i_auxtime25]+[i_auxtime26]+[i_auxtime27]+[i_auxtime28]+[i_auxtime29]+[i_auxtime30]
                +[i_auxtime31]+[i_auxtime32]+[i_auxtime33]+[i_auxtime34]+[i_auxtime35]+[i_auxtime36]+[i_auxtime37]+[i_auxtime38]+[i_auxtime39]+[i_auxtime40]
                +[i_auxtime41]+[i_auxtime42]+[i_auxtime43]+[i_auxtime44]+[i_auxtime45]+[i_auxtime46]+[i_auxtime47]+[i_auxtime48]+[i_auxtime49]+[i_auxtime50]
                +[i_auxtime51]+[i_auxtime52]+[i_auxtime53]+[i_auxtime54]+[i_auxtime55]+[i_auxtime56]+[i_auxtime57]+[i_auxtime58]+[i_auxtime59]+[i_auxtime60]
                +[i_auxtime61]+[i_auxtime62]+[i_auxtime63]+[i_auxtime64]+[i_auxtime65]+[i_auxtime66]+[i_auxtime67]+[i_auxtime68]+[i_auxtime69]+[i_auxtime70]
                +[i_auxtime71]+[i_auxtime72]+[i_auxtime73]+[i_auxtime74]+[i_auxtime75]+[i_auxtime76]+[i_auxtime77]+[i_auxtime78]+[i_auxtime79]+[i_auxtime80]
                +[i_auxtime81]+[i_auxtime82]+[i_auxtime83]+[i_auxtime84]+[i_auxtime85]+[i_auxtime86]+[i_auxtime87]+[i_auxtime88]+[i_auxtime89]+[i_auxtime90]
                +[i_auxtime91]+[i_auxtime92]+[i_auxtime93]+[i_auxtime94]+[i_auxtime95]+[i_auxtime96]+[i_auxtime97]+[i_auxtime98]+[i_auxtime99])  
                AS [AuxNoProd]
            ,SUM(B.[i_acdtime]) AS [TalkTime]
            ,SUM(B.[holdtime]) AS [HoldTime]
            ,SUM(B.[acwtime]) AS [ACWTime]
            ,SUM(B.[ringtime]) AS [RingTime]
            ,SUM(B.[acdcalls]) AS [RealInteractionsAnswered]
            ,SUM(ISNULL(B.[acdcalls],0)) + SUM(ISNULL(B.[abncalls],0)) + SUM(ISNULL(B.[othercalls],0)) - SUM(ISNULL(B.[abncalls1],0)) - SUM(ISNULL(B.[abncalls2],0)) - SUM(ISNULL(B.[abncalls3],0)) AS [RealInteractionsOffered]
            , CASE
                    WHEN    SUM(ISNULL(B.[acdcalls],0) + ISNULL(B.[abncalls],0) + ISNULL(B.[othercalls],0) - ISNULL(B.[abncalls1],0) - ISNULL(B.[abncalls2],0) - ISNULL(B.[abncalls3],0)) = 0
                         OR SUM((ISNULL(B.[acdcalls],0) + ISNULL(B.[abncalls],0) + ISNULL(B.[othercalls],0)) - ISNULL(B.[abncalls1],0) - ISNULL(B.[abncalls2],0) - ISNULL(B.[abncalls3],0)) IS NULL
                        THEN 0
                    ELSE  SUM(ISNULL(B.[acceptable],0)) / SUM((ISNULL(B.[acdcalls],0) + ISNULL(B.[abncalls],0) + ISNULL(B.[othercalls],0)) - ISNULL(B.[abncalls1],0)- ISNULL(B.[abncalls2],0) - ISNULL(B.[abncalls3],0))
                        END AS [KPIValue]
            ,SUM(ISNULL(B.[acdcalls],0)) + SUM(ISNULL(B.[abncalls],0)) + SUM(ISNULL(B.[othercalls],0)) - SUM(ISNULL(B.[abncalls1],0)) - SUM(ISNULL(B.[abncalls2],0)) - SUM(ISNULL(B.[abncalls3],0)) AS [Weight]
            ,0 AS [AvailableProductive]

        FROM 
        [BBVA].[dbo].[hsplit] AS B WITH(NOLOCK)
		WHERE [row_date] BETWEEN @DateStart AND @DateEnd
        GROUP BY B.[split],B.[cms],B.[row_date];

IF OBJECT_ID('tempdb..#tmptbOAUBBVA') IS NOT NULL DROP TABLE #tmptbOAUBBVA;
        CREATE TABLE #tmptbOAUBBVA(
            [Fecha]                         DATE
            ,[FCSTInteractionsAnswered]     DECIMAL(18,2)
            ,[KPIprojection]                FLOAT
            ,[SHKprojection]                FLOAT
            ,[ABSprojection]                FLOAT
            ,[AHTprojection]                FLOAT
            ,[KPIWeight]                    DECIMAL(18,2)
            ,[ReqHours]                     DECIMAL(18,2)
            ,[FCSTStafftime]                DECIMAL(18,2)
);

INSERT INTO #tmptbOAUBBVA
    SELECT
        [Fecha] AS [Fecha]
        ,SUM(ISNULL([Volume],0)) AS [FCSTInteractionsAnswered]
        ,CASE
            WHEN SUM([Volume])=0
                THEN 0
            ELSE
                (SUM(ISNULL([Volume],0)*ISNULL(CAST([SL] AS FLOAT),0)))/SUM(ISNULL([Volume],0))
            END AS [KPIprojection]
        ,CASE
            WHEN SUM([Net Staff])=0
                THEN 0
            ELSE
                (SUM(ISNULL([Net Staff],0))-SUM(ISNULL([Productive Staff],0)))/SUM(ISNULL([Net Staff],0))
            END AS [SHKprojection]
        ,CASE
            WHEN SUM([Scheduled Staff])=0
                THEN 0
            ELSE
                (SUM(ISNULL([Scheduled Staff],0))-SUM(ISNULL([Net Staff],0)))/SUM(ISNULL([Scheduled Staff],0))
            END AS [ABSprojection]
        ,CASE
            WHEN SUM([Volume])=0
                THEN 0
            ELSE
                ((SUM(ISNULL([Volume],0)*ISNULL(CAST([AHT] AS FLOAT),0)))/SUM(ISNULL([Volume],0)))*60
            END AS [AHTprojection]
        ,SUM(ISNULL([Volume],0)) AS [KPIWeight] 
        ,SUM(ISNULL([Req],0))/2 AS [ReqHours] 
        ,SUM(ISNULL([Net Staff],0))/2 AS [FCSTStafftime]

    FROM [dbo].[tbOAU] WITH (NOLOCK)
	WHERE [fecha] BETWEEN @DateStart AND @DateEnd
    GROUP BY [Fecha];



IF OBJECT_ID('tempdb..#tmpRecordBBVAQA') IS NOT NULL DROP TABLE #tmpRecordBBVAQA;
        CREATE TABLE #tmpRecordBBVAQA(


            [IdClient] INT 
            ,[Date] DATE 
            ,[Avail] INT 
            ,[AuxProd] INT  --0
            ,[AuxNoProd] INT 
            ,[TalkTime] INT 
            ,[HoldTime] INT 
            ,[ACWTime] INT 
            ,[RingTime] INT  
            ,[RealInteractionsAnswered] INT
            ,[RealInteractionsOffered] INT
            ,[FCSTInteractionsAnswered] DECIMAL(18, 2)
            ,[KPIValue] INT 
            ,[KPIprojection] FLOAT 
            ,[SHKprojection] FLOAT 
            ,[ABSprojection] FLOAT 
            ,[AHTprojection] FLOAT 
            ,[Weight] INT 
            ,[ReqHours] DECIMAL(18, 2) 
            ,[KPIWeight] DECIMAL(18, 2) 
            ,[FCSTStafftime] DECIMAL(18, 2)
            ,[AvailableProductive] INT  --0
            ,[LastUpdateDate] DATETIME 
            
);
 INSERT INTO #tmpRecordBBVAQA
        SELECT
            
            1254 AS [IdClient]
            ,OA.Fecha
            ,HS.[Avail]
            ,HS.[AuxProd]
            ,HS.[AuxNoProd]
            ,HS.[TalkTime]
            ,HS.[HoldTime]
            ,HS.[ACWTime]
            ,HS.[RingTime]                      
            ,HS.[RealInteractionsAnswered]
            ,HS.[RealInteractionsOffered]
            ,OA.[FCSTInteractionsAnswered]
            ,HS.[KPIValue]
            ,OA.[KPIprojection]
            ,OA.[SHKprojection]
            ,OA.[ABSprojection]
            ,OA.[AHTprojection]
            ,HS.[Weight]
            ,OA.[ReqHours]
            ,OA.[KPIWeight]
            ,OA.[FCSTStafftime]
            ,HS.[AvailableProductive]
            ,GETDATE()
    FROM #TMPHsplit AS HS WITH(NOLOCK)
    INNER JOIN [tbLobSkillProductivos] AS S WITH (NOLOCK)
    ON S.[Lucent] = HS.[cms] COLLATE SQL_Latin1_General_CP1_CI_AS AND S.[skill] = HS.[split] 
    INNER JOIN #tmptbOAUBBVA AS OA 
    ON HS.[row_date] = OA.[Fecha]
    WHERE S.[Lob] <>'Outbound';

/*======================================== Carga a la tabla fisica [dbo].[tbRecordVodafone] usando MERGE ======================================*/

   MERGE [dbo].[tbRecordBBVA] AS [tgt]
        USING
        (
              SELECT                     
                [IdClient]                 
                ,[Date]                    
                ,[Avail]                    
                ,[AuxProd]                  
                ,[AuxNoProd]                
                ,[TalkTime]                 
                ,[HoldTime]                 
                ,[ACWTime]                  
                ,[RingTime]                 
                ,[RealInteractionsAnswered] 
                ,[RealInteractionsOffered]  
                ,[FCSTInteractionsAnswered] 
                ,[KPIValue]                 
                ,[KPIprojection]            
                ,[SHKprojection]            
                ,[ABSprojection]            
                ,[AHTprojection]            
                ,[Weight]                   
                ,[ReqHours]                 
                ,[KPIWeight]                
                ,[FCSTStafftime]            
                ,[AvailableProductive]      
                ,[LastUpdateDate]           

            FROM #tmpRecordBBVAQA
        ) AS [src]
        ON
        (
           
            [src].[Avail] = [tgt].[Avail] AND [src].[AuxNoProd] = [tgt].[AuxNoProd] AND  [src].[Date] = [tgt].[Date]
            --AND [src].[AuxProd] = [tgt].[AuxProd] 
            
        )
        -- For updates
        WHEN MATCHED THEN
          UPDATE 
              SET
                 --                              =[src].        
                [tgt].[IdClient]                    =[src].[IdClient]                                    
                ,[tgt].[Date]                      = [src].[Date]           
                ,[tgt].[Avail]                      = [src].[Avail]            
                ,[tgt].[AuxProd]                    = [src].[AuxProd]          
                ,[tgt].[AuxNoProd]                  = [src].[AuxNoProd]           
                ,[tgt].[TalkTime]                   = [src].[TalkTime]        
                ,[tgt].[HoldTime]                   = [src].[HoldTime]
                ,[tgt].[ACWTime]                    = [src].[ACWTime]
                ,[tgt].[RingTime]                   = [src].[RingTime] 
                ,[tgt].[RealInteractionsAnswered]   = [src].[RealInteractionsAnswered]
                ,[tgt].[RealInteractionsOffered]    = [src].[RealInteractionsOffered]
                ,[tgt].[FCSTInteractionsAnswered]   = [src].[FCSTInteractionsAnswered] 
                ,[tgt].[KPIValue]                   = [src].[KPIValue]
                ,[tgt].[KPIprojection]              = [src].[KPIprojection] 
                ,[tgt].[SHKprojection]              = [src].[SHKprojection]           
                ,[tgt].[ABSprojection]              = [src].[ABSprojection]        
                ,[tgt].[AHTprojection]              = [src].[AHTprojection]            
                ,[tgt].[Weight]                     = [src].[Weight]             
                ,[tgt].[ReqHours]                   = [src].[ReqHours]           
                ,[tgt].[KPIWeight]                  = [src].[KPIWeight]            
                ,[tgt].[FCSTStafftime]              = [src].[FCSTStafftime]
                ,[tgt].[AvailableProductive]        = [src].[AvailableProductive]
                ,[tgt].[LastUpdateDate]             = [src].[LastUpdateDate]

        WHEN NOT MATCHED THEN
            INSERT
            (
                    [IdClient]                 
                    ,[Date]                    
                    ,[Avail]                    
                    ,[AuxProd]                  
                    ,[AuxNoProd]                
                    ,[TalkTime]                 
                    ,[HoldTime]                 
                    ,[ACWTime]                  
                    ,[RingTime]                 
                    ,[RealInteractionsAnswered] 
                    ,[RealInteractionsOffered]  
                    ,[FCSTInteractionsAnswered] 
                    ,[KPIValue]                 
                    ,[KPIprojection]            
                    ,[SHKprojection]            
                    ,[ABSprojection]            
                    ,[AHTprojection]            
                    ,[Weight]                   
                    ,[ReqHours]                 
                    ,[KPIWeight]                
                    ,[FCSTStafftime]            
                    ,[AvailableProductive]      
                    ,[LastUpdateDate]           
            )
            VALUES
            (
                     [src].[IdClient]                 
                    ,[src].[Date]                    
                    ,[src].[Avail]                    
                    ,[src].[AuxProd]                  
                    ,[src].[AuxNoProd]                
                    ,[src].[TalkTime]                 
                    ,[src].[HoldTime]                 
                    ,[src].[ACWTime]                  
                    ,[src].[RingTime]                 
                    ,[src].[RealInteractionsAnswered] 
                    ,[src].[RealInteractionsOffered]  
                    ,[src].[FCSTInteractionsAnswered] 
                    ,[src].[KPIValue]                 
                    ,[src].[KPIprojection]            
                    ,[src].[SHKprojection]            
                    ,[src].[ABSprojection]            
                    ,[src].[AHTprojection]            
                    ,[src].[Weight]                 
                    ,[src].[ReqHours]                 
                    ,[src].[KPIWeight]                
                    ,[src].[FCSTStafftime]            
                    ,[src].[AvailableProductive]      
                    ,[src].[LastUpdateDate]  
            );
        
		END TRY

        BEGIN CATCH
            SET @Error = 1;
            PRINT ERROR_MESSAGE();
        END CATCH
        /*=======================Eliminacion de temporales=========================*/

     IF OBJECT_ID('tempdb..#TMPHsplit') IS NOT NULL DROP TABLE #TMPHsplit;
     IF OBJECT_ID('tempdb..#tmptbOAUBBVA') IS NOT NULL DROP TABLE #tmptbOAUBBVA;
	 IF OBJECT_ID('tempdb..#tmpRecordBBVAQA') IS NOT NULL DROP TABLE #tmpRecordBBVAQA;
     
  END