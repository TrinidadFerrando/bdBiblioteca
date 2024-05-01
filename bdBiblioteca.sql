/*Creación de bd*/
CREATE SCHEMA bdBiblioteca;
USE bdBiblioteca;

/*Creación de tablas*/
CREATE TABLE Socios (
    DNI VARCHAR(20) PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    Apellido VARCHAR(100) NOT NULL,
    FechaNacimiento DATE NOT NULL,
    Direccion VARCHAR(200),
    Telefono VARCHAR(20),
    FechaAlta DATE NOT NULL,
    EstadoSuscripcion ENUM('Activa', 'Desactiva') NOT NULL
);

CREATE TABLE Libros (
    IDLibro INT AUTO_INCREMENT PRIMARY KEY,
    Titulo VARCHAR(255) NOT NULL,
    Autor VARCHAR(100) NOT NULL,
    Genero VARCHAR(50),
    AnioPublicacion YEAR
);

CREATE TABLE Prestamos (
    IDPrestamo INT AUTO_INCREMENT PRIMARY KEY,
    DNI VARCHAR(20),
    IDLibro INT,
    FechaRetiro DATE NOT NULL,
    FechaDevolucion DATE NOT NULL,
    Estado ENUM('Pendiente', 'Devuelto', 'Vencido') NOT NULL,
    FOREIGN KEY (DNI) REFERENCES Socios(DNI),
    FOREIGN KEY (IDLibro) REFERENCES Libros(IDLibro)
);


/*Insercción de datos en las tablas*/
INSERT INTO Socios (DNI, Nombre, Apellido, FechaNacimiento, Direccion, Telefono, FechaAlta, EstadoSuscripcion) VALUES
('33445566', 'Juan', 'Perez', '1988-05-15', 'Av Siempreviva 555', '011-1567899879', '2015-05-15', 'Activa'),
('34347788', 'Carlos', 'Calabresa', '1987-05-27', 'Av Cordoba 123', '011-1564566549', '2016-06-16', 'Activa'),
('33556677', 'Esteban', 'Quito', '1988-04-24', 'Av del Trabajador 1122', '011-1561233219', '2014-04-14', 'Desactiva'),
('33445588', 'Andrea', 'Lira', '1989-01-29', 'Bv los Andes 3355', '0342-155398022', '2019-01-11', 'Activa');

INSERT INTO Libros (Titulo, Autor, Genero, AnioPublicacion) VALUES
('El principito', 'Antoine de Saint-Exupery', 'Ciencia Ficción', 2016),
('El Alquimista', 'Paulo Cohelo', 'Novela Narrativa', 1995),
('Einstein, su vida y su universo', 'Walter Isaacson', 'Biografía', 2007),
('Metamorfosis', 'Franz Kafka', 'Terror', 1999),
('El Hobbit', 'J. R. R. Tolkien', 'Ciencia Ficción', 2003),
('El señor de los anillos: La comunidad del anillo', 'J. R. R. Tolkien', 'Ciencia Ficción', 2003),
('Cancion de hielo y fuego vol 1: Juego de tronos', 'George R. R. Martin', 'Ciencia Ficción', 2019);

INSERT INTO Prestamos (DNI, IDLibro, FechaRetiro, FechaDevolucion, Estado) VALUES
('33445566', 1, '2022-05-05', '2022-05-20', 'Devuelto'),
('33445566', 5, '2022-05-15', '2022-06-01', 'Devuelto'),
('33445588', 4, '2022-07-01', '2022-07-16', 'Vencido'),
('34347788', 2, '2022-07-10', '2022-07-25', 'Pendiente');


/*Consultas*/
/*a. Listar dni, nombre y apellido de socios que tengan una suscripción activa*/
SELECT DNI, Nombre, Apellido
FROM Socios
WHERE EstadoSuscripcion = 'Activa';

/*b. Listar dni, nombre, apellido, teléfono, título del libro, fecha de retiro y fecha
de devolución de aquellos préstamos que se hayan vencido.*/
SELECT s.DNI, s.Nombre, s.Apellido, s.Telefono, l.Titulo, p.FechaRetiro, p.FechaDevolucion
FROM Prestamos p
JOIN Socios s ON p.DNI = s.DNI
JOIN Libros l ON p.IDLibro = l.IDLibro
WHERE p.Estado = 'Vencido';

/*c. Listar dni, nombre, apellido, teléfono, título del libro, fecha de retiro y fecha
de devolución de aquellos préstamos que se estén por vencer en el día.*/
SELECT s.DNI, s.Nombre, s.Apellido, s.Telefono, l.Titulo, p.FechaRetiro, p.FechaDevolucion
FROM Prestamos p
JOIN Socios s ON p.DNI = s.DNI
JOIN Libros l ON p.IDLibro = l.IDLibro
WHERE p.FechaDevolucion = CURDATE() AND p.Estado = 'Pendiente';

/*d.Listar título, autor, género, año de la edición de los libros disponibles para
prestar por autor, se debe validar que el libro no se encuentre prestado en
ese momento.*/
SELECT l.Titulo, l.Autor, l.Genero, l.AnioPublicacion
FROM Libros l
LEFT JOIN Prestamos p ON l.IDLibro = p.IDLibro AND p.Estado = 'Pendiente'
WHERE p.IDPrestamo IS NULL
ORDER BY l.Autor;

