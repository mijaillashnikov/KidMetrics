USE DWH_UNICEF;
SET NOCOUNT ON;
SELECT 'ESTABLECIMIE' AS q, COUNT(*) AS filas, COUNT(DISTINCT CAST(X.CodRenipress AS VARCHAR(20))) AS claves FROM (
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
        SELECT ROW_NUMBER() OVER (PARTITION BY T1.CodRenipress
                                  ORDER BY T1.Cantidad DESC, T1.NombreEESS, T1.CategoriaEESS, T1.Diresa, T1.Red
                                         , T1.Microred, T1.Departamento, T1.Provincia, T1.Distrito) AS NRO
             , T1.*
        FROM
            (
                SELECT T1.CodRenipress, T1.NombreEESS, T1.CategoriaEESS, T1.Diresa, T1.Red
                     , T1.Microred, T1.Departamento, T1.Provincia, T1.Distrito
                     , COUNT(*) AS Cantidad
                FROM
                    (
                        SELECT CAST(RIGHT('00000000' + CAST(CAST(dbo.fn_Num(T1.RENIPRESS_SA) AS INT) AS VARCHAR(8)), 8) AS VARCHAR(8))   AS CodRenipress
                             , CAST(ISNULL(NULLIF(CASE WHEN B.P2 > 0 THEN UPPER(TRIM(SUBSTRING(T1.EESS_SA, B.P2 + 3, 150)))
                                                       ELSE UPPER(TRIM(T1.EESS_SA)) END, ''), 'SIN DATO') AS VARCHAR(150))         AS NombreEESS
                             , CAST(ISNULL(NULLIF(CASE WHEN A.P1 > 0 THEN UPPER(TRIM(LEFT(T1.EESS_SA, A.P1 - 1))) END, ''), 'SIN DATO') AS VARCHAR(10)) AS CategoriaEESS
                             , CAST(ISNULL(NULLIF(UPPER(TRIM(T1.DIRESA_SA)), ''), 'SIN DATO')    AS VARCHAR(100))  AS Diresa
                             , CAST(ISNULL(NULLIF(UPPER(TRIM(T1.RED_SA)), ''), 'SIN DATO')       AS VARCHAR(100))  AS Red
                             , CAST(ISNULL(NULLIF(UPPER(TRIM(T1.MICRORED_SA)), ''), 'SIN DATO')  AS VARCHAR(100))  AS Microred
                             , CAST(ISNULL(NULLIF(UPPER(TRIM(T1.DPTO_EESS_SA)), ''), 'SIN DATO') AS VARCHAR(50))   AS Departamento
                             , CAST(ISNULL(NULLIF(UPPER(TRIM(T1.PROV_EESS_SA)), ''), 'SIN DATO') AS VARCHAR(80))   AS Provincia
                             , CAST(ISNULL(NULLIF(UPPER(TRIM(T1.DIST_EESS_SA)), ''), 'SIN DATO') AS VARCHAR(80))   AS Distrito
                        FROM SA_PERU T1
                        CROSS APPLY (SELECT CHARINDEX(' - ', T1.EESS_SA) AS P1) A
                        CROSS APPLY (SELECT CASE WHEN A.P1 > 0 THEN CHARINDEX(' - ', T1.EESS_SA, A.P1 + 3) ELSE 0 END AS P2) B
                        WHERE dbo.fn_Num(T1.RENIPRESS_SA) > 0
                    ) T1
                GROUP BY T1.CodRenipress, T1.NombreEESS, T1.CategoriaEESS, T1.Diresa, T1.Red
                       , T1.Microred, T1.Departamento, T1.Provincia, T1.Distrito
            ) T1
    ) T1
