-- =====================================================================
--  Caso de Prueba 2: "Compra con detalles en el último pago,
--                     con reclamación y reenvío"
--
--  Se ejecuta por BLOQUES, cada uno en la conexión indicada
--  (en Workbench: una pestaña de conexión por usuario).
--  Cada bloque vuelve a buscar sus IDs en las tablas, porque las
--  variables @ no pasan de una conexión a otra.
--  Regla: corre los bloques en orden y no mezcles dos casos a la vez
--  (los bloques toman "la última orden" registrada).
--
--  Conexiones:  marco.ramirez (rol admin)  = el sistema / banco
--               app.web (roles common_user -> buyer) = el usuario
-- =====================================================================


-- ##### BLOQUE 1 · CONEXIÓN: marco.ramirez · Preparación de datos de prueba
-- Da de alta 10 productos con stock en 3 vendedores, para que el
-- comprador tenga de dónde escoger.
USE db_test;

DROP TEMPORARY TABLE IF EXISTS tmp_sellers;
CREATE TEMPORARY TABLE tmp_sellers (k INT PRIMARY KEY, seller_ID INT);
INSERT INTO tmp_sellers
SELECT ROW_NUMBER() OVER (), x.ID
FROM (SELECT ID FROM tb_users WHERE status = b'1' ORDER BY RAND() LIMIT 3) x;

INSERT IGNORE INTO tbd_products_users_providers (user_ID, product_ID, type_ownership, status, avalaible_date)
SELECT s.seller_ID, x.ID, 'Owner', b'1', NOW()
FROM (SELECT ID, ROW_NUMBER() OVER () AS rn
      FROM (SELECT p.ID FROM tb_products p
            WHERE p.status = 1 AND p.current_stock >= 5 AND p.current_price > 0
              AND NOT EXISTS (SELECT 1 FROM tbd_products_users_providers pp WHERE pp.product_ID = p.ID)
            ORDER BY RAND() LIMIT 10) r) x
JOIN tmp_sellers s ON s.k = (x.rn % 3) + 1;


-- ##### BLOQUE 2 · CONEXIÓN: app.web · rol common_user · carrito, orden, domicilio y método de pago
USE db_test;
SET ROLE 'common_user';

-- Paso 1. Inicia sesión un usuario ya registrado (de los 10k), sin carrito previo
SELECT u.ID, CONCAT(p.given_names, ' ', p.family_names), p.phone
  INTO @user_id, @user_name, @user_phone
FROM tb_users u
JOIN tb_people p ON p.user_ID = u.ID
WHERE u.status = b'1'
  AND NOT EXISTS (SELECT 1 FROM tb_carts c WHERE c.user_ID = u.ID)
  AND NOT EXISTS (SELECT 1 FROM tbd_products_users_providers pp WHERE pp.user_ID = u.ID)
ORDER BY RAND() LIMIT 1;

START TRANSACTION;

-- Paso 2. Crea 1 carrito con 10 productos aleatorios (1 a 5 unidades)
INSERT INTO tb_carts (user_ID) VALUES (@user_id);
SET @cart_id := LAST_INSERT_ID();

INSERT INTO tbd_carts_items (cart_ID, provider_ID, product_ID, quantity)
SELECT @cart_id, x.provider_ID, x.product_ID, FLOOR(1 + RAND() * 5)
FROM (SELECT pp.product_ID, MIN(pp.user_ID) AS provider_ID
      FROM tbd_products_users_providers pp
      JOIN tb_products p ON p.ID = pp.product_ID
      WHERE pp.status = b'1' AND pp.user_ID <> @user_id
        AND p.status = 1 AND p.current_stock >= 5 AND p.current_price > 0
      GROUP BY pp.product_ID
      ORDER BY RAND() LIMIT 10) x;

-- Paso 3. Orden de compra ligada al carrito + sub-órdenes por vendedor
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

-- Paso 4. Domicilio de envío que NO es su hogar: trabajo
INSERT INTO tb_user_addresses (user_ID, address_label, recipient_name, recipient_phone,
                               delivery_instructions, is_default)
VALUES (@user_id, 'Trabajo', @user_name, @user_phone,
        'Entregar en recepción, horario de oficina 9:00 a 18:00', 0);
SET @address_id := LAST_INSERT_ID();

INSERT INTO tbd_address_components (address_ID, value, component_type) VALUES
    (@address_id, 'Av. Reforma 210, Piso 3, Oficina 302', 'street'),
    (@address_id, 'Centro',                               'neighborhood'),
    (@address_id, 'Huauchinango',                         'city'),
    (@address_id, 'Puebla',                               'state'),
    (@address_id, '73160',                                'postal_code'),
    (@address_id, 'México',                               'country');

