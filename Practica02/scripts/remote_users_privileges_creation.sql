/* ============================================================
   1. CREACIÓN DE USUARIOS
   ============================================================ */
CREATE USER IF NOT EXISTS 'jose.amaro'@'%' IDENTIFIED BY '240726';
CREATE USER IF NOT EXISTS 'marco.ramirez'@'%' IDENTIFIED BY 'qwerty123';
CREATE USER IF NOT EXISTS 'jorge.garcia'@'%' IDENTIFIED BY '240508';
CREATE USER IF NOT EXISTS 'omar.sampayo'@'%' IDENTIFIED BY '240428';
CREATE USER IF NOT EXISTS 'jhosep.escamilla'@'%' IDENTIFIED BY '240687';
CREATE USER IF NOT EXISTS 'uriel.gonzalez'@'%' IDENTIFIED BY '240463';
CREATE USER IF NOT EXISTS 'yhostin.ramirez'@'%' IDENTIFIED BY '240071';

/* ============================================================
   2. CREACIÓN DE ROLES PARA EL SISTEMA E-COMMERCE
   ============================================================ */
CREATE ROLE IF NOT EXISTS 'superadmin';
CREATE ROLE IF NOT EXISTS 'admin';
CREATE ROLE IF NOT EXISTS 'seller';
CREATE ROLE IF NOT EXISTS 'buyer';
CREATE ROLE IF NOT EXISTS 'common';
CREATE ROLE IF NOT EXISTS 'common_user';
CREATE ROLE IF NOT EXISTS 'user_not_registered';
CREATE ROLE IF NOT EXISTS 'support';

/* ============================================================
   3. ASIGNACIÓN DE PRIVILEGIOS A LOS ROLES
   ============================================================ */

/* SUPERADMIN */
GRANT ALL PRIVILEGES ON *.* TO 'superadmin' WITH GRANT OPTION;   

/* ADMIN */
GRANT ALL PRIVILEGES ON db_test.* TO 'admin';
GRANT ALL PRIVILEGES ON respaldo_db_test.* TO 'admin';

/* SUPPORT */
GRANT SELECT, INSERT, UPDATE ON db_test.tb_users TO 'support';
GRANT SELECT, INSERT, UPDATE ON db_test.tb_products TO 'support';
GRANT SELECT, INSERT, UPDATE ON db_test.tb_users TO 'support';

/* SELLER */
GRANT SELECT, INSERT, UPDATE ON db_test.tb_products TO 'seller';

/* ============================================================
   4. ASIGNACIÓN DE PRIVILEGIOS DIRECTOS Y ROLES A USUARIOS
   ============================================================ */

-- Privilegios directos
GRANT ALL PRIVILEGES ON *.* TO 'jose.amaro'@'%' WITH GRANT OPTION;
GRANT SELECT, INSERT, UPDATE, DELETE ON db_test.* TO 'omar.sampayo'@'%';

-- Asignación de Roles
GRANT 'superadmin' TO 'jose.amaro'@'%';
GRANT 'admin' TO 'marco.ramirez'@'%';
GRANT 'support' TO 'jorge.garcia'@'%';
GRANT 'seller' TO 'jhosep.escamilla'@'%';
GRANT 'seller' TO 'yhostin.ramirez'@'%';

/* ============================================================
   5. CONFIGURACIÓN DE ROLES POR DEFECTO
   ============================================================ */
SET DEFAULT ROLE 'superadmin' TO 'jose.amaro'@'%';
SET DEFAULT ROLE 'admin' TO 'marco.ramirez'@'%';
SET DEFAULT ROLE 'support' TO 'jorge.garcia'@'%';
SET DEFAULT ROLE 'seller' TO 'jhosep.escamilla'@'%';
SET DEFAULT ROLE 'seller' TO 'yhostin.ramirez'@'%';

/* Mensaje final de éxito */
SELECT "Los usuarios y privilegios han sido creados correctamente" AS mensaje;