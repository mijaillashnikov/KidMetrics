--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*
Nombre de Reporte     : SCRIPT PARA LA CARGA DE LA TABLA DE HECHOS - BI SALUD Y NUTRICION INFANTIL
Descripcion           : Consultas usadas en el paquete FACT_ATENCION_NUTRICIONAL.dtsx (limpieza, origen y lookups)
Base de Datos         : SQL SERVER
Requisito             : Dimensiones cargadas (3.-SCRIPT_PROCESO_SSIS_DIMENSIONES.sql / paquetes DIM_*.dtsx)
*/
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*1.- LIMPIA FACT_ATENCIONNUTRICIONAL*/
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
TRUNCATE TABLE Fact_AtencionNutricional;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*2.- ORIGEN SA_PERU (claves de negocio + medidas + indicadores)*/
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT  CAST(CONVERT(CHAR(8), FA.F, 112) AS INT)                                                    AS FechaAtencion
      , CAST(CASE WHEN FH.F BETWEEN '2017-01-01' AND '2050-12-31'
                  THEN CONVERT(CHAR(8), FH.F, 112) ELSE '19000101' END AS INT)                      AS FechaHemoglobina
      , CAST(RIGHT('00000000' + CAST(CAST(N.Renipress AS INT) AS VARCHAR(8)), 8) AS VARCHAR(8))     AS CodRenipress
      , CAST(CASE WHEN N.UbiREN > 0 THEN RIGHT('000000' + CAST(CAST(N.UbiREN AS INT) AS VARCHAR(6)), 6)
                  ELSE '000000' END AS VARCHAR(6))                                                   AS UbigeoEESS
      , CAST(CASE WHEN N.UbiPN > 0 THEN RIGHT('000000' + CAST(CAST(N.UbiPN AS INT) AS VARCHAR(6)), 6)
                  ELSE '000000' END AS VARCHAR(6))                                                   AS UbigeoResidencia
      , CAST(CASE WHEN N.Edad BETWEEN 6 AND 59 AND UPPER(TRIM(T1.SEXO_SA)) IN ('M', 'F')
                  THEN UPPER(TRIM(T1.SEXO_SA)) ELSE 'X' END AS VARCHAR(1))                           AS Sexo
      , CAST(CASE WHEN N.Edad BETWEEN 6 AND 59 AND UPPER(TRIM(T1.SEXO_SA)) IN ('M', 'F')
                  THEN N.Edad ELSE 0 END AS INT)                                                     AS EdadMeses
      , CAST(D.Dx AS VARCHAR(30))                                                                    AS Diagnostico
      , CAST(CASE WHEN N.Talla BETWEEN 45 AND 130 THEN 'CON MEDICION' ELSE 'SIN DATO' END AS VARCHAR(30)) AS Categoria
      , CAST(CASE CAST(dbo.fn_Num(T1.SIS_SA) AS INT)       WHEN 1 THEN '1' WHEN 0 THEN '0' ELSE '9' END AS VARCHAR(1)) AS SIS
      , CAST(CASE CAST(dbo.fn_Num(T1.JUNTOS_SA) AS INT)    WHEN 1 THEN '1' WHEN 0 THEN '0' ELSE '9' END AS VARCHAR(1)) AS Juntos
      , CAST(CASE CAST(dbo.fn_Num(T1.QALIWARMA_SA) AS INT) WHEN 1 THEN '1' WHEN 0 THEN '0' ELSE '9' END AS VARCHAR(1)) AS QaliWarma
      , CAST(CASE CAST(dbo.fn_Num(T1.PIN_SA) AS INT)       WHEN 1 THEN '1' WHEN 0 THEN '0' ELSE '9' END AS VARCHAR(1)) AS Pin
      , CAST(CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', CONCAT_WS('|', T1.DIRESA_SA, T1.RENIPRESS_SA, T1.FECHAATENCION_SA
             , T1.SEXO_SA, T1.EDADMESES_SA, T1.UBIGEOPN_SA, T1.PESO_SA, T1.TALLA_SA, T1.HEMOGLOBINA_SA
             , T1.FECHAHEMOGLOBINA_SA, T1.HBC_SA, T1.DX_ANEMIA_SA)), 2) AS CHAR(64))                 AS IdRegistroOrigen
      , CAST(CASE WHEN N.Peso BETWEEN 2 AND 30 THEN N.Peso END AS DECIMAL(5,2))                      AS PesoKg
      , CAST(CASE WHEN N.Talla BETWEEN 45 AND 130 THEN N.Talla END AS DECIMAL(5,1))                  AS TallaCm
      , CAST(CASE WHEN N.Hb BETWEEN 4 AND 20 THEN N.Hb END AS DECIMAL(4,1))                          AS HemoglobinaObservada
      , CAST(N.Hbc AS DECIMAL(5,2))                                                                  AS HemoglobinaCorregida
      , CAST(CASE WHEN D.Dx IN ('ANEMIA LEVE', 'ANEMIA MODERADA', 'ANEMIA SEVERA') THEN 1 ELSE 0 END AS TINYINT) AS IndAnemia
      , CAST(CASE WHEN CAST(dbo.fn_Num(T1.CRED_SA) AS INT) = 1 THEN 1 ELSE 0 END AS TINYINT)           AS IndCRED
      , CAST(CASE WHEN CAST(dbo.fn_Num(T1.SUPLEMENTACION_SA) AS INT) = 1 THEN 1 ELSE 0 END AS TINYINT) AS IndSuplementacion
      , CAST(CASE WHEN CAST(dbo.fn_Num(T1.CONSEJERIA_SA) AS INT) = 1 THEN 1 ELSE 0 END AS TINYINT)     AS IndConsejeria
      , CAST(CASE WHEN CAST(dbo.fn_Num(T1.SESION_SA) AS INT) = 1 THEN 1 ELSE 0 END AS TINYINT)         AS IndSesionDemostrativa
      , CAST(CASE WHEN FH.F = FA.F THEN 1 ELSE 0 END AS TINYINT)                                       AS IndTamizajeOportuno
      , CAST(CASE WHEN N.Hbc IS NULL OR D.Dx = 'SIN DATO' THEN 0
                  WHEN D.Dx <> CASE WHEN N.Hbc < 7  THEN 'ANEMIA SEVERA'
                                    WHEN N.Hbc < 10 THEN 'ANEMIA MODERADA'
                                    WHEN N.Hbc < 11 THEN 'ANEMIA LEVE'
                                    ELSE 'NORMAL' END THEN 1 ELSE 0 END AS TINYINT)                  AS IndDxInconsistente
