-- =====================================================================
--  Caso de Prueba 3: "Compra exitosa con cancelación parcial,
--                     ajuste y reembolso parcial"
--
--  Se ejecuta por BLOQUES, cada uno en la conexión indicada.
--  Corre los bloques en orden y no mezcles dos casos a la vez.
--
--  Conexiones:  marco.ramirez (rol admin) = el sistema
--               app.movil (roles common_user -> buyer) = el usuario
-- =====================================================================


-- ##### BLOQUE 1 · CONEXIÓN: marco.ramirez · Preparación de datos de prueba
-- Da de alta en vendedores 3 productos de una misma categoría (stock >= 10)
USE db_test;

SELECT pc.category_ID INTO @category_id
FROM tbd_products_categories pc
JOIN tb_products p ON p.ID = pc.product_ID
WHERE pc.status = b'1' AND p.status = 1 AND p.current_stock >= 10 AND p.current_price > 0
  AND NOT EXISTS (SELECT 1 FROM tbd_products_users_providers pp WHERE pp.product_ID = p.ID)
GROUP BY pc.category_ID
HAVING COUNT(*) >= 3
ORDER BY RAND() LIMIT 1;

DROP TEMPORARY TABLE IF EXISTS tmp_sellers;
CREATE TEMPORARY TABLE tmp_sellers (k INT PRIMARY KEY, seller_ID INT);
INSERT INTO tmp_sellers
SELECT ROW_NUMBER() OVER (), x.ID
FROM (SELECT ID FROM tb_users WHERE status = b'1' ORDER BY RAND() LIMIT 2) x;

INSERT IGNORE INTO tbd_products_users_providers (user_ID, product_ID, type_ownership, status, avalaible_date)
SELECT s.seller_ID, x.ID, 'Owner', b'1', NOW()
FROM (SELECT ID, ROW_NUMBER() OVER () AS rn
      FROM (SELECT p.ID
            FROM tbd_products_categories pc
            JOIN tb_products p ON p.ID = pc.product_ID
            WHERE pc.category_ID = @category_id AND pc.status = b'1'
              AND p.status = 1 AND p.current_stock >= 10 AND p.current_price > 0
              AND NOT EXISTS (SELECT 1 FROM tbd_products_users_providers pp WHERE pp.product_ID = p.ID)
            ORDER BY RAND() LIMIT 3) r) x
JOIN tmp_sellers s ON s.k = (x.rn % 2) + 1;

SELECT @category_id AS categoria_preparada;


-- ##### BLOQUE 2 · CONEXIÓN: app.movil · rol common_user · carrito, orden, domicilio y método de pago
USE db_test;
SET ROLE 'common_user';

-- Paso 1. Inicia sesión un usuario registrado sin carrito previo
SELECT u.ID, CONCAT(p.given_names, ' ', p.family_names), p.phone
  INTO @user_id, @user_name, @user_phone
FROM tb_users u
JOIN tb_people p ON p.user_ID = u.ID
WHERE u.status = b'1'
  AND NOT EXISTS (SELECT 1 FROM tb_carts c WHERE c.user_ID = u.ID)
  AND NOT EXISTS (SELECT 1 FROM tbd_products_users_providers pp WHERE pp.user_ID = u.ID)
ORDER BY RAND() LIMIT 1;

-- Una categoría con al menos 3 productos a la venta y con stock >= 10
SELECT pc.category_ID INTO @category_id
FROM tbd_products_categories pc
JOIN tb_products p ON p.ID = pc.product_ID
WHERE pc.status = b'1' AND p.status = 1 AND p.current_stock >= 10 AND p.current_price > 0
  AND EXISTS (SELECT 1 FROM tbd_products_users_providers pp
              WHERE pp.product_ID = p.ID AND pp.status = b'1' AND pp.user_ID <> @user_id)
GROUP BY pc.category_ID
HAVING COUNT(*) >= 3
ORDER BY RAND() LIMIT 1;

START TRANSACTION;

-- Carrito con 3 productos de esa categoría (1 a 10 unidades)
INSERT INTO tb_carts (user_ID) VALUES (@user_id);
SET @cart_id := LAST_INSERT_ID();

INSERT INTO tbd_carts_items (cart_ID, provider_ID, product_ID, quantity)
SELECT @cart_id, x.provider_ID, x.product_ID, FLOOR(1 + RAND() * 10)
FROM (SELECT pp.product_ID, MIN(pp.user_ID) AS provider_ID
      FROM tbd_products_categories pc
      JOIN tb_products p ON p.ID = pc.product_ID
      JOIN tbd_products_users_providers pp ON pp.product_ID = p.ID
      WHERE pc.category_ID = @category_id AND pc.status = b'1'
        AND pp.status = b'1' AND pp.user_ID <> @user_id
        AND p.status = 1 AND p.current_stock >= 10 AND p.current_price > 0
      GROUP BY pp.product_ID
      ORDER BY RAND() LIMIT 3) x;

-- Paso 2. Orden de compra
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

-- Paso 3. Domicilio que no es su hogar: "Casa Papas"
INSERT INTO tb_user_addresses (user_ID, address_label, recipient_name, recipient_phone,
                               delivery_instructions, is_default)
