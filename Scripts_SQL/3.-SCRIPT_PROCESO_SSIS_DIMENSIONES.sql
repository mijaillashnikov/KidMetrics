--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*
Nombre de Reporte     : SCRIPT PARA LA CARGA DE DIMENSIONES - BI SALUD Y NUTRICION INFANTIL
Descripcion           : Consultas usadas en los paquetes SSIS (origen, lookups y actualizacion)
Base de Datos         : SQL SERVER
Requisito             : dbo.fn_Num y dbo.fn_FechaES creadas (0.-SCRIPT_FUNCIONES_LIMPIEZA.sql)
*/
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*1.- DIM_ESTABLECIMIENTO  (paquete DIM_ESTABLECIMIENTO.dtsx)*/
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- LIMPIA TMP_ESTABLECIMIENTO
TRUNCATE TABLE TMP_Establecimiento;
-- CARGA SA_PERU (una sola version por CodRenipress: la mas frecuente)
SELECT  T1.CodRenipress
      , T1.NombreEESS
      , T1.CategoriaEESS
      , T1.Diresa
      , T1.Red
      , T1.Microred
      , T1.Departamento
      , T1.Provincia
      , T1.Distrito
FROM
    (
        SELECT ROW_NUMBER() OVER (PARTITION BY T1.CodRenipress ORDER BY T1.Cantidad DESC) AS NRO
             , T1.*
        FROM
            (
                SELECT T1.CodRenipress, T1.NombreEESS, T1.CategoriaEESS, T1.Diresa, T1.Red
                     , T1.Microred, T1.Departamento, T1.Provincia, T1.Distrito
                     , COUNT(*) AS Cantidad
                FROM
                    (
                        SELECT CAST(RIGHT('00000000' + CAST(CAST(dbo.fn_Num(T1.RENIPRESS_SA) AS INT) AS VARCHAR(8)), 8) AS VARCHAR(8))   AS CodRenipress
                             , CAST(CASE WHEN B.P2 > 0 THEN UPPER(TRIM(SUBSTRING(T1.EESS_SA, B.P2 + 3, 150)))
                                         ELSE UPPER(TRIM(T1.EESS_SA)) END AS VARCHAR(150))                                         AS NombreEESS
                             , CAST(ISNULL(CASE WHEN A.P1 > 0 THEN UPPER(TRIM(LEFT(T1.EESS_SA, A.P1 - 1))) END, 'SIN DATO') AS VARCHAR(10)) AS CategoriaEESS
                             , CAST(ISNULL(NULLIF(UPPER(TRIM(T1.DIRESA_SA)), ''), 'SIN DATO')    AS VARCHAR(100))  AS Diresa
                             , CAST(ISNULL(NULLIF(UPPER(TRIM(T1.RED_SA)), ''), 'SIN DATO')       AS VARCHAR(100))  AS Red
                             , CAST(ISNULL(NULLIF(UPPER(TRIM(T1.MICRORED_SA)), ''), 'SIN DATO')  AS VARCHAR(100))  AS Microred
                             , CAST(ISNULL(NULLIF(UPPER(TRIM(T1.DPTO_EESS_SA)), ''), 'SIN DATO') AS VARCHAR(50))   AS Departamento
                             , CAST(ISNULL(NULLIF(UPPER(TRIM(T1.PROV_EESS_SA)), ''), 'SIN DATO') AS VARCHAR(80))   AS Provincia
                             , CAST(ISNULL(NULLIF(UPPER(TRIM(T1.DIST_EESS_SA)), ''), 'SIN DATO') AS VARCHAR(80))   AS Distrito
                        FROM SA_PERU T1
                        CROSS APPLY (SELECT CHARINDEX(' - ', T1.EESS_SA) AS P1) A
                        CROSS APPLY (SELECT CASE WHEN A.P1 > 0 THEN CHARINDEX(' - ', T1.EESS_SA, A.P1 + 3) ELSE 0 END AS P2) B
                        WHERE dbo.fn_Num(T1.RENIPRESS_SA) IS NOT NULL
                    ) T1
                GROUP BY T1.CodRenipress, T1.NombreEESS, T1.CategoriaEESS, T1.Diresa, T1.Red
                       , T1.Microred, T1.Departamento, T1.Provincia, T1.Distrito
            ) T1
    ) T1
