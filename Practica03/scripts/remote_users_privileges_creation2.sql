/* ============================================================
   PRIVILEGIOS POR ROL SOBRE LAS TABLAS DE db_test
   Ejecutar DESPUÉS de remote_users_privileges_creation.sql

   Notas:
   - Los triggers son DEFINER=root, así que NINGÚN rol necesita
     permisos sobre tb_logs: la bitácora se escribe sola.
   - Los procedimientos (sp_*) también son DEFINER=root, así que
     quien los llama solo necesita EXECUTE.
   - tb_users.password nunca se expone: se usan permisos por columna.
   - GRANT/REVOKE surten efecto de inmediato; FLUSH PRIVILEGES no es
     necesario.
   ============================================================ */


/* ============================================================
   0. LIMPIEZA DE GRANTS ANTERIORES QUE SE REEMPLAZAN
      (ejecutar una sola vez; si un grant ya no existe, MySQL
       marca error 1141 y basta con omitir esa línea)
   ============================================================ */

-- 'support' tenía acceso total a tb_users (incluye password y DELETE físico)
REVOKE SELECT, INSERT, UPDATE, DELETE ON db_test.tb_users FROM 'support';

-- El EXECUTE se mueve al rol (antes estaba directo a jorge.garcia)
REVOKE EXECUTE ON PROCEDURE db_test.sp_soft_delete_user FROM 'jorge.garcia'@'%';

-- 'user_not_registered' ya no inserta directo: usa sp_register_user_person
-- (así la contraseña siempre pasa por SHA2 y tb_users/tb_people se llenan
--  en una sola transacción)
REVOKE INSERT ON db_test.tb_people FROM 'user_not_registered';
REVOKE INSERT ON db_test.tb_users  FROM 'user_not_registered';


/* ============================================================
   1. USER_NOT_REGISTERED (visitante / registro)
   ============================================================ */
GRANT EXECUTE ON PROCEDURE db_test.sp_register_user_person TO 'user_not_registered';

-- Puede explorar el catálogo
GRANT SELECT ON db_test.tb_products             TO 'user_not_registered';
GRANT SELECT ON db_test.tbc_categories          TO 'user_not_registered';
GRANT SELECT ON db_test.tbd_products_categories TO 'user_not_registered';


/* ============================================================
   2. BUYER (comprador)
   ============================================================ */

-- Catálogo y catálogos de pago (solo lectura)
GRANT SELECT ON db_test.tb_products                  TO 'buyer';
GRANT SELECT ON db_test.tbc_categories               TO 'buyer';
GRANT SELECT ON db_test.tbd_products_categories      TO 'buyer';
GRANT SELECT ON db_test.tbd_products_users_providers TO 'buyer';
GRANT SELECT ON db_test.tbc_payment_methods          TO 'buyer';
GRANT SELECT ON db_test.tbc_payment_methods_types    TO 'buyer';

-- Su cuenta (sin acceso a password)
GRANT SELECT (ID, email, nickname, creation_date, last_login, status)
      ON db_test.tb_users TO 'buyer';
GRANT UPDATE (email, nickname) ON db_test.tb_users TO 'buyer';
GRANT SELECT, UPDATE ON db_test.tb_people TO 'buyer';

-- Direcciones y métodos de pago guardados
GRANT SELECT, INSERT, UPDATE ON db_test.tb_user_addresses         TO 'buyer';
GRANT SELECT, INSERT, UPDATE ON db_test.tbd_address_components    TO 'buyer';
GRANT SELECT, INSERT, UPDATE ON db_test.tbd_user_payment_methods  TO 'buyer';

-- Carrito y lista de deseos
GRANT SELECT, INSERT, UPDATE         ON db_test.tb_carts                    TO 'buyer';
GRANT SELECT, INSERT, UPDATE, DELETE ON db_test.tbd_carts_items             TO 'buyer';  -- no tiene columna status: quitar un item = DELETE
GRANT SELECT, INSERT, UPDATE         ON db_test.tbd_users_wishlist_products TO 'buyer';

