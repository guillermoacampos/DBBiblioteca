CREATE DATABASE DBBiblioteca
COLLATE Latin1_General_CI_AI;

GO

USE DBBiblioteca;
GO

-- ==============================================
-- TABLAS
-- ==============================================


-- Tabla Socios
CREATE TABLE Socios(
	IDSocio INT PRIMARY KEY IDENTITY(1, 1),
	Nombre VARCHAR(100) NOT NULL,
	Apellido VARCHAR(100) NOT NULL,
	Direccion VARCHAR(255) NOT NULL,
	Telefono VARCHAR(100) NOT NULL,
	Email VARCHAR(255) NOT NULL
);

--Tabla Libros
CREATE TABLE Libros(
	IDLibro INT PRIMARY KEY IDENTITY(1, 1),
	ISBN VARCHAR(50) NOT NULL,
	Titulo VARCHAR(255) NOT NULL,
	FechaPublicacion DATE NOT NULL,
	EjemplaresTotales INT NOT NULL,
	EjemplaresDisponibles INT NOT NULL
);

--Tabla Autores
CREATE TABLE Autores(
	IDAutor INT PRIMARY KEY IDENTITY(1, 1),
	NombreAutor VARCHAR(150) NOT NULL
);

--TABLA LibrosAutores
CREATE TABLE LibrosAutores(
	IDLibro INT NOT NULL,
	IDAutor INT NOT NULL,
	PRIMARY KEY (IDLibro, IDAutor),
	FOREIGN KEY (IDLibro) REFERENCES Libros(IDLibro),
	FOREIGN KEY (IDAutor) REFERENCES Autores(IDAutor)
);

--Tabla Turnos
CREATE TABLE Turnos(
	IDTurno INT PRIMARY KEY IDENTITY(1, 1),
	Descripcion VARCHAR (50) NOT NULL
);

--Tabla Empleados
CREATE TABLE Empleados(
	IDEmpleado INT PRIMARY KEY IDENTITY(1, 1),
	Nombre VARCHAR(100) NOT NULL,
	Apellido VARCHAR(100) NOT NULL,
	IDTurno INT NOT NULL,
	FOREIGN KEY (IDTurno) REFERENCES Turnos(IDTurno)
);

--Tabla Prestamos
CREATE TABLE Prestamos(
	IDPrestamo INT PRIMARY KEY IDENTITY(1, 1),
	IDSocio INT NOT NULL,
	IDEmpleado INT NOT NULL,
	IDLibro INT NOT NULL,
	FechaPrestamo DATE NOT NULL,
	FechaDevolucionEsperada DATE NOT NULL,
	FechaDevolucionReal DATE NULL,
	FOREIGN KEY (IDSocio) REFERENCES Socios(IDSocio),
	FOREIGN KEY (IDEmpleado) REFERENCES Empleados(IDEmpleado),
	FOREIGN KEY (IDLibro) REFERENCES Libros(IDLibro)
);

--Tabla Multas
CREATE TABLE Multas(
	IDMulta INT PRIMARY KEY IDENTITY(1, 1),
	IDPrestamo INT NOT NULL,
	Monto MONEY NOT NULL,
	FechaGenerada DATE NOT NULL,
	Estado BIT NOT NULL,
	FOREIGN KEY (IDPrestamo) REFERENCES Prestamos(IDPrestamo)
);