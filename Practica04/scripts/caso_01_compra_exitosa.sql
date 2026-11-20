-- =====================================================================
--  Caso de Prueba 1: "Compra Exitosa, sin modificaciones"
--
--  Se ejecuta por BLOQUES, cada uno en la conexión indicada
--  (en Workbench: una pestaña por usuario). Cada bloque vuelve a buscar
--  sus IDs en las tablas, porque las variables @ no pasan de una
--  conexión a otra. Corre los bloques en orden y no mezcles dos casos.
--
--  Conexiones:  marco.ramirez (rol admin) = el sistema / banco
--               app.web (user_not_registered -> common_user -> buyer) = el usuario
-- =====================================================================


-- ##### BLOQUE 1 · CONEXIÓN: marco.ramirez · Preparación de datos de prueba
-- Pone a la venta 5 productos con stock en 2 vendedores al azar
USE db_test;

DROP TEMPORARY TABLE IF EXISTS tmp_sellers;
CREATE TEMPORARY TABLE tmp_sellers (k INT PRIMARY KEY, seller_ID INT);
INSERT INTO tmp_sellers
SELECT ROW_NUMBER() OVER (), x.ID
FROM (SELECT ID FROM tb_users WHERE status = b'1' ORDER BY RAND() LIMIT 2) x;

INSERT IGNORE INTO tbd_products_users_providers (user_ID, product_ID, type_ownership, status, avalaible_date)
SELECT s.seller_ID, x.ID, 'Owner', b'1', NOW()
FROM (SELECT ID, ROW_NUMBER() OVER () AS rn
      FROM (SELECT p.ID FROM tb_products p
            WHERE p.status = 1 AND p.current_stock >= 5 AND p.current_price > 0
              AND NOT EXISTS (SELECT 1 FROM tbd_products_users_providers pp WHERE pp.product_ID = p.ID)
            ORDER BY RAND() LIMIT 5) r) x
JOIN tmp_sellers s ON s.k = (x.rn % 2) + 1;


-- ##### BLOQUE 2 · CONEXIÓN: app.web · rol user_not_registered · un usuario nuevo se registra
USE db_test;
SET ROLE 'user_not_registered';

-- El visitante revisa productos disponibles (estatus activo y con existencias)
SELECT ID, name, current_price, current_stock, status
FROM tb_products
WHERE status = 1 AND current_stock > 0
ORDER BY RAND() LIMIT 5;

-- Paso 1. Registro con sus datos personales y de cuenta
-- (el procedimiento guarda tb_users y tb_people en una sola transacción
--  y la contraseña se guarda con SHA2)
SET @sufijo := DATE_FORMAT(NOW(), '%Y%m%d%H%i%s');

CALL sp_register_user_person(
    CONCAT('maria.hernandez.', @sufijo, '@example.test'),   -- email (único)
    CONCAT('mhernandez_', @sufijo),                          -- nickname
    'Prueba#2026',                                           -- password
    'Sra.',                                                  -- título de cortesía
    'María Fernanda',                                        -- nombres
    'Hernández Cruz',                                        -- apellidos
    '2001-03-15',                                            -- fecha de nacimiento
    2,                                                       -- género
    'MX',                                                    -- país
    '7641001122'                                             -- teléfono
);

SELECT CURRENT_ROLE() AS rol_activo;


-- ##### BLOQUE 3 · CONEXIÓN: app.web · rol common_user · carrito, orden, domicilio y tarjeta de débito
USE db_test;
SET ROLE 'common_user';

-- Inicia sesión el usuario recién registrado
SELECT u.ID, CONCAT(p.given_names, ' ', p.family_names), p.phone
  INTO @user_id, @user_name, @user_phone
FROM tb_users u
JOIN tb_people p ON p.user_ID = u.ID
WHERE u.ID = (SELECT MAX(ID) FROM tb_users);

START TRANSACTION;

-- Paso 2-3. Selecciona 5 productos disponibles y crea 1 carrito
INSERT INTO tb_carts (user_ID) VALUES (@user_id);
SET @cart_id := LAST_INSERT_ID();