VALUES (@user_id, 'Casa Papas', @user_name, @user_phone,
        'Casa de mis papás, portón verde; si no estoy, recibe mi mamá', 0);
SET @address_id := LAST_INSERT_ID();

INSERT INTO tbd_address_components (address_ID, value, component_type) VALUES
    (@address_id, 'Calle Hidalgo 58',   'street'),
    (@address_id, 'Barrio de San Juan', 'neighborhood'),
    (@address_id, 'Zacatlán',           'city'),
    (@address_id, 'Puebla',             'state'),
    (@address_id, '73310',              'postal_code'),
    (@address_id, 'México',             'country');

UPDATE tb_orders
SET shipping_address = (SELECT GROUP_CONCAT(value ORDER BY ID SEPARATOR ', ')
                        FROM tbd_address_components WHERE address_ID = @address_id)
WHERE ID = @order_id;

-- Paso 4. Método de pago: tarjeta digital Spin simulada de 16 dígitos
SET @card := CONCAT('4', LPAD(CAST(FLOOR(RAND() * 1000000000000000) AS UNSIGNED), 15, '0'));

INSERT INTO tbd_user_payment_methods (user_ID, payment_method_type_ID, provider,
                                      provider_method_ref, label, last_four, is_default)
VALUES (@user_id,
        (SELECT ID FROM tbc_payment_methods_types WHERE code = 'DIGITAL_CARD'),
        'SPIN-SIM', CONCAT('SIM-SPIN-', @card),
        'Spin de prueba CP03', RIGHT(@card, 4), 1);

COMMIT;

SELECT @user_id AS user_ID, @category_id AS category_ID, @order_id AS order_ID, @total AS total,
       @card AS spin_simulada, CURRENT_ROLE() AS rol_activo;


-- ##### BLOQUE 3 · CONEXIÓN: app.movil · rol buyer · un solo pago en efectivo por el total
USE db_test;
SET ROLE 'buyer';

SELECT ID, user_id INTO @order_id, @user_id FROM tb_orders ORDER BY ID DESC LIMIT 1;
SELECT MAX(ID) INTO @upm_id FROM tbd_user_payment_methods WHERE user_ID = @user_id;

-- pago de contado en efectivo (depósito a la tarjeta Spin)
CALL sp_pay_order(@order_id, @upm_id, 'Efectivo', 1);


-- ##### BLOQUE 4 · CONEXIÓN: marco.ramirez · se confirma el pago y el sistema procesa la orden
USE db_test;

SELECT ID INTO @order_id FROM tb_orders ORDER BY ID DESC LIMIT 1;

START TRANSACTION;
UPDATE tb_payment_transaction t
JOIN tb_payments p ON p.ID = t.payment_ID
SET t.transaction_status = 'Completed',
    t.response_message   = 'Pago único en efectivo (depósito a Spin) confirmado'
WHERE p.order_id = @order_id;
UPDATE tb_payments SET payment_status = 'Completed' WHERE order_id = @order_id;

UPDATE tb_orders SET status = 'Processing' WHERE ID = @order_id;
UPDATE tb_buyer_orders SET fulfillment_status = 'Accepted' WHERE order_ID = @order_id;

UPDATE tb_products p
JOIN tbd_order_items oi ON oi.product_ID = p.ID
JOIN tb_buyer_orders bo ON bo.ID = oi.buyer_order_ID
SET p.current_stock = p.current_stock - oi.quantity
WHERE bo.order_ID = @order_id;
COMMIT;


-- ##### BLOQUE 5 · CONEXIÓN: app.movil · rol buyer · cancela 1 producto del pedido
USE db_test;
SET ROLE 'buyer';

SELECT ID, user_id INTO @order_id, @user_id FROM tb_orders ORDER BY ID DESC LIMIT 1;

SELECT oi.ID, oi.buyer_order_ID, oi.quantity INTO @item_cancel, @bo_cancel, @qty_cancel
FROM tbd_order_items oi
JOIN tb_buyer_orders bo ON bo.ID = oi.buyer_order_ID
WHERE bo.order_ID = @order_id
ORDER BY RAND() LIMIT 1;

START TRANSACTION;
INSERT INTO tb_order_cancellations (buyer_order_ID, user_ID, reason, cancellation_status)
VALUES (@bo_cancel, @user_id, 'El cliente ya no requiere este producto', 'Requested');
SET @cancel_id := LAST_INSERT_ID();

INSERT INTO tbd_cancellation_items (cancellation_ID, order_item_ID, quantity)
VALUES (@cancel_id, @item_cancel, @qty_cancel);
COMMIT;


-- ##### BLOQUE 6 · CONEXIÓN: marco.ramirez · actualiza la orden, reembolsa, envía y entrega
USE db_test;

SELECT ID, user_id, total_amount INTO @order_id, @user_id, @total_original
FROM tb_orders ORDER BY ID DESC LIMIT 1;
SELECT MAX(ID) INTO @address_id FROM tb_user_addresses WHERE user_ID = @user_id;
SELECT ID INTO @payment_id FROM tb_payments WHERE order_id = @order_id ORDER BY ID LIMIT 1;