WHERE T1.NRO = 1;
-- VALIDA SI EXISTE DIM_ESTABLECIMIENTO
SELECT T1.CodRenipress
FROM Dim_Establecimiento T1
-- VALIDA SI EXISTE CAMBIOS EN DIM_ESTABLECIMIENTO
SELECT T1.CodRenipress
     , T1.NombreEESS
     , T1.CategoriaEESS
     , T1.Diresa
     , T1.Red
     , T1.Microred
     , T1.Departamento
     , T1.Provincia
     , T1.Distrito
FROM Dim_Establecimiento T1
-- ACTUALIZA DIM_ESTABLECIMIENTO
UPDATE T1
SET T1.NombreEESS         = T2.NombreEESS
  , T1.CategoriaEESS      = T2.CategoriaEESS
  , T1.Diresa             = T2.Diresa
  , T1.Red                = T2.Red
  , T1.Microred           = T2.Microred
  , T1.Departamento       = T2.Departamento
  , T1.Provincia          = T2.Provincia
  , T1.Distrito           = T2.Distrito
  , T1.FechaActualizacion = GETDATE()
FROM Dim_Establecimiento T1 INNER JOIN TMP_Establecimiento T2 ON T1.CodRenipress = T2.CodRenipress;
--
SELECT T1.* FROM Dim_Establecimiento T1;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*2.- DIM_TIEMPO  (paquete DIM_TIEMPO.dtsx)*/
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- LIMPIA TMP_TIEMPO
TRUNCATE TABLE TMP_Tiempo;
-- CARGA CALENDARIO (una fila por dia 2017-2050 + fila SIN FECHA)
SELECT  CAST(CONVERT(VARCHAR(8), C.Fecha, 112) AS INT)                     AS Fecha
      , CAST(YEAR(C.Fecha) AS INT)                                         AS Anio
      , CAST(MONTH(C.Fecha) AS INT)                                        AS Mes
      , CAST(CHOOSE(MONTH(C.Fecha), 'ENERO','FEBRERO','MARZO','ABRIL','MAYO','JUNIO',
                    'JULIO','AGOSTO','SETIEMBRE','OCTUBRE','NOVIEMBRE','DICIEMBRE') AS VARCHAR(12)) AS NombreMes
      , CAST(DATEPART(QUARTER, C.Fecha) AS INT)                            AS Trimestre
      , CAST(CASE WHEN MONTH(C.Fecha) <= 6 THEN 1 ELSE 2 END AS INT)       AS Semestre
      , CAST(CONCAT(YEAR(C.Fecha), '-', RIGHT('0' + CAST(MONTH(C.Fecha) AS VARCHAR(2)), 2)) AS VARCHAR(7)) AS PeriodoEstandarizado
FROM
    (
        SELECT TOP (DATEDIFF(DAY, '2017-01-01', '2050-12-31') + 1)
               DATEADD(DAY, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1, CAST('2017-01-01' AS DATE)) AS Fecha
        FROM sys.all_objects A
        CROSS JOIN sys.all_objects B
    ) C
UNION ALL
SELECT CAST(19000101 AS INT), CAST(1900 AS INT), CAST(0 AS INT), CAST('SIN FECHA' AS VARCHAR(12))
     , CAST(0 AS INT), CAST(0 AS INT), CAST('SIN FEC' AS VARCHAR(7));
-- VALIDA SI EXISTE DIM_TIEMPO
SELECT T1.Fecha
FROM Dim_Tiempo T1
-- VALIDA SI EXISTE CAMBIOS EN DIM_TIEMPO
SELECT T1.Fecha
     , T1.Anio
     , T1.Mes
     , T1.NombreMes
     , T1.Trimestre
     , T1.Semestre
     , T1.PeriodoEstandarizado
