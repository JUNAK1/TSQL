USE [Cardif]
GO
/****** Object:  StoredProcedure [dbo].[spRecordCardif]    Script Date: 9/18/2023 6:07:05 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
<Informacion Creacion>
User_NT:E_1010083873 
Fecha: 2023-09-18
Descripcion: Creación de un sp de carga que toma datos de las tablas [hagent] [hsplit] [tboau] [tbLobSkillProductivos]
y los carga en [tbRecordCardif]
<Ejemplo>
Exec [dbo].[spConsolidadosRecord] 
*/
ALTER PROCEDURE [dbo].[spRecordCardif]
AS

SET NOCOUNT ON;

    BEGIN
        BEGIN TRY
        /*===============Bloque declaracion de variables==========*/
        
        DECLARE @ERROR INT =0;
        
        /*======================================== Creación y carga temporal #TMPHagent ======================================*/

        IF OBJECT_ID('tempdb..#TMPHagent') IS NOT NULL DROP TABLE #TMPHagent;
        CREATE TABLE #TMPHagent
        (   
             [split]                         INT
            ,[cms]                          VARCHAR(50)
            ,[row_date]                     DATE
            ,[Avail]                        INT
            ,[AuxProd]                      INT
            ,[AuxNoProd]                    INT
            ,[TalkTime]                     INT
            ,[HoldTime]                     INT
            ,[ACWTime]                      INT
            ,[RingTime]                     INT
        );

        INSERT INTO #TMPHagent
        SELECT
            B.[split]
            ,B.[cms]
            ,B.row_date
            ,sum(B.[ti_availtime])  AS [Avail]
            , 0 AS [AuxProd]
            ,(sum(ISNULL(B.[ti_auxtime],0)) - sum(ISNULL(B.[ti_auxtime6],0)) ) AS [AuxNoProd]
            ,sum(B.[i_acdtime]) AS [TalkTime]
            ,sum(B.[holdacdtime]) AS [HoldTime]
            ,sum(B.[i_acwtime]) AS [ACWTime]
            ,sum(B.[ringtime]) AS [RingTime]
        FROM 
        [10.151.230.21\SCOFFS].[WFM CMS].[dbo].[hagent] AS B WITH(NOLOCK)
        GROUP BY B.[split],B.[cms],B.[row_date]


