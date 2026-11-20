--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*
Nombre de Reporte     : CONSULTAS DE EJEMPLO SOBRE EL MODELO ESTRELLA - BI SALUD Y NUTRICION INFANTIL
Descripcion           : Consultas analiticas sobre Fact_AtencionNutricional y sus dimensiones
Base de Datos         : SQL SERVER (DWH_UNICEF)
Nota                  : La prevalencia de anemia se calcula solo sobre atenciones con diagnostico registrado
*/
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*1.- PREVALENCIA DE ANEMIA POR DEPARTAMENTO DE RESIDENCIA*/
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT  G.Departamento
      , SUM(F.CantidadAtenciones)                                      AS Atenciones
      , SUM(F.IndAnemia)                                               AS CasosAnemia
      , CAST(100.0 * SUM(F.IndAnemia) / NULLIF(SUM(F.CantidadAtenciones), 0) AS DECIMAL(5,2)) AS PctAnemia
FROM Fact_AtencionNutricional F
INNER JOIN Dim_Geografia         G ON G.IdGeografia   = F.IdGeografiaResidencia
INNER JOIN Dim_DiagnosticoAnemia D ON D.IdDiagnostico = F.IdDiagnostico
WHERE D.Diagnostico <> 'SIN DATO'
  AND G.Ubigeo      <> '000000'
GROUP BY G.Departamento
ORDER BY PctAnemia DESC;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*2.- EVOLUCION MENSUAL: ATENCIONES, CASOS Y PREVALENCIA DE ANEMIA*/
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT  T.PeriodoEstandarizado
      , T.NombreMes
      , SUM(F.CantidadAtenciones)                                      AS Atenciones
      , SUM(F.IndAnemia)                                               AS CasosAnemia
      , CAST(100.0 * SUM(F.IndAnemia) / NULLIF(SUM(F.CantidadAtenciones), 0) AS DECIMAL(5,2)) AS PctAnemia
FROM Fact_AtencionNutricional F
INNER JOIN Dim_Tiempo T ON T.IdTiempo = F.IdTiempoAtencion
GROUP BY T.PeriodoEstandarizado, T.NombreMes
ORDER BY T.PeriodoEstandarizado;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*3.- DISTRIBUCION DEL DIAGNOSTICO POR GRUPO ETARIO Y SEXO*/
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT  P.GrupoEtario
      , P.Sexo
      , SUM(CASE WHEN D.Diagnostico = 'NORMAL'          THEN 1 ELSE 0 END) AS Normal
      , SUM(CASE WHEN D.Diagnostico = 'ANEMIA LEVE'     THEN 1 ELSE 0 END) AS Leve
      , SUM(CASE WHEN D.Diagnostico = 'ANEMIA MODERADA' THEN 1 ELSE 0 END) AS Moderada
      , SUM(CASE WHEN D.Diagnostico = 'ANEMIA SEVERA'   THEN 1 ELSE 0 END) AS Severa
      , CAST(100.0 * SUM(F.IndAnemia) / COUNT(*) AS DECIMAL(5,2))           AS PctAnemia
FROM Fact_AtencionNutricional F
INNER JOIN Dim_Paciente          P ON P.IdPaciente    = F.IdPaciente
INNER JOIN Dim_DiagnosticoAnemia D ON D.IdDiagnostico = F.IdDiagnostico
WHERE P.Sexo <> 'X'
  AND D.Diagnostico <> 'SIN DATO'
GROUP BY P.GrupoEtario, P.Sexo
ORDER BY P.GrupoEtario, P.Sexo;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*4.- ANEMIA Y COBERTURA DE SUPLEMENTACION SEGUN PROGRAMA SOCIAL (JUNTOS)*/
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT  CASE PS.Juntos WHEN '1' THEN 'CON JUNTOS' WHEN '0' THEN 'SIN JUNTOS' ELSE 'SIN DATO' END AS ProgramaJuntos
      , COUNT(*)                                                       AS Atenciones
      , CAST(100.0 * SUM(F.IndAnemia)         / COUNT(*) AS DECIMAL(5,2)) AS PctAnemia
      , CAST(100.0 * SUM(F.IndSuplementacion) / COUNT(*) AS DECIMAL(5,2)) AS PctSuplementacion
      , CAST(100.0 * SUM(F.IndCRED)           / COUNT(*) AS DECIMAL(5,2)) AS PctCRED
FROM Fact_AtencionNutricional F
INNER JOIN Dim_ProgramaSocial PS ON PS.IdProgramaSocial = F.IdProgramaSocial
GROUP BY PS.Juntos
ORDER BY PS.Juntos;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*5.- TOP 10 ESTABLECIMIENTOS CON MAS CASOS DE ANEMIA MODERADA O SEVERA*/
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT TOP 10
        E.CodRenipress
      , E.NombreEESS
      , E.CategoriaEESS
      , E.Diresa
      , SUM(CASE WHEN D.Diagnostico IN ('ANEMIA MODERADA', 'ANEMIA SEVERA') THEN 1 ELSE 0 END) AS CasosModSev
      , COUNT(*)                                                       AS Atenciones
      , CAST(AVG(F.HemoglobinaCorregida) AS DECIMAL(5,2))              AS HbCorregidaProm
FROM Fact_AtencionNutricional F
INNER JOIN Dim_Establecimiento   E ON E.IdEstablecimiento = F.IdEstablecimiento
INNER JOIN Dim_DiagnosticoAnemia D ON D.IdDiagnostico     = F.IdDiagnostico
GROUP BY E.CodRenipress, E.NombreEESS, E.CategoriaEESS, E.Diresa
ORDER BY CasosModSev DESC;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*6.- CALIDAD DEL DATO: TAMIZAJE OPORTUNO Y DIAGNOSTICOS INCONSISTENTES POR DIRESA*/
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT  E.Diresa
      , COUNT(*)                                                         AS Atenciones
      , CAST(100.0 * SUM(F.IndTamizajeOportuno) / COUNT(*) AS DECIMAL(5,2)) AS PctTamizajeOportuno
      , SUM(F.IndDxInconsistente)                                        AS DxInconsistentes
      , SUM(CASE WHEN TH.Fecha = 19000101 THEN 1 ELSE 0 END)             AS SinFechaHemoglobina
FROM Fact_AtencionNutricional F
INNER JOIN Dim_Establecimiento E  ON E.IdEstablecimiento = F.IdEstablecimiento
INNER JOIN Dim_Tiempo          TH ON TH.IdTiempo         = F.IdTiempoHemoglobina
GROUP BY E.Diresa
ORDER BY DxInconsistentes DESC;
