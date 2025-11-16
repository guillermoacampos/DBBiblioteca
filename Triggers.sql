USE DBBiblioteca;
GO

--========================
-- Triggers
--========================


--====================================================================================================
--   1) Al insertar Prestamos:
--   - Si el prestamo es mayor al stock de ejemplares se realiza un roll back 
--   - Si la cantidad que solicitan es menor al stock, se realiza el prestamo y resta los ejemplares disponibles
--====================================================================================================
CREATE TRIGGER tr_Prestamos_AfterInsert
ON Prestamos
AFTER INSERT
AS
BEGIN
    BEGIN TRY
        -- 1) Buscar si para algún libro en 'inserted' se solicita más de lo disponible
        IF EXISTS (
            SELECT 1 
            FROM (
                SELECT I.IDLibro, COUNT(*) AS Pedidos
                FROM inserted I
                GROUP BY I.IDLibro
            ) AS req
            JOIN Libros L ON L.IDLibro = req.IDLibro
            WHERE req.Pedidos > L.EjemplaresDisponibles
        )
        BEGIN
            RAISERROR('No hay suficientes ejemplares disponibles.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        -- 2) Decrementar EjemplaresDisponibles por cada libro según la cantidad insertada
        UPDATE l
        SET l.EjemplaresDisponibles = l.EjemplaresDisponibles - r.CantidadPrestada
        FROM Libros l
        JOIN (
            SELECT i.IDLibro, COUNT(*) AS CantidadPrestada
            FROM inserted i
            GROUP BY i.IDLibro
        ) AS r ON l.IDLibro = r.IDLibro;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        RETURN;
    END CATCH
END
GO

-- =========================================================
--     2) Al actualizar Prestamos (cuando se registra la devolución):
--     - Detecta filas cuyo FechaDevolucionReal cambia de NULL -> NOT NULL
--     - Incrementa EjemplaresDisponibles por cada devolución
--     - Si la devolución es tardía (FechaDevolucionReal > FechaDevolucionEsperada) inserta una fila en Multas
--       (fórmula de ejemplo: 1.00 (moneda) por día de atraso — puedes cambiar la tasa)
-- ========================================================= 
CREATE TRIGGER tr_Prestamos_AfterUpdate_Devolucion
ON Prestamos
AFTER UPDATE
AS
BEGIN
    BEGIN TRY
        -- Filas que pasaron de sin devolver (deleted.FechaDevolucionReal IS NULL)
        -- a devuelto (inserted.FechaDevolucionReal IS NOT NULL)
        ;WITH Devoluciones AS (
            SELECT i.IDPrestamo, i.IDLibro, i.FechaDevolucionEsperada, i.FechaDevolucionReal
            FROM inserted i
            JOIN deleted d ON d.IDPrestamo = i.IDPrestamo
            WHERE d.FechaDevolucionReal IS NULL AND i.FechaDevolucionReal IS NOT NULL
        )
        -- 1) Incrementar EjemplaresDisponibles por libro según cantidad de devoluciones
        UPDATE l
        SET l.EjemplaresDisponibles = l.EjemplaresDisponibles + d.CntDevoluciones
        FROM Libros l
        JOIN (
            SELECT IDLibro, COUNT(*) AS CntDevoluciones
            FROM Devoluciones
            GROUP BY IDLibro
        ) d ON l.IDLibro = d.IDLibro;

        -- 2) Generar multas para las devoluciones tardías
        DECLARE @TasaPorDia MONEY = 1.00; 
        INSERT INTO Multas (IDPrestamo, Monto, FechaGenerada, Estado)
        SELECT 
            dv.IDPrestamo,
            CAST(DATEDIFF(DAY, dv.FechaDevolucionEsperada, dv.FechaDevolucionReal) * @TasaPorDia AS MONEY) AS Monto,
            dv.FechaDevolucionReal AS FechaGenerada,
            CAST(1 AS BIT) AS Estado
        FROM Devoluciones dv
        WHERE DATEDIFF(DAY, dv.FechaDevolucionEsperada, dv.FechaDevolucionReal) > 0;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        RETURN;
    END CATCH
END
GO

-- =========================================================
--   3) Impedir eliminación de Libros que tengan prestamos activos
-- ========================================================= 
CREATE TRIGGER tr_Libros_PreventDelete_IfActiveLoans
ON Libros
AFTER DELETE
AS
BEGIN
    BEGIN TRY
        IF EXISTS (
            SELECT 1
            FROM deleted d
            JOIN Prestamos p ON p.IDLibro = d.IDLibro
            WHERE p.FechaDevolucionReal IS NULL
        )
        BEGIN
            RAISERROR('No se puede eliminar el/los libro(s): existen préstamos activos asociados.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        RETURN;
    END CATCH
END
GO

 --  =========================================================
 --  4) Impedir eliminación de Socios que tengan prestamos activos
 --  ========================================================= 
CREATE TRIGGER tr_Socios_PreventDelete_IfActiveLoans
ON Socios
AFTER DELETE
AS
BEGIN
    BEGIN TRY
        IF EXISTS (
            SELECT 1
            FROM deleted d
            JOIN Prestamos p ON p.IDSocio = d.IDSocio
            WHERE p.FechaDevolucionReal IS NULL
        )
        BEGIN
            RAISERROR('No se puede eliminar el/los socio(s): existen préstamos activos asociados.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
    END CATCH
END
GO