-- Compra: orden, sub-órdenes por vendedor, items y pago
GRANT SELECT, INSERT         ON db_test.tb_orders      TO 'buyer';
GRANT SELECT, INSERT, UPDATE ON db_test.tb_buyer_orders TO 'buyer';
GRANT SELECT, INSERT         ON db_test.tbd_order_items TO 'buyer';
GRANT SELECT, INSERT         ON db_test.tb_payments     TO 'buyer';
GRANT SELECT                 ON db_test.tb_payment_transaction TO 'buyer';
GRANT SELECT                 ON db_test.tb_shipments    TO 'buyer';

-- Posventa: puede solicitar cancelaciones y devoluciones, y ver reembolsos
GRANT SELECT, INSERT ON db_test.tb_order_cancellations TO 'buyer';
GRANT SELECT, INSERT ON db_test.tbd_cancellation_items TO 'buyer';
GRANT SELECT, INSERT ON db_test.tb_returns             TO 'buyer';
GRANT SELECT, INSERT ON db_test.tbd_return_items       TO 'buyer';
GRANT SELECT         ON db_test.tb_refunds             TO 'buyer';


/* ============================================================
   3. SELLER (vendedor)
   ============================================================ */

-- Productos (ya tenía tb_products y tbc_categories; se completa el flujo)
GRANT SELECT, INSERT, UPDATE ON db_test.tb_products                  TO 'seller';
GRANT SELECT                 ON db_test.tbc_categories               TO 'seller';
GRANT SELECT, INSERT, UPDATE ON db_test.tbd_products_categories      TO 'seller';
GRANT SELECT, INSERT, UPDATE ON db_test.tbd_products_users_providers TO 'seller';  -- vínculo vendedor-producto

-- Pedidos que le tocan: ve la sub-orden y solo puede cambiar el estado de surtido
GRANT SELECT                          ON db_test.tb_buyer_orders TO 'seller';
GRANT UPDATE (fulfillment_status)     ON db_test.tb_buyer_orders TO 'seller';
GRANT SELECT                          ON db_test.tbd_order_items TO 'seller';
GRANT SELECT, INSERT, UPDATE          ON db_test.tb_shipments    TO 'seller';

-- Cancelaciones y devoluciones de sus ventas (solo lectura)
GRANT SELECT ON db_test.tb_order_cancellations TO 'seller';
GRANT SELECT ON db_test.tbd_cancellation_items TO 'seller';
GRANT SELECT ON db_test.tb_returns             TO 'seller';
GRANT SELECT ON db_test.tbd_return_items       TO 'seller';

-- Opcional: que el vendedor dé de baja productos (ojo: el SP no valida que sea suyo)
-- GRANT EXECUTE ON PROCEDURE db_test.sp_soft_delete_product TO 'seller';


/* ============================================================
   4. SUPPORT (soporte)
   ============================================================ */

-- Usuarios y personas (sin password, sin DELETE físico)
GRANT SELECT (ID, email, nickname, creation_date, last_login, status)
      ON db_test.tb_users TO 'support';
GRANT UPDATE (email, nickname, status) ON db_test.tb_users TO 'support';
GRANT SELECT, UPDATE ON db_test.tb_people              TO 'support';
GRANT SELECT, UPDATE ON db_test.tb_user_addresses      TO 'support';
GRANT SELECT, UPDATE ON db_test.tbd_address_components TO 'support';
GRANT SELECT         ON db_test.tbd_user_payment_methods TO 'support';

GRANT EXECUTE ON PROCEDURE db_test.sp_register_user_person TO 'support';
GRANT EXECUTE ON PROCEDURE db_test.sp_soft_delete_user     TO 'support';
GRANT EXECUTE ON PROCEDURE db_test.sp_soft_delete_product  TO 'support';

-- Catálogo (se conservan los grants originales)
GRANT SELECT, INSERT, UPDATE ON db_test.tb_products             TO 'support';
GRANT SELECT, INSERT, UPDATE ON db_test.tbc_categories          TO 'support';
GRANT SELECT, INSERT, UPDATE ON db_test.tbd_products_categories TO 'support';
GRANT SELECT                 ON db_test.tbd_products_users_providers TO 'support';
GRANT SELECT                 ON db_test.tbc_payment_methods       TO 'support';
GRANT SELECT                 ON db_test.tbc_payment_methods_types TO 'support';

