--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*
Nombre de Reporte     : SCRIPT DE DATA PROFILING DE LA TABLA STAGING SA_PERU - BI SALUD Y NUTRICION INFANTIL
Descripcion           : Perfilado de calidad del origen antes de la carga: volumen, completitud, validez de tipos,
                        rangos, dominios, unicidad y consistencia. Cada hallazgo justifica una regla de limpieza del ETL.
Base de Datos         : SQL SERVER (DWH_UNICEF)
Requisito             : dbo.fn_Num y dbo.fn_FechaES creadas (0.-SCRIPT_FUNCIONES_LIMPIEZA.sql)
Nota                  : SA_PERU se cargo desde el CSV con casi todas las columnas como VARCHAR(500); por eso el perfilado
                        revisa si cada texto se puede convertir al tipo que le corresponde.
*/
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
USE DWH_UNICEF;
SET NOCOUNT ON;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*1.- VOLUMEN Y ESTRUCTURA*/
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 1.1 Total de registros
SELECT COUNT(*) AS TotalRegistros FROM SA_PERU;

-- 1.2 Columnas y tipos de la tabla staging
SELECT  C.ORDINAL_POSITION AS Nro
      , C.COLUMN_NAME      AS Columna
      , C.DATA_TYPE        AS Tipo
      , C.CHARACTER_MAXIMUM_LENGTH AS Longitud
FROM INFORMATION_SCHEMA.COLUMNS C
WHERE C.TABLE_NAME = 'SA_PERU'
ORDER BY C.ORDINAL_POSITION;