FROM Dim_Tiempo T1
-- ACTUALIZA DIM_TIEMPO
UPDATE T1
SET T1.Anio = T2.Anio
  , T1.Mes = T2.Mes
  , T1.NombreMes = T2.NombreMes
  , T1.Trimestre = T2.Trimestre
  , T1.Semestre = T2.Semestre
  , T1.PeriodoEstandarizado = T2.PeriodoEstandarizado
  , T1.FechaActualizacion = GETDATE()
FROM Dim_Tiempo T1 INNER JOIN TMP_Tiempo T2 ON T1.Fecha = T2.Fecha;
--
SELECT T1.* FROM Dim_Tiempo T1;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*3.- DIM_GEOGRAFIA  (paquete DIM_GEOGRAFIA.dtsx)*/
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- LIMPIA TMP_GEOGRAFIA
TRUNCATE TABLE TMP_Geografia;
-- CARGA SA_PERU (UBIGEO del EESS + UBIGEO del padron nominal; una version por Ubigeo)
SELECT  T1.Ubigeo
      , T1.Departamento
      , T1.Provincia
      , T1.Distrito
FROM
    (
        SELECT ROW_NUMBER() OVER (PARTITION BY T1.Ubigeo ORDER BY T1.Cantidad DESC) AS NRO
             , T1.*
        FROM
            (
                SELECT T1.Ubigeo, T1.Departamento, T1.Provincia, T1.Distrito, COUNT(*) AS Cantidad
                FROM
                    (
                        SELECT CAST(RIGHT('000000' + CAST(CAST(dbo.fn_Num(T1.UBIGE0REN_SA) AS INT) AS VARCHAR(6)), 6) AS VARCHAR(6)) AS Ubigeo
                             , CAST(UPPER(TRIM(T1.DEPARTAMENTOREN_SA)) AS VARCHAR(50))  AS Departamento
                             , CAST(UPPER(TRIM(T1.PROVINCIAREN_SA))    AS VARCHAR(80))  AS Provincia
                             , CAST(UPPER(TRIM(T1.DISTRITOREN_SA))     AS VARCHAR(80))  AS Distrito
                        FROM SA_PERU T1
                        WHERE dbo.fn_Num(T1.UBIGE0REN_SA) IS NOT NULL
                        UNION ALL
                        SELECT CAST(RIGHT('000000' + CAST(CAST(dbo.fn_Num(T1.UBIGEOPN_SA) AS INT) AS VARCHAR(6)), 6) AS VARCHAR(6))
                             , CAST(UPPER(TRIM(T1.DEPARTAMENTOPN_SA)) AS VARCHAR(50))
                             , CAST(UPPER(TRIM(T1.PROVINCIAPN_SA))    AS VARCHAR(80))
                             , CAST(UPPER(TRIM(T1.DISTRITOPN_SA))     AS VARCHAR(80))
                        FROM SA_PERU T1
                        WHERE dbo.fn_Num(T1.UBIGEOPN_SA) IS NOT NULL
                          AND TRIM(T1.DEPARTAMENTOPN_SA) <> ''
                    ) T1
                GROUP BY T1.Ubigeo, T1.Departamento, T1.Provincia, T1.Distrito
            ) T1
    ) T1
WHERE T1.NRO = 1
UNION ALL
SELECT CAST('000000' AS VARCHAR(6)), CAST('SIN DATO' AS VARCHAR(50)), CAST('SIN DATO' AS VARCHAR(80)), CAST('SIN DATO' AS VARCHAR(80));
-- VALIDA SI EXISTE DIM_GEOGRAFIA
SELECT T1.Ubigeo
FROM Dim_Geografia T1
-- VALIDA SI EXISTE CAMBIOS EN DIM_GEOGRAFIA
SELECT T1.Ubigeo
     , T1.Departamento
     , T1.Provincia
     , T1.Distrito