-- Paso 4. Agrega los 5 productos con cantidades diferentes (1, 2, 3, 4 y 5)
INSERT INTO tbd_carts_items (cart_ID, provider_ID, product_ID, quantity)
SELECT @cart_id, x.provider_ID, x.product_ID, x.rn
FROM (SELECT y.product_ID, y.provider_ID, ROW_NUMBER() OVER () AS rn
      FROM (SELECT pp.product_ID, MIN(pp.user_ID) AS provider_ID
            FROM tbd_products_users_providers pp
            JOIN tb_products p ON p.ID = pp.product_ID
            WHERE pp.status = b'1' AND pp.user_ID <> @user_id
              AND p.status = 1 AND p.current_stock >= 5 AND p.current_price > 0
            GROUP BY pp.product_ID
            ORDER BY RAND() LIMIT 5) y) x;

-- Paso 5. Orden de compra (ligada al carrito) + sub-órdenes por vendedor
SELECT SUM(ci.quantity * p.current_price) INTO @total
FROM tbd_carts_items ci JOIN tb_products p ON p.ID = ci.product_ID
WHERE ci.cart_ID = @cart_id;

INSERT INTO tb_orders (user_id, cart_ID, total_amount, status)
VALUES (@user_id, @cart_id, @total, 'Pending');
SET @order_id := LAST_INSERT_ID();

UPDATE tb_carts SET status = b'0' WHERE ID = @cart_id;

INSERT INTO tb_buyer_orders (order_ID, seller_ID, subtotal, shipping_cost, fulfillment_status)
SELECT @order_id, ci.provider_ID, SUM(ci.quantity * p.current_price), 0.00, 'Pending'
FROM tbd_carts_items ci JOIN tb_products p ON p.ID = ci.product_ID
WHERE ci.cart_ID = @cart_id
GROUP BY ci.provider_ID;

INSERT INTO tbd_order_items (buyer_order_ID, product_ID, provider_ID, product_name, quantity, unit_price)
SELECT bo.ID, ci.product_ID, ci.provider_ID, LEFT(p.name, 255), ci.quantity, p.current_price
FROM tbd_carts_items ci
JOIN tb_products p      ON p.ID = ci.product_ID
JOIN tb_buyer_orders bo ON bo.order_ID = @order_id AND bo.seller_ID = ci.provider_ID
WHERE ci.cart_ID = @cart_id;

-- Paso 6. Registra su domicilio para envío
INSERT INTO tb_user_addresses (user_ID, address_label, recipient_name, recipient_phone,
                               delivery_instructions, is_default)
VALUES (@user_id, 'Casa', @user_name, @user_phone,
        'Casa blanca con portón negro, frente a la tienda', 1);
SET @address_id := LAST_INSERT_ID();

INSERT INTO tbd_address_components (address_ID, value, component_type) VALUES
    (@address_id, 'Calle Juárez 27',   'street'),
    (@address_id, 'Centro',            'neighborhood'),
    (@address_id, 'Xicotepec de Juárez', 'city'),
    (@address_id, 'Puebla',            'state'),
    (@address_id, '73080',             'postal_code'),
    (@address_id, 'México',            'country');

UPDATE tb_orders
SET shipping_address = (SELECT GROUP_CONCAT(value ORDER BY ID SEPARATOR ', ')
                        FROM tbd_address_components WHERE address_ID = @address_id)
WHERE ID = @order_id;

-- Paso 7. Método de pago: tarjeta de débito simulada de 16 dígitos
SET @card := CONCAT('4', LPAD(CAST(FLOOR(RAND() * 1000000000000000) AS UNSIGNED), 15, '0'));

INSERT INTO tbd_user_payment_methods (user_ID, payment_method_type_ID, provider,
                                      provider_method_ref, label, last_four, is_default)
VALUES (@user_id,
        (SELECT ID FROM tbc_payment_methods_types WHERE code = 'DEBIT_CARD'),
        'SIMULADOR', CONCAT('SIM-DC-', @card),
        'Débito de prueba CP01', RIGHT(@card, 4), 1);

COMMIT;

SELECT @user_id AS user_ID, @cart_id AS cart_ID, @order_id AS order_ID, @total AS total,
       @card AS tarjeta_simulada, CURRENT_ROLE() AS rol_activo;


-- ##### BLOQUE 4 · CONEXIÓN: app.web · rol buyer · pago único con tarjeta de débito
USE db_test;
SET ROLE 'buyer';     -- al pagar se activa el rol de comprador

