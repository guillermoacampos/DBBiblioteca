-- Inserciones de ejemplo para DBBiblioteca
USE DBBiblioteca;
GO

-- Turnos
INSERT INTO Turnos (Descripcion) VALUES
('Mañana'),
('Tarde'),
('Noche');

-- Empleados (IDTurno debe existir)
INSERT INTO Empleados (Nombre, Apellido, IDTurno) VALUES
('Ana', 'Gómez', 1),
('Luis', 'Pérez', 2),
('María', 'Santos', 1),
('Carlos', 'Fernández', 3);

-- Socios
INSERT INTO Socios (Nombre, Apellido, Direccion, Telefono, Email) VALUES
('Laura', 'Martínez', 'Av. Siempre Viva 123', '555-0101', 'laura.m@example.com'),
('Javier', 'Rodríguez', 'Calle Falsa 221', '555-0102', 'javier.r@example.com'),
('Sofía', 'López', 'P.º del Prado 45', '555-0103', 'sofia.l@example.com'),
('Miguel', 'Torres', 'Av. Central 10', '555-0104', 'miguel.t@example.com'),
('Elena', 'García', 'Calle Luna 8', '555-0105', 'elena.g@example.com'),
('Diego', 'Ramírez', 'P.º Verde 77', '555-0106', 'diego.r@example.com'),
('Camila', 'Vega', 'Calle Sol 3', '555-0107', 'camila.v@example.com'),
('Andrés', 'Molina', 'Av. Mar 50', '555-0108', 'andres.m@example.com');

-- Autores
INSERT INTO Autores (NombreAutor) VALUES
('Gabriel García Márquez'),
('J. K. Rowling'),
('George Orwell'),
('Jane Austen'),
('Yuval Noah Harari'),
('Antoine de Saint-Exupéry');

-- Libros (EjemplaresDisponibles inicial, será ajustado luego)
INSERT INTO Libros (ISBN, Titulo, FechaPublicacion, EjemplaresTotales, EjemplaresDisponibles) VALUES
('978-0307389732', 'Cien años de soledad', '1967-06-05', 3, 3),
('978-0747532699', 'Harry Potter y la piedra filosofal', '1997-06-26', 5, 5),
('978-0451524935', '1984', '1949-06-08', 2, 2),
('978-1503290563', 'Orgullo y prejuicio', '1813-01-28', 1, 1),
('978-0062316097', 'Sapiens: De animales a dioses', '2011-02-04', 3, 3),
('978-0156012195', 'El Principito', '1943-04-06', 4, 4);

-- Relación Libros-Autores (varios ejemplos, incluido 1:N y N:M)
INSERT INTO LibrosAutores (IDLibro, IDAutor) VALUES
(1, 1), -- Cien años de soledad - GGM
(2, 2), -- HP - Rowling
(3, 3), -- 1984 - Orwell
(4, 4), -- Orgullo y prejuicio - Austen
(5, 5), -- Sapiens - Harari
(6, 6); -- El Principito - Saint-Exupéry

-- Prestamos
-- Notas de fechas: la fecha actual del sistema es 2025-11-16 (para efectos de pruebas)
-- 1) Devuelto a tiempo
INSERT INTO Prestamos (IDSocio, IDEmpleado, IDLibro, FechaPrestamo, FechaDevolucionEsperada, FechaDevolucionReal) VALUES
(1, 1, 1, '2025-10-01', '2025-10-15', '2025-10-14');

-- 2) Activo y vencido (debe generar multa pendiente)
INSERT INTO Prestamos (IDSocio, IDEmpleado, IDLibro, FechaPrestamo, FechaDevolucionEsperada, FechaDevolucionReal) VALUES
(2, 2, 2, '2025-10-05', '2025-10-19', NULL);

-- 3) Devuelto tarde (multado y pagado)
INSERT INTO Prestamos (IDSocio, IDEmpleado, IDLibro, FechaPrestamo, FechaDevolucionEsperada, FechaDevolucionReal) VALUES
(3, 1, 1, '2025-10-20', '2025-11-03', '2025-11-05');

-- 4) Activo y aún dentro del plazo (no vencido)
INSERT INTO Prestamos (IDSocio, IDEmpleado, IDLibro, FechaPrestamo, FechaDevolucionEsperada, FechaDevolucionReal) VALUES
(4, 3, 5, '2025-11-10', '2025-11-24', NULL);

-- 5) Muy atrasado, no devuelto (multa alta, pendiente)
INSERT INTO Prestamos (IDSocio, IDEmpleado, IDLibro, FechaPrestamo, FechaDevolucionEsperada, FechaDevolucionReal) VALUES
(5, 4, 4, '2025-08-01', '2025-08-15', NULL);

-- 6) Otro préstamo activo sobre Sapiens para reducir disponibilidad
INSERT INTO Prestamos (IDSocio, IDEmpleado, IDLibro, FechaPrestamo, FechaDevolucionEsperada, FechaDevolucionReal) VALUES
(6, 2, 5, '2025-10-28', '2025-11-11', NULL);

-- Multas: asociadas a los préstamos 2 (activo vencido), 3 (devuelto tarde) y 5 (muy atrasado)
-- 1) Préstamo 2: multa pendiente
INSERT INTO Multas (IDPrestamo, Monto, FechaGenerada, Estado) VALUES
(2, 15.00, '2025-11-05', 0);

-- 2) Préstamo 3: multa pagada
INSERT INTO Multas (IDPrestamo, Monto, FechaGenerada, Estado) VALUES
(3, 5.00, '2025-11-06', 1);

-- 3) Préstamo 5: multa mayor, pendiente
INSERT INTO Multas (IDPrestamo, Monto, FechaGenerada, Estado) VALUES
(5, 50.00, '2025-09-01', 0);

-- Ajustar EjemplaresDisponibles automáticamente según préstamos activos (FechaDevolucionReal IS NULL)
UPDATE L
SET EjemplaresDisponibles = L.EjemplaresTotales - ISNULL(P.cnt, 0)
FROM Libros L
LEFT JOIN (
    SELECT IDLibro, COUNT(*) AS cnt
    FROM Prestamos
    WHERE FechaDevolucionReal IS NULL
    GROUP BY IDLibro
) P ON L.IDLibro = P.IDLibro;

-- Comprobaciones (selects de prueba)
--SELECT * FROM Turnos;
--SELECT * FROM Empleados;
--SELECT * FROM Socios;
--SELECT * FROM Autores;
--SELECT * FROM Libros;
--SELECT * FROM LibrosAutores;
--SELECT * FROM Prestamos;
--SELECT * FROM Multas;
--GO