WHERE T1.NRO = 1
) X;
SELECT 'GEOGRAFIA' AS q, COUNT(*) AS filas, COUNT(DISTINCT CAST(X.Ubigeo AS VARCHAR(20))) AS claves FROM (
SELECT  T1.Ubigeo
      , T1.Departamento
      , T1.Provincia
      , T1.Distrito
FROM
    (
        SELECT ROW_NUMBER() OVER (PARTITION BY T1.Ubigeo
                                  ORDER BY T1.Cantidad DESC, T1.Departamento, T1.Provincia, T1.Distrito) AS NRO
             , T1.*
        FROM
            (
                SELECT T1.Ubigeo, T1.Departamento, T1.Provincia, T1.Distrito, COUNT(*) AS Cantidad
                FROM
                    (
                        SELECT CAST(RIGHT('000000' + CAST(CAST(dbo.fn_Num(T1.UBIGE0REN_SA) AS INT) AS VARCHAR(6)), 6) AS VARCHAR(6))  AS Ubigeo
                             , CAST(ISNULL(NULLIF(UPPER(TRIM(T1.DEPARTAMENTOREN_SA)), ''), 'SIN DATO') AS VARCHAR(50))  AS Departamento
                             , CAST(ISNULL(NULLIF(UPPER(TRIM(T1.PROVINCIAREN_SA)), ''), 'SIN DATO')    AS VARCHAR(80))  AS Provincia
                             , CAST(ISNULL(NULLIF(UPPER(TRIM(T1.DISTRITOREN_SA)), ''), 'SIN DATO')     AS VARCHAR(80))  AS Distrito
                        FROM SA_PERU T1
                        WHERE dbo.fn_Num(T1.UBIGE0REN_SA) > 0
                        UNION ALL
                        SELECT CAST(RIGHT('000000' + CAST(CAST(dbo.fn_Num(T1.UBIGEOPN_SA) AS INT) AS VARCHAR(6)), 6) AS VARCHAR(6))
                             , CAST(ISNULL(NULLIF(UPPER(TRIM(T1.DEPARTAMENTOPN_SA)), ''), 'SIN DATO') AS VARCHAR(50))
                             , CAST(ISNULL(NULLIF(UPPER(TRIM(T1.PROVINCIAPN_SA)), ''), 'SIN DATO')    AS VARCHAR(80))
                             , CAST(ISNULL(NULLIF(UPPER(TRIM(T1.DISTRITOPN_SA)), ''), 'SIN DATO')     AS VARCHAR(80))
                        FROM SA_PERU T1
                        WHERE dbo.fn_Num(T1.UBIGEOPN_SA) > 0
                    ) T1
                GROUP BY T1.Ubigeo, T1.Departamento, T1.Provincia, T1.Distrito
            ) T1
    ) T1
WHERE T1.NRO = 1
UNION ALL
SELECT CAST('000000' AS VARCHAR(6)), CAST('SIN DATO' AS VARCHAR(50)), CAST('SIN DATO' AS VARCHAR(80)), CAST('SIN DATO' AS VARCHAR(80))
) X;
SELECT 'PACIENTE' AS q, COUNT(*) AS filas, COUNT(DISTINCT CAST(X.Sexo AS VARCHAR(20)) + '|' + CAST(X.EdadMeses AS VARCHAR(20))) AS claves FROM (
SELECT DISTINCT
       CAST(UPPER(TRIM(T1.SEXO_SA)) AS VARCHAR(1))      AS Sexo
     , E.EDAD                                           AS EdadMeses
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
SELECT CAST('X' AS VARCHAR(1)), CAST(0 AS INT), CAST('SIN DATO' AS VARCHAR(15))
) X;
SELECT 'DIAGNOSTICO_' AS q, COUNT(*) AS filas, COUNT(DISTINCT CAST(X.Diagnostico AS VARCHAR(20))) AS claves FROM (
SELECT DISTINCT
       CAST(UPPER(TRIM(T1.DX_ANEMIA_SA)) AS VARCHAR(30)) AS Diagnostico
FROM SA_PERU T1
WHERE TRIM(T1.DX_ANEMIA_SA) <> ''
UNION
SELECT CAST('SIN DATO' AS VARCHAR(30))
) X;
SELECT 'PROGRAMA_SOC' AS q, COUNT(*) AS filas, COUNT(DISTINCT CAST(X.SIS AS VARCHAR(20)) + '|' + CAST(X.Juntos AS VARCHAR(20)) + '|' + CAST(X.QaliWarma AS VARCHAR(20)) + '|' + CAST(X.Pin AS VARCHAR(20))) AS claves FROM (
SELECT DISTINCT
       CAST(CASE CAST(dbo.fn_Num(T1.SIS_SA) AS INT)       WHEN 1 THEN '1' WHEN 0 THEN '0' ELSE '9' END AS VARCHAR(1)) AS SIS
     , CAST(CASE CAST(dbo.fn_Num(T1.JUNTOS_SA) AS INT)    WHEN 1 THEN '1' WHEN 0 THEN '0' ELSE '9' END AS VARCHAR(1)) AS Juntos
     , CAST(CASE CAST(dbo.fn_Num(T1.QALIWARMA_SA) AS INT) WHEN 1 THEN '1' WHEN 0 THEN '0' ELSE '9' END AS VARCHAR(1)) AS QaliWarma
     , CAST(CASE CAST(dbo.fn_Num(T1.PIN_SA) AS INT)       WHEN 1 THEN '1' WHEN 0 THEN '0' ELSE '9' END AS VARCHAR(1)) AS Pin
FROM SA_PERU T1
) X;
SELECT 'ESTADO_NUTRI' AS q, COUNT(*) AS filas, COUNT(DISTINCT CAST(X.Categoria AS VARCHAR(20))) AS claves FROM (
SELECT DISTINCT
       CAST(CASE WHEN dbo.fn_Num(T1.TALLA_SA) BETWEEN 45 AND 130 THEN 'CON MEDICION'
                 ELSE 'SIN DATO' END AS VARCHAR(30)) AS Categoria
FROM SA_PERU T1
) X;
SELECT X.* FROM (
SELECT DISTINCT
       CAST(UPPER(TRIM(T1.DX_ANEMIA_SA)) AS VARCHAR(30)) AS Diagnostico
FROM SA_PERU T1
WHERE TRIM(T1.DX_ANEMIA_SA) <> ''
UNION
SELECT CAST('SIN DATO' AS VARCHAR(30))
) X ORDER BY 1;
SELECT X.* FROM (
SELECT DISTINCT
       CAST(CASE CAST(dbo.fn_Num(T1.SIS_SA) AS INT)       WHEN 1 THEN '1' WHEN 0 THEN '0' ELSE '9' END AS VARCHAR(1)) AS SIS
     , CAST(CASE CAST(dbo.fn_Num(T1.JUNTOS_SA) AS INT)    WHEN 1 THEN '1' WHEN 0 THEN '0' ELSE '9' END AS VARCHAR(1)) AS Juntos
     , CAST(CASE CAST(dbo.fn_Num(T1.QALIWARMA_SA) AS INT) WHEN 1 THEN '1' WHEN 0 THEN '0' ELSE '9' END AS VARCHAR(1)) AS QaliWarma
     , CAST(CASE CAST(dbo.fn_Num(T1.PIN_SA) AS INT)       WHEN 1 THEN '1' WHEN 0 THEN '0' ELSE '9' END AS VARCHAR(1)) AS Pin
FROM SA_PERU T1
) X ORDER BY 1,2,3,4;
SELECT X.* FROM (
SELECT DISTINCT
       CAST(CASE WHEN dbo.fn_Num(T1.TALLA_SA) BETWEEN 45 AND 130 THEN 'CON MEDICION'
                 ELSE 'SIN DATO' END AS VARCHAR(30)) AS Categoria
FROM SA_PERU T1
) X ORDER BY 1;
SELECT CAST(UPPER(TRIM(SEXO_SA)) AS VARCHAR(20)) AS sexo, COUNT(*) AS n FROM SA_PERU GROUP BY UPPER(TRIM(SEXO_SA));
SELECT TOP 5 X.* FROM (
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
        SELECT ROW_NUMBER() OVER (PARTITION BY T1.CodRenipress
                                  ORDER BY T1.Cantidad DESC, T1.NombreEESS, T1.CategoriaEESS, T1.Diresa, T1.Red
                                         , T1.Microred, T1.Departamento, T1.Provincia, T1.Distrito) AS NRO
             , T1.*
        FROM
            (
                SELECT T1.CodRenipress, T1.NombreEESS, T1.CategoriaEESS, T1.Diresa, T1.Red
                     , T1.Microred, T1.Departamento, T1.Provincia, T1.Distrito
                     , COUNT(*) AS Cantidad
                FROM
                    (
                        SELECT CAST(RIGHT('00000000' + CAST(CAST(dbo.fn_Num(T1.RENIPRESS_SA) AS INT) AS VARCHAR(8)), 8) AS VARCHAR(8))   AS CodRenipress
                             , CAST(ISNULL(NULLIF(CASE WHEN B.P2 > 0 THEN UPPER(TRIM(SUBSTRING(T1.EESS_SA, B.P2 + 3, 150)))
                                                       ELSE UPPER(TRIM(T1.EESS_SA)) END, ''), 'SIN DATO') AS VARCHAR(150))         AS NombreEESS
                             , CAST(ISNULL(NULLIF(CASE WHEN A.P1 > 0 THEN UPPER(TRIM(LEFT(T1.EESS_SA, A.P1 - 1))) END, ''), 'SIN DATO') AS VARCHAR(10)) AS CategoriaEESS
                             , CAST(ISNULL(NULLIF(UPPER(TRIM(T1.DIRESA_SA)), ''), 'SIN DATO')    AS VARCHAR(100))  AS Diresa
                             , CAST(ISNULL(NULLIF(UPPER(TRIM(T1.RED_SA)), ''), 'SIN DATO')       AS VARCHAR(100))  AS Red
                             , CAST(ISNULL(NULLIF(UPPER(TRIM(T1.MICRORED_SA)), ''), 'SIN DATO')  AS VARCHAR(100))  AS Microred
                             , CAST(ISNULL(NULLIF(UPPER(TRIM(T1.DPTO_EESS_SA)), ''), 'SIN DATO') AS VARCHAR(50))   AS Departamento
                             , CAST(ISNULL(NULLIF(UPPER(TRIM(T1.PROV_EESS_SA)), ''), 'SIN DATO') AS VARCHAR(80))   AS Provincia
                             , CAST(ISNULL(NULLIF(UPPER(TRIM(T1.DIST_EESS_SA)), ''), 'SIN DATO') AS VARCHAR(80))   AS Distrito
                        FROM SA_PERU T1
                        CROSS APPLY (SELECT CHARINDEX(' - ', T1.EESS_SA) AS P1) A
                        CROSS APPLY (SELECT CASE WHEN A.P1 > 0 THEN CHARINDEX(' - ', T1.EESS_SA, A.P1 + 3) ELSE 0 END AS P2) B
                        WHERE dbo.fn_Num(T1.RENIPRESS_SA) > 0
                    ) T1
                GROUP BY T1.CodRenipress, T1.NombreEESS, T1.CategoriaEESS, T1.Diresa, T1.Red
                       , T1.Microred, T1.Departamento, T1.Provincia, T1.Distrito
            ) T1
    ) T1
WHERE T1.NRO = 1
) X ORDER BY 1;
SELECT COUNT(*) AS sin_formato_eess FROM SA_PERU WHERE CHARINDEX(' - ', EESS_SA) = 0;
EXEC master.sys.sp_enum_oledb_providers;