/*e. Listar título, autor, género y la cantidad de veces que fueron prestados los
libros ordenándolos de manera descendente desde el libro que fue
prestado la mayor cantidad de veces*/
SELECT l.Titulo, l.Autor, l.Genero, COUNT(p.IDPrestamo) AS VecesPrestado
FROM Libros l
LEFT JOIN Prestamos p ON l.IDLibro = p.IDLibro
GROUP BY l.IDLibro
ORDER BY VecesPrestado DESC;

/*f. Mostrar título, nombre, apellido y fecha de devolución para un libro
determinado que se encuentra en préstamo, del que se quiere saber
cuando vuelve a estar disponible para prestar nuevamente.*/
SELECT l.Titulo, s.Nombre, s.Apellido, p.FechaDevolucion
FROM Prestamos p
JOIN Socios s ON p.DNI = s.DNI
JOIN Libros l ON p.IDLibro = l.IDLibro
WHERE l.Titulo like '%El Alquimista%' AND p.Estado = 'Pendiente'; -- aca puse al libro El Alquimista porque es el unico que esta en este estado, pero puede ser cualquiera.


/*FUNCION*/
/*Aclaración: como una función no puede devolver una tabla directamente, va a devolver una cadena delimitada por comas*/
-- Listar libros disponibles por género

/*Creación de la función*/
DELIMITER //
CREATE FUNCTION ListarLibrosDisponiblesPorGenero(generoBuscado VARCHAR(50))
RETURNS VARCHAR(4000)
DETERMINISTIC
BEGIN
    DECLARE libros_disponibles VARCHAR(4000) DEFAULT '';
    DECLARE done INT DEFAULT FALSE;
    DECLARE libro VARCHAR(255);
    DECLARE cur CURSOR FOR 
        SELECT CONCAT(L.IDLibro, ': ', L.Titulo, ' - ', L.Autor)
        FROM Libros L
        WHERE L.Genero = generoBuscado
          AND L.IDLibro NOT IN (
            SELECT P.IDLibro
            FROM Prestamos P
            WHERE P.Estado IN ('Pendiente', 'Vencido')
          );
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN cur;

    read_loop: LOOP
        FETCH cur INTO libro;
        IF done THEN
            LEAVE read_loop;
        END IF;
        IF libros_disponibles = '' THEN
            SET libros_disponibles = libro;
        ELSE
            SET libros_disponibles = CONCAT(libros_disponibles, ', ', libro);
        END IF;
    END LOOP;

    CLOSE cur;
    RETURN libros_disponibles;
END //
DELIMITER ;

/*Uso de la función*/
SELECT ListarLibrosDisponiblesPorGenero('Ciencia Ficción');  -- acá psue ciencia ficción (que tiene 4 dispo) pero puede ir otra como ser Terror
SELECT ListarLibrosDisponiblesPorGenero('Terror');  -- no esta disponible por eso esta vacio  



/*PROCEDIMIENTO*/
-- Procedi para gestionar socios *alta/actualizacion* y consultar pretamos vencidos 

/*Procedimiento para Alta/Actualización de Socios*/
/*Creacion*/
DELIMITER //
CREATE PROCEDURE AltaOActualizarSocio(
    IN p_DNI VARCHAR(20),
    IN p_Nombre VARCHAR(100),
    IN p_Apellido VARCHAR(100),
    IN p_FechaNacimiento DATE,
    IN p_Direccion VARCHAR(200),
    IN p_Telefono VARCHAR(20),
    IN p_FechaAlta DATE,
    IN p_EstadoSuscripcion ENUM('Activa', 'Desactiva')
)
BEGIN
    IF EXISTS (SELECT * FROM Socios WHERE DNI = p_DNI) THEN
        UPDATE Socios
        SET Nombre = p_Nombre,
            Apellido = p_Apellido,
            FechaNacimiento = p_FechaNacimiento,
            Direccion = p_Direccion,
            Telefono = p_Telefono,
            FechaAlta = p_FechaAlta,
            EstadoSuscripcion = p_EstadoSuscripcion
        WHERE DNI = p_DNI;
    ELSE
        INSERT INTO Socios (DNI, Nombre, Apellido, FechaNacimiento, Direccion, Telefono, FechaAlta, EstadoSuscripcion)
        VALUES (p_DNI, p_Nombre, p_Apellido, p_FechaNacimiento, p_Direccion, p_Telefono, p_FechaAlta, p_EstadoSuscripcion);
    END IF;
END //
DELIMITER ;

/*Uso del procedimeinto de Alta/Actualización de Socio */ 
CALL AltaOActualizarSocio('12345678', 'Trinidad', 'Ferrando', '2000-09-19', 'Gorriti', '1234567890', '2022-01-01', 'Activa'); -- Alta de socio por ejemplo


/*Procedimiento para Consultar Socios con Préstamos Vencidos*/
/*Creación*/
DELIMITER //
CREATE PROCEDURE ConsultarSociosConPrestamosVencidos()
BEGIN
    SELECT S.DNI, S.Nombre, S.Apellido, S.Telefono, S.Direccion
    FROM Socios S
    JOIN Prestamos P ON S.DNI = P.DNI
    WHERE P.Estado = 'Vencido';
END //
DELIMITER ;

/*Uso del proci para consultar socios con pretsamos vencidos*/
CALL ConsultarSociosConPrestamosVencidos();

