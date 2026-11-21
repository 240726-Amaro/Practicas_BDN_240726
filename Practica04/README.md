# Práctica 04: Casos de prueba de compra y trazabilidad en MySQL

## Descripción de la práctica

Ejecución de cinco casos de prueba del flujo de compra de la base de datos de comercio electrónico `db_test`, usando las cuentas y roles creados en prácticas anteriores. Cada caso se corre por bloques: `marco.ramirez` (rol admin) actúa como el sistema o el banco, y `app.web` / `app.movil` (roles `common_user` → `buyer`) actúan como el usuario. Todas las operaciones quedan registradas en la bitácora `tb_logs` y se consultan con vistas de trazabilidad por caso. El esquema actual corresponde al respaldo BD24.

## Casos de prueba

|ID|Caso de prueba|Escenario|Conexiones|Script|Vista de trazabilidad|
|---|---|---|---|---|---|
|1.|Compra exitosa, sin modificaciones|Un usuario nuevo se registra, compra 5 productos de 2 vendedores, paga en una sola exhibición con tarjeta de débito y recibe en su domicilio|`marco.ramirez`, `app.web`|[caso_01](scripts/caso_01_compra_exitosa.sql)|`vw_trazabilidad_caso1_compra_exitosa`|
|2.|Pagos mensuales, último rechazado, reclamación y reenvío|Compra de 10 productos de 3 vendedores con tarjeta de crédito a 6 meses; el banco rechaza el último pago, el envío llega a su trabajo, reclama 1 producto dañado y se le reenvía|`marco.ramirez`, `app.web`|[caso_02](scripts/caso_02_pagos_mensuales_reclamacion_reenvio.sql)|`vw_trazabilidad_caso2_pagos_reclamacion`|
|3.|Cancelación parcial, ajuste y reembolso parcial|Compra de 3 productos de una misma categoría con tarjeta digital Spin y pago en efectivo; cancela 1 producto, se ajusta la orden, se reembolsa lo cancelado y se entrega el resto|`marco.ramirez`, `app.movil`|[caso_03](scripts/caso_03_cancelacion_parcial_reembolso.sql)|`vw_trazabilidad_caso3_cancelacion_parcial`|
|4.|Mismo proveedor con entrega en punto de recolección|Compra de 3 productos de un solo vendedor (una sola suborden) con cuenta SPEI y pago en efectivo; nadie recibe en casa y el cliente recoge en el punto de recolección|`marco.ramirez`, `app.web`|[caso_04](scripts/caso_04_mismo_proveedor_punto_recoleccion.sql)|`vw_trazabilidad_caso4_punto_recoleccion`|
|5.|Compra fallida por falta de inventario|Compra de un producto sin existencias pagada con cupón de regalo; la orden no se atiende, se cancela y el cupón se reasigna al usuario|`marco.ramirez`, `app.movil`|[caso_05](scripts/caso_05_falta_inventario_cupon.sql)|`vw_trazabilidad_caso5_falta_inventario`|

Las cinco vistas filtran `vw_trazabilidad_compras`, que reúne por orden los registros de `tb_logs` de todas las tablas del flujo de compra (carrito, orden, subórdenes, pagos, transacciones, envíos, devoluciones, cancelaciones, reembolsos e inventario).

## Actividades realizadas

- Ejecución de los cinco casos de prueba por bloques, alternando las conexiones del sistema y del usuario.
- Creación de la vista consolidada `vw_trazabilidad_compras` y de una vista de trazabilidad por cada caso.
- Consultas de verificación de usuarios, roles, tablas, triggers, procedimientos y del caso de compra.
- Respaldos de la base de datos (BD21 a BD24).
- Actualización del diccionario de datos y del diagrama relacional.

## Resultados obtenidos

- **Diccionario de datos:** [diccionario de datos BD24](diccionario_datos/diccionario_datos.md) y [versión Excel](diccionario_datos/diccionario_datos.xlsx).
- **Diagrama relacional:** [diagrama entidad-relación](diccionario_datos/diagrama_er.mmd) y [versión navegable](diagrama/index.html).
- **Respaldo más reciente:** [`BD24.sql`](backups/BD24.sql).
