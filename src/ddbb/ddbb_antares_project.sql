-- ===============================
-- Antares Project - Secure SQL Dump
-- ===============================


-- Crear base de datos
CREATE DATABASE IF NOT EXISTS ddbb_antares_project;
USE ddbb_antares_project;

-- ===============================
-- Tabla de Usuarios
-- ===============================
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100),
    role ENUM('admin', 'tutor', 'alumno') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ===============================
-- Tabla de Cursos
-- ===============================
CREATE TABLE courses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    duration INT NOT NULL,
    tutor_id INT NOT NULL,
    admin_id INT,
    status ENUM('borrador', 'publicado') DEFAULT 'borrador',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (tutor_id) REFERENCES users(id),
    FOREIGN KEY (admin_id) REFERENCES users(id),
    CONSTRAINT chk_price_positive CHECK (price > 0),
    CONSTRAINT chk_duration_positive CHECK (duration > 0)
);

-- ===============================
-- Tabla de Relación Alumno-Curso
-- ===============================
CREATE TABLE student_courses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    course_id INT NOT NULL,
    payment_status ENUM('pendiente', 'verificado') DEFAULT 'pendiente',
    payment_date TIMESTAMP NULL,
    payment_receipt_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES users(id),
    FOREIGN KEY (course_id) REFERENCES courses(id)
);

-- ===============================
-- Tabla de Pagos
-- ===============================
CREATE TABLE payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    course_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_method ENUM('tarjeta', 'paypal', 'transferencia'),
    receipt_url VARCHAR(255),
    verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES users(id),
    FOREIGN KEY (course_id) REFERENCES courses(id),
    CONSTRAINT chk_amount_positive CHECK (amount > 0)
);

-- ===============================
-- Tabla de Mensajes
-- ===============================
CREATE TABLE messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sender_id INT NOT NULL,
    receiver_id INT NOT NULL,
    subject VARCHAR(100),
    body TEXT NOT NULL,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP NULL,
    FOREIGN KEY (sender_id) REFERENCES users(id),
    FOREIGN KEY (receiver_id) REFERENCES users(id)
);

-- ===============================
-- VIEWS Por Rol
-- ===============================

-- Vista para tutores
CREATE VIEW view_tutor_courses AS
SELECT c.*, u.full_name AS tutor_name
FROM courses c
JOIN users u ON c.tutor_id = u.id
WHERE u.role = 'tutor';

-- Vista para alumnos: cursos en los que está inscrito
CREATE VIEW view_alumno_courses AS
SELECT sc.*, c.title, c.description, c.duration, c.price
FROM student_courses sc
JOIN courses c ON sc.course_id = c.id
JOIN users u ON sc.student_id = u.id
WHERE u.role = 'alumno';

-- Vista para administradores: listado completo de cursos
CREATE VIEW view_admin_courses AS
SELECT c.*, 
       tu.full_name AS tutor_name,
       ad.full_name AS admin_name
FROM courses c
LEFT JOIN users tu ON c.tutor_id = tu.id
LEFT JOIN users ad ON c.admin_id = ad.id;

-- ===============================
-- STORED PROCEDURES
-- ===============================

DELIMITER $$

-- Registrar nuevo curso (solo si es tutor)
CREATE PROCEDURE sp_create_course (
    IN p_title VARCHAR(100),
    IN p_description TEXT,
    IN p_price DECIMAL(10,2),
    IN p_duration INT,
    IN p_tutor_id INT
)
BEGIN
    DECLARE tutor_role ENUM('admin', 'tutor', 'alumno');

    SELECT role INTO tutor_role FROM users WHERE id = p_tutor_id;

    IF tutor_role = 'tutor' THEN
        INSERT INTO courses (title, description, price, duration, tutor_id)
        VALUES (p_title, p_description, p_price, p_duration, p_tutor_id);
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo los tutores
         pueden crear cursos.';
    END IF;
END $$

-- Verificar pago manualmente (solo admin)
CREATE PROCEDURE sp_verify_payment (
    IN p_payment_id INT,
    IN p_admin_id INT
)
BEGIN
    DECLARE admin_role ENUM('admin', 'tutor', 'alumno');

    SELECT role INTO admin_role FROM users WHERE id = p_admin_id;

    IF admin_role = 'admin' THEN
        UPDATE payments
        SET verified = TRUE
        WHERE id = p_payment_id;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No autorizado
         para verificar pagos.';
    END IF;
END $$

DELIMITER ;

-- ===============================
-- TRIGGERS
-- ===============================

DELIMITER $$

-- Sincroniza automáticamente estado del curso del alumno al pagar
CREATE TRIGGER trg_verify_payment
AFTER INSERT ON payments
FOR EACH ROW
BEGIN
    UPDATE student_courses
    SET payment_status = 'verificado',
        payment_date = NEW.created_at,
        payment_receipt_url = NEW.receipt_url
    WHERE student_id = NEW.student_id AND course_id = NEW.course_id;
END$$

DELIMITER ;

-- ===============================
-- FIN DE ARCHIVO
-- ===============================
