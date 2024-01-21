USE [BBVA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* --------------------
<Informacion Creacion>

User_NT: E_1088352987, E_1143864762, E_1053871829, E_1014297790
Fecha: 2023-10-02
Descripcion: 
Se crea la vista [dbo].[vwReporteDiarioAHTHagent] para la consulta de los datos de la tabla [BBVA].[dbo].[tbOAU]
La vista se crea segun el query extraido  del documento de excel 
con el  nombre 2.1 PDC Cortes New
<Area> pipeline
<Tipo_Resultado> Vista
*/
CREATE VIEW [dbo].[vwReporteDiarioAHTHagent]  --WITH SCHEMABINDING
AS 
	SELECT
		row_date, 
		starttime, 
		split, 
		acd, 
		logid, 
		sum(ti_stafftime) as conexion, 
		sum(ti_availtime) as disponible, 
		sum(acdtime) as conversacion, 
		sum(acwtime) as acw, 
		sum(ti_auxtime) as auxiliar, 
		sum(acdcalls) as atendidas, 
		sum(transferred) as Transferidas, 
		sum(holdacdtime) as hold, 
		sum(ti_auxtime0) as auxiliar0, 
		sum(ti_auxtime1) as auxiliar1, 
		sum(ti_auxtime2) as auxiliar2, 
		sum(ti_auxtime3) as auxiliar3, 
		sum(ti_auxtime4) as auxiliar4, 
		sum(ti_auxtime5) as auxiliar5, 
		sum(ti_auxtime6) as auxiliar6, 
		sum(ti_auxtime7) as auxiliar7, 
		sum(ti_auxtime8) as auxiliar8, 
		sum(ti_auxtime9) as auxiliar9
From Hagent_day with(nolock)
		Where split in('1400','1401','1403','1404','1405','1408','1410','1411','1413',
						'1414','1415','1416','1417','1418','1419','1423','1424','1425',
						'1426','1427','1428','1406','1436','1429','1499','5801','5802') 
						and ACD = '1'
		Group by row_date, starttime, logid, split, acd;
GO