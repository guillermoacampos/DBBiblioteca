USE DBBiblioteca;
GO

--===================
-- Carga de Socios
--===================

CREATE PROCEDURE sp_Agregar_Socio
@Nombre VARCHAR(100),
@Apellido VARCHAR(100),
@Direccion VARCHAR(255),
@Telefono VARCHAR(100), 
@Email VARCHAR(255)
AS BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION

		IF @Nombre IS NULL OR @Nombre = ''
		RAISERROR('El nombre no puede ser nulo ni vacío', 16, 1);

		IF @Apellido IS NULL OR @Apellido = ''
		RAISERROR('El apellido no puede ser nulo ni vacío', 16, 1);

		IF @Direccion IS NULL OR @Direccion = ''
		RAISERROR('La dirección no puede ser nula ni vacío', 16, 1);

		IF @Telefono IS NULL OR @Telefono = ''
		RAISERROR('El teléfono no puede ser nulo ni vacío', 16, 1);

		IF @Email IS NULL OR @Email = ''
		RAISERROR('El email no puede ser nulo ni vacío', 16, 1);

		-------------------------------------------------
        -- VALIDAR DUPLICADOS (EMAIL)
        -------------------------------------------------

		IF EXISTS(SELECT 1 FROM Socios WHERE Email = @Email)
		RAISERROR ('El email ingresado ya existe', 16, 1);

		-------------------------------------------------
        -- VALIDAR FORMATO DE EMAIL
        -------------------------------------------------
		IF @Email NOT LIKE '%@%.%'
		RAISERROR('El formato de email no es válido', 16, 1);

		-------------------------------------------------
        -- INSERCIÓN SI TODO ES CORRECTO
        -------------------------------------------------

		INSERT INTO Socios(Nombre, Apellido, Direccion, Telefono, Email)
		VALUES(@Nombre, @Apellido, @Direccion, @Telefono, @Email);

	COMMIT TRANSACTION
	END TRY

	BEGIN CATCH

		-------------------------------------------------
        -- MANEJO DE ERRORES
        -------------------------------------------------

		ROLLBACK TRANSACTION;
		PRINT 'ERROR AL AGREGAR SOCIO: ' + ERROR_MESSAGE();

	END CATCH
END
GO

--===================
-- Carga de Libros
--===================

CREATE PROCEDURE sp_Agregar_Libro
@ISBN VARCHAR(50),
@Titulo VARCHAR(255),
@FechaPublicacion DATE,
@EjemplaresTotales INT,
@EjemplaresDisponibles INT
AS BEGIN
	SET NOCOUNT ON

	BEGIN TRY
	BEGIN TRANSACTION

		IF @ISBN IS NULL OR @ISBN = ''
		RAISERROR('El ISBN no puede ser nulo ni vacío', 16, 1);

		IF @Titulo IS NULL OR @Titulo = ''
		RAISERROR('El Título no puede ser nulo ni vacío', 16, 1);

		-------------------------------------------------
        -- VALIDAR CANTIDADES
        -------------------------------------------------

		IF @EjemplaresTotales <= 0
		RAISERROR('Los ejemplares totales deben ser mayores que 0', 16, 1);

		IF @EjemplaresDisponibles <= 0
		RAISERROR('Los ejemplares disponibles deben ser mayores que 0', 16, 1);

		-------------------------------------------------
        -- VALIDAR DUPLICADOS (ISBN)
        -------------------------------------------------

		IF EXISTS(SELECT 1 FROM Libros WHERE ISBN = @ISBN)
		RAISERROR ('El ISBN ingresado ya existe', 16, 1);

		-------------------------------------------------
        -- INSERCIÓN SI TODO ES CORRECTO
        -------------------------------------------------

		INSERT INTO Libros(ISBN, Titulo, FechaPublicacion, EjemplaresTotales, EjemplaresDisponibles)
		VALUES(@ISBN, @Titulo, @FechaPublicacion, @EjemplaresTotales, @EjemplaresDisponibles);

	COMMIT TRANSACTION
	END TRY

	BEGIN CATCH

		-------------------------------------------------
        -- MANEJO DE ERRORES
        -------------------------------------------------

		ROLLBACK TRANSACTION;
		PRINT 'ERROR AL AGREGAR LIBRO: ' + ERROR_MESSAGE();

	END CATCH
END
GO



--===================
-- Carga de Prestamos
--===================

