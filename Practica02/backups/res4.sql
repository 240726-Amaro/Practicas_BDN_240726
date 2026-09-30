-- MySQL dump 10.13  Distrib 8.0.36, for Win64 (x86_64)
--
-- Host: 127.0.0.1    Database: db_test
-- ------------------------------------------------------
-- Server version	8.0.36

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `tb_logs`
--

DROP TABLE IF EXISTS `tb_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_logs` (
  `ID` int NOT NULL AUTO_INCREMENT,
  `table_name` varchar(100) NOT NULL,
  `operation` enum('Create','Read','Update','Delete') NOT NULL,
  `db_user` varchar(80) NOT NULL,
  `description` text NOT NULL,
  `operation_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `operation_status` bit(1) DEFAULT b'1',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tb_logs`
--

LOCK TABLES `tb_logs` WRITE;
/*!40000 ALTER TABLE `tb_logs` DISABLE KEYS */;
INSERT INTO `tb_logs` VALUES (1,'tb_users','Create','root@localhost','Usuario creado, ID: 1, email: ivan@utxicotepec.edu.mx, nickname: Ivan123','2026-09-09 17:17:54',_binary ''),(2,'tb_users','Create','root@localhost','Usuario creado, ID: 2, email: adrian@utxicotepec.edu.mx, nickname: Adrian123','2026-09-09 17:17:54',_binary ''),(3,'tb_users','Create','root@localhost','Usuario creado, ID: 3, email: alan@utxicotepec.edu.mx, nickname: Alan123','2026-09-09 17:17:57',_binary ''),(4,'tb_users','Create','adrian@PC-18','Usuario creado, ID: 5, email: eduardo@utxicotepec.edu.mx, nickname: Eduardo123','2026-09-09 18:24:30',_binary ''),(5,'tb_users','Create','adrian@PC-18','Usuario creado, ID: 8, email: carlos@utxicotepec.edu.mx, nickname: Carlos123','2026-09-09 18:26:27',_binary ''),(6,'tb_users','Create','adrian@PC-18','Usuario creado, ID: 10, email: maria@utxicotepec.edu.mx, nickname: Maria123','2026-09-09 18:26:27',_binary ''),(7,'tb_users','Delete','adrian@PC-18','Usuario eliminado. ID=10, email=maria@utxicotepec.edu.mx, nickname=Maria123','2026-09-09 18:40:50',_binary ''),(8,'tb_products','Create','jhosep.escamilla@PC-11','Producto creado. ID: 1, SKU: TAR-ASU-407, Nombre: Tarjeta de Video ASUS Dual GeForce RTX 4070 Super, Precio: 14499.00, Stock: 10','2026-09-22 10:47:42',_binary ''),(9,'tb_products','Create','jhosep.escamilla@PC-11','Producto creado. ID: 2, SKU: PRO-AMD-78X, Nombre: Procesador AMD Ryzen 7 7800X3D, Precio: 8299.00, Stock: 25','2026-09-22 10:47:42',_binary ''),(10,'tb_products','Create','jhosep.escamilla@PC-11','Producto creado. ID: 3, SKU: SSD-SAM-990, Nombre: SSD NVMe M.2 Samsung 990 PRO 2TB, Precio: 3899.50, Stock: 35','2026-09-22 10:47:42',_binary ''),(11,'tb_products','Create','jhosep.escamilla@PC-11','Producto creado. ID: 4, SKU: RAM-COR-32G, Nombre: Memoria RAM Corsair Vengeance DDR5 32GB, Precio: 2450.00, Stock: 50','2026-09-22 10:47:42',_binary ''),(12,'tb_products','Create','jhosep.escamilla@PC-11','Producto creado. ID: 5, SKU: FUEN-COR-RM8, Nombre: Fuente de Poder Corsair RM850e 850W, Precio: 2799.00, Stock: 20','2026-09-22 10:47:42',_binary ''),(13,'tb_products','Create','omar.sampayo@PC-14','Producto creado. ID: 6, SKU: DIS-WD-4TB, Nombre: Disco Duro Externo WD My Passport 4TB, Precio: 2199.00, Stock: 25','2026-09-22 10:57:54',_binary ''),(14,'tb_products','Create','omar.sampayo@PC-14','Producto creado. ID: 7, SKU: CAM-LOG-C920, Nombre: Webcam Logitech C920 HD Pro, Precio: 1499.50, Stock: 18','2026-09-22 10:57:54',_binary '');
/*!40000 ALTER TABLE `tb_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tb_products`
--

DROP TABLE IF EXISTS `tb_products`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_products` (
  `ID` int unsigned NOT NULL AUTO_INCREMENT,
  `SKU` varchar(50) NOT NULL,
  `name` varchar(250) NOT NULL,
  `description` text,
  `current_price` decimal(10,2) NOT NULL DEFAULT '0.00',
  `current_stock` int unsigned NOT NULL DEFAULT '0',
  `status` tinyint DEFAULT '1',
  `creation_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_update` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `SKU` (`SKU`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tb_products`
--

LOCK TABLES `tb_products` WRITE;
/*!40000 ALTER TABLE `tb_products` DISABLE KEYS */;
INSERT INTO `tb_products` VALUES (1,'TAR-ASU-407','Tarjeta de Video ASUS Dual GeForce RTX 4070 Super','Memoria de 12GB GDDR6X, diseño de 2.5 ranuras, tecnología de ventiladores Axial-tech y renderizado por IA con DLSS 3.',14499.00,10,1,'2026-09-22 10:47:42','2026-09-22 10:47:42'),(2,'PRO-AMD-78X','Procesador AMD Ryzen 7 7800X3D','8 núcleos y 16 hilos, reloj base de 4.2GHz (Turbo hasta 5.0GHz), 104MB de caché L2+L3 con tecnología 3D V-Cache, Socket AM5.',8299.00,25,1,'2026-09-22 10:47:42','2026-09-22 10:47:42'),(3,'SSD-SAM-990','SSD NVMe M.2 Samsung 990 PRO 2TB','Disco de estado sólido PCIe Gen 4.0 x4 con velocidades de lectura de hasta 7450 MB/s y escritura de hasta 6900 MB/s, ideal para PC y PS5.',3899.50,35,1,'2026-09-22 10:47:42','2026-09-22 10:47:42'),(4,'RAM-COR-32G','Memoria RAM Corsair Vengeance DDR5 32GB','Kit de 2x16GB a 6000MHz CL36, optimizado para Intel XMP 3.0 y AMD EXPO, disipador de aluminio de bajo perfil.',2450.00,50,1,'2026-09-22 10:47:42','2026-09-22 10:47:42'),(5,'FUEN-COR-RM8','Fuente de Poder Corsair RM850e 850W','Certificación 80 PLUS Gold, totalmente modular, compatible con ATX 3.0 y PCIe 5.0, condensadores de grado industrial a 105°C.',2799.00,20,1,'2026-09-22 10:47:42','2026-09-22 10:47:42'),(6,'DIS-WD-4TB','Disco Duro Externo WD My Passport 4TB','Disco duro portátil USB 3.2 Gen 1, protección mediante contraseña con cifrado de hardware AES de 256 bits, formato de 2.5 pulgadas compatible con PC y Mac.',2199.00,25,1,'2026-09-22 10:57:54','2026-09-22 10:57:54'),(7,'CAM-LOG-C920','Webcam Logitech C920 HD Pro','Cámara web Full HD 1080p a 30 fps, sonido estéreo con micrófonos dobles, corrección de luz automática HD y enfoque automático.',1499.50,18,1,'2026-09-22 10:57:54','2026-09-22 10:57:54');
/*!40000 ALTER TABLE `tb_products` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_products_after_insert` AFTER INSERT ON `tb_products` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (
        table_name,
        operation,
        db_user,
        description,
        operation_date,
        operation_status
    )
    VALUES (
        'tb_products',
        'Create',
        USER(),
        CONCAT('Producto creado. ID: ', NEW.ID, ', SKU: ', COALESCE(NEW.SKU, 'NULL'), ', Nombre: ', COALESCE(NEW.name, 'NULL'), ', Precio: ', NEW.current_price, ', Stock: ', NEW.current_stock),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_products_after_update` AFTER UPDATE ON `tb_products` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (
        table_name,
        operation,
        db_user,
        description,
        operation_date,
        operation_status
    )
    VALUES (
        'tb_products',
        'Update',
        USER(),
        CONCAT(
            'Producto actualizado. ID=', NEW.ID,
            '. Cambios: ',
            CONCAT_WS(', ',
                IF(NOT (OLD.SKU <=> NEW.SKU), CONCAT('SKU: [', COALESCE(OLD.SKU, 'NULL'), '] -> [', COALESCE(NEW.SKU, 'NULL'), ']'), NULL),
                IF(NOT (OLD.name <=> NEW.name), CONCAT('name: [', COALESCE(OLD.name, 'NULL'), '] -> [', COALESCE(NEW.name, 'NULL'), ']'), NULL),
                IF(NOT (OLD.description <=> NEW.description), CONCAT('description: [', COALESCE(OLD.description, 'NULL'), '] -> [', COALESCE(NEW.description, 'NULL'), ']'), NULL),
                IF(NOT (OLD.current_price <=> NEW.current_price), CONCAT('price: [', COALESCE(OLD.current_price, '0'), '] -> [', COALESCE(NEW.current_price, '0'), ']'), NULL),
                IF(NOT (OLD.current_stock <=> NEW.current_stock), CONCAT('stock: [', COALESCE(OLD.current_stock, '0'), '] -> [', COALESCE(NEW.current_stock, '0'), ']'), NULL),
                IF(NOT (OLD.status <=> NEW.status), CONCAT('status: [', COALESCE(OLD.status, '0'), '] -> [', COALESCE(NEW.status, '0'), ']'), NULL)
            )
        ),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_products_after_delete` AFTER DELETE ON `tb_products` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (
        table_name,
        operation,
        db_user,
        description,
        operation_date,
        operation_status
    )
    VALUES (
        'tb_products',
        'Delete',
        USER(),
        CONCAT(
            'Producto eliminado. ID=', OLD.ID,
            ', SKU=', COALESCE(OLD.SKU, 'NULL'),
            ', Nombre=', COALESCE(OLD.name, 'NULL')
        ),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `tb_users`
--

DROP TABLE IF EXISTS `tb_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_users` (
  `ID` int NOT NULL AUTO_INCREMENT,
  `email` varchar(80) NOT NULL,
  `nickname` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `creation_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_login` datetime DEFAULT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `email` (`email`),
  UNIQUE KEY `nickname` (`nickname`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tb_users`
--

LOCK TABLES `tb_users` WRITE;
/*!40000 ALTER TABLE `tb_users` DISABLE KEYS */;
INSERT INTO `tb_users` VALUES (1,'ivan@utxicotepec.edu.mx','Ivan123','827ccb0eea8a706c4c34a16891f84e7b','2026-09-09 17:17:54',NULL),(2,'adrian@utxicotepec.edu.mx','Adrian123','827ccb0eea8a706c4c34a16891f84e7b','2026-09-09 17:17:54',NULL),(3,'alan@utxicotepec.edu.mx','Alan123','827ccb0eea8a706c4c34a16891f84e7b','2026-09-09 17:17:57',NULL),(5,'eduardo@utxicotepec.edu.mx','Eduardo123','81dc9bdb52d04dc20036dbd8313ed055','2026-09-09 18:24:30',NULL),(8,'carlos@utxicotepec.edu.mx','Carlos123','81dc9bdb52d04dc20036dbd8313ed055','2026-09-09 18:26:27',NULL);
/*!40000 ALTER TABLE `tb_users` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_users_after_insert` AFTER INSERT ON `tb_users` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (
        table_name,
        operation,
        db_user,
        description,
        operation_date,
        operation_status
    )
    VALUES (
        'tb_users',
        'Create',
        USER(),
        CONCAT('Usuario creado, ID: ', NEW.ID, ', email: ', NEW.email, ', nickname: ', NEW.nickname),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_users_after_update` AFTER UPDATE ON `tb_users` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (
        table_name,
        operation,
        db_user,
        description,
        operation_date,
        operation_status
    )
    VALUES (
        'tb_users',
        'Update',
        USER(),
        CONCAT(
            'Usuario actualizado. ID=', NEW.ID,
            '. Cambios: ',
            CONCAT_WS(', ',
                IF(
                    NOT (OLD.email <=> NEW.email),
                    CONCAT(
                        'email: [',
                        COALESCE(OLD.email, 'NULL'),
                        '] -> [',
                        COALESCE(NEW.email, 'NULL'),
                        ']'
                    ),
                    NULL
                ),
                IF(
                    NOT (OLD.nickname <=> NEW.nickname),
                    CONCAT(
                        'nickname: [',
                        COALESCE(OLD.nickname, 'NULL'),
                        '] -> [',
                        COALESCE(NEW.nickname, 'NULL'),
                        ']'
                    ),
                    NULL
                )
            )
        ),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_users_after_delete` AFTER DELETE ON `tb_users` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (
        table_name,
        operation,
        db_user,
        description,
        operation_date,
        operation_status
    )
    VALUES (
        'tb_users',
        'Delete',
        USER(),
        CONCAT(
            'Usuario eliminado. ID=', OLD.ID,
            ', email=', COALESCE(OLD.email, 'NULL'),
            ', nickname=', COALESCE(OLD.nickname, 'NULL')
        ),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Dumping events for database 'db_test'
--

--
-- Dumping routines for database 'db_test'
--
/*!50003 DROP PROCEDURE IF EXISTS `sp_soft_delete_product` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_soft_delete_product`( IN p_product_id INT UNSIGNED)
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM tb_products
        WHERE ID = p_product_id
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El producto especificado no existe';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM tb_products
        WHERE ID = p_product_id
          AND status = b'0'
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El producto ya se encuentra eliminado';
    END IF;

    UPDATE tb_products
    SET status = b'0'
    WHERE ID = p_product_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-09-23 18:32:54
