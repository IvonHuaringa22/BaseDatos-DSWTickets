USE MASTER
GO

IF EXISTS(SELECT * FROM  sys.databases WHERE name='tienda_ticketsGP3')
	DROP DATABASE tienda_ticketsGP3
GO
CREATE DATABASE tienda_ticketsGP3
GO

USE tienda_ticketsGP3
GO

-- creacion de tablas ----

CREATE TABLE Usuarios (
    IdUsuario INT PRIMARY KEY IDENTITY,
    Nombre NVARCHAR(100),
    Correo NVARCHAR(100) UNIQUE,
    Contraseña NVARCHAR(100),
    TipoUsuario NVARCHAR(20) -- 'Cliente' o 'Administrador'
);

CREATE TABLE Eventos (
    IdEvento INT PRIMARY KEY IDENTITY,
    NombreEvento NVARCHAR(150),
    TipoEvento NVARCHAR(50), -- Concierto, Teatro, Carrera, etc.
    Lugar NVARCHAR(200),
    Fecha DATE,
    Hora TIME,
    Descripcion NVARCHAR(MAX)
);

CREATE TABLE Zonas (
    IdZona INT PRIMARY KEY IDENTITY,
    IdEvento INT FOREIGN KEY REFERENCES Eventos(IdEvento),
    NombreZona NVARCHAR(50), -- VIP, Media, Popular
    Precio DECIMAL(10,2),
    Capacidad INT -- Total de tickets disponibles en esa zona
);

CREATE TABLE Compras (
    IdCompra INT PRIMARY KEY IDENTITY,
    IdUsuario INT FOREIGN KEY REFERENCES Usuarios(IdUsuario),
    FechaCompra DATETIME DEFAULT GETDATE(),
    MetodoPago NVARCHAR(50), -- Tarjeta, Yape, PayPal, otros
    EstadoPago NVARCHAR(50) -- Pagado, Pendiente, Cancelado
);

CREATE TABLE Tickets (
    IdTicket INT PRIMARY KEY IDENTITY,
    IdCompra INT FOREIGN KEY REFERENCES Compras(IdCompra),
    IdZona INT FOREIGN KEY REFERENCES Zonas(IdZona)
);

------ PROCEDIMIENTOS CRUD USUARIO ----------

-- Crear un nuevo usuario
CREATE PROCEDURE RegistrarUsuario
    @Nombre NVARCHAR(100),
    @Correo NVARCHAR(100),
    @Contraseña NVARCHAR(100),
    @TipoUsuario NVARCHAR(20)
AS
BEGIN
    INSERT INTO Usuarios (Nombre, Correo, Contraseña, TipoUsuario)
    VALUES (@Nombre, @Correo, @Contraseña, @TipoUsuario);
END;
GO

-- Leer todos los usuarios
CREATE PROCEDURE ListarUsuarios
AS
BEGIN
    SELECT IdUsuario, Nombre, Correo, Contraseña, TipoUsuario
    FROM Usuarios;
END;
GO

-- Leer un usuario por Id
CREATE PROCEDURE ObtenerUsuario
    @IdUsuario INT
AS
BEGIN
    SELECT IdUsuario, Nombre, Correo, Contraseña, TipoUsuario
    FROM Usuarios
    WHERE IdUsuario = @IdUsuario;
END;
GO

-- Actualizar un usuario
CREATE PROCEDURE ActualizarUsuario
    @IdUsuario INT,
    @Nombre NVARCHAR(100),
    @Correo NVARCHAR(100),
    @Contraseña NVARCHAR(100),
    @TipoUsuario NVARCHAR(20)
AS
BEGIN
    UPDATE Usuarios
    SET Nombre = @Nombre,
        Correo = @Correo,
        Contraseña = @Contraseña,
        TipoUsuario = @TipoUsuario
    WHERE IdUsuario = @IdUsuario;
END;
GO

-- Eliminar un usuario
CREATE PROCEDURE EliminarUsuario
    @IdUsuario INT
AS
BEGIN
    DELETE FROM Usuarios
    WHERE IdUsuario = @IdUsuario;
END;
GO

-------------PROCEDIMIENTOS EVENTOS-------------------

CREATE PROCEDURE RegistrarEvento
    @NombreEvento NVARCHAR(150),
    @TipoEvento NVARCHAR(50),
    @Lugar NVARCHAR(200),
    @Fecha DATE,
    @Hora TIME,
    @Descripcion NVARCHAR(MAX)