-- Pedidos, pagos y envíos (consulta; puede actualizar el envío)
GRANT SELECT         ON db_test.tb_orders              TO 'support';
GRANT SELECT         ON db_test.tb_buyer_orders        TO 'support';
GRANT SELECT         ON db_test.tbd_order_items        TO 'support';
GRANT SELECT         ON db_test.tb_payments            TO 'support';
GRANT SELECT         ON db_test.tb_payment_transaction TO 'support';
GRANT SELECT, UPDATE ON db_test.tb_shipments           TO 'support';

-- Posventa: gestiona estados de cancelaciones y devoluciones; reembolsos solo lectura
GRANT SELECT, UPDATE ON db_test.tb_order_cancellations TO 'support';
GRANT SELECT, UPDATE ON db_test.tbd_cancellation_items TO 'support';
GRANT SELECT, UPDATE ON db_test.tb_returns             TO 'support';
GRANT SELECT, UPDATE ON db_test.tbd_return_items       TO 'support';
GRANT SELECT         ON db_test.tb_refunds             TO 'support';

-- Carritos y wishlist (solo para atender dudas)
GRANT SELECT ON db_test.tb_carts                    TO 'support';
GRANT SELECT ON db_test.tbd_carts_items             TO 'support';
GRANT SELECT ON db_test.tbd_users_wishlist_products TO 'support';


/* ============================================================
   5. SUPERADMIN y ADMIN
      Sin cambios: superadmin = ALL en *.* ; admin = ALL en
      db_test.* y respaldo_db_test.* (incluye tb_logs y las vistas
      vw_trazabilidad_*).
   ============================================================ */


/* ============================================================
   6. CORRECCIONES EN USUARIOS
   ============================================================ */

-- eduardo.amaro tenía el rol 'support' pero sin rol por defecto:
-- al conectarse el rol NO estaba activo y no tenía permisos.
SET DEFAULT ROLE 'support' TO 'eduardo.amaro'@'%';

-- Cuentas de las apps: ahora tienen 3 roles (user_not_registered, common_user, buyer).
-- Un rol otorgado con GRANT no se activa al conectarse si no está en el rol por
-- defecto. Este bloque debe ejecutarse DESPUÉS de la sección 5 de tu script de
-- usuarios (o actualiza esa sección), porque el último SET DEFAULT ROLE es el que vale.
SET DEFAULT ROLE 'user_not_registered', 'common_user', 'buyer' TO 'app.movil'@'%';
SET DEFAULT ROLE 'user_not_registered', 'common_user', 'buyer' TO 'app.web'@'%';

-- Pendientes (descomenta y ajusta cuando decidas su rol):
-- GRANT 'support' TO 'uriel.gonzalez'@'%';
-- SET DEFAULT ROLE 'support' TO 'uriel.gonzalez'@'%';
--
-- omar.sampayo tiene SELECT/INSERT/UPDATE/DELETE directo en TODO db_test
-- (incluye tb_logs y tb_users.password). Si le toca un rol, reemplaza:
-- REVOKE SELECT, INSERT, UPDATE, DELETE ON db_test.* FROM 'omar.sampayo'@'%';
-- GRANT '<rol>' TO 'omar.sampayo'@'%';
-- SET DEFAULT ROLE '<rol>' TO 'omar.sampayo'@'%';


/* ============================================================
   7. VERIFICACIÓN
   ============================================================ */
-- SHOW GRANTS FOR 'buyer';
-- SHOW GRANTS FOR 'seller';
-- SHOW GRANTS FOR 'support';
-- SHOW GRANTS FOR 'user_not_registered';
-- SHOW GRANTS FOR 'jose.castillo'@'%' USING 'buyer';

SELECT 'Privilegios por rol aplicados correctamente' AS mensaje;
