-- =====================================================================
--  Caso de Prueba 4: "Compra exitosa del mismo proveedor con entrega
--                     en el punto de recolección"
--
--  Se ejecuta por BLOQUES, cada uno en la conexión indicada.
--  Corre los bloques en orden y no mezcles dos casos a la vez.
--
--  Conexiones:  marco.ramirez (rol admin) = el sistema
--               app.web (roles common_user -> buyer) = el usuario
-- =====================================================================


-- ##### BLOQUE 1 · CONEXIÓN: marco.ramirez · Preparación de datos de prueba
-- Un vendedor al azar con 3 productos nuevos a la venta (stock >= 3)
USE db_test;

SELECT ID INTO @seller_id FROM tb_users WHERE status = b'1' ORDER BY RAND() LIMIT 1;

INSERT IGNORE INTO tbd_products_users_providers (user_ID, product_ID, type_ownership, status, avalaible_date)
SELECT @seller_id, x.ID, 'Owner', b'1', NOW()
FROM (SELECT p.ID FROM tb_products p
      WHERE p.status = 1 AND p.current_stock >= 3 AND p.current_price > 0
        AND NOT EXISTS (SELECT 1 FROM tbd_products_users_providers pp WHERE pp.product_ID = p.ID)
      ORDER BY RAND() LIMIT 3) x;

SELECT @seller_id AS vendedor_preparado;


-- ##### BLOQUE 2 · CONEXIÓN: app.web · rol common_user · carrito, orden, domicilio y método de pago
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

-- Un proveedor que venda al menos 3 productos con stock >= 3
SELECT pp.user_ID INTO @seller_id
FROM tbd_products_users_providers pp
JOIN tb_products p ON p.ID = pp.product_ID
WHERE pp.status = b'1' AND pp.user_ID <> @user_id
  AND p.status = 1 AND p.current_stock >= 3 AND p.current_price > 0
GROUP BY pp.user_ID
HAVING COUNT(*) >= 3
ORDER BY RAND() LIMIT 1;

START TRANSACTION;

-- Carrito con 3 productos de ese proveedor (1 a 3 unidades)
INSERT INTO tb_carts (user_ID) VALUES (@user_id);
SET @cart_id := LAST_INSERT_ID();

INSERT INTO tbd_carts_items (cart_ID, provider_ID, product_ID, quantity)
SELECT @cart_id, @seller_id, x.product_ID, FLOOR(1 + RAND() * 3)
FROM (SELECT pp.product_ID
      FROM tbd_products_users_providers pp
      JOIN tb_products p ON p.ID = pp.product_ID
      WHERE pp.user_ID = @seller_id AND pp.status = b'1'
        AND p.status = 1 AND p.current_stock >= 3 AND p.current_price > 0
      ORDER BY RAND() LIMIT 3) x;

-- Paso 2. Orden de compra (1 sola sub-orden porque es 1 proveedor)
SELECT SUM(ci.quantity * p.current_price) INTO @total
FROM tbd_carts_items ci JOIN tb_products p ON p.ID = ci.product_ID
WHERE ci.cart_ID = @cart_id;

INSERT INTO tb_orders (user_id, cart_ID, total_amount, status)
VALUES (@user_id, @cart_id, @total, 'Pending');
SET @order_id := LAST_INSERT_ID();

UPDATE tb_carts SET status = b'0' WHERE ID = @cart_id;

INSERT INTO tb_buyer_orders (order_ID, seller_ID, subtotal, shipping_cost, fulfillment_status)
VALUES (@order_id, @seller_id, @total, 0.00, 'Pending');
SET @bo_id := LAST_INSERT_ID();

INSERT INTO tbd_order_items (buyer_order_ID, product_ID, provider_ID, product_name, quantity, unit_price)
SELECT @bo_id, ci.product_ID, ci.provider_ID, LEFT(p.name, 255), ci.quantity, p.current_price
FROM tbd_carts_items ci JOIN tb_products p ON p.ID = ci.product_ID
WHERE ci.cart_ID = @cart_id;

-- Paso 3. Domicilio de envío: su hogar
INSERT INTO tb_user_addresses (user_ID, address_label, recipient_name, recipient_phone,
                               delivery_instructions, is_default)
VALUES (@user_id, 'Casa', @user_name, @user_phone, 'Tocar el timbre; casa de dos pisos color crema', 1);
SET @address_id := LAST_INSERT_ID();

INSERT INTO tbd_address_components (address_ID, value, component_type) VALUES
    (@address_id, 'Calle 5 de Mayo 112', 'street'),
    (@address_id, 'Col. La Cruz',        'neighborhood'),
    (@address_id, 'Teziutlán',           'city'),
    (@address_id, 'Puebla',              'state'),
    (@address_id, '73800',               'postal_code'),
    (@address_id, 'México',              'country');

UPDATE tb_orders
SET shipping_address = (SELECT GROUP_CONCAT(value ORDER BY ID SEPARATOR ', ')
                        FROM tbd_address_components WHERE address_ID = @address_id)
WHERE ID = @order_id;

-- Paso 4. Método de pago: cuenta SPEI simulada de 16 dígitos
SET @cuenta := LPAD(CAST(FLOOR(RAND() * 10000000000000000) AS UNSIGNED), 16, '0');

