/*Creacion  de usuarios remotos*/

CREATE USER 'jose.amaro'@'%' IDENTIFIED BY '240726';
CREATE USER 'marco.ramirez'@'%' IDENTIFIED BY 'qwerty123';
CREATE USER 'jorge.garcia'@'%' IDENTIFIED BY '240508';
CREATE USER 'sharely.gonzalez'@'%' IDENTIFIED BY '240639';

/*SUPER USUARIO*/
GRANT ALL PRIVILEGES ON *.* TO 'jose.amaro'@'%' WITH GRANT OPTION;

/*creacion de roles para los usuarios de la plataforma de ecommerce*/
CREATE ROLE 'admin';
CREATE ROLE 'seller';
CREATE ROLE 'buyer';
CREATE ROLE 'common_user';
CREATE ROLE 'user_not_registered';
CREATE ROLE 'support';

/*ASIGNACION DE PRIVILEGIOS*/
-- ADMIN
GRANT ALL PRIVILEGES ON respaldo_db_test.* TO 'admin';

-- SUPPORT
GRANT SELECT, INSERT, UPDATE ON respaldo_db_test.tb_users TO 'support';

/*ASIGNAR EL ROL AL USUARIO*/
GRANT 'admin' TO 'marco.ramirez'@'%';
GRANT 'support' TO 'jorge.garcia'@'%';