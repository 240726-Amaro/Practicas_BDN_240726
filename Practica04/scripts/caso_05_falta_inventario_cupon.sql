-- =====================================================================
--  Caso de Prueba 5: "Compra fallida por falta de inventario"
--
--  Se ejecuta por BLOQUES, cada uno en la conexión indicada.
--  Corre los bloques en orden y no mezcles dos casos a la vez.
--
--  Conexiones:  marco.ramirez (rol admin) = el sistema
--               app.movil (roles common_user -> buyer) = el usuario
-- =====================================================================


-- ##### BLOQUE 1 · CONEXIÓN: marco.ramirez · Preparación de datos de prueba
-- Pone a la venta un producto que se quedó con existencias en 0
USE db_test;

INSERT IGNORE INTO tbd_products_users_providers (user_ID, product_ID, type_ownership, status, avalaible_date)
SELECT (SELECT ID FROM tb_users WHERE status = b'1' ORDER BY RAND() LIMIT 1), x.ID, 'Owner', b'1', NOW()
FROM (SELECT p.ID FROM tb_products p
      WHERE p.status = 1 AND p.current_stock = 0 AND p.current_price > 0
        AND NOT EXISTS (SELECT 1 FROM tbd_products_users_providers pp WHERE pp.product_ID = p.ID)
      ORDER BY RAND() LIMIT 1) x;


-- ##### BLOQUE 2 · CONEXIÓN: app.movil · rol common_user · carrito, orden, domicilio y cupón
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

-- 1 producto (1 a 5 unidades) cuyo inventario no alcanza
SET @qty := FLOOR(1 + RAND() * 5);

SELECT pp.product_ID, pp.user_ID INTO @product_id, @seller_id
FROM tbd_products_users_providers pp
JOIN tb_products p ON p.ID = pp.product_ID
WHERE pp.status = b'1' AND pp.user_ID <> @user_id
  AND p.status = 1 AND p.current_price > 0 AND p.current_stock < @qty
ORDER BY RAND() LIMIT 1;

START TRANSACTION;

INSERT INTO tb_carts (user_ID) VALUES (@user_id);
SET @cart_id := LAST_INSERT_ID();

INSERT INTO tbd_carts_items (cart_ID, provider_ID, product_ID, quantity)
VALUES (@cart_id, @seller_id, @product_id, @qty);

-- Paso 2. Orden de compra
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
VALUES (@user_id, 'Casa', @user_name, @user_phone, 'Dejar con el vecino de la casa 4 si no hay nadie', 1);
SET @address_id := LAST_INSERT_ID();

INSERT INTO tbd_address_components (address_ID, value, component_type) VALUES
    (@address_id, 'Privada Morelos 7', 'street'),
    (@address_id, 'San Pedro',         'neighborhood'),
    (@address_id, 'Cuetzalan',         'city'),
    (@address_id, 'Puebla',            'state'),
    (@address_id, '73560',             'postal_code'),
    (@address_id, 'México',            'country');

UPDATE tb_orders
SET shipping_address = (SELECT GROUP_CONCAT(value ORDER BY ID SEPARATOR ', ')
                        FROM tbd_address_components WHERE address_ID = @address_id)
WHERE ID = @order_id;

-- Paso 4. Método de pago: cupón de regalo que cubre el total
SET @cupon := CONCAT('GIFT-', UPPER(LEFT(REPLACE(UUID(), '-', ''), 12)));

INSERT INTO tbd_user_payment_methods (user_ID, payment_method_type_ID, provider,
                                      provider_method_ref, label, last_four, is_default)
VALUES (@user_id,
        (SELECT ID FROM tbc_payment_methods_types WHERE code = 'GIFT_COUPON'),
        'CUPONES-SIM', @cupon,
        CONCAT('Cupón de regalo por $', FORMAT(CEIL(@total / 100) * 100, 2)), RIGHT(@cupon, 4), 1);

COMMIT;

