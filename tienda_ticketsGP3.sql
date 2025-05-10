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

CREATE TABLE Clientes (
    IdCliente INT PRIMARY KEY IDENTITY(1,1),
    Nombre NVARCHAR(100),
    DNI NVARCHAR(15),
    Telefono NVARCHAR(20),
    IdUsuario INT FOREIGN KEY REFERENCES Usuarios(IdUsuario)
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

select * from Clientes

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

CREATE PROCEDURE BuscarEventosPorNombre
    @NombreEvento NVARCHAR(100)
AS
BEGIN
    SELECT * 
    FROM Eventos
    WHERE NombreEvento LIKE '%' + @NombreEvento + '%'
END

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
EXEC RegistrarUsuario 'Ivon Huaringa', 'ivon@gmail.com', '$2a$12$r0iMhShyg.sT2x8TB59rauSGDDTsy2BrKW2RhIWYR2Ash8qTRK1ce', 'Administrador';
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
('Festival de Jazz', 'Concierto', 'Plaza Mayor', '2025-09-05', '20:00:00', 'Músicos de renombre en una noche de jazz imperdible.'),
('Concierto en el Estadio Nacional', 'Concierto', 'Estadio Nacional, Lima, Perú', '2025-06-15', '20:00:00', 'Un evento increíble con artistas internacionales.'),
('Obra de Teatro: La Casa de Papel', 'Teatro', 'Teatro Municipal de Lima', '2025-07-20', '19:30:00', 'Una puesta en escena basada en la famosa serie.'),
('Carrera 10K Lima', 'Carrera', 'Parque Kennedy, Miraflores, Lima, Perú', '2025-08-10', '07:00:00', 'Una emocionante carrera por las principales calles de Miraflores.'),
('Festival de Música Latina', 'Concierto', 'Parque de la Exposición, Lima, Perú', '2025-09-01', '18:00:00', 'Disfruta de los mejores artistas latinos.'),
('Obra de Teatro: Hamlet', 'Teatro', 'Teatro La Plaza, Lima, Perú', '2025-09-25', '20:00:00', 'Una interpretación moderna de la famosa obra de Shakespeare.'),
('Maratón Lima 42K', 'Carrera', 'Circuito de playas, Lima, Perú', '2025-10-05', '06:00:00', 'La maratón más esperada de la ciudad.'),
('Concierto Rock en el Parque de la Reserva', 'Concierto', 'Parque de la Reserva, Lima, Perú', '2025-10-20', '19:00:00', 'Un evento para los amantes del rock en vivo.'),
('Obra de Teatro: El Fantasma de la Ópera', 'Teatro', 'Teatro Municipal de Lima', '2025-11-10', '19:30:00', 'Una adaptación de la famosa obra musical.'),
('Carrera 5K Miraflores', 'Carrera', 'Malecón de Miraflores, Lima, Perú', '2025-11-15', '08:00:00', 'Una carrera de 5K para disfrutar del paisaje de Miraflores.'),
('Festival de Jazz en Lima', 'Concierto', 'Centro de Convenciones, Lima, Perú', '2025-12-01', '17:00:00', 'Vive la experiencia del jazz con músicos internacionales.');

-- Insertar zonas para cada evento
INSERT INTO Zonas (IdEvento, NombreZona, Precio, Capacidad) VALUES
(1, 'VIP', 150.00, 500), -- Concierto de Rock
(1, 'General', 80.00, 2000),
(2, 'Preferencial', 120.00, 300), -- Obra de Teatro Clásica
(2, 'General', 60.00, 800),
(3, 'Inscripción Individual', 50.00, 1000), -- Maratón Ciudad
(4, 'VIP', 100.00, 400), -- Festival de Jazz
(4, 'General', 50.00, 1500),
(5, 'VIP', 300.00, 1000),
(5, 'Media', 150.00, 2000),
(5, 'Popular', 50.00, 3000),
(6, 'VIP', 120.00, 500),
(6, 'Media', 80.00, 800),
(6, 'Popular', 40.00, 1000),
(7, 'VIP', 50.00, 200),
(7, 'Media', 30.00, 500),
(7, 'Popular', 10.00, 1000),
(8, 'VIP', 150.00, 700),
(8, 'Media', 100.00, 1500),
(8, 'Popular', 40.00, 2500),
(9, 'VIP', 200.00, 400),
(9, 'Media', 120.00, 900),
(9, 'Popular', 60.00, 1500),
(10, 'VIP', 60.00, 300),
(10, 'Media', 40.00, 600),
(10, 'Popular', 20.00, 1200),
(11, 'VIP', 250.00, 800),
(11, 'Media', 100.00, 1500),
(11, 'Popular', 70.00, 2500),
(12, 'VIP', 180.00, 600),
(12, 'Media', 120.00, 1000),
(12, 'Popular', 50.00, 1500),
(13, 'VIP', 40.00, 500),
(13, 'Media', 30.00, 800),
(13, 'Popular', 10.00, 2000),
(14, 'VIP', 350.00, 1000),
(14, 'Media', 200.00, 1500),
(14, 'Popular', 100.00, 2500);

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