FROM Dim_Geografia T1
-- ACTUALIZA DIM_GEOGRAFIA
UPDATE T1
SET T1.Departamento       = T2.Departamento
  , T1.Provincia          = T2.Provincia
  , T1.Distrito           = T2.Distrito
  , T1.FechaActualizacion = GETDATE()
FROM Dim_Geografia T1 INNER JOIN TMP_Geografia T2 ON T1.Ubigeo = T2.Ubigeo;
--
SELECT T1.* FROM Dim_Geografia T1;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*4.- DIM_PACIENTE  (paquete DIM_PACIENTE.dtsx)*/
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- LIMPIA TMP_PACIENTE
TRUNCATE TABLE TMP_Paciente;
-- CARGA SA_PERU
SELECT DISTINCT
       CAST(UPPER(TRIM(T1.SEXO_SA)) AS VARCHAR(1))     AS Sexo
     , E.EDAD                                          AS EdadMeses
     , CAST(CASE WHEN E.EDAD <= 11 THEN '6-11 MESES'
                 WHEN E.EDAD <= 23 THEN '12-23 MESES'
                 WHEN E.EDAD <= 35 THEN '24-35 MESES'
                 WHEN E.EDAD <= 47 THEN '36-47 MESES'
                 ELSE '48-59 MESES' END AS VARCHAR(15)) AS GrupoEtario
FROM SA_PERU T1
CROSS APPLY (SELECT CAST(dbo.fn_Num(T1.EDADMESES_SA) AS INT) AS EDAD) E
WHERE E.EDAD BETWEEN 6 AND 59
  AND UPPER(TRIM(T1.SEXO_SA)) IN ('M', 'F')
UNION ALL
SELECT CAST('X' AS VARCHAR(1)), 0, CAST('SIN DATO' AS VARCHAR(15));
-- VALIDA SI EXISTE DIM_PACIENTE
SELECT T1.Sexo
     , T1.EdadMeses
FROM Dim_Paciente T1
-- VALIDA SI EXISTE CAMBIOS EN DIM_PACIENTE
SELECT T1.Sexo
     , T1.EdadMeses
     , T1.GrupoEtario
FROM Dim_Paciente T1
-- ACTUALIZA DIM_PACIENTE
UPDATE T1
SET T1.GrupoEtario        = T2.GrupoEtario
  , T1.FechaActualizacion = GETDATE()
FROM Dim_Paciente T1 INNER JOIN TMP_Paciente T2 ON T1.Sexo = T2.Sexo AND T1.EdadMeses = T2.EdadMeses;
--
SELECT T1.* FROM Dim_Paciente T1;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*5.- DIM_DIAGNOSTICO_ANEMIA  (paquete DIM_DIAGNOSTICO_ANEMIA.dtsx)*/
--   Toda la fila es la clave natural: "VALIDA SI EXISTE CAMBIOS" compara las mismas columnas y el UPDATE solo marca FechaActualizacion.
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- LIMPIA TMP_DIAGNOSTICOANEMIA
TRUNCATE TABLE TMP_DiagnosticoAnemia;
-- CARGA SA_PERU
SELECT DISTINCT
       CAST(UPPER(TRIM(T1.DX_ANEMIA_SA)) AS VARCHAR(30)) AS Diagnostico