FROM SA_PERU T1
CROSS APPLY (SELECT dbo.fn_FechaES(T1.FECHAATENCION_SA)    AS F) FA
CROSS APPLY (SELECT dbo.fn_FechaES(T1.FECHAHEMOGLOBINA_SA) AS F) FH
CROSS APPLY (SELECT dbo.fn_Num(T1.RENIPRESS_SA)            AS Renipress
                  , dbo.fn_Num(T1.UBIGE0REN_SA)            AS UbiREN
                  , dbo.fn_Num(T1.UBIGEOPN_SA)             AS UbiPN
                  , CAST(dbo.fn_Num(T1.EDADMESES_SA) AS INT) AS Edad
                  , dbo.fn_Num(T1.PESO_SA)                 AS Peso
                  , dbo.fn_Num(T1.TALLA_SA)                AS Talla
                  , dbo.fn_Num(T1.HEMOGLOBINA_SA)          AS Hb
                  , dbo.fn_Num(T1.HBC_SA)                  AS Hbc) N
CROSS APPLY (SELECT ISNULL(NULLIF(UPPER(TRIM(T1.DX_ANEMIA_SA)), ''), 'SIN DATO') AS Dx) D;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*3.- LOOKUPS A LAS DIMENSIONES (en el paquete: si no encuentra coincidencia, falla)*/
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- LKP DIM_TIEMPO ATENCION
SELECT T1.IdTiempo AS IdTiempoAtencion
     , T1.Fecha    AS FechaAtencion
FROM Dim_Tiempo T1;

-- LKP DIM_TIEMPO HEMOGLOBINA
SELECT T1.IdTiempo AS IdTiempoHemoglobina
     , T1.Fecha    AS FechaHemoglobina
FROM Dim_Tiempo T1;

-- LKP DIM_ESTABLECIMIENTO
SELECT T1.IdEstablecimiento
     , T1.CodRenipress
FROM Dim_Establecimiento T1;

-- LKP DIM_GEOGRAFIA EESS
SELECT T1.IdGeografia AS IdGeografiaEESS
     , T1.Ubigeo      AS UbigeoEESS
FROM Dim_Geografia T1;

-- LKP DIM_GEOGRAFIA RESIDENCIA
SELECT T1.IdGeografia AS IdGeografiaResidencia
     , T1.Ubigeo      AS UbigeoResidencia
FROM Dim_Geografia T1;

-- LKP DIM_PACIENTE
SELECT T1.IdPaciente
     , T1.Sexo
     , T1.EdadMeses
FROM Dim_Paciente T1;

-- LKP DIM_DIAGNOSTICO_ANEMIA
SELECT T1.IdDiagnostico
     , T1.Diagnostico
FROM Dim_DiagnosticoAnemia T1;

-- LKP DIM_ESTADO_NUTRICIONAL
SELECT T1.IdEstadoNutricional
     , T1.Categoria
FROM Dim_EstadoNutricional T1;

-- LKP DIM_PROGRAMA_SOCIAL
SELECT T1.IdProgramaSocial
     , T1.SIS
     , T1.Juntos
     , T1.QaliWarma
     , T1.Pin
FROM Dim_ProgramaSocial T1;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*4.- INSERTA FACT_ATENCIONNUTRICIONAL: columnas Id* de los lookups + medidas e indicadores del origen*/
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SELECT TOP 100 T1.* FROM Fact_AtencionNutricional T1
-- SELECT COUNT(*) FROM Fact_AtencionNutricional        -- esperado: 539 087
