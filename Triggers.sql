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
    SET NOCOUNT ON;

    DECLARE @TasaPorDia MONEY = 1.00;

    -- Recolectar las devoluciones: filas que pasaron de FechaDevolucionReal IS NULL -> NOT NULL
    DECLARE @Devoluciones TABLE (
        IDPrestamo INT,
        IDLibro INT,
        FechaDevolucionEsperada DATE,
        FechaDevolucionReal DATE
    );

    INSERT INTO @Devoluciones (IDPrestamo, IDLibro, FechaDevolucionEsperada, FechaDevolucionReal)
    SELECT i.IDPrestamo, i.IDLibro, i.FechaDevolucionEsperada, i.FechaDevolucionReal
    FROM inserted i
    JOIN deleted d ON d.IDPrestamo = i.IDPrestamo
    WHERE d.FechaDevolucionReal IS NULL
      AND i.FechaDevolucionReal IS NOT NULL;

    -- Si no hay devoluciones, salir
    IF NOT EXISTS (SELECT 1 FROM @Devoluciones)
        RETURN;

    -- 1) Incrementar EjemplaresDisponibles por libro según cantidad de devoluciones
    UPDATE l
    SET l.EjemplaresDisponibles = l.EjemplaresDisponibles + a.CntDevoluciones
    FROM Libros l
    JOIN (
        SELECT IDLibro, COUNT(*) AS CntDevoluciones
        FROM @Devoluciones
        GROUP BY IDLibro
    ) a ON l.IDLibro = a.IDLibro;

    -- 2) Generar multas para devoluciones tardías (inserción segura, evitando duplicados)
    BEGIN TRY
        INSERT INTO Multas (IDPrestamo, Monto, FechaGenerada, Estado)
        SELECT 
            dv.IDPrestamo,
            CAST(DATEDIFF(DAY, dv.FechaDevolucionEsperada, dv.FechaDevolucionReal) * @TasaPorDia AS MONEY) AS Monto,
            dv.FechaDevolucionReal AS FechaGenerada,
            CAST(1 AS BIT) AS Estado
        FROM @Devoluciones dv
        WHERE DATEDIFF(DAY, dv.FechaDevolucionEsperada, dv.FechaDevolucionReal) > 0
          AND NOT EXISTS (
              SELECT 1 FROM Multas m WHERE m.IDPrestamo = dv.IDPrestamo
          );
    END TRY
    BEGIN CATCH
        -- Loguear el error en tabla de debug si existe, si no, imprimir
        DECLARE @err NVARCHAR(4000) = ERROR_MESSAGE();
        IF OBJECT_ID('dbo.DebugTriggerLog') IS NOT NULL
        BEGIN
            INSERT INTO dbo.DebugTriggerLog (TriggerName, ErrorMessage)
            VALUES ('tr_Prestamos_AfterUpdate_Devolucion', @err);
        END
        ELSE
        BEGIN
            PRINT 'TRIGGER ERROR (tr_Prestamos_AfterUpdate_Devolucion): ' + ISNULL(@err,'(sin mensaje)');
        END
        -- NO hacemos ROLLBACK aquí para no deshacer el UPDATE del procedimiento llamador.
    END CATCH;
END;
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