UPDATE tb_orders
SET shipping_address = (SELECT GROUP_CONCAT(value ORDER BY ID SEPARATOR ', ')
                        FROM tbd_address_components WHERE address_ID = @address_id)
WHERE ID = @order_id;

-- Paso 5. Método de pago: tarjeta de crédito simulada de 16 dígitos
SET @card := CONCAT('5', LPAD(CAST(FLOOR(RAND() * 1000000000000000) AS UNSIGNED), 15, '0'));

INSERT INTO tbd_user_payment_methods (user_ID, payment_method_type_ID, provider,
                                      provider_method_ref, label, last_four, is_default)
VALUES (@user_id,
        (SELECT ID FROM tbc_payment_methods_types WHERE code = 'CREDIT_CARD'),
        'SIMULADOR', CONCAT('SIM-CC-', @card),
        'Crédito de prueba CP02', RIGHT(@card, 4), 1);

COMMIT;

SELECT @user_id AS user_ID, @cart_id AS cart_ID, @order_id AS order_ID, @total AS total,
       @card AS tarjeta_simulada, CURRENT_ROLE() AS rol_activo;


-- ##### BLOQUE 3 · CONEXIÓN: app.web · rol buyer · registra 6 pagos mensuales
USE db_test;
SET ROLE 'buyer';     -- al pagar se activa el rol de comprador

SELECT ID, user_id INTO @order_id, @user_id FROM tb_orders ORDER BY ID DESC LIMIT 1;
SELECT MAX(ID) INTO @upm_id FROM tbd_user_payment_methods WHERE user_ID = @user_id;

CALL sp_pay_order(@order_id, @upm_id, 'Tarjeta de crédito', 6);

SELECT CURRENT_ROLE() AS rol_activo;


-- ##### BLOQUE 4 · CONEXIÓN: marco.ramirez · banco autoriza 5 y rechaza el último; el sistema procesa, envía y entrega
USE db_test;

SELECT ID, user_id INTO @order_id, @user_id FROM tb_orders ORDER BY ID DESC LIMIT 1;
SELECT MAX(ID) INTO @address_id FROM tb_user_addresses WHERE user_ID = @user_id;
SELECT MAX(ID) INTO @ultimo_pago FROM tb_payments WHERE order_id = @order_id;
SET @t0 := NOW();

START TRANSACTION;

-- Paso 7. Transacciones bancarias
UPDATE tb_payment_transaction t
JOIN tb_payments p ON p.ID = t.payment_ID
SET t.transaction_status = IF(p.ID = @ultimo_pago, 'Failed', 'Completed'),
    t.response_message   = IF(p.ID = @ultimo_pago,
                              'Rechazada: límite excedido de crédito',
                              'Autorización simulada aprobada')
WHERE p.order_id = @order_id;

UPDATE tb_payments
SET payment_status = IF(ID = @ultimo_pago, 'Failed', 'Completed')
WHERE order_id = @order_id;

-- Paso 8. Orden atendida + inventario
UPDATE tb_orders SET status = 'Processing' WHERE ID = @order_id;
UPDATE tb_buyer_orders SET fulfillment_status = 'Accepted' WHERE order_ID = @order_id;

UPDATE tb_products p
JOIN tbd_order_items oi ON oi.product_ID = p.ID
JOIN tb_buyer_orders bo ON bo.ID = oi.buyer_order_ID
SET p.current_stock = p.current_stock - oi.quantity
WHERE bo.order_ID = @order_id;

UPDATE tb_buyer_orders SET fulfillment_status = 'Preparing' WHERE order_ID = @order_id;

-- Paso 9. Envío (uno por vendedor) y entrega
INSERT INTO tb_shipments (buyer_order_ID, address_ID, carrier, tracking_number, shipment_status,
                          shipped_date, estimated_delivery_date)
SELECT ID, @address_id, 'Estafeta',
       CONCAT('EST', LPAD(CAST(FLOOR(RAND() * 10000000000) AS UNSIGNED), 10, '0')),
       'Shipped', @t0 + INTERVAL 1 DAY, @t0 + INTERVAL 4 DAY
FROM tb_buyer_orders WHERE order_ID = @order_id;

UPDATE tb_buyer_orders SET fulfillment_status = 'Sent' WHERE order_ID = @order_id;
UPDATE tb_orders SET status = 'Shipped' WHERE ID = @order_id;

UPDATE tb_shipments s JOIN tb_buyer_orders bo ON bo.ID = s.buyer_order_ID
SET s.shipment_status = 'Delivered', s.delivered_date = @t0 + INTERVAL 3 DAY
WHERE bo.order_ID = @order_id;