SELECT ID, user_id INTO @order_id, @user_id FROM tb_orders ORDER BY ID DESC LIMIT 1;
SELECT MAX(ID) INTO @upm_id FROM tbd_user_payment_methods WHERE user_ID = @user_id;
SELECT ID INTO @pm_debito FROM tbc_payment_methods WHERE name = 'Tarjeta de débito';

-- Pasos 8-9. Registra el pago único; el procedimiento registra la
-- transacción bancaria, la autoriza y deja la orden en Processing
CALL sp_process_payment(@order_id, @upm_id, @pm_debito);

SELECT CURRENT_ROLE() AS rol_activo;


-- ##### BLOQUE 5 · CONEXIÓN: marco.ramirez · el sistema atiende la orden, envía y entrega en casa
USE db_test;

SELECT ID, user_id INTO @order_id, @user_id FROM tb_orders ORDER BY ID DESC LIMIT 1;
SELECT MAX(ID) INTO @address_id FROM tb_user_addresses WHERE user_ID = @user_id;
SET @t0 := NOW();

START TRANSACTION;

-- Paso 10. Orden atendida + inventario
UPDATE tb_buyer_orders SET fulfillment_status = 'Accepted' WHERE order_ID = @order_id;

UPDATE tb_products p
JOIN tbd_order_items oi ON oi.product_ID = p.ID
JOIN tb_buyer_orders bo ON bo.ID = oi.buyer_order_ID
SET p.current_stock = p.current_stock - oi.quantity
WHERE bo.order_ID = @order_id;

UPDATE tb_buyer_orders SET fulfillment_status = 'Preparing' WHERE order_ID = @order_id;

-- Paso 11. Envío (uno por vendedor) y entrega en casa
INSERT INTO tb_shipments (buyer_order_ID, address_ID, carrier, tracking_number, shipment_status,
                          shipped_date, estimated_delivery_date)
SELECT ID, @address_id, 'Estafeta',
       CONCAT('EST', LPAD(CAST(FLOOR(RAND() * 10000000000) AS UNSIGNED), 10, '0')),
       'Shipped', @t0 + INTERVAL 1 DAY, @t0 + INTERVAL 3 DAY
FROM tb_buyer_orders WHERE order_ID = @order_id;

UPDATE tb_buyer_orders SET fulfillment_status = 'Sent' WHERE order_ID = @order_id;
UPDATE tb_orders SET status = 'Shipped' WHERE ID = @order_id;

UPDATE tb_shipments s JOIN tb_buyer_orders bo ON bo.ID = s.buyer_order_ID
SET s.shipment_status = 'Delivered', s.delivered_date = @t0 + INTERVAL 2 DAY
WHERE bo.order_ID = @order_id;

UPDATE tb_buyer_orders SET fulfillment_status = 'Delivered' WHERE order_ID = @order_id;
UPDATE tb_orders SET status = 'Delivered' WHERE ID = @order_id;

COMMIT;

-- Verificación
SELECT u.ID AS user_ID, u.email, u.nickname, CONCAT(p.given_names, ' ', p.family_names) AS nombre
FROM tb_users u JOIN tb_people p ON p.user_ID = u.ID WHERE u.ID = @user_id;

SELECT o.ID, o.user_id, o.cart_ID, o.total_amount, o.status, o.shipping_address
FROM tb_orders o WHERE o.ID = @order_id;

SELECT bo.seller_ID, oi.product_name, oi.quantity, oi.unit_price, oi.subtotal
FROM tb_buyer_orders bo JOIN tbd_order_items oi ON oi.buyer_order_ID = bo.ID
WHERE bo.order_ID = @order_id ORDER BY oi.quantity;

SELECT p.ID, p.amount, p.payment_status, t.transaction_status, t.response_message
FROM tb_payments p JOIN tb_payment_transaction t ON t.payment_ID = p.ID
WHERE p.order_id = @order_id;

SELECT s.ID, s.buyer_order_ID, s.tracking_number, s.shipment_status, s.delivered_date
FROM tb_shipments s JOIN tb_buyer_orders bo ON bo.ID = s.buyer_order_ID
WHERE bo.order_ID = @order_id;
