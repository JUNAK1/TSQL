USE [Cardif]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* --------------------
<Informacion Creacion>

User_NT: E_1016102870
Fecha: 2023-09-21
Descripcion: 
Se crea la vista [dbo].[vwCorteAuxAHtmCardif] para la consulta de los datos de la tabla [WFM CMS].[dbo].[hagent]
La vista se crea segun el query extraido  del documento de excel 
con el  nombre Corte auxiliar  AHT Mensual Cardif 
<Area> pipeline
<Tipo_Resultado> Vista
*/
CREATE VIEW [dbo].[vwCorteAuxAHtmCardif] --WITH SCHEMABINDING
AS
SELECT
		row_date
		, split
		, logid
		, SUM(ti_stafftime) AS conexion
		, SUM(ti_availtime) AS disponible
		, SUM(acdtime) AS conversacion
		, SUM(acwtime) AS acw
		, SUM(ti_auxtime) AS auxiliar
		, SUM(acdcalls) AS atendidas
		, SUM(holdacdtime) AS hold
		, SUM(ti_auxtime0) AS auxiliar0
		, SUM(ti_auxtime1) AS auxiliar1
		, SUM(ti_auxtime2) AS auxiliar2
		, SUM(ti_auxtime3) AS auxiliar3
		, SUM(ti_auxtime4) AS auxiliar4
		, SUM(ti_auxtime5) AS auxiliar5
		, SUM(ti_auxtime6) AS auxiliar6
		, SUM(ti_auxtime7) AS auxiliar7
		, SUM(ti_auxtime8) AS auxiliar8
		, SUM(ti_auxtime9) AS auxiliar9
		, SUM(auxoutofftime) AS TiempoSaliente
FROM [10.151.230.21\SCOFFS].[WFM CMS].[dbo].[hagent] WITH(NOLOCK)
WHERE split in ('7487','7488','7489','7490','7491','7492','7493','7494','7496','7497','7498'
		,'7499','7500','7501','7502','7503','7504','7505','7506','7507','7508','7509','7510','7511'
		,'7512','7513','7514','7515','7516','7517','7518','7519','7520','7521','7522','7523','7524'
		,'7525','7526','7527','7528','7529','7530','7531','7532','7533','7534','7535','7536','7537'
		,'7538','7539','7540','7541','7542','7543','7544','7545','7546','7547','7548','7549','7550'
		,'7551','7552','7553','7554','7555','7556','7557','7558','7559','7560','7561','7562','7563'
		,'7565','7566','7567','7568','7569','7570','7571','7572','7573','7574','7575','7576','7577'
		,'7578','7579','7580','7581','7582','7583','7584','7585','7586','7587','7588','7589','7590'
		,'7591','7592','7593','7594','7595','7596','7597','7598','7599','7600','7601','7602','7603'
		,'7604','7605','7606','7607','7608','7609','7610','7611','7612','7613','7614','7615','7616'
		,'7617','7618','7619','7620','7621','7622','7623','7624','7625','7626','7627','7628','7629'
		,'7630','7631','7632','7633','7634','7635','7636','7637','7638','7639','7640','7641','7642'
		,'7643','7644','7645','7646','7647','7648','7649','7650','7651','7652','7653','7654','7655'
		,'7656','7657','7658','7659','7660','7661','7662','7663','7664','7665','7666','7667','7668'
		,'7669','7670','7671','7672','7673','7674','7675','7676','7677','7678','7679','7680','7681'
		,'7682','7683','7684','7685','7686','7687','7688','7689','7690','7691','7692','7693','7694'
		,'7695','7696','7697','7698','7699','7700','7701','7708','7709','7738','7739','7752','7753'
		,'7754','7755','7757','7757','7758','7759','7760','7761','7762')
		AND row_date >= '2023-07-01' AND ACD = '1'
GROUP BY row_date, logid, split;
GO