AS
BEGIN
    INSERT INTO Eventos (NombreEvento, TipoEvento, Lugar, Fecha, Hora, Descripcion)
    VALUES (@NombreEvento, @TipoEvento, @Lugar, @Fecha, @Hora, @Descripcion);
END;
GO

CREATE PROCEDURE ListarEventos
AS
BEGIN
    SELECT 
        e.IdEvento,
        e.NombreEvento,
        e.TipoEvento,
        e.Lugar,
        e.Fecha,
        e.Hora,
        e.Descripcion,
        z.IdZona,
        z.NombreZona,
        z.Precio,
        z.Capacidad
    FROM Eventos e
    LEFT JOIN Zonas z ON e.IdEvento = z.IdEvento
    ORDER BY e.Fecha, e.Hora;
END;
GO

CREATE PROCEDURE BuscarEventoPorId
    @IdEvento INT
AS
BEGIN
    SELECT * FROM Eventos WHERE IdEvento = @IdEvento
END
GO

CREATE PROCEDURE EditarEvento
    @IdEvento INT,
    @NombreEvento NVARCHAR(100),
    @TipoEvento NVARCHAR(50),
    @Lugar NVARCHAR(100),
    @Fecha DATE,
    @Hora TIME,
    @Descripcion NVARCHAR(500)
AS
BEGIN
    UPDATE Eventos
    SET NombreEvento = @NombreEvento,
        TipoEvento = @TipoEvento,
        Lugar = @Lugar,
        Fecha = @Fecha,
        Hora = @Hora,
        Descripcion = @Descripcion
    WHERE IdEvento = @IdEvento
END
GO

CREATE PROCEDURE EliminarEvento
    @IdEvento INT
AS
BEGIN
    DELETE FROM Eventos WHERE IdEvento = @IdEvento
END
GO

CREATE PROCEDURE InsertarZona
    @IdEvento INT,
    @NombreZona NVARCHAR(50),
    @Precio DECIMAL(10,2),
    @Capacidad INT
AS
BEGIN
    INSERT INTO Zonas (IdEvento, NombreZona, Precio, Capacidad)
    VALUES (@IdEvento, @NombreZona, @Precio, @Capacidad);
END;
GO

-------------PROCEDIMIENTOS otros-------------------

CREATE PROCEDURE RegistrarCompra
    @IdUsuario INT,
    @MetodoPago NVARCHAR(50),
    @EstadoPago NVARCHAR(50),
    @IdCompra INT OUTPUT
AS
BEGIN
    INSERT INTO Compras (IdUsuario, MetodoPago, EstadoPago)
    VALUES (@IdUsuario, @MetodoPago, @EstadoPago);

    SET @IdCompra = SCOPE_IDENTITY();
END;
GO

CREATE PROCEDURE InsertarTicket
    @IdCompra INT,
    @IdZona INT
AS
BEGIN
    INSERT INTO Tickets (IdCompra, IdZona)
    VALUES (@IdCompra, @IdZona);
END;
GO

-- Insertar usuarios y otros
EXEC RegistrarUsuario 'Sayuri Huaringa', 'sayuri@gmail.com', '$2a$12$bBz7St.uYNbY3UUkF9MbG.zzJWklmlz/w6wFxswEbddwxfLPPGIFG', 'Cliente';
EXEC RegistrarUsuario 'Carlos Admin', 'admin@email.com', 'admin123', 'Administrador';
EXEC RegistrarUsuario 'Ivon Huaringa', 'ivonhuaringa@gmail.com', '$2a$12$r0iMhShyg.sT2x8TB59rauSGDDTsy2BrKW2RhIWYR2Ash8qTRK1ce', 'Administrador';

UPDATE Usuarios
SET Contraseña = '$2a$12$bBz7St.uYNbY3UUkF9MbG.zzJWklmlz/w6wFxswEbddwxfLPPGIFG'
WHERE Correo = 'ana@email.com';

-- Insertar evento
EXEC InsertarEvento 'Concierto de Rock', 'Concierto', 'Estadio Nacional', '2025-07-10', '20:00', 'Grupo Rio';

-- Insertar zonas para el evento (IdEvento = 1)
EXEC InsertarZona 1, 'VIP', 200.00, 50;
EXEC InsertarZona 1, 'Media', 120.00, 100;
EXEC InsertarZona 1, 'Popular', 60.00, 200;