/*======================================== Creación y carga temporal #TMPHsplit ======================================*/    
        IF OBJECT_ID('tempdb..#TMPHsplit') IS NOT NULL DROP TABLE #TMPHsplit;
        
        CREATE TABLE #TMPHsplit
            (
                [split]                         INT
                ,[cms]                          VARCHAR(50)
                ,[row_date]                     DATE
                ,[RealInteractionsAnswered]     INT
                ,[RealInteractionsOffered]      INT
                ,[KPIValue]                     FLOAT
                ,[Weight]                       INT
                ,[AvailableProductive]          INT
            );


            INSERT INTO #TMPHsplit --#TMP_HCMercadoLibre where [GeneralId] = 'ext_adrangel'
            SELECT
                C.[split]
                ,C.[cms]
                ,C.[row_date]
                ,sum(C.[acdcalls]) AS [RealInteractionsAnswered]
                ,sum(C.[callsoffered]) AS [RealInteractionsOffered]
                ,   CASE
                    WHEN    sum(C.[callsoffered]) = 0 OR sum(C.[callsoffered]) IS NULL
                        THEN 0
                    ELSE  sum(ISNULL(C.[acceptable],0)) /  sum(C.[callsoffered])
                    END AS [KPIValue]
                ,sum(C.[callsoffered]) AS [Weight]
                , 0 AS [AvailableProductive]
            FROM [10.151.230.21\SCOFFS].[WFM CMS].[dbo].[hsplit] AS C WITH(NOLOCK)
            GROUP BY C.[split],C.[cms],C.[row_date]

        /*======================================== Creación y carga temporal #TMPLobSkill ======================================*/                  

    IF OBJECT_ID('tempdb..#TMPLobSkill') IS NOT NULL DROP TABLE #TMPLobSkill;
                
        CREATE TABLE #TMPLobSkill
            (
                skill   INT
                ,Lucent NVARCHAR(50)
            );
        
        INSERT INTO #TMPLobSkill
        SELECT 
            [skill]
            ,[Lucent]
        FROM [TPCCP-DB10].[Cardif].[dbo].[tbLobSkillProductivos] WITH(NOLOCK)
        group by [skill],[Lucent]

        /*======================================== Creación y carga temporal #TMPOverAndUnder ======================================*/                  

    IF OBJECT_ID('tempdb..#TMPOverAndUnder') IS NOT NULL DROP TABLE #TMPOverAndUnder;
                
        CREATE TABLE #TMPOverAndUnder
            (
                 [Fecha]                        DATE
                ,[FCSTInteractionsAnswered]     DECIMAL
                ,[KPIprojection]                FLOAT
                ,[SHKprojection]                DECIMAL
                ,[ABSprojection]                DECIMAL
                ,[AHTprojection]                FLOAT
                ,[KPIWeight]                    DECIMAL
                ,[ReqHours]                     DECIMAL
                ,[FCSTStafftime]                DECIMAL
            );
        
        INSERT INTO #TMPOverAndUnder
        SELECT 
            [Fecha]                             AS [Fecha]
            ,SUM(ISNULL([NetCapacity],0))                   AS [FCSTInteractionsAnswered]
            ,SUM(ISNULL(CAST([SL] AS FLOAT),0))                         AS [KPIprojection]
            ,CASE
                 WHEN SUM([NetStaff]) = 0 OR SUM([NetStaff]) IS NULL
                       THEN 0
                 ELSE  1-(SUM(ISNULL([ProductiveStaff],0)) /  SUM([NetStaff]))

                 END                            AS [SHKprojection]
            ,CASE
                WHEN  SUM([ScheduledStaff]) = 0 OR  SUM([ScheduledStaff]) IS NULL
                    THEN 0
                ELSE 1-(SUM(ISNULL([NetStaff],0)) / SUM([ScheduledStaff]))

                END                             AS [ABSprojection]
            ,SUM(ISNULL([AHT],0))*60                 AS [AHTprojection]
            ,SUM(ISNULL([NetCapacity],0))                      AS [KPIWeight]
            ,(SUM(ISNULL([Req],0))*1800)/3600        AS [ReqHours]
            ,(SUM(ISNULL([netStaff],0))*1800)/3600   AS [FCSTStafftime]
        FROM [TPCCP-DB10].[Cardif].[dbo].[tboau]  WITH(NOLOCK)
        GROUP BY [Fecha]

    /*======================================== Creación y carga temporal #TMPConsolidadosRecordQA ======================================*/  
    IF OBJECT_ID('tempdb..#TMPConsolidadosRecordQA') IS NOT NULL DROP TABLE #TMPConsolidadosRecordQA;
                
        CREATE TABLE #TMPConsolidadosRecordQA
            (
                 [Id]                           INT NOT NULL
                ,[IdClient]                     INT NOT NULL
                ,[Date]                         DATE NOT NULL
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
 
  
            );

     INSERT INTO #TMPConsolidadosRecordQA
        SELECT 
             1421 AS [Id]
            ,0 AS [IdClient]
            ,HA.[row_date] AS [Date]
            ,HA.[Avail]                       
            ,HA.[AuxProd]                     
            ,HA.[AuxNoProd]                   
            ,HA.[TalkTime]                    
            ,HA.[HoldTime]                    
            ,HA.[ACWTime]                     
            ,HA.[RingTime]                    
            ,HS.[RealInteractionsAnswered]    
            ,HS.[RealInteractionsOffered]     
            ,HS.[KPIValue]                     
            ,HS.[Weight]                      
            ,HS.[AvailableProductive]         
            ,TB.[FCSTInteractionsAnswered]     
            ,TB.[KPIprojection]                
            ,TB.[SHKprojection]                
            ,TB.[ABSprojection]                
            ,TB.[AHTprojection]               
            ,TB.[KPIWeight]                    
            ,TB.[ReqHours]                     
            ,TB.[FCSTStafftime]   
            ,GETDATE()
            FROM #TMPLobSkill AS LS 
                INNER JOIN #TMPHagent HA 
                ON LS.[skill] = HA.[split] AND LS.[Lucent] = HA.[cms]
                INNER JOIN #TMPHsplit AS HS 
                ON LS.skill = HS.split AND LS.Lucent = HS.cms AND HS.[row_date] = HA.[row_date]
                INNER JOIN #TMPOverAndUnder TB
                ON TB.[Fecha] = HA.[row_date]
        
        

        /*************************Merge tabla fisica********************/