-- 1.3 Muestra de registros
SELECT TOP 10 T1.* FROM SA_PERU T1;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*2.- COMPLETITUD: NULOS, VACIOS Y MARCAS DE NULO DEL EXCEL (#NULL! / #¡NULO!) POR COLUMNA*/
--   Se arma una consulta por cada columna de SA_PERU con SQL dinamico.
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @sql NVARCHAR(MAX) = N'';
SELECT @sql = @sql + CASE WHEN @sql = N'' THEN N'' ELSE N' UNION ALL ' END
     + N'SELECT ' + CAST(C.ORDINAL_POSITION AS NVARCHAR(5)) + N' AS Nro, ''' + C.COLUMN_NAME + N''' AS Columna'
     + N', SUM(CASE WHEN ' + QUOTENAME(C.COLUMN_NAME) + N' IS NULL THEN 1 ELSE 0 END) AS Nulos'
     + N', SUM(CASE WHEN TRIM(CAST(' + QUOTENAME(C.COLUMN_NAME) + N' AS VARCHAR(500))) = '''' THEN 1 ELSE 0 END) AS Vacios'
     + N', SUM(CASE WHEN TRIM(CAST(' + QUOTENAME(C.COLUMN_NAME) + N' AS VARCHAR(500))) IN (''#NULL!'', ''#¡NULO!'') THEN 1 ELSE 0 END) AS MarcaNulo'
     + N', COUNT(DISTINCT ' + QUOTENAME(C.COLUMN_NAME) + N') AS ValoresDistintos'
     + N' FROM SA_PERU'
FROM INFORMATION_SCHEMA.COLUMNS C
WHERE C.TABLE_NAME = 'SA_PERU'
ORDER BY C.ORDINAL_POSITION;
SET @sql = N'SELECT X.*, CAST(100.0 * (X.Nulos + X.Vacios + X.MarcaNulo) / (SELECT COUNT(*) FROM SA_PERU) AS DECIMAL(5,2)) AS PctFaltante FROM ('
         + @sql + N') X ORDER BY X.Nro;';
EXEC sp_executesql @sql;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*3.- VALIDEZ DE TIPOS: TEXTOS QUE NO SE PUEDEN CONVERTIR A NUMERO O FECHA*/
--   Regla derivada: dbo.fn_Num (coma decimal -> punto) y dbo.fn_FechaES ('01-ago-22' -> 2022-08-01).
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 3.1 Formato real de los textos numericos y de fecha (coma decimal y mes abreviado en espanol)
SELECT TOP 5 T1.PESO_SA, T1.TALLA_SA, T1.HEMOGLOBINA_SA, T1.HBC_SA, T1.FECHAATENCION_SA, T1.FECHAHEMOGLOBINA_SA
FROM SA_PERU T1;

-- 3.2 Valores no vacios que no se convierten
SELECT  SUM(CASE WHEN N.Peso  IS NULL AND F.PesoTxt  NOT IN ('', '#NULL!', '#¡NULO!') THEN 1 ELSE 0 END) AS PesoNoNumerico
      , SUM(CASE WHEN N.Talla IS NULL AND F.TallaTxt NOT IN ('', '#NULL!', '#¡NULO!') THEN 1 ELSE 0 END) AS TallaNoNumerica
      , SUM(CASE WHEN N.Hb    IS NULL AND F.HbTxt    NOT IN ('', '#NULL!', '#¡NULO!') THEN 1 ELSE 0 END) AS HbNoNumerica
      , SUM(CASE WHEN N.FAt   IS NULL THEN 1 ELSE 0 END)                                                   AS FechaAtencionInvalida
      , SUM(CASE WHEN N.FHb   IS NULL AND F.FHbTxt   NOT IN ('', '#NULL!', '#¡NULO!') THEN 1 ELSE 0 END) AS FechaHbNoConvertible
FROM SA_PERU T1
CROSS APPLY (SELECT ISNULL(TRIM(T1.PESO_SA), '') AS PesoTxt, ISNULL(TRIM(T1.TALLA_SA), '') AS TallaTxt
                  , ISNULL(TRIM(T1.HEMOGLOBINA_SA), '') AS HbTxt, ISNULL(TRIM(T1.FECHAHEMOGLOBINA_SA), '') AS FHbTxt) F
CROSS APPLY (SELECT dbo.fn_Num(T1.PESO_SA) AS Peso, dbo.fn_Num(T1.TALLA_SA) AS Talla, dbo.fn_Num(T1.HEMOGLOBINA_SA) AS Hb
                  , dbo.fn_FechaES(T1.FECHAATENCION_SA) AS FAt, dbo.fn_FechaES(T1.FECHAHEMOGLOBINA_SA) AS FHb) N;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*4.- RANGOS: MINIMOS, MAXIMOS Y VALORES FUERA DEL RANGO CLINICO*/
--   Regla derivada: fuera de rango -> NULL en la fact (peso 2-30 kg, talla 45-130 cm, Hb 4-20 g/dL, edad 6-59 meses).
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 'EdadMeses' AS Variable, MIN(V) AS Minimo, MAX(V) AS Maximo, CAST(AVG(V) AS DECIMAL(8,2)) AS Promedio
     , SUM(CASE WHEN V NOT BETWEEN 6 AND 59 THEN 1 ELSE 0 END) AS FueraDeRango, SUM(CASE WHEN V IS NULL THEN 1 ELSE 0 END) AS SinValor
FROM (SELECT dbo.fn_Num(EDADMESES_SA) AS V FROM SA_PERU) X
UNION ALL
SELECT 'Peso (kg)', MIN(V), MAX(V), CAST(AVG(V) AS DECIMAL(8,2))
     , SUM(CASE WHEN V NOT BETWEEN 2 AND 30 THEN 1 ELSE 0 END), SUM(CASE WHEN V IS NULL THEN 1 ELSE 0 END)
FROM (SELECT dbo.fn_Num(PESO_SA) AS V FROM SA_PERU) X
UNION ALL
SELECT 'Talla (cm)', MIN(V), MAX(V), CAST(AVG(V) AS DECIMAL(8,2))
     , SUM(CASE WHEN V NOT BETWEEN 45 AND 130 THEN 1 ELSE 0 END), SUM(CASE WHEN V IS NULL THEN 1 ELSE 0 END)
FROM (SELECT dbo.fn_Num(TALLA_SA) AS V FROM SA_PERU) X
UNION ALL
SELECT 'Hemoglobina (g/dL)', MIN(V), MAX(V), CAST(AVG(V) AS DECIMAL(8,2))
     , SUM(CASE WHEN V NOT BETWEEN 4 AND 20 THEN 1 ELSE 0 END), SUM(CASE WHEN V IS NULL THEN 1 ELSE 0 END)
FROM (SELECT dbo.fn_Num(HEMOGLOBINA_SA) AS V FROM SA_PERU) X
UNION ALL
SELECT 'HBC corregida (g/dL)', MIN(V), MAX(V), CAST(AVG(V) AS DECIMAL(8,2))
     , SUM(CASE WHEN V NOT BETWEEN 4 AND 20 THEN 1 ELSE 0 END), SUM(CASE WHEN V IS NULL THEN 1 ELSE 0 END)
FROM (SELECT dbo.fn_Num(HBC_SA) AS V FROM SA_PERU) X
UNION ALL
SELECT 'Altitud EESS (msnm)', MIN(V), MAX(V), CAST(AVG(V) AS DECIMAL(8,2))
     , SUM(CASE WHEN V NOT BETWEEN 0 AND 5000 THEN 1 ELSE 0 END), SUM(CASE WHEN V IS NULL THEN 1 ELSE 0 END)
FROM (SELECT dbo.fn_Num(ALTURAREN_SA) AS V FROM SA_PERU) X;

-- 4.1 Valores centinela (997, 999) en peso y talla
SELECT 'Peso' AS Variable, dbo.fn_Num(PESO_SA) AS Valor, COUNT(*) AS Registros
FROM SA_PERU WHERE dbo.fn_Num(PESO_SA) >= 900 GROUP BY dbo.fn_Num(PESO_SA)
UNION ALL
SELECT 'Talla', dbo.fn_Num(TALLA_SA), COUNT(*)
FROM SA_PERU WHERE dbo.fn_Num(TALLA_SA) >= 900 GROUP BY dbo.fn_Num(TALLA_SA)
ORDER BY 1, 2;

-- 4.2 Rango de fechas de atencion y de hemoglobina
SELECT  MIN(F.FAt) AS AtencionDesde, MAX(F.FAt) AS AtencionHasta
      , MIN(F.FHb) AS HemoglobinaDesde, MAX(F.FHb) AS HemoglobinaHasta
      , SUM(CASE WHEN F.FHb IS NULL THEN 1 ELSE 0 END)                                         AS FechaHbNula
      , SUM(CASE WHEN F.FHb NOT BETWEEN '2017-01-01' AND '2050-12-31' THEN 1 ELSE 0 END)       AS FechaHbFueraDeRango
FROM SA_PERU T1
CROSS APPLY (SELECT dbo.fn_FechaES(T1.FECHAATENCION_SA) AS FAt, dbo.fn_FechaES(T1.FECHAHEMOGLOBINA_SA) AS FHb) F;

-- 4.3 Atenciones por mes
SELECT FORMAT(dbo.fn_FechaES(FECHAATENCION_SA), 'yyyy-MM') AS Periodo, COUNT(*) AS Atenciones
FROM SA_PERU
GROUP BY FORMAT(dbo.fn_FechaES(FECHAATENCION_SA), 'yyyy-MM')
ORDER BY Periodo;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*5.- DOMINIOS: VALORES PERMITIDOS EN CAMPOS CATEGORICOS*/
--   Regla derivada: textos en mayusculas y sin espacios; banderas 1/0 y 9 = sin dato; sexo fuera de M/F -> 'X'.
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 5.1 Sexo
SELECT ISNULL(SEXO_SA, '(NULL)') AS Sexo, COUNT(*) AS Registros FROM SA_PERU GROUP BY SEXO_SA ORDER BY Registros DESC;

-- 5.2 Diagnostico de anemia
SELECT ISNULL(DX_ANEMIA_SA, '(NULL)') AS Diagnostico, COUNT(*) AS Registros FROM SA_PERU GROUP BY DX_ANEMIA_SA ORDER BY Registros DESC;

-- 5.3 Banderas de programas sociales e intervenciones
SELECT 'SIS' AS Campo, ISNULL(SIS_SA, '(NULL)') AS Valor, COUNT(*) AS Registros FROM SA_PERU GROUP BY SIS_SA
UNION ALL SELECT 'JUNTOS', ISNULL(JUNTOS_SA, '(NULL)'), COUNT(*) FROM SA_PERU GROUP BY JUNTOS_SA
UNION ALL SELECT 'QALIWARMA', ISNULL(QALIWARMA_SA, '(NULL)'), COUNT(*) FROM SA_PERU GROUP BY QALIWARMA_SA
UNION ALL SELECT 'PIN', ISNULL(PIN_SA, '(NULL)'), COUNT(*) FROM SA_PERU GROUP BY PIN_SA
UNION ALL SELECT 'CRED', ISNULL(CRED_SA, '(NULL)'), COUNT(*) FROM SA_PERU GROUP BY CRED_SA
UNION ALL SELECT 'SUPLEMENTACION', ISNULL(SUPLEMENTACION_SA, '(NULL)'), COUNT(*) FROM SA_PERU GROUP BY SUPLEMENTACION_SA
UNION ALL SELECT 'CONSEJERIA', ISNULL(CONSEJERIA_SA, '(NULL)'), COUNT(*) FROM SA_PERU GROUP BY CONSEJERIA_SA
UNION ALL SELECT 'SESION', ISNULL(SESION_SA, '(NULL)'), COUNT(*) FROM SA_PERU GROUP BY SESION_SA
ORDER BY 1, 2;

-- 5.4 Categoria del establecimiento (primer tramo de EESS_SA: 'I-3   - 00002316 - TTIO')
SELECT CASE WHEN CHARINDEX(' - ', EESS_SA) > 0 THEN UPPER(TRIM(LEFT(EESS_SA, CHARINDEX(' - ', EESS_SA) - 1))) ELSE '(SIN CATEGORIA)' END AS Categoria
     , COUNT(*) AS Registros
FROM SA_PERU
GROUP BY CASE WHEN CHARINDEX(' - ', EESS_SA) > 0 THEN UPPER(TRIM(LEFT(EESS_SA, CHARINDEX(' - ', EESS_SA) - 1))) ELSE '(SIN CATEGORIA)' END
ORDER BY Registros DESC;

-- 5.5 DIRESA y redes "sin asignar"
SELECT UPPER(TRIM(DIRESA_SA)) AS Diresa, COUNT(*) AS Registros
     , SUM(CASE WHEN UPPER(RED_SA) LIKE '%SIN RED%' THEN 1 ELSE 0 END) AS SinRedAsignada
FROM SA_PERU
GROUP BY UPPER(TRIM(DIRESA_SA))
ORDER BY Registros DESC;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*6.- UNICIDAD: DUPLICADOS Y CLAVES CON MAS DE UNA VERSION*/
--   Regla derivada: una sola version por clave (la mas frecuente) con ROW_NUMBER() en el origen de cada dimension.
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 6.1 Registros exactamente repetidos (mismos 12 campos de la atencion)
SELECT COUNT(*) AS Registros, COUNT(DISTINCT H.Hash) AS RegistrosDistintos, COUNT(*) - COUNT(DISTINCT H.Hash) AS Repetidos
FROM SA_PERU T1
CROSS APPLY (SELECT HASHBYTES('SHA2_256', CONCAT_WS('|', T1.DIRESA_SA, T1.RENIPRESS_SA, T1.FECHAATENCION_SA, T1.SEXO_SA
                   , T1.EDADMESES_SA, T1.UBIGEOPN_SA, T1.PESO_SA, T1.TALLA_SA, T1.HEMOGLOBINA_SA
                   , T1.FECHAHEMOGLOBINA_SA, T1.HBC_SA, T1.DX_ANEMIA_SA)) AS Hash) H;

-- 6.2 Codigos RENIPRESS con mas de un nombre o ubicacion
SELECT TOP 20 CAST(dbo.fn_Num(RENIPRESS_SA) AS INT) AS Renipress
     , COUNT(DISTINCT UPPER(TRIM(EESS_SA))) AS NombresDistintos
     , COUNT(DISTINCT UPPER(TRIM(RED_SA)))  AS RedesDistintas
     , MIN(EESS_SA) AS Ejemplo1, MAX(EESS_SA) AS Ejemplo2
FROM SA_PERU
GROUP BY CAST(dbo.fn_Num(RENIPRESS_SA) AS INT)
HAVING COUNT(DISTINCT UPPER(TRIM(EESS_SA))) > 1 OR COUNT(DISTINCT UPPER(TRIM(RED_SA))) > 1
ORDER BY NombresDistintos DESC;

-- 6.3 Ubigeos con mas de un nombre de distrito
SELECT TOP 20 RIGHT('000000' + CAST(CAST(dbo.fn_Num(UBIGE0REN_SA) AS INT) AS VARCHAR(6)), 6) AS Ubigeo
     , COUNT(DISTINCT UPPER(TRIM(DISTRITOREN_SA))) AS NombresDistintos
     , MIN(DISTRITOREN_SA) AS Ejemplo1, MAX(DISTRITOREN_SA) AS Ejemplo2
FROM SA_PERU
WHERE dbo.fn_Num(UBIGE0REN_SA) > 0
GROUP BY RIGHT('000000' + CAST(CAST(dbo.fn_Num(UBIGE0REN_SA) AS INT) AS VARCHAR(6)), 6)
HAVING COUNT(DISTINCT UPPER(TRIM(DISTRITOREN_SA))) > 1
ORDER BY NombresDistintos DESC;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*7.- CONSISTENCIA ENTRE CAMPOS*/
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 7.1 Diagnostico de origen vs. diagnostico recalculado con la HBC (umbrales MINSA: <7 severa, <10 moderada, <11 leve)
--     Regla derivada: IndDxInconsistente = 1 en la fact.
SELECT  UPPER(TRIM(T1.DX_ANEMIA_SA)) AS DxOrigen
      , R.DxRecalculado
      , COUNT(*) AS Registros
FROM SA_PERU T1
CROSS APPLY (SELECT CASE WHEN dbo.fn_Num(T1.HBC_SA) IS NULL THEN 'SIN HBC'
                         WHEN dbo.fn_Num(T1.HBC_SA) < 7  THEN 'ANEMIA SEVERA'
                         WHEN dbo.fn_Num(T1.HBC_SA) < 10 THEN 'ANEMIA MODERADA'
                         WHEN dbo.fn_Num(T1.HBC_SA) < 11 THEN 'ANEMIA LEVE'
                         ELSE 'NORMAL' END AS DxRecalculado) R
GROUP BY UPPER(TRIM(T1.DX_ANEMIA_SA)), R.DxRecalculado
ORDER BY CASE WHEN UPPER(TRIM(T1.DX_ANEMIA_SA)) = R.DxRecalculado THEN 0 ELSE 1 END DESC, Registros DESC;

-- 7.2 Hemoglobina observada vs. corregida por altitud (sesgo fisiologico: sin corregir se oculta la anemia)
SELECT  SUM(CASE WHEN dbo.fn_Num(HEMOGLOBINA_SA) < 11 THEN 1 ELSE 0 END) AS HbObservadaMenor11
      , SUM(CASE WHEN dbo.fn_Num(HBC_SA) < 11 THEN 1 ELSE 0 END)         AS HbCorregidaMenor11
      , CAST(AVG(dbo.fn_Num(HEMOGLOBINA_SA) - dbo.fn_Num(HBC_SA)) AS DECIMAL(5,2)) AS AjustePromedio
FROM SA_PERU
WHERE dbo.fn_Num(HEMOGLOBINA_SA) BETWEEN 4 AND 20;

-- 7.3 Momento del dosaje respecto a la atencion (tamizaje oportuno = mismo dia)
SELECT  CASE WHEN F.FHb IS NULL THEN '1. SIN FECHA DE HB'
             WHEN F.FHb = F.FAt THEN '2. MISMO DIA'
             WHEN F.FHb < F.FAt THEN '3. ANTES DE LA ATENCION'
             ELSE '4. DESPUES DE LA ATENCION' END AS Momento
      , COUNT(*) AS Registros
FROM SA_PERU T1
CROSS APPLY (SELECT dbo.fn_FechaES(T1.FECHAATENCION_SA) AS FAt, dbo.fn_FechaES(T1.FECHAHEMOGLOBINA_SA) AS FHb) F
GROUP BY CASE WHEN F.FHb IS NULL THEN '1. SIN FECHA DE HB'
              WHEN F.FHb = F.FAt THEN '2. MISMO DIA'
              WHEN F.FHb < F.FAt THEN '3. ANTES DE LA ATENCION'
              ELSE '4. DESPUES DE LA ATENCION' END
ORDER BY Momento;

-- 7.4 UBIGEO de residencia sin el cero inicial (se guardo como numero: 80106 en vez de 080106)
--     Regla derivada: RIGHT('000000' + ..., 6) para completar a 6 digitos; sin dato -> '000000'.
SELECT  SUM(CASE WHEN LEN(TRIM(UBIGEOPN_SA)) = 5 THEN 1 ELSE 0 END)  AS UbigeoPN_5Digitos
      , SUM(CASE WHEN LEN(TRIM(UBIGEOPN_SA)) = 6 THEN 1 ELSE 0 END)  AS UbigeoPN_6Digitos
      , SUM(CASE WHEN dbo.fn_Num(UBIGEOPN_SA) IS NULL THEN 1 ELSE 0 END) AS UbigeoPN_SinDato
      , SUM(CASE WHEN dbo.fn_Num(UBIGE0REN_SA) IS NULL THEN 1 ELSE 0 END) AS UbigeoREN_SinDato
FROM SA_PERU;

-- 7.5 Comillas sobrantes del CSV en el nombre del establecimiento
SELECT COUNT(*) AS RegistrosConComillas, COUNT(DISTINCT EESS_SA) AS NombresDistintosConComillas
FROM SA_PERU
WHERE EESS_SA LIKE '%"%';
