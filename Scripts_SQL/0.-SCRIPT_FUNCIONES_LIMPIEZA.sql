/*-------------------------------------------*/
-- FUNCIONES DE LIMPIEZA (ejecutar primero)
/*-------------------------------------------*/
-- Texto con coma decimal -> número. '#NULL!', '#¡NULO!' y '' -> NULL
CREATE OR ALTER FUNCTION dbo.fn_Num (@txt VARCHAR(500))
RETURNS DECIMAL(12,4)
AS
BEGIN
    RETURN TRY_CAST(REPLACE(TRIM(@txt), ',', '.') AS DECIMAL(12,4));
END;
GO

-- '01-ago-22' -> 2022-08-01. Error o vacío -> NULL
CREATE OR ALTER FUNCTION dbo.fn_FechaES (@txt VARCHAR(500))
RETURNS DATE
AS
BEGIN
    DECLARE @d INT        = TRY_CAST(PARSENAME(REPLACE(TRIM(@txt), '-', '.'), 3) AS INT);
    DECLARE @m VARCHAR(3) = UPPER(PARSENAME(REPLACE(TRIM(@txt), '-', '.'), 2));
    DECLARE @a INT        = TRY_CAST(PARSENAME(REPLACE(TRIM(@txt), '-', '.'), 1) AS INT);

    SET @m = REPLACE(@m, 'SET', 'SEP');
    DECLARE @mes INT = (CHARINDEX(@m, 'ENEFEBMARABRMAYJUNJULAGOSEPOCTNOVDIC') + 2) / 3;

    IF @d IS NULL OR @a IS NULL OR @mes = 0 RETURN NULL;
    SET @a = CASE WHEN @a < 50 THEN 2000 + @a ELSE 1900 + @a END;

    RETURN TRY_CAST(CONCAT(@a, '-', @mes, '-', @d) AS DATE);
END;
GO
