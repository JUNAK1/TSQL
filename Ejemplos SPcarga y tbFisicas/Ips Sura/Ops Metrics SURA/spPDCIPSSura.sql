USE [GrupoSura]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*
<Informacion Creacion>
User_NT: E_1143864762, E_1016102870, E_1015216308, E_1088352987
Fecha: 2023-10-06
Descripcion: 
Se crea un sp de carga [spPDCIpsSura] con 3 temporales que son #tmpWFMHSplit, #tmpWFMHsplitDay y #tmpPDCQA 
Se realiza un insert a la tabla fisica tbPDCIpsSura con los respectivos filtros de fecha y cliente 

<Ejemplo>
Exec [dbo].[spPDCIpsSura] 
*/                      
CREATE PROCEDURE [dbo].[spPDCIPSSura]
AS

SET NOCOUNT ON;

    BEGIN
        BEGIN TRY
        /*===============Bloque declaracion de variables==========*/

        DECLARE @ERROR INT = 0;
        
/*======================================== Creación y carga temporal #tmpWFMHSplit ======================================*/
        IF OBJECT_ID('tempdb..#tmpWFMHSplit') IS NOT NULL 
        DROP TABLE #tmpWFMHSplit;

        CREATE TABLE #tmpWFMHSplit
        (   
             [Split]                      INT
            ,[Fecha]                      VARCHAR(50)
            ,[ACD]                        INT
            ,[starttime]                  DATETIME
            ,[LlamadasOfrecidas]          INT
            ,[LlamadasACD]                INT
            ,[ACDDentroNivel]             INT
            ,[LlamadasAbandonadas]        INT
            ,[TiempoLogueado]             INT
            ,[TiempoAvail]                INT
            ,[TiempoACD]                  INT
            ,[TiempoACW]                  INT
            ,[TiempoHold]                 INT
            ,[LlamadasSalida]             INT
            ,[Aux1]                       INT
            ,[Aux2]                       INT
            ,[Aux3]                       INT
            ,[Aux4]                       INT
            ,[Aux5]                       INT
            ,[Aux6]                       INT
            ,[Aux7]                       INT
            ,[Aux8]                       INT
            ,[Aux9]                       INT
        );

       INSERT INTO #tmpWFMHSplit
       SELECT
        [split] AS [Split],
        CONVERT(VARCHAR,[row_date],103) AS [Fecha],
        [acd] AS [ACD],
        CASE 
            WHEN LEN([starttime]) = 4 THEN CAST(CAST(LEFT([starttime],2) + ':'+ RIGHT([starttime],2) AS VARCHAR) AS DATETIME)
            WHEN LEN([starttime]) = 3 THEN CAST(CAST('0'+ LEFT([starttime],1) + ':'+ RIGHT([starttime],2) AS VARCHAR) AS DATETIME)
            WHEN LEN([starttime]) = 2 THEN CAST(CAST('00' + ':'+ RIGHT([starttime],2) AS VARCHAR) AS DATETIME)
        ELSE 0 END AS [starttime],
        
        SUM([callsoffered]) AS [Llamadas Ofrecidas],
        SUM([acdcalls])  AS [Llamadas ACD],
        SUM([acceptable])  AS [ACD Dentro del Nivel],
        SUM([abncalls]) AS [Llamadas Abandonadas],
        SUM([i_stafftime]) AS [Tiempo Logueado],
        SUM([i_availtime]) AS [Tiempo de Avail],
        SUM([i_acdtime]) AS [Tiempo ACD],
        SUM([i_acwtime]) AS [Tiempo ACW],
        SUM([holdtime]) AS [Tiempo en HOLD],
        SUM([auxoutcalls]) AS [Llamadas Salida],
        SUM([i_auxtime1]) AS [Aux1],
        SUM([i_auxtime2]) AS [Aux2],
        SUM([i_auxtime3]) AS [Aux3],
        SUM([i_auxtime4]) AS [Aux4],
        SUM([i_auxtime5]) AS [Aux5],
        SUM([i_auxtime6]) AS [Aux6],
        SUM([i_auxtime7]) AS [Aux7],
        SUM([i_auxtime8]) AS [Aux8],
        SUM([i_auxtime9]) AS [Aux9]
        FROM [WFM CMS].[dbo].[Hsplit] WITH (NOLOCK)

        WHERE [row_date] BETWEEN '2023-05-01' AND CAST(getdate() AS DATE)
        AND [acd] = 2
        AND [split] IN (1691,1939,1938,1940,1941,1603,1636,1838,1858,1808,1887,1888,1824,1823,1626,
                        1640,1604,1632,1639,1650,1651,2503,2504,2505,1667,1877,1844,1691,1694,1600,1623,1695,1685,
                        1820,1696,1896,1872,1598,1661,1820,3005,1872,1937,1232,3007,1615,1825,2515,2512,3009,2525,
                        1837,1862,2541,2529,3038,3513,1660,3526,3533,3534,2544)

        GROUP BY [row_date], [split], [acd], [starttime];

        
