USE DBBiblioteca;
GO

--========================
-- Función Días de Atraso
--========================

CREATE FUNCTION fn_Dias_Atraso(@IDPrestamo INT)
RETURNS INT
AS BEGIN
	DECLARE @Dias INT;
	DECLARE @FechaEsperada DATE;
	DECLARE @FechaReal DATE;

	SELECT 
		@FechaEsperada = FechaDevolucionEsperada,
		@FechaReal = FechaDevolucionReal
	FROM Prestamos
	WHERE IDPrestamo = @IDPrestamo;

	IF @FechaReal IS NULL
		SET @Dias = 0;

	ELSE IF @FechaReal <= @FechaEsperada
		SET @Dias = 0;

	ELSE 
		SET @Dias = DATEDIFF(DAY, @FechaEsperada, @FechaReal);

	RETURN @Dias;
END
GO