FROM SA_PERU T1
WHERE TRIM(T1.DX_ANEMIA_SA) <> ''
UNION
SELECT CAST('SIN DATO' AS VARCHAR(30));
-- VALIDA SI EXISTE DIM_DIAGNOSTICOANEMIA
SELECT T1.Diagnostico
FROM Dim_DiagnosticoAnemia T1
-- VALIDA SI EXISTE CAMBIOS EN DIM_DIAGNOSTICOANEMIA
SELECT T1.Diagnostico
FROM Dim_DiagnosticoAnemia T1
-- ACTUALIZA DIM_DIAGNOSTICOANEMIA
UPDATE T1
SET T1.FechaActualizacion = GETDATE()
FROM Dim_DiagnosticoAnemia T1 INNER JOIN TMP_DiagnosticoAnemia T2 ON T1.Diagnostico = T2.Diagnostico;
--
SELECT T1.* FROM Dim_DiagnosticoAnemia T1;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*6.- DIM_PROGRAMA_SOCIAL  (paquete DIM_PROGRAMA_SOCIAL.dtsx)*/
--   Toda la fila es la clave natural: "VALIDA SI EXISTE CAMBIOS" compara las mismas columnas y el UPDATE solo marca FechaActualizacion.
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- LIMPIA TMP_PROGRAMASOCIAL
TRUNCATE TABLE TMP_ProgramaSocial;
-- CARGA SA_PERU
SELECT DISTINCT
       CAST(CASE CAST(dbo.fn_Num(T1.SIS_SA) AS INT)       WHEN 1 THEN '1' WHEN 0 THEN '0' ELSE '9' END AS VARCHAR(1)) AS SIS
     , CAST(CASE CAST(dbo.fn_Num(T1.JUNTOS_SA) AS INT)    WHEN 1 THEN '1' WHEN 0 THEN '0' ELSE '9' END AS VARCHAR(1)) AS Juntos
     , CAST(CASE CAST(dbo.fn_Num(T1.QALIWARMA_SA) AS INT) WHEN 1 THEN '1' WHEN 0 THEN '0' ELSE '9' END AS VARCHAR(1)) AS QaliWarma
     , CAST(CASE CAST(dbo.fn_Num(T1.PIN_SA) AS INT)       WHEN 1 THEN '1' WHEN 0 THEN '0' ELSE '9' END AS VARCHAR(1)) AS Pin
FROM SA_PERU T1;
-- VALIDA SI EXISTE DIM_PROGRAMASOCIAL
SELECT T1.SIS
     , T1.Juntos
     , T1.QaliWarma
     , T1.Pin
FROM Dim_ProgramaSocial T1
-- VALIDA SI EXISTE CAMBIOS EN DIM_PROGRAMASOCIAL
SELECT T1.SIS
     , T1.Juntos
     , T1.QaliWarma
     , T1.Pin
FROM Dim_ProgramaSocial T1
-- ACTUALIZA DIM_PROGRAMASOCIAL
UPDATE T1
SET T1.FechaActualizacion = GETDATE()
FROM Dim_ProgramaSocial T1 INNER JOIN TMP_ProgramaSocial T2 ON T1.SIS = T2.SIS AND T1.Juntos = T2.Juntos AND T1.QaliWarma = T2.QaliWarma AND T1.Pin = T2.Pin;
--
SELECT T1.* FROM Dim_ProgramaSocial T1;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*7.- DIM_ESTADO_NUTRICIONAL  (paquete DIM_ESTADO_NUTRICIONAL.dtsx)*/
--   Toda la fila es la clave natural: "VALIDA SI EXISTE CAMBIOS" compara las mismas columnas y el UPDATE solo marca FechaActualizacion.
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- LIMPIA TMP_ESTADONUTRICIONAL
TRUNCATE TABLE TMP_EstadoNutricional;
-- CARGA SA_PERU
SELECT DISTINCT
       CAST(CASE WHEN dbo.fn_Num(T1.TALLA_SA) BETWEEN 45 AND 130 THEN 'CON MEDICION'
                 ELSE 'SIN DATO' END AS VARCHAR(30)) AS Categoria
FROM SA_PERU T1;
-- VALIDA SI EXISTE DIM_ESTADONUTRICIONAL
SELECT T1.Categoria
FROM Dim_EstadoNutricional T1
-- VALIDA SI EXISTE CAMBIOS EN DIM_ESTADONUTRICIONAL
SELECT T1.Categoria
FROM Dim_EstadoNutricional T1
-- ACTUALIZA DIM_ESTADONUTRICIONAL
UPDATE T1
SET T1.FechaActualizacion = GETDATE()
FROM Dim_EstadoNutricional T1 INNER JOIN TMP_EstadoNutricional T2 ON T1.Categoria = T2.Categoria;
--
SELECT T1.* FROM Dim_EstadoNutricional T1;