-- Registrar compra
DECLARE @IdCompra INT;
EXEC RegistrarCompra 1, 'Tarjeta', 'Pagado', @IdCompra OUTPUT;

-- Insertar tickets (ejemplo de tickets para zona VIP)
EXEC InsertarTicket @IdCompra, 1;
EXEC InsertarTicket @IdCompra, 1;
GO

-- Insertar eventos
INSERT INTO Eventos (NombreEvento, TipoEvento, Lugar, Fecha, Hora, Descripcion) VALUES
('Concierto de Rock', 'Concierto', 'Estadio Nacional', '2025-06-15', '19:30:00', 'Una noche llena de rock y energía.'),
('Obra de Teatro Clásica', 'Teatro', 'Teatro Municipal', '2025-07-10', '18:00:00', 'Presentación de una obra clásica con actores reconocidos.'),
('Maratón Ciudad', 'Carrera', 'Parque Central', '2025-08-20', '07:00:00', 'Evento de maratón en el centro de la ciudad.'),
('Festival de Jazz', 'Concierto', 'Plaza Mayor', '2025-09-05', '20:00:00', 'Músicos de renombre en una noche de jazz imperdible.');

-- Insertar zonas para cada evento
INSERT INTO Zonas (IdEvento, NombreZona, Precio, Capacidad) VALUES
(1, 'VIP', 150.00, 500), -- Concierto de Rock
(1, 'General', 80.00, 2000),
(2, 'Preferencial', 120.00, 300), -- Obra de Teatro Clásica
(2, 'General', 60.00, 800),
(3, 'Inscripción Individual', 50.00, 1000), -- Maratón Ciudad
(4, 'VIP', 100.00, 400), -- Festival de Jazz
(4, 'General', 50.00, 1500);


CREATE PROCEDURE ComprarTickets
    @IdUsuario INT,
    @IdZona INT,
    @CantidadTickets INT,
    @MetodoPago NVARCHAR(50),
    @EstadoPago NVARCHAR(50)
AS
BEGIN
    DECLARE @IdEvento INT;
    DECLARE @IdCompra INT;
    DECLARE @TotalTicketsExistentes INT;

    -- Obtener el evento de la zona
    SELECT @IdEvento = IdEvento
    FROM Zonas
    WHERE IdZona = @IdZona;

    -- Contar cuántos tickets ya tiene este usuario en este evento
    SELECT @TotalTicketsExistentes = COUNT(*)
    FROM Tickets t
    INNER JOIN Compras c ON t.IdCompra = c.IdCompra
    INNER JOIN Zonas z ON t.IdZona = z.IdZona
    WHERE c.IdUsuario = @IdUsuario
      AND z.IdEvento = @IdEvento;

    -- Verificar si puede comprar
    IF (@TotalTicketsExistentes + @CantidadTickets) > 5
    BEGIN
        RAISERROR ('No puedes comprar más de 5 tickets por evento.', 16, 1);
        RETURN;
    END;
GO

    -- Registrar la compra
    INSERT INTO Compras (IdUsuario, MetodoPago, EstadoPago)
    VALUES (@IdUsuario, @MetodoPago, @EstadoPago);

    SET @IdCompra = SCOPE_IDENTITY();

    -- Insertar los tickets
    DECLARE @i INT = 1;
    WHILE @i <= @CantidadTickets
    BEGIN
        INSERT INTO Tickets (IdCompra, IdZona)
        VALUES (@IdCompra, @IdZona);

        SET @i = @i + 1;
    END;
GO

EXEC ComprarTickets
    @IdUsuario = 1,
    @IdZona = 1,
    @CantidadTickets = 2,
    @MetodoPago = 'Tarjeta',
    @EstadoPago = 'Pagado';


SELECT 
    u.Nombre AS NombreUsuario,
    e.NombreEvento,
    z.NombreZona,
    COUNT(t.IdTicket) AS CantidadTickets,
    c.MetodoPago,
    c.EstadoPago,
    c.FechaCompra
FROM Compras c
INNER JOIN Usuarios u ON c.IdUsuario = u.IdUsuario
INNER JOIN Tickets t ON c.IdCompra = t.IdCompra
INNER JOIN Zonas z ON t.IdZona = z.IdZona
INNER JOIN Eventos e ON z.IdEvento = e.IdEvento
GROUP BY 
    u.Nombre,
    e.NombreEvento,
    z.NombreZona,
    c.MetodoPago,
    c.EstadoPago,
    c.FechaCompra
ORDER BY 
    c.FechaC
GO