/*======================================== Creación y carga temporal #tmpWFMHsplitDay ======================================*/

        IF OBJECT_ID('tempdb..#tmpWFMHsplitDay') IS NOT NULL  
        DROP TABLE #tmpWFMHsplitDay;

        CREATE TABLE #tmpWFMHsplitDay
        (   
             [Split]                      INT
            ,[Fecha]                      VARCHAR(50)
            ,[ACD]                        INT
            ,[starttime]                  DATETIME
            ,[LlamadasOfrecidas]          INT
            ,[LlamadasACD]                INT
            ,[ACDDentroNivel]             INT
            ,[LlamadasAbandonadas]        INT
            ,[TiempoLogueado]             INT
            ,[TiempoAvail]                INT
            ,[TiempoACD]                  INT
            ,[TiempoACW]                  INT
            ,[TiempoHold]                 INT
            ,[LlamadasSalida]             INT
            ,[Aux1]                       INT
            ,[Aux2]                       INT
            ,[Aux3]                       INT
            ,[Aux4]                       INT
            ,[Aux5]                       INT
            ,[Aux6]                       INT
            ,[Aux7]                       INT
            ,[Aux8]                       INT
            ,[Aux9]                       INT
        );

        INSERT INTO #tmpWFMHsplitDay
         SELECT
        [split] AS [Split],
        CONVERT(VARCHAR,[row_date],103) AS [Fecha],
        [acd] AS [ACD],
        CASE 
            WHEN LEN([starttime]) = 4 
                    THEN CAST(CAST(LEFT([starttime],2) + ':'+ RIGHT([starttime],2) AS VARCHAR) AS DATETIME)
            WHEN LEN([starttime]) = 3 
                    THEN CAST(CAST('0'+ LEFT([starttime],1) + ':'+ RIGHT([starttime],2) AS VARCHAR) AS DATETIME)
            WHEN LEN([starttime]) = 2 
                    THEN CAST(CAST('00' + ':'+ RIGHT([starttime],2) AS VARCHAR) AS DATETIME)
            ELSE 0 END AS [starttime] ,
             
        SUM([callsoffered]) AS [Llamadas Ofrecidas], 
        SUM([acdcalls]) AS [Llamadas ACD],
        SUM([acceptable]) AS [ACD Dentro del Nivel],
        SUM([abncalls]) AS [Llamadas AbANDonadas],
        SUM([i_stafftime]) AS [Tiempo Logueado],
        SUM([i_availtime]) AS [Tiempo de Avail],
        SUM([i_acdtime]) AS [Tiempo ACD],
        SUM([i_acwtime]) AS [Tiempo ACW],     
        SUM([holdtime]) AS [Tiempo en HOLD],
        SUM([auxoutcalls]) AS [Llamadas Salida],
        SUM([i_auxtime1]) AS [Aux1],
        SUM([i_auxtime2]) AS [Aux2],
        SUM([i_auxtime3]) AS [Aux3],
        SUM([i_auxtime4]) AS [Aux4],
        SUM([i_auxtime5]) AS [Aux5],
        SUM([i_auxtime6]) AS [Aux6],
        SUM([i_auxtime7]) AS [Aux7],
        SUM([i_auxtime8]) AS [Aux8],  
        SUM([i_auxtime9]) AS [Aux9]

    FROM [WFM CMS].[dbo].[Hsplit_Day] WITH (NOLOCK)
    WHERE [acd] = 2
    AND [split] IN 
    (1691,1939,1938,1940,1941,1603,1636,1838,1858,1808,1887,1888,
    1824,1823,1626,1640,1604,1632,1639,1650,1651,2503,2504,2505,
    1667,1877,1844,1691,1694,1600,1623,1695,1685,1820,1696,1896,
    1872,1598,1661,1820,3005,1872,1937,1232,3007,1615,1825,2515,
    2512,2525,1837,1862,2541,2529,3038,3513,1660,3526,3533,3534,2544)
    GROUP BY [row_date], [split], [acd],[starttime];

 /*======================================== Creación y carga temporal #tmpPDCQA ======================================*/
       
        
        IF OBJECT_ID('tempdb..#tmpPDCQA ') IS NOT NULL 
        DROP TABLE #tmpPDCQA ;

         CREATE TABLE #tmpPDCQA
        (   
             [Split]                      INT
            ,[Fecha]                      VARCHAR(50)	
            ,[ACD]                        INT
            ,[starttime]                  DATETIME
            ,[LlamadasOfrecidas]          INT
            ,[LlamadasACD]                INT
            ,[ACDDentroNivel]             INT
            ,[LlamadasAbandonadas]        INT
            ,[TiempoLogueado]             INT
            ,[TiempoAvail]                INT
            ,[TiempoACD]                  INT
            ,[TiempoACW]                  INT
            ,[TiempoHold]                 INT
            ,[LlamadasSalida]             INT
            ,[Aux1]                       INT
            ,[Aux2]                       INT
            ,[Aux3]                       INT
            ,[Aux4]                       INT
            ,[Aux5]                       INT
            ,[Aux6]                       INT
            ,[Aux7]                       INT
            ,[Aux8]                       INT
            ,[Aux9]                       INT
        );
        /*=======================INSERCION HSPLIT=========================*/
		INSERT INTO #tmpPDCQA
        SELECT
             [Split]              
            ,[Fecha]              
            ,[ACD]                
            ,[starttime]          
            ,[LlamadasOfrecidas]  
            ,[LlamadasACD]        
            ,[ACDDentroNivel]     
            ,[LlamadasAbandonadas]
            ,[TiempoLogueado]     
            ,[TiempoAvail]        
            ,[TiempoACD]          
            ,[TiempoACW]          
            ,[TiempoHold]         
            ,[LlamadasSalida]     
            ,[Aux1]               
            ,[Aux2]               
            ,[Aux3]               
            ,[Aux4]               
            ,[Aux5]               
            ,[Aux6]               
            ,[Aux7]               
            ,[Aux8]               
            ,[Aux9]                
        FROM #tmpWFMHSplit;
        /*=======================INSERCION HSPLITDAY=========================*/
        INSERT INTO #tmpPDCQA
        SELECT
             [Split]              
            ,[Fecha]              
            ,[ACD]                
            ,[starttime]          
            ,[LlamadasOfrecidas]  
            ,[LlamadasACD]        
            ,[ACDDentroNivel]     
            ,[LlamadasAbandonadas]
            ,[TiempoLogueado]     
            ,[TiempoAvail]        
            ,[TiempoACD]          
            ,[TiempoACW]          
            ,[TiempoHold]         
            ,[LlamadasSalida]     
            ,[Aux1]               
            ,[Aux2]               
            ,[Aux3]               
            ,[Aux4]               
            ,[Aux5]               
            ,[Aux6]               
            ,[Aux7]               
            ,[Aux8]               
            ,[Aux9]                
        FROM #tmpWFMHsplitDay;

			/*=======================Truncate e Insert=========================*/
        TRUNCATE TABLE [tbPDCIpsSura]
        INSERT INTO [tbPDCIpsSura]
              SELECT
                 [Split]            
                ,[Fecha]              
                ,[ACD]                
                ,[starttime]          
                ,[LlamadasOfrecidas]  
                ,[LlamadasACD]        
                ,[ACDDentroNivel]     
                ,[LlamadasAbandonadas]
                ,[TiempoLogueado]     
                ,[TiempoAvail]        
                ,[TiempoACD]          
                ,[TiempoACW]          
                ,[TiempoHold]         
                ,[LlamadasSalida]     
                ,[Aux1]               
                ,[Aux2]               
                ,[Aux3]               
                ,[Aux4]               
                ,[Aux5]               
                ,[Aux6]               
                ,[Aux7]               
                ,[Aux8]               
                ,[Aux9]                
        FROM #tmpPDCQA;
       

		END TRY

        BEGIN CATCH
            SET @Error = 1;
            PRINT ERROR_MESSAGE();
        END CATCH
        /*=======================Eliminacion de temporales=========================*/

     IF OBJECT_ID('tempdb..#tmpWFMHSplit') IS NOT NULL 
        DROP TABLE #tmpWFMHSplit;
     IF OBJECT_ID('tempdb..#tmpWFMHsplitDay') IS NOT NULL 
        DROP TABLE #tmpWFMHsplitDay;
	 IF OBJECT_ID('tempdb..#tmpPDCQA') IS NOT NULL 
        DROP TABLE #tmpPDCQA;
     
  END