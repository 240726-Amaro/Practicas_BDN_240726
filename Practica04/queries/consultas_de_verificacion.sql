--mysql -h 177.7.61.91 -P 40727 -u marco.ramirez -p db_test

Después de conectarse, el profesor puede auditar así:

SELECT DATABASE(), CURRENT_USER(), CURRENT_ROLE();
SHOW GRANTS FOR CURRENT_USER;

SHOW TABLES;
SHOW TRIGGERS FROM db_test;
SHOW PROCEDURE STATUS WHERE Db = 'db_test';

Para verificar el caso de compra que realizaste:

SELECT ID, email, nickname
FROM tb_users
WHERE email = 'josue.amaro.p04@example.test';

SELECT ID, user_ID, status
FROM tb_carts
WHERE user_ID = 10234;

SELECT ci.cart_ID, ci.provider_ID, ci.product_ID, p.name, ci.quantity
FROM tbd_carts_items AS ci
JOIN tb_products AS p ON p.ID = ci.product_ID
WHERE ci.cart_ID = 1
ORDER BY ci.product_ID;

SELECT ID, status, total_amount, shipping_address
FROM tb_orders
WHERE ID = 1;

SELECT ID, seller_ID, fulfillment_status, subtotal, shipping_cost
FROM tb_buyer_orders
WHERE ID = 1;

SELECT ID, payment_status, amount, transaction_reference
FROM tb_payments
WHERE order_id = 1;

SELECT payment_ID, transaction_type, amount, transaction_status,
       gateway_reference, response_message
FROM tb_payment_transaction
WHERE payment_ID = 1;

Para revisar la bitácora, las columnas correctas son db_user y operation_date:

SELECT ID, table_name, operation, db_user, operation_date, description
FROM tb_logs
WHERE table_name IN (
    'tb_users',
    'tb_carts',
    'tbd_carts_items',
    'tb_orders',
    'tb_buyer_orders',
    'tbd_order_items',
    'tb_payments',
    'tb_payment_transaction'
)
ORDER BY ID;