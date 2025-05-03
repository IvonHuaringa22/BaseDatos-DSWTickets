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

CREATE TABLE Clientes (
    IdCliente INT PRIMARY KEY IDENTITY(1,1),
    Nombre NVARCHAR(100),
    DNI NVARCHAR(15),
    Telefono NVARCHAR(20),
    IdUsuario INT FOREIGN KEY REFERENCES Usuarios(IdUsuario)
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
        IdEvento,
        NombreEvento,
        TipoEvento,
        Lugar,
        Fecha,
        Hora,
        Descripcion
    FROM Eventos
    ORDER BY Fecha, Hora;
END;
GO

CREATE PROCEDURE ObtenerEvento
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

-------------PROCEDIMIENTOS COMPRA TICKETS -------------------

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

CREATE PROCEDURE ComprarTickets
    @IdUsuario INT,
    @IdZona INT,
    @CantidadTickets INT,
    @MetodoPago NVARCHAR(50),
    @EstadoPago NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CapacidadDisponible INT;
    DECLARE @IdCompra INT;

    -- Validar capacidad
    SELECT @CapacidadDisponible = Capacidad
    FROM Zonas
    WHERE IdZona = @IdZona;

    IF @CapacidadDisponible < @CantidadTickets
    BEGIN
        RAISERROR('No hay suficientes tickets disponibles.', 16, 1);
        RETURN;
    END

    -- Registrar la compra
    EXEC RegistrarCompra @IdUsuario, @MetodoPago, @EstadoPago, @IdCompra OUTPUT;

    -- Insertar tickets
    DECLARE @Contador INT = 1;
    WHILE @Contador <= @CantidadTickets
    BEGIN
        EXEC InsertarTicket @IdCompra, @IdZona;
        SET @Contador = @Contador + 1;
    END

    -- Actualizar capacidad
    UPDATE Zonas
    SET Capacidad = Capacidad - @CantidadTickets
    WHERE IdZona = @IdZona;
END;
GO


------------------------------- INSERCIONES-----------------------------------

---- Insertar usuarios-----------
EXEC RegistrarUsuario 'Sayuri Huaringa', 'sayuri@gmail.com', '$2a$12$bBz7St.uYNbY3UUkF9MbG.zzJWklmlz/w6wFxswEbddwxfLPPGIFG', 'Cliente';
EXEC RegistrarUsuario 'Carlos Admin', 'admin@email.com', 'admin123', 'Administrador';
EXEC RegistrarUsuario 'Ivon Huaringa', 'ivonhuaringa@gmail.com', '$2a$12$r0iMhShyg.sT2x8TB59rauSGDDTsy2BrKW2RhIWYR2Ash8qTRK1ce', 'Administrador';
EXEC RegistrarUsuario 'Andre Quinteros', 'andre@gmail.com', '$2a$12$bBz7St.uYNbY3UUkF9MbG.zzJWklmlz/w6wFxswEbddwxfLPPGIFG', 'Cliente';
EXEC RegistrarUsuario 'Nilton Flores', 'nilton@gmail.com', '$2a$12$bBz7St.uYNbY3UUkF9MbG.zzJWklmlz/w6wFxswEbddwxfLPPGIFG', 'Cliente';

----Insert Clientes-------
INSERT INTO Clientes (Nombre, DNI, Telefono, IdUsuario) VALUES
('Andre Quinteros', '71234567', '987654321', 8),
('Nilton Flores', '71234567', '987654321', 9),
('Sayuri Huaringa', '71234567', '987654321', 5);

----- Insertar eventos---------
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

-- Registrar compra
DECLARE @IdCompra INT;
EXEC RegistrarCompra 1, 'Tarjeta', 'Pagado', @IdCompra OUTPUT;

-- Insertar tickets (ejemplo de tickets para zona VIP)
EXEC InsertarTicket @IdCompra, 1;
EXEC InsertarTicket @IdCompra, 1;
GO

----------- Consultas y mantenimiento ------------------
SELECT * FROM Usuarios;
SELECT * FROM Clientes;
SELECT * FROM Eventos;
SELECT * FROM Zonas;

SELECT IdEvento, NombreEvento FROM Eventos;
SELECT IdZona, IdEvento, NombreZona FROM Zonas;

-- Reiniciar IDENTITY----
DELETE FROM Zonas;
DBCC CHECKIDENT ('Zonas', RESEED, 0);

DELETE FROM Eventos;
DBCC CHECKIDENT ('Eventos', RESEED, 0);

-- Join de ejemplo
SELECT * FROM Eventos e
JOIN Zonas z ON e.IdEvento = z.IdEvento;
GO

 ------------------


