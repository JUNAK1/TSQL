USE [Cardif]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*--------------------------
<Información Creación>
User_NT: E_1000687202
Fecha: 2023-09-21
Descripción: Creación de vista [vwCortIndicDiaCardifHsplitDay] que selecciona los datos indicados del Excel de la tabla Hsplit_day y Hagent_day
Se deja comentado el WITH SCHEMABINDING por lo que se trae información de otros servidores
----------------------------*/
CREATE VIEW [dbo].[vwCortIndicDiaCardifHsplitDay] --WITH SCHEMABINDING 
AS
	SELECT 
  Hsplit_day.row_date AS Fecha
, Hsplit_day.starttime
, Hsplit_day.split AS Skill
, Hsplit_day.acd
, Hsplit_day.callsoffered AS Ofrecidas
, Hsplit_day.acdcalls AS Atendidas
, Hsplit_day.abncalls
, Hsplit_day.othercalls
, Hsplit_day.abncalls1 AS Abandonadas5
, Hsplit_day.abncalls2 AS Abandonadas10
, Hsplit_day.abncalls3 AS Abandonadas15
, Hsplit_day.abncalls4 AS Abandonadas20
, Hsplit_day.acceptable AS LlamadasNDS
, Hsplit_day.anstime AS tiempoatencion
, Hsplit_day.abntime AS tiempoabandono
, Hsplit_day.auxoutoffcalls AS llamadassalientes
, SUM(Hagent_day.ti_stafftime) AS conexion
, SUM(Hagent_day.ti_availtime) AS disponible
, SUM(Hagent_day.ti_auxtime)-SUM(Hagent_day.ti_auxtime6) AS auxiliar
, SUM(Hagent_day.i_acdtime) AS conversacion
, SUM(Hagent_day.i_acwtime) AS acw
, SUM(Hagent_day.holdacdtime) AS hold
, SUM(Hagent_day.auxoutofftime) AS TiempoSaliente

FROM [10.151.230.21\SCOFFS].[WFM CMS].[dbo].[hsplit_day] WITH(NOLOCK) 
LEFT JOIN [10.151.230.21\SCOFFS].[WFM CMS].[dbo].[Hagent_day] WITH(NOLOCK) 
ON (Hsplit_day.row_date=Hagent_day.row_date) AND (Hsplit_day.starttime=Hagent_day.starttime) and (Hsplit_day.split=Hagent_day.split) and (Hsplit_day.ACD=Hagent_day.ACD)
WHERE Hsplit_day.split IN('7660','7500','7501','7502','7503','7504','7520','7521','7522','7523','7524','7540','7541','7542'
,'7543','7544','7563','7560','7561','7562','7580','7581','7582','7570','7571','7572','7593','7590','7591','7592','7600'
,'7601','7602','7613','7610','7611','7612','7623','7624','7620','7621','7622','7633','7630','7631','7632','7643','7640'
,'7641','7642','7650','7651','7652','7670','7671','7672','7673','7674','7675','7676','7661','7662','7663','7664'
,'7677','7678','7679','7680','7681','7682','7683','7684','7685','7686','7687','7688','7689','7690','7691','7692','7693'
,'7694','7695','7696','7697','7698','7699','7505','7506','7507','7508','7509','7510','7511','7512','7513','7514','7515'
,'7516','7517','7518','7519','7525','7526','7527','7528','7529','7530','7531','7532','7533','7534','7535','7536','7537'
,'7538','7539','7545','7546','7547','7548','7549','7550','7551','7552','7553','7554','7555','7556','7557','7558','7559'
,'7565','7566','7567','7568','7569','7573','7574','7575','7576','7577','7578','7579','7583','7584','7585','7586','7587'
,'7588','7589','7594','7595','7596','7597','7598','7599','7603','7604','7605','7606','7607','7608','7609','7614','7615'
,'7616','7617','7618','7619','7625','7626','7627','7628','7629','7634','7635','7636','7637','7638','7639','7644','7645'
,'7646','7647','7648','7649','7653','7654','7655','7656','7657','7658','7659','7665','7666','7667','7668','7669','7496'
,'7497','7498','7499','7700','7701','7493','7489','7488','7487','7494','7492','7491','7490','7705','7706','7707','7757'
,'7758','7759','7760','7761','7762','7756') AND Hsplit_day.ACD = '1'

GROUP BY
  Hsplit_day.row_date
, Hsplit_day.split
, Hsplit_day.starttime
, Hsplit_day.acd
, Hsplit_day.callsoffered
, Hsplit_day.acdcalls
, Hsplit_day.abncalls
, Hsplit_day.acceptable
, Hsplit_day.anstime
, Hsplit_day.abntime
, Hsplit_day.othercalls
, Hsplit_day.abncalls1
, Hsplit_day.abncalls2
, Hsplit_day.abncalls3
, Hsplit_day.abncalls4
, Hsplit_day.auxoutoffcalls
GO