SELECT @user_id AS user_ID, @product_id AS product_ID, @qty AS cantidad_pedida,
       (SELECT current_stock FROM tb_products WHERE ID = @product_id) AS stock,
       @order_id AS order_ID, @cupon AS cupon, CURRENT_ROLE() AS rol_activo;


-- ##### BLOQUE 3 · CONEXIÓN: app.movil · rol buyer · paga con el cupón
USE db_test;
SET ROLE 'buyer';

SELECT ID, user_id INTO @order_id, @user_id FROM tb_orders ORDER BY ID DESC LIMIT 1;
SELECT MAX(ID) INTO @upm_id FROM tbd_user_payment_methods WHERE user_ID = @user_id;

-- el procedimiento deja el cupón apartado (status = 0) mientras se procesa
CALL sp_pay_order(@order_id, @upm_id, 'Cupón de regalo', 1);


-- ##### BLOQUE 4 · CONEXIÓN: marco.ramirez · no atendida por falta de inventario; cancela y reasigna el cupón
USE db_test;

SELECT ID, user_id INTO @order_id, @user_id FROM tb_orders ORDER BY ID DESC LIMIT 1;
SELECT ID INTO @bo_id FROM tb_buyer_orders WHERE order_ID = @order_id LIMIT 1;
SELECT ID, user_payment_method_ID INTO @payment_id, @upm_id
FROM tb_payments WHERE order_id = @order_id LIMIT 1;

-- Paso 5. Validación de inventario
SELECT COUNT(*) INTO @faltantes
FROM tbd_order_items oi JOIN tb_products p ON p.ID = oi.product_ID
WHERE oi.buyer_order_ID = @bo_id AND p.current_stock < oi.quantity;

START TRANSACTION;

UPDATE tb_buyer_orders SET fulfillment_status = 'Canceled' WHERE ID = @bo_id AND @faltantes > 0;

-- Paso 6. Cancelación de la orden y reasignación del cupón
INSERT INTO tb_order_cancellations (buyer_order_ID, user_ID, reason, cancellation_status)
SELECT @bo_id, @user_id, 'Cancelación automática del sistema: falta de inventario', 'Approved'
FROM DUAL WHERE @faltantes > 0;
SET @cancel_id := IF(@faltantes > 0, LAST_INSERT_ID(), NULL);

INSERT INTO tbd_cancellation_items (cancellation_ID, order_item_ID, quantity)
SELECT @cancel_id, oi.ID, oi.quantity
FROM tbd_order_items oi WHERE oi.buyer_order_ID = @bo_id AND @cancel_id IS NOT NULL;

UPDATE tb_payment_transaction
SET transaction_status = 'Failed',
    response_message   = 'Orden no atendida por falta de inventario; cargo anulado y cupón reasignado'
WHERE payment_ID = @payment_id AND @faltantes > 0;
UPDATE tb_payments SET payment_status = 'Failed' WHERE ID = @payment_id AND @faltantes > 0;

UPDATE tb_orders SET status = 'Cancelled' WHERE ID = @order_id AND @faltantes > 0;
UPDATE tb_order_cancellations SET cancellation_status = 'Completed' WHERE ID = @cancel_id;

-- el cupón vuelve a estar disponible para el usuario
UPDATE tbd_user_payment_methods SET status = b'1' WHERE ID = @upm_id AND @faltantes > 0;

COMMIT;

-- Verificación
SELECT @faltantes AS productos_sin_stock, o.ID, o.status, o.total_amount
FROM tb_orders o WHERE o.ID = @order_id;

SELECT p.payment_status, t.transaction_status, t.response_message
FROM tb_payments p JOIN tb_payment_transaction t ON t.payment_ID = p.ID
WHERE p.order_id = @order_id;

SELECT provider_method_ref AS cupon, label, CAST(status AS UNSIGNED) AS activo
FROM tbd_user_payment_methods WHERE ID = @upm_id;

SELECT ID, table_name, operation, db_user FROM tb_logs
WHERE table_name IN ('tbd_user_payment_methods', 'tb_orders', 'tb_order_cancellations')
ORDER BY ID DESC LIMIT 8;