INSERT INTO tbd_user_payment_methods (user_ID, payment_method_type_ID, provider,
                                      provider_method_ref, label, last_four, is_default)
VALUES (@user_id,
        (SELECT ID FROM tbc_payment_methods_types WHERE code = 'SPEI_TRANSFER'),
        'SPEI-SIM', CONCAT('SIM-SPEI-', @cuenta),
        'Cuenta SPEI de prueba CP04', RIGHT(@cuenta, 4), 1);

COMMIT;

SELECT @user_id AS user_ID, @seller_id AS proveedor_ID, @order_id AS order_ID, @total AS total,
       @cuenta AS cuenta_spei_simulada, CURRENT_ROLE() AS rol_activo;


-- ##### BLOQUE 3 · CONEXIÓN: app.web · rol buyer · un solo pago en efectivo por el total
USE db_test;
SET ROLE 'buyer';

SELECT ID, user_id INTO @order_id, @user_id FROM tb_orders ORDER BY ID DESC LIMIT 1;
SELECT MAX(ID) INTO @upm_id FROM tbd_user_payment_methods WHERE user_ID = @user_id;

-- pago de contado en efectivo (depósito referenciado a la cuenta SPEI)
CALL sp_pay_order(@order_id, @upm_id, 'Efectivo', 1);


-- ##### BLOQUE 4 · CONEXIÓN: marco.ramirez · confirma pago, procesa, envía y entrega en punto de recolección
USE db_test;

SELECT ID, user_id INTO @order_id, @user_id FROM tb_orders ORDER BY ID DESC LIMIT 1;
SELECT ID INTO @bo_id FROM tb_buyer_orders WHERE order_ID = @order_id LIMIT 1;
SELECT MAX(ID) INTO @address_id FROM tb_user_addresses WHERE user_ID = @user_id;
SET @t0 := NOW();

START TRANSACTION;

-- Pago confirmado
UPDATE tb_payment_transaction t
JOIN tb_payments p ON p.ID = t.payment_ID
SET t.transaction_status = 'Completed',
    t.response_message   = 'Pago único en efectivo a cuenta SPEI confirmado'
WHERE p.order_id = @order_id;
UPDATE tb_payments SET payment_status = 'Completed' WHERE order_id = @order_id;

-- Paso 6. Orden atendida
UPDATE tb_orders SET status = 'Processing' WHERE ID = @order_id;
UPDATE tb_buyer_orders SET fulfillment_status = 'Accepted' WHERE ID = @bo_id;

UPDATE tb_products p
JOIN tbd_order_items oi ON oi.product_ID = p.ID
SET p.current_stock = p.current_stock - oi.quantity
WHERE oi.buyer_order_ID = @bo_id;

UPDATE tb_buyer_orders SET fulfillment_status = 'Preparing' WHERE ID = @bo_id;

-- Paso 7. Envío: nadie recibe -> punto de recolección
INSERT INTO tb_shipments (buyer_order_ID, address_ID, carrier, tracking_number, shipment_status,
                          shipped_date, estimated_delivery_date)
VALUES (@bo_id, @address_id, 'Estafeta',
        CONCAT('EST', LPAD(CAST(FLOOR(RAND() * 10000000000) AS UNSIGNED), 10, '0')),
        'Shipped', @t0 + INTERVAL 1 DAY, @t0 + INTERVAL 3 DAY);
SET @shipment_id := LAST_INSERT_ID();

UPDATE tb_buyer_orders SET fulfillment_status = 'Sent' WHERE ID = @bo_id;
UPDATE tb_orders SET status = 'Shipped' WHERE ID = @order_id;

UPDATE tb_shipments SET shipment_status = 'In transit' WHERE ID = @shipment_id;

UPDATE tb_shipments
SET shipment_status = 'Failed attempt',
    notes = 'Intento de entrega 1: no hubo quien recibiera en el domicilio'
WHERE ID = @shipment_id;

UPDATE tb_shipments
SET shipment_status = 'At pickup point',
    notes = 'Paquete en punto de recolección: Sucursal Estafeta Teziutlán Centro, Av. Hidalgo 300'
WHERE ID = @shipment_id;

-- Paso 8. El cliente recoge en el punto de recolección
UPDATE tb_shipments
SET shipment_status = 'Delivered',
    delivered_date  = @t0 + INTERVAL 4 DAY,
    notes = 'Entregado en punto de recolección (Sucursal Estafeta Teziutlán Centro) contra identificación'
WHERE ID = @shipment_id;

UPDATE tb_buyer_orders SET fulfillment_status = 'Delivered' WHERE ID = @bo_id;
UPDATE tb_orders SET status = 'Delivered' WHERE ID = @order_id;

COMMIT;

-- Verificación
SELECT o.ID, o.user_id, o.cart_ID, o.total_amount, o.status FROM tb_orders o WHERE o.ID = @order_id;

SELECT oi.provider_ID, oi.product_name, oi.quantity, oi.subtotal
FROM tbd_order_items oi WHERE oi.buyer_order_ID = @bo_id;

SELECT operation, db_user, description
FROM tb_logs
WHERE table_name = 'tb_shipments'
  AND description REGEXP CONCAT('^Env.o [a-z]+\\. ID=', @shipment_id, '[,.]')
ORDER BY ID;