CREATE PROCEDURE sp_Agregar_Prestamo
@IDSocio INT,
@IDEmpleado INT,
@IDLibro INT,
@FechaPrestamo DATE,
@FechaDevolucionEsperada DATE
AS BEGIN
	
	SET NOCOUNT ON;

	BEGIN TRY
		BEGIN TRANSACTION

			-------------------------------------------------
			-- VALIDAR EXISTENCIA
			-------------------------------------------------
			IF NOT EXISTS(SELECT 1 FROM Socios WHERE IDSocio = @IDSocio)
			RAISERROR ('El Socio ingresado no existe', 16, 1);

			IF NOT EXISTS(SELECT 1 FROM Empleados WHERE IDEmpleado = @IDEmpleado)
			RAISERROR ('El Empleado ingresado no existe', 16, 1);

			IF NOT EXISTS(SELECT 1 FROM Libros WHERE IDLibro = @IDLibro)
			RAISERROR ('El Libro ingresado no existe', 16, 1);

			-------------------------------------------------
			-- VALIDAR EJEMPLARES DISPONIBLES
			-------------------------------------------------
			DECLARE @EjemplaresDisponibles INT;
			SELECT @EjemplaresDisponibles = EjemplaresDisponibles FROM Libros WHERE IDLibro = @IDLibro 

			IF @EjemplaresDisponibles <= 0
			RAISERROR('No se encuentran ejemplares disponibles para el libro ingresado', 16, 1);

			-------------------------------------------------
			-- VALIDAR FECHAS
			-------------------------------------------------
			IF @FechaPrestamo > @FechaDevolucionEsperada
			RAISERROR('La fecha de préstamo no puede ser posterior a la fecha de devolución esperada', 16, 1);

			-------------------------------------------------
			-- INSERCIÓN SI TODO ES CORRECTO
			-------------------------------------------------
			INSERT INTO Prestamos(IDSocio, IDEmpleado, IDLibro, FechaPrestamo, FechaDevolucionEsperada)
			VALUES(@IDSocio, @IDEmpleado, @IDLibro, @FechaPrestamo, @FechaDevolucionEsperada);


		COMMIT TRANSACTION
	END TRY

	BEGIN CATCH
		
		-------------------------------------------------
        -- MANEJO DE ERRORES
        -------------------------------------------------

		ROLLBACK TRANSACTION;
		PRINT 'ERROR AL AGREGAR PRÉSTAMO: ' + ERROR_MESSAGE();

	END CATCH
END




--====================
-- Carga de Devolución
--====================

CREATE PROCEDURE sp_Agregar_Devolucion
@IDPrestamo INT,
@FechaDevolucionReal DATE
AS BEGIN
	
	SET NOCOUNT ON;
	
	BEGIN TRY
		BEGIN TRANSACTION
			
			-------------------------------------------------
			-- VALIDAR EXISTENCIA DE PRÉSTAMO
			-------------------------------------------------
			IF NOT EXISTS (SELECT 1 FROM Prestamos WHERE IDPrestamo = @IDPrestamo)
			RAISERROR('No existe el préstamo ingresado', 16, 1);

			-------------------------------------------------
			-- VALIDAR QUE NO ESTÉ REGISTRADA LA DEVOLUCIÓN
			-------------------------------------------------
			IF EXISTS (SELECT 1 FROM Prestamos WHERE IDPrestamo = @IDPrestamo AND FechaDevolucionReal IS NOT NULL)
			RAISERROR('Se encuentra registrada la devolución', 16, 1);

			-------------------------------------------------
			-- VALIDAR QUE LA FECHA DE DEVOLUCIÓN SEA VÁLIDA
			-------------------------------------------------
			DECLARE @FechaPrestamo DATE;
			SELECT @FechaPrestamo = FechaPrestamo FROM Prestamos WHERE IDPrestamo = @IDPrestamo;

			IF @FechaDevolucionReal < @FechaPrestamo
			RAISERROR('La fecha de devolución no puede ser anterior a la fecha de préstamo', 16, 1);

			-------------------------------------------------
			-- INGRESAR FECHA DE DEVOLUCIÓN
			-------------------------------------------------

			UPDATE Prestamos
			SET FechaDevolucionReal = @FechaDevolucionReal
			WHERE IDPrestamo = @IDPrestamo;

		COMMIT TRANSACTION
	END TRY

	BEGIN CATCH

		-------------------------------------------------
        -- MANEJO DE ERRORES
        -------------------------------------------------

		ROLLBACK TRANSACTION;
		PRINT 'ERROR AL AGREGAR DEVOLUCIÓN: ' + ERROR_MESSAGE();

	END CATCH
END




-- Procedimiento Almacenado Parametrizado

--=======================================================
-- sp_Reporte_MultasPorSocio
--=======================================================
-- Descripción:
-- Este procedimiento elabora un reporte de las multas
-- registradas para un socio específico, mostrando los
-- datos del socio (ID del socio, Nombre y Apellido), 
-- el ID del préstamo, el ID de la multa, el monto de 
-- cada multa y la fecha de la multa. Además mostrará
-- un resumen con la cantidad total de multas y el monto
-- acumulado.
==========================================================

CREATE PROCEDURE sp_Reporte_MultasPorSocio
@IDSocio INT
AS BEGIN
	SET NOCOUNT ON;

	--=======================
	-- Detalle de cada multa
	--=======================

	SELECT
		s.IDSocio,
		s.Nombre,
		s.Apellido,
		p.IDPrestamo,
		m.IDMulta,
		m.Monto,
		m.FechaGenerada
	FROM Multas m
	INNER JOIN Prestamos p
		ON m.IDPrestamo = p.IDPrestamo
	INNER JOIN Socios s
		ON p.IDSocio = s.IDSocio
	WHERE s.IDSocio = @IDSocio;

	--==================================
	-- Resumen total agrupado por socio
	--==================================

	SELECT
		s.IDSocio,
		s.Nombre,
		s.Apellido,
		COUNT(m.IDMulta) AS [Cantidad de Multas],
		SUM(m.Monto) AS [Monto total]
	FROM Multas m
	INNER JOIN Prestamos p
		ON m.IDPrestamo = p.IDPrestamo
	INNER JOIN Socios s
		ON p.IDSocio = s.IDSocio
	WHERE s.IDSocio = @IDSocio
	GROUP BY s.IDSocio, s.Nombre, s.Apellido;
END