SELECT oc.ID, oc.buyer_order_ID, ci.quantity, oi.product_ID, ci.quantity * oi.unit_price
  INTO @cancel_id, @bo_cancel, @qty_cancel, @prod_cancel, @monto_cancel
FROM tb_order_cancellations oc
JOIN tbd_cancellation_items ci ON ci.cancellation_ID = oc.ID
JOIN tbd_order_items oi        ON oi.ID = ci.order_item_ID
JOIN tb_buyer_orders bo        ON bo.ID = oc.buyer_order_ID
WHERE bo.order_ID = @order_id AND oc.cancellation_status = 'Requested'
ORDER BY oc.ID DESC LIMIT 1;
SET @t0 := NOW();

START TRANSACTION;
UPDATE tb_order_cancellations SET cancellation_status = 'Approved' WHERE ID = @cancel_id;

-- Paso 8. Actualización de la orden
UPDATE tb_products SET current_stock = current_stock + @qty_cancel WHERE ID = @prod_cancel;
UPDATE tb_buyer_orders SET subtotal = subtotal - @monto_cancel WHERE ID = @bo_cancel;
UPDATE tb_buyer_orders SET fulfillment_status = 'Canceled' WHERE ID = @bo_cancel AND subtotal = 0;
UPDATE tb_orders SET total_amount = total_amount - @monto_cancel WHERE ID = @order_id;

-- Paso 9. Reembolso de lo cancelado
INSERT INTO tb_refunds (payment_ID, cancellation_ID, amount, refund_status, reason)
VALUES (@payment_id, @cancel_id, @monto_cancel, 'Pending',
        CONCAT('Reembolso por cancelación parcial ID=', @cancel_id));
SET @refund_id := LAST_INSERT_ID();

INSERT INTO tb_payment_transaction (payment_ID, transaction_type, amount, transaction_status,
                                    gateway_reference, response_message)
VALUES (@payment_id, 'Refund', @monto_cancel, 'Completed',
        CONCAT('SIM-RF-', REPLACE(UUID(), '-', '')), 'Reembolso parcial abonado a la tarjeta Spin');

UPDATE tb_refunds SET refund_status = 'Processed', refund_date = NOW() WHERE ID = @refund_id;
UPDATE tb_order_cancellations SET cancellation_status = 'Completed' WHERE ID = @cancel_id;

-- Paso 10. Envío de lo que quedó y entrega
UPDATE tb_buyer_orders SET fulfillment_status = 'Preparing'
WHERE order_ID = @order_id AND fulfillment_status <> 'Canceled';

INSERT INTO tb_shipments (buyer_order_ID, address_ID, carrier, tracking_number, shipment_status,
                          shipped_date, estimated_delivery_date)
SELECT ID, @address_id, 'DHL',
       CONCAT('DHL', LPAD(CAST(FLOOR(RAND() * 10000000000) AS UNSIGNED), 10, '0')),
       'Shipped', @t0 + INTERVAL 1 DAY, @t0 + INTERVAL 3 DAY
FROM tb_buyer_orders WHERE order_ID = @order_id AND fulfillment_status <> 'Canceled';

UPDATE tb_buyer_orders SET fulfillment_status = 'Sent'
WHERE order_ID = @order_id AND fulfillment_status <> 'Canceled';
UPDATE tb_orders SET status = 'Shipped' WHERE ID = @order_id;

UPDATE tb_shipments s JOIN tb_buyer_orders bo ON bo.ID = s.buyer_order_ID
SET s.shipment_status = 'Delivered', s.delivered_date = @t0 + INTERVAL 2 DAY
WHERE bo.order_ID = @order_id;

UPDATE tb_buyer_orders SET fulfillment_status = 'Delivered'
WHERE order_ID = @order_id AND fulfillment_status <> 'Canceled';
UPDATE tb_orders SET status = 'Delivered' WHERE ID = @order_id;
COMMIT;

-- Verificación
SELECT @total_original AS total_original, @monto_cancel AS monto_cancelado,
       (SELECT total_amount FROM tb_orders WHERE ID = @order_id) AS total_final;

SELECT bo.ID AS buyer_order_ID, bo.subtotal, bo.fulfillment_status, oi.ID AS order_item_ID,
       oi.product_name, oi.quantity, oi.subtotal,
       IF(ci.order_item_ID IS NULL, '', 'CANCELADO') AS cancelado
FROM tb_buyer_orders bo
JOIN tbd_order_items oi ON oi.buyer_order_ID = bo.ID
LEFT JOIN tbd_cancellation_items ci ON ci.order_item_ID = oi.ID
WHERE bo.order_ID = @order_id ORDER BY bo.ID, oi.ID;

SELECT t.transaction_type, t.amount, t.transaction_status, t.response_message
FROM tb_payment_transaction t WHERE t.payment_ID = @payment_id ORDER BY t.ID;

SELECT ID, table_name, operation, db_user FROM tb_logs
WHERE table_name IN ('tb_order_cancellations', 'tb_refunds', 'tb_orders')
ORDER BY ID DESC LIMIT 10;
