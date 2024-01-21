USE [MercadoLibre]
GO

/****** Object:  Table [dbo].[tbReporteAusentismoMeLi]    Script Date: 09/10/2023 11:00:00 AM ******/

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[tbReporteAusentismoMeLi](
    
	[Ccms] 					INT NOT NULL
	,[NCeco]  				VARCHAR(120) NULL
	,[FechaStaff] 			DATE NOT NULL
	,[TypeLog] 				VARCHAR(20) NULL
	,[Login]  				DATETIME NULL
	,[FLAGTurno] 			VARCHAR(15) NULL
	,[TimeStamp] 			DATETIME NULL

CONSTRAINT [pkReporteAusentismoMeLi] PRIMARY KEY CLUSTERED 
(
	[Ccms]
	,[FechaStaff]

)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO