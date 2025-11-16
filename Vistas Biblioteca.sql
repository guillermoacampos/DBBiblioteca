USE DBBiblioteca;
GO

-========================================================
--Vista: Vista_Libros_Catalogo
--Descripción: 
--Esta vista muestra información detallada de los libros 
--del catálogo de la biblioteca. Incluye su ISBN, título,
--fecha de publicación, cantidad total de ejemplares,
--ejemplares disponible y sus respectivos autores.
--=======================================================

CREATE VIEW Vista_Libros_Catalogo
AS SELECT
	l.IDLibro,
	l.ISBN,
	l.Titulo,
	STRING_AGG(a.NombreAutor, ', ') AS [Autores],
	l.FechaPublicacion,
	l.EjemplaresTotales,
	l.EjemplaresDisponibles
FROM Libros l
INNER JOIN LibrosAutores la
	ON l.IDLibro = la.IDLibro
INNER JOIN Autores a
	ON la.IDAutor = a.IDAutor
GROUP BY l.IDLibro, l.ISBN, l.Titulo, l.FechaPublicacion, l.EjemplaresTotales, l.EjemplaresDisponibles;

GO



-================================================================
--Vista: Vista_Prestamos_Vigentes
--Descripción: 
--Esta vista muestra un listado de los prestamos activos, 
--e incluye ID del Prestamo, Nombre del socio, Título del 
--libro, la Fecha del Prestamo y la Fecha de Devolucion Esperada.
--===============================================================

CREATE VIEW Vista_Prestamos_Vigentes
AS SELECT
	p.IDPrestamo,
	s.Nombre,
	l.Titulo,
	p.FechaPrestamo,
	p.FechaDevolucionEsperada
FROM Prestamos p
INNER JOIN Socios s
	ON p.IDSocio = s.IDSocio
INNER JOIN Libros l
	ON p.IDLibro = l.IDLibro
WHERE p.FechaDevolucionReal IS NULL;

GO



-================================================================
--Vista: Vista_Multas
--Descripción: 
--Esta vista muestra un listado con las multas registradas por
--cada socio, incluyendo la cantidad de multas y el monto total.
--Además incluye el ID del socio, el nombre y el apellido.
--===============================================================

CREATE VIEW Vista_Multas
AS SELECT
	s.IDSocio,
	s.Nombre,
	s.Apellido,
	COUNT(m.IDMulta) AS [Cantidad de multas],
	SUM(m.Monto) AS [Monto total]
FROM Multas m
INNER JOIN Prestamos p
	ON m.IDPrestamo = p.IDPrestamo
INNER JOIN Socios s
	ON p.IDSocio = s.IDSocio
GROUP BY s.IDSocio, s.Nombre, s.Apellido;

GO