UPDATE tb_buyer_orders SET fulfillment_status = 'Delivered' WHERE order_ID = @order_id;
UPDATE tb_orders SET status = 'Delivered' WHERE ID = @order_id;

COMMIT;


-- ##### BLOQUE 5 · CONEXIÓN: app.web · rol buyer · reclama 1 producto dañado
USE db_test;
SET ROLE 'buyer';

SELECT ID, user_id INTO @order_id, @user_id FROM tb_orders ORDER BY ID DESC LIMIT 1;

SELECT oi.ID, oi.buyer_order_ID INTO @item_danado, @bo_danado
FROM tbd_order_items oi
JOIN tb_buyer_orders bo ON bo.ID = oi.buyer_order_ID
WHERE bo.order_ID = @order_id
ORDER BY RAND() LIMIT 1;

START TRANSACTION;
INSERT INTO tb_returns (buyer_order_ID, user_ID, reason, return_status)
VALUES (@bo_danado, @user_id, 'El producto llegó dañado (golpe en empaque y equipo)', 'Requested');
SET @return_id := LAST_INSERT_ID();

INSERT INTO tbd_return_items (return_ID, order_item_ID, quantity, condition_notes)
VALUES (@return_id, @item_danado, 1, 'Unidad dañada; se solicita reposición, no reembolso');
COMMIT;


-- ##### BLOQUE 6 · CONEXIÓN: marco.ramirez · el sistema atiende la reclamación y reenvía el producto
USE db_test;

SELECT ID, user_id INTO @order_id, @user_id FROM tb_orders ORDER BY ID DESC LIMIT 1;
SELECT MAX(ID) INTO @address_id FROM tb_user_addresses WHERE user_ID = @user_id;
SELECT r.ID, r.buyer_order_ID, ri.order_item_ID, oi.product_ID
  INTO @return_id, @bo_danado, @item_danado, @prod_danado
FROM tb_returns r
JOIN tbd_return_items ri ON ri.return_ID = r.ID
JOIN tbd_order_items oi  ON oi.ID = ri.order_item_ID
JOIN tb_buyer_orders bo  ON bo.ID = r.buyer_order_ID
WHERE bo.order_ID = @order_id
ORDER BY r.ID DESC LIMIT 1;
SET @t0 := NOW();

START TRANSACTION;
UPDATE tb_returns SET return_status = 'Approved' WHERE ID = @return_id;
UPDATE tb_returns SET return_status = 'Received' WHERE ID = @return_id;
UPDATE tb_buyer_orders SET fulfillment_status = 'Returned' WHERE ID = @bo_danado;

UPDATE tb_products SET current_stock = current_stock - 1 WHERE ID = @prod_danado;

INSERT INTO tb_shipments (buyer_order_ID, address_ID, carrier, tracking_number, shipment_status,
                          shipped_date, estimated_delivery_date, notes)
VALUES (@bo_danado, @address_id, 'Estafeta',
        CONCAT('EST', LPAD(CAST(FLOOR(RAND() * 10000000000) AS UNSIGNED), 10, '0')),
        'Shipped', @t0 + INTERVAL 1 DAY, @t0 + INTERVAL 4 DAY,
        CONCAT('Reenvío por devolución ID=', @return_id, ', order_item_ID=', @item_danado));
SET @reenvio_id := LAST_INSERT_ID();

UPDATE tb_buyer_orders SET fulfillment_status = 'Sent' WHERE ID = @bo_danado;
UPDATE tb_shipments SET shipment_status = 'Delivered', delivered_date = @t0 + INTERVAL 3 DAY
WHERE ID = @reenvio_id;
UPDATE tb_buyer_orders SET fulfillment_status = 'Delivered' WHERE ID = @bo_danado;
COMMIT;

-- Verificación
SELECT o.ID, o.user_id, o.cart_ID, o.total_amount, o.status, o.shipping_address
FROM tb_orders o WHERE o.ID = @order_id;

SELECT p.ID, p.amount, p.payment_status, p.payment_date, t.transaction_status, t.response_message
FROM tb_payments p JOIN tb_payment_transaction t ON t.payment_ID = p.ID
WHERE p.order_id = @order_id ORDER BY p.ID;

SELECT s.ID, s.buyer_order_ID, s.tracking_number, s.shipment_status, s.notes
FROM tb_shipments s JOIN tb_buyer_orders bo ON bo.ID = s.buyer_order_ID
WHERE bo.order_ID = @order_id ORDER BY s.ID;

SELECT ID, table_name, operation, db_user, operation_date
FROM tb_logs WHERE table_name IN ('tb_orders', 'tb_payments', 'tb_returns')
ORDER BY ID DESC LIMIT 15;