MERGE [TPCCP-DB10].[Cardif].[tbRecordCardif] AS [tgt]
        USING
        (
              SELECT
                 [id]
                ,[IdClient]
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
                ,[KPIValue]
                ,[Weight]
                ,[AvailableProductive]
                ,[FCSTInteractionsAnswered]
                ,[KPIprojection]
                ,[SHKprojection]
                ,[ABSprojection]
                ,[AHTprojection]
                ,[KPIWeight]
                ,[ReqHours]
                ,[FCSTStafftime]
                ,[TimeStamp]
            FROM #TMPConsolidadosRecordQA 




        ) AS [src]
        ON
        (
           
            [src].[Avail] = [tgt].[Avail] AND [src].[AuxProd] = [tgt].[AuxProd] AND [src].[AuxNoProd] = [tgt].[AuxNoProd]
        )
        -- For updates
        WHEN MATCHED THEN--CONSULTAR PERO LO MAS PROBALBLE ES QUE NO NECESTEMOS
          UPDATE 
              SET
                 

                 --                              =[src].
                 [tgt].[Id]                          =[src].[Id]
                ,[tgt].[IdClient]                    =[src].[IdClient]
                ,[tgt].[Date]                        =[src].[Date]
                ,[tgt].[Avail]                       =[src].[Avail]
                ,[tgt].[AuxProd]                     =[src].[AuxProd]
                ,[tgt].[AuxNoProd]                   =[src].[AuxNoProd]
                ,[tgt].[TalkTime]                    =[src].[TalkTime]
                ,[tgt].[HoldTime]                    =[src].[HoldTime]
                ,[tgt].[ACWTime]                     =[src].[ACWTime]
                ,[tgt].[RingTime]                    =[src].[RingTime]
                ,[tgt].[RealInteractionsAnswered]    =[src].[RealInteractionsAnswered]
                ,[tgt].[RealInteractionsOffered]     =[src].[RealInteractionsOffered]
                ,[tgt].[KPIValue]                    =[src].[KPIValue]
                ,[tgt].[Weight]                      =[src].[Weight]
                ,[tgt].[AvailableProductive]         =[src].[AvailableProductive]
                ,[tgt].[FCSTInteractionsAnswered]    =[src].[FCSTInteractionsAnswered]
                ,[tgt].[KPIprojection]               =[src].[KPIprojection]
                ,[tgt].[SHKprojection]               =[src].[SHKprojection]
                ,[tgt].[ABSprojection]               =[src].[ABSprojection]
                ,[tgt].[AHTprojection]               =[src].[AHTprojection]
                ,[tgt].[KPIWeight]                   =[src].[KPIWeight]
                ,[tgt].[ReqHours]                    =[src].[ReqHours]
                ,[tgt].[FCSTStafftime]               =[src].[FCSTStafftime]
                ,[tgt].[TimeStamp]                   =[src].[TimeStamp]






         --For Inserts
        WHEN NOT MATCHED THEN
            INSERT
            (
                
                 [Id]
                ,[IdClient]
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
                ,[KPIValue]
                ,[Weight]
                ,[AvailableProductive]
                ,[FCSTInteractionsAnswered]
                ,[KPIprojection]
                ,[SHKprojection]
                ,[ABSprojection]
                ,[AHTprojection]
                ,[KPIWeight]
                ,[ReqHours]
                ,[FCSTStafftime]
                ,[TimeStamp]
            )
            VALUES
            (
                
                 [src].[Id]
                ,[src].[IdClient]
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
                ,[src].[KPIValue]
                ,[src].[Weight]
                ,[src].[AvailableProductive]
                ,[src].[FCSTInteractionsAnswered]
                ,[src].[KPIprojection]
                ,[src].[SHKprojection]
                ,[src].[ABSprojection]
                ,[src].[AHTprojection]
                ,[src].[KPIWeight]
                ,[src].[ReqHours]
                ,[src].[FCSTStafftime]
                ,[src].[TimeStamp]
            );


        END TRY
        
        BEGIN CATCH
            SET @Error = 1;
            PRINT ERROR_MESSAGE();
        END CATCH
        /*=======================Eliminaci�n de temporales=========================*/

        IF OBJECT_ID('tempdb..#TMPHagent') IS NOT NULL DROP TABLE #TMPHagent;
        IF OBJECT_ID('tempdb..#TMPHsplit') IS NOT NULL DROP TABLE #TMPHsplit;
        IF OBJECT_ID('tempdb..#TMPLobSkill') IS NOT NULL DROP TABLE #TMPLobSkill;
        IF OBJECT_ID('tempdb..#TMPOverAndUnder') IS NOT NULL DROP TABLE #TMPOverAndUnder;
        IF OBJECT_ID('tempdb..#TMPConsolidadosRecordQA') IS NOT NULL DROP TABLE #TMPConsolidadosRecordQA;
     
    END