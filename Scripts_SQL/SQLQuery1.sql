USE DWH_UNICEF;
SET NOCOUNT ON;
SELECT 'Dim_Establecimiento' AS Tabla, COUNT(*) AS Filas, COUNT(DISTINCT CodRenipress) AS Claves, MIN(FechaCarga) AS Carga FROM Dim_Establecimiento
UNION ALL SELECT 'Dim_Tiempo', COUNT(*), COUNT(DISTINCT Fecha), MIN(FechaCarga) FROM Dim_Tiempo
UNION ALL SELECT 'Dim_Geografia', COUNT(*), COUNT(DISTINCT Ubigeo), MIN(FechaCarga) FROM Dim_Geografia
UNION ALL SELECT 'Dim_Paciente', COUNT(*), COUNT(DISTINCT Sexo + '|' + CAST(EdadMeses AS VARCHAR)), MIN(FechaCarga) FROM Dim_Paciente
UNION ALL SELECT 'Dim_DiagnosticoAnemia', COUNT(*), COUNT(DISTINCT Diagnostico), MIN(FechaCarga) FROM Dim_DiagnosticoAnemia
UNION ALL SELECT 'Dim_ProgramaSocial', COUNT(*), COUNT(DISTINCT SIS+Juntos+QaliWarma+Pin), MIN(FechaCarga) FROM Dim_ProgramaSocial
UNION ALL SELECT 'Dim_EstadoNutricional', COUNT(*), COUNT(DISTINCT Categoria), MIN(FechaCarga) FROM Dim_EstadoNutricional
UNION ALL SELECT 'TMP_Establecimiento', COUNT(*), 0, NULL FROM TMP_Establecimiento
UNION ALL SELECT 'TMP_Geografia', COUNT(*), 0, NULL FROM TMP_Geografia
UNION ALL SELECT 'TMP_Paciente', COUNT(*), 0, NULL FROM TMP_Paciente;
SELECT TOP 3 * FROM Dim_Establecimiento ORDER BY IdEstablecimiento;
SELECT * FROM Dim_DiagnosticoAnemia; SELECT * FROM Dim_EstadoNutricional;
SELECT MIN(Fecha) AS Desde, MAX(Fecha) AS Hasta FROM Dim_Tiempo;
