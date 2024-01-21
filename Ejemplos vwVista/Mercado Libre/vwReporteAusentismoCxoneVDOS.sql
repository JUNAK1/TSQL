USE [Mercadolibre]
GO
SET
    ANSI_NULLS ON
GO
SET
    QUOTED_IDENTIFIER ON
GO
    /* ---------------------------
     <Información Creación>
     User_NT: E_1012322897, E_1000687202, E_1000687202, E_1143864762, E_1019137609, E_1105792917, E_1088352987
     Fecha: 2023-10-4
     Descripcion: Creación de vista [vwReporteAusentismoCxoneVDOS] que selecciona los datos indicados del Excel
     
     
     ------------------------------*/
    CREATE VIEW [dbo].[vwReporteAusentismoCxoneVDOS] --WITH SCHEMABINDING
    AS
	WITH CTELoginLogout AS 
	(
		SELECT
			--CONCAT(cast(dateid as varchar) , userldap ) as conca
			[dateid],
			[userldap],
			[estado],
			[datestart],
			[Franja],
	CASE
		WHEN [Estado] <> 'Offline'
		and ABS(
			CAST(
				(
					DATEDIFF_BIG(
						ss,
						LAG([datestart], 1, 0) OVER(
							ORDER BY
								[userldap],
								[datestart]
						),
						[datestart]
					) * 1.00
				) / 3600 AS DECIMAL(18, 5)
			)
		) > 6 THEN 'IniTurno'
		WHEN --[Estado] = 'FinTurno' and 
		ABS(
			CAST(
				(
					DATEDIFF_BIG(
						ss,
						LEAD([datestart], 1, 0) OVER(
							ORDER BY
								[userldap],
								[datestart]
						),
						[datestart]
					) * 1.00
				) / 3600 AS DECIMAL(18, 5)
			)
		) > 6 THEN 'FinTurno'
				END AS 'FlagIniFinTurno'
		FROM
				[MercadoLibre].[dbo].[tbLoginLogout] nolock
	)

	SELECT 
		[dateid],
		--isnull(
		CAST(
			CASE
				WHEN FlagIniFinTurno = 'IniTurno' THEN CAST([datestart] AS DATE) --case when lead( [datestart],1,0) over(order by userldap, [datestart] asc) = 0 then CAST(getdate()-4 as date) else lead( [datestart],1,0) over(order by userldap, [datestart] asc)  end 
			END AS DATE
		) --,case when lag( [datestart],1,0) over(order by userldap, [datestart] asc) = 0 then CAST(getdate()-4 as date) else lead( [datestart],1,0) over(order by userldap, [datestart] asc)  end )
		AS [DateDim],
		[userldap],
		[estado],
		[FlagIniFinTurno],
		[datestart] --,case when lag( [datestart],1,0) over(order by userldap, [datestart] asc) = 0 then CAST(getdate() as date) else lag( [datestart],1,0) over(order by userldap, [datestart] asc)  end as [Reg-1]
		--,lead([datestart],1,0) over(order by userldap, [datestart] asc) as [Reg+1]
		--,abs(cast((datediff_big(ss,lag( [datestart],1,0) over(order by userldap),[datestart])*1.00)/3600 as decimal(18,5)))       [DReg-1]
		--,abs(cast((datediff_big(ss,lead([datestart],1,0) over(order by userldap) ,[datestart])*1.00)/3600 as decimal(18,5)))  [DReg+1]
	FROM
			CTELoginLogout AS a
	WHERE
		[FlagIniFinTurno] in ('IniTurno', 'FinTurno')
		and [dateid] >= GETDATE() -5 --and userldap = 'ext_crhsilva'
	
GO