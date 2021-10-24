-- phpMyAdmin SQL Dump
-- version 5.0.4
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 25-10-2021 a las 00:38:52
-- Versión del servidor: 10.4.17-MariaDB
-- Versión de PHP: 8.0.1

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `pi_ste`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_AddRequestMovement` (IN `apiTecnico` INT, IN `apiCantidad` INT, IN `apiPrecioCompra` INT, IN `apiTotal` INT, IN `apiIdItem` INT)  BEGIN
	
    SET @totalStock = (SELECT stock FROM inventario WHERE codigo = apiIdItem);
    
	SET @today = CURDATE();
    
    UPDATE inventario SET stock = (@totalStock - apiCantidad) WHERE codigo = apiIdItem;

	INSERT INTO rotation
         
         (
             tecnico,
             cantidad,
             precioCompra,
             total,
             fecha
         )
         
         VALUES 
         (
             apiTecnico,
          	 apiCantidad,
             apiPrecioCompra,
             apiTotal,
             @today
         );
         
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_AddTicketMove` (IN `apiIdTicket` INT)  BEGIN

SET @description = (SELECT CONCAT(marca,' - ',modelo) FROM ticket WHERE idTicket = apiIdTicket);
SET @amount = (SELECT totalPago FROM ticket WHERE idTicket = apiIdTicket);

SET @actualDay = ( SELECT NOW());

INSERT INTO movimientos (nombre,tipo,precio,idCorte,diaMovimiento,mesMovimiento,yearMovimiento)

VALUES

(@description,0,@amount,0,DAY(@actualDay),MONTH(@actualDay),YEAR(@actualDay));

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_CreateTicket` (IN `apiDiaRecoleccion` INT, IN `apiMesRecoleccion` INT, IN `apiRecolectionYear` INT, IN `apiDiaEntrega` INT, IN `apiMesEntrega` INT, IN `apiEntregaYear` INT, IN `apiModelo` VARCHAR(30) CHARSET utf8, IN `apiMarca` VARCHAR(30) CHARSET utf8, IN `apiDescripcion` VARCHAR(50) CHARSET utf8, IN `apiServicio` VARCHAR(50) CHARSET utf8, IN `apiCotizacion` FLOAT, IN `apiMedioPagoId` INT, IN `apiTotalPago` FLOAT, IN `apiTecnico` INT, IN `apiEstadoReparacion` INT, IN `apiNombreCliente` VARCHAR(50) CHARSET utf8, IN `apiNumeroCliente` BIGINT)  BEGIN

INSERT INTO ticket

	(
        diaRecoleccion , 
        mesRecoleccion, 
        recolectionYear,
        
    	diaEntrega,
        mesEntrega,
        entregaYear,
        
    	modelo,
        marca,
        descripcion,
        
    	servicio,
        cotizacion,
        medioPagoId,
        
    	totalPago,
        tecnico,
        estadoReparacion,
        
    	nombreCliente,
        numeroCliente
    )

VALUES
        
        (   apiDiaRecoleccion,
         	apiMesRecoleccion,
	        apiRecolectionYear,
         
         	apiDiaEntrega,
         	apiMesEntrega,
          	apiEntregaYear,
         
         	apiModelo,
         	apiMarca,           
         	apiDescripcion,
         
         	apiServicio,
         	apiCotizacion,
	        apiMedioPagoId,
         
         	apiTotalPago,
            apiTecnico,
         	apiEstadoReparacion,
         
         	apiNombreCliente,
         	apiNumeroCliente
        );
        
        SELECT LAST_INSERT_ID() AS idTicketCreated;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_GetAmount` ()  BEGIN 
CALL sp_GetCurrentAmount();
CALL sp_GetLastCurrentAmount();

SELECT 
	IFNULL(@currentAmounth,0) AS currentAmount,
    IF(ISNULL(@currentAmount),1,0) AS createAmount;
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_GetAnualInventory` ()  BEGIN

SET
    @lastDay =(
    SELECT
        DATE_FORMAT(NOW(), '%Y-12-31'));
    SET
        @firstDay =(
        SELECT
            DATE_FORMAT(NOW(), '%Y-01-01'));
        SET
            @anualInventorySold =(
            SELECT
                SUM(total)
            FROM
                rotation
            WHERE
                fecha BETWEEN @firstDay AND @lastDay
        );
        
        
        /**SELECT 
        	@totalInventory AS totalInventory,
            CONCAT('$',FORMAT(@totalInventory,2)) AS formated;*/
            
            END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_GetAverageTicket` ()  BEGIN

	SET @actualDay = DATE_FORMAT(CURDATE(),'%e');
        
        SET @sumatory = (SELECT 
            SUM(ticket.totalPago) AS sumatory
        FROM ticket

        WHERE
            ticket.diaRecoleccion = @actualDay
                       AND ticket.estadoReparacion = 2);
            
         SET @noTickets = (SELECT 
            COUNT(*) AS noTickets
        FROM ticket

        WHERE
            ticket.diaRecoleccion = @actualDay);

	SET @averageTicket = (@sumatory/@noTickets);
	
    SET @ticketSells = @sumatory;
    
    SET @averageTicket = (IFNULL(@averageTicket,0));
    
    SET @ticketSells = (IFNULL(@ticketSells,0));
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_GetCurrentAmount` ()  BEGIN

SET @actualDay = ( SELECT NOW());
    
SET @currentAmounth = (SELECT 
	montoInicial AS currentAmounth FROM dinero WHERE 
    	dia = DAY(@actualDay) AND
        mes = MONTH(@actualDay) AND
        yearTime = YEAR(@actualDay));
        
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_GetDayInventory` ()  BEGIN

    SET
        @today =(
    SELECT
        DATE(NOW()));
    SELECT
        SUM(total) AS daySolds
    FROM
        rotation
    WHERE
        fecha = @today;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_GetDaySuminister` ()  BEGIN
    CALL sp_GetInventoryValueV2();
    
    CALL sp_GetSellDaysAverage();
    
    SET @suministerDay = @inventoryValue/@averageSellsDay;   
    
    	SET @suministerDay = (IFNULL(@suministerDay,0));
   		
        SET @averageSellsDay = (IFNULL(@averageSellsDay,0));
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_GetInventoryAvailable` ()  BEGIN

SELECT 
	
    codigo AS id,
    descripcion AS description,
    stock AS stock,
    precioCompra as buyPrice,
    CONCAT(codigo,' - ',descripcion , ' (',stock,')') AS idDesc
    
FROM inventario WHERE stock > 0 ORDER BY codigo;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_GetInventoryRotation` ()  BEGIN

	CALL sp_GetAnualInventory(); 
    
    SET @rotationInventory = @anualInventorySold / @inventoryValue;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_GetInventoryValue` ()  NO SQL
BEGIN

	SELECT 
    SUM(inventario.stock*inventario.precioCompra) AS inventoryValue
    
    FROM inventario WHERE inventario.stock > 0;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_GetInventoryValueV2` ()  BEGIN

	SET @inventoryValue = (SELECT 
    SUM(inventario.stock*inventario.precioCompra) AS inventoryValue
    
    FROM inventario WHERE inventario.stock > 0);

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_GetLastCurrentAmount` ()  BEGIN

SET @lastCurrenAmount = (SELECT montoInicial FROM dinero ORDER BY idEstadoCaja DESC LIMIT 1);

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_GetManageStatics` ()  BEGIN
	
    /*
    Respect the order of the stored procedures
    
    1. CALL sp_GetAverageTicket();                  
    2. CALL sp_GetAnualInventory();
    3. CALL sp_GetInventoryValue();
    4. CALL sp_GetWeekInventory();
    5. CALL sp_GetDayInventory();
    
    */
    
	CALL sp_GetAverageTicket();                  
	CALL sp_GetAnualInventory();
    CALL sp_GetInventoryValue();
    CALL sp_GetWeekInventory();
    CALL sp_GetDayInventory();
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_GetManageStaticsV2` ()  BEGIN 
	
    CALL sp_GetAverageTicket();
    
	CALL sp_GetDaySuminister();
    
    CALL sp_GetWeekSuminister();
    
    CALL sp_GetInventoryRotation();

/* GENERATE DE JSON OBJECT */
    SET @result = (SELECT 
		JSON_OBJECT(
            
            'ticket',JSON_OBJECT(
            'average',@averageTicket,
            'sumatoryTickets',@ticketSells,
            'noTickets',@noTickets
            ),
        	'suministerDay', JSON_OBJECT(
            'average',@suministerDay,
            'averageSells',@averageSellsDay,
            'inventoryValue',@inventoryValue
            
            ),
            'suministerWeek',JSON_OBJECT(
            'average',@suministerWeek,
            'averageSells',@averageSellsWeek,
            'inventoryValue',@inventoryValue
            ),
            'rotation',JSON_OBJECT(
            'average',@rotationInventory
            )
        ) AS result);
 
/* CREATE THE ROOT OF THE JSON */
     SELECT @result AS result;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_GetNoTickets` (IN `apiTecnico` INT)  BEGIN

SELECT COUNT(tecnico) AS noTickets FROM ticket WHERE tecnico = apiTecnico;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_GetPayMethods` ()  BEGIN

SELECT 
                formaspago.id AS id,
                formaspago.nombre AS description

            FROM formaspago ORDER BY nombre ASC;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_GetRepairStatus` ()  BEGIN

SELECT
                reparacion_estatus.id AS id,
                reparacion_estatus.descripcion AS description

            FROM reparacion_estatus ORDER BY description ASC;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_GetSellDaysAverage` ()  BEGIN

SET @today = (SELECT NOW());

SET @actualDay = (SELECT DAYOFMONTH(@today));
SET @actualMonth = (SELECT MONTH(@today));
SET @actualYear = (SELECT YEAR(@today));

SET @averageSellsDay = (SELECT SUM(precio) FROM movimientos WHERE diaMovimiento = @actualDay AND mesMovimiento = @actualMonth AND yearMovimiento = @actualYear AND nombre LIKE '%accesorios%');

SET @averageSellsDay = @averageSellsDay * 10;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_GetSellWeekAverage` ()  BEGIN

/* https://dba.stackexchange.com/questions/15742/sql-query-to-get-last-day-of-every-week */
SET
    @lastDayWeek =(
    SELECT
        DATE(
            NOW() + INTERVAL(6 - WEEKDAY(NOW())) DAY));
            /* https://www.webstudying.net/notes/get-the-first-and-last-day-of-the-current-week-in-mysql/ */
        SET
            @firstDayWeek =(
            SELECT
                DATE_SUB(
                    CURDATE(), INTERVAL WEEKDAY(CURDATE()) + 0 DAY));

/* RANGE FOR THE START DATE */

SET @actualDayStart = (SELECT DAYOFMONTH(@firstDayWeek));
SET @actualMonthStart = (SELECT MONTH(@firstDayWeek));
SET @actualYearStart = (SELECT YEAR(@firstDayWeek));

/* RANGE FOR THE END DATE */

SET @actualDayEnd = (SELECT DAYOFMONTH(@lastDayWeek));
SET @actualMonthEnd = (SELECT MONTH(@lastDayWeek));
SET @actualYearEnd = (SELECT YEAR(@lastDayWeek));

SET @averageSellsWeek = (SELECT SUM(precio)
FROM movimientos
WHERE 
    (diaMovimiento >= @actualDayStart AND 
    diaMovimiento <= @actualDayEnd AND
    mesMovimiento >= @actualMonthStart AND
    mesMovimiento <= @actualMonthEnd AND
    yearMovimiento >= @actualYearStart AND
    yearMovimiento <= @actualYearEnd AND
    nombre LIKE '%accesorios%'
    ));
    
    SET @averageSellsWeek = @averageSellsWeek * 55;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_GetTicket` (IN `apiIdTicket` INT)  BEGIN

SELECT
	ticket.idTicket AS id,
    JSON_OBJECT(
        'fullName',ticket.nombreCliente,
        'phone',ticket.numeroCliente
    ) AS customer,
    
    ticket.tecnico AS idTechnician,
    ticket.estadoReparacion AS idRepairStatus,
    CONCAT(ticket.entregaYear,'-',ticket.mesEntrega,'-',ticket.diaEntrega) AS deliverDate,
    CONCAT(ticket.recolectionYear,'-',ticket.mesRecoleccion,'-',ticket.diaRecoleccion) AS recolectionDate,
    ticket.modelo AS model,
    ticket.marca AS fabricant,
    ticket.servicio AS idService,
    ticket.descripcion AS observations,
    ticket.medioPagoId AS idPayMethod,
    ticket.cotizacion AS quotation,
    ticket.totalPago AS amount
    
FROM ticket WHERE ticket.idTicket = apiIdTicket;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_GetTickets` (IN `apiIdTecnico` INT, IN `apiInicio` INT, IN `apiLimite` INT)  BEGIN

SELECT
    JSON_OBJECT(
        'id',ticket.idTicket,
        'recolection',CONCAT(ticket.diaRecoleccion,'/',ticket.mesRecoleccion,'/',ticket.recolectionYear),
        'deliver',CONCAT(ticket.diaEntrega,'/',ticket.mesEntrega,'/',ticket.entregaYear),
        'model',ticket.modelo,
        'reparation',JSON_OBJECT(
            'id',reparacion_estatus.id,
            'description',reparacion_estatus.descripcion
        ),
        'status',reparacion_estatus.descripcion

    ) AS ticket
    
	FROM ticket 

	INNER JOIN reparacion_estatus ON ticket.estadoReparacion  = reparacion_estatus.id 

	WHERE tecnico = apiIdTecnico ORDER BY ticket.idTicket DESC LIMIT apiInicio,apiLimite;

/*SELECT

    ticket.idTicket AS id,
    CONCAT(ticket.diaRecoleccion,'/',ticket.mesRecoleccion,'/',ticket.recolectionYear) AS recolection,
    CONCAT(ticket.diaEntrega,'/',ticket.mesEntrega,'/',ticket.entregaYear) AS deliver,
    ticket.modelo AS model,
    JSON_OBJECT(
        'id',reparacion_estatus.id,
        'descripcion',reparacion_estatus.descripcion
    )AS reparacion,
    reparacion_estatus.descripcion AS status
    
	FROM ticket 

	INNER JOIN reparacion_estatus ON ticket.estadoReparacion  = reparacion_estatus.id 

	WHERE tecnico = apiIdTecnico ORDER BY ticket.idTicket DESC LIMIT apiInicio,apiLimite;*/

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_GetUsers` ()  BEGIN

	SELECT
            usuario.id AS id,
            usuario.username AS userName,
            JSON_OBJECT(
                'id',usuario.rol
            ) AS rol,
            JSON_OBJECT(
                'first',usuario.nombre,
                'middle',usuario.nombre2,
                'pattern',usuario.paterno,
                'mother',usuario.materno,
                'fullName',CONCAT_WS(' ',usuario.nombre,usuario.nombre2,usuario.paterno,usuario.materno)
            ) AS name
        FROM usuario ORDER BY usuario.nombre ASC;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_GetWeekInventory` ()  BEGIN

/* https://dba.stackexchange.com/questions/15742/sql-query-to-get-last-day-of-every-week */
SET
    @lastDayWeek =(
    SELECT
        DATE(
            NOW() + INTERVAL(6 - WEEKDAY(NOW())) DAY));
            /* https://www.webstudying.net/notes/get-the-first-and-last-day-of-the-current-week-in-mysql/ */
        SET
            @firstDayWeek =(
            SELECT
                DATE_SUB(
                    CURDATE(), INTERVAL WEEKDAY(CURDATE()) + 0 DAY));
                SELECT
                    SUM(rotation.total) AS weekInventory
                    
                FROM
                    rotation
                WHERE
                    fecha BETWEEN @firstDayWeek AND @lastDayWeek;
                    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_GetWeekSuminister` ()  BEGIN

	CALL sp_GetInventoryValueV2();
    
    CALL sp_GetSellWeekAverage();
    
    SET @suministerWeek = @inventoryValue/@averageSellsWeek; 
    
	SET @suministerWeek = (IFNULL(@suministerWeek,0));
    
    SET @averageSellsWeek = (IFNULL(@suministerWeek,0));

END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `categoria`
--

CREATE TABLE `categoria` (
  `idCategoria` int(11) NOT NULL,
  `nombre` varchar(30) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `categoria`
--

INSERT INTO `categoria` (`idCategoria`, `nombre`) VALUES
(1, 'Reparacion'),
(2, 'Limpieza'),
(3, 'Pantallas'),
(4, 'Baterias'),
(5, 'Videojuegos'),
(6, 'Software');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `clientes`
--

CREATE TABLE `clientes` (
  `idCliente` int(11) NOT NULL,
  `primerNombre` varchar(15) NOT NULL,
  `segundoNombre` varchar(15) DEFAULT NULL,
  `apellidoPaterno` varchar(15) NOT NULL,
  `apellidoMaterno` varchar(15) NOT NULL,
  `numero` bigint(20) NOT NULL,
  `recomendadoPor` int(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `clientes`
--

INSERT INTO `clientes` (`idCliente`, `primerNombre`, `segundoNombre`, `apellidoPaterno`, `apellidoMaterno`, `numero`, `recomendadoPor`) VALUES
(1, 'Jose ', 'Luis', 'Perez ', 'Olguin', 8111932475, 1),
(2, 'Adrian', '', 'Alardin', 'Iracheta', 8121966517, 3),
(3, 'Miguel', 'Angel', 'Cazares', 'Caballero', 8164891501, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `contacto`
--

CREATE TABLE `contacto` (
  `idContacto` int(11) NOT NULL,
  `nombre` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `contacto`
--

INSERT INTO `contacto` (`idContacto`, `nombre`) VALUES
(1, 'Facebook'),
(2, 'Whatsapp'),
(3, 'Recomendacion');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `dinero`
--

CREATE TABLE `dinero` (
  `idEstadoCaja` int(11) NOT NULL,
  `montoInicial` float NOT NULL,
  `montoFinal` float NOT NULL,
  `dia` int(2) NOT NULL,
  `mes` int(2) NOT NULL,
  `yearTime` int(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `dinero`
--

INSERT INTO `dinero` (`idEstadoCaja`, `montoInicial`, `montoFinal`, `dia`, `mes`, `yearTime`) VALUES
(1, 999.99, 0, 9, 5, 2021),
(5, 350.01, 0, 11, 5, 2021),
(6, 350.01, 0, 13, 5, 2021),
(7, 350.01, 0, 14, 5, 2021),
(8, 350.01, 0, 15, 5, 2021),
(9, 350.01, 0, 16, 5, 2021),
(10, 350.01, 0, 17, 5, 2021),
(11, 350.01, 0, 18, 5, 2021),
(12, 350.01, 0, 2, 10, 2021),
(13, 350.01, 0, 3, 10, 2021),
(14, 350.01, 0, 4, 10, 2021),
(15, 350.01, 0, 9, 10, 2021),
(16, 350.01, 0, 10, 10, 2021),
(17, 350.01, 0, 21, 10, 2021),
(18, 350.01, 0, 22, 10, 2021),
(19, 350.01, 0, 24, 10, 2021);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `estados`
--

CREATE TABLE `estados` (
  `idEstado` int(11) NOT NULL,
  `nombreEstado` varchar(30) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `estados`
--

INSERT INTO `estados` (`idEstado`, `nombreEstado`) VALUES
(1, 'Apagado'),
(2, 'Chip'),
(3, 'Encendido'),
(4, 'Sim');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `formaspago`
--

CREATE TABLE `formaspago` (
  `id` int(11) NOT NULL,
  `nombre` varchar(30) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `formaspago`
--

INSERT INTO `formaspago` (`id`, `nombre`) VALUES
(1, 'Efectivo'),
(2, 'Tarjeta');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `gastos`
--

CREATE TABLE `gastos` (
  `idGasto` int(11) NOT NULL,
  `nombre` varchar(50) NOT NULL,
  `descripcion` longtext DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `gestion`
--

CREATE TABLE `gestion` (
  `id` int(11) NOT NULL,
  `descripcion` longtext NOT NULL,
  `gasto` int(20) NOT NULL,
  `tipo` int(1) NOT NULL,
  `dia` int(2) NOT NULL,
  `mes` int(2) NOT NULL,
  `yearData` int(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `inventario`
--

CREATE TABLE `inventario` (
  `codigo` int(11) NOT NULL,
  `nombre` varchar(30) NOT NULL,
  `descripcion` longtext NOT NULL,
  `stock` int(20) NOT NULL,
  `categoria` int(10) NOT NULL,
  `precioCompra` float NOT NULL,
  `precioVenta` float NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `inventario`
--

INSERT INTO `inventario` (`codigo`, `nombre`, `descripcion`, `stock`, `categoria`, `precioCompra`, `precioVenta`) VALUES
(18, '', 'Office 365', 0, 6, 800, 1000),
(19, '', 'Azure blob', 3, 6, 199.99, 249.99),
(20, '', 'App service', 9, 6, 149.99, 199.99);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `movimientos`
--

CREATE TABLE `movimientos` (
  `idMovimiento` int(11) NOT NULL,
  `nombre` varchar(20) NOT NULL,
  `tipo` tinyint(1) NOT NULL COMMENT '[1-Egreso]■[0-Ingreso]',
  `precio` float NOT NULL,
  `idCorte` int(11) DEFAULT NULL,
  `diaMovimiento` int(2) NOT NULL,
  `mesMovimiento` int(2) NOT NULL,
  `yearMovimiento` int(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `movimientos`
--

INSERT INTO `movimientos` (`idMovimiento`, `nombre`, `tipo`, `precio`, `idCorte`, `diaMovimiento`, `mesMovimiento`, `yearMovimiento`) VALUES
(1, 'Luz', 1, 399.99, 1, 9, 5, 2021),
(2, 'Internet', 1, 299.99, 1, 9, 5, 2021),
(3, 'Ventana rota', 1, 949.99, 1, 9, 5, 2021),
(14, 'Luz', 1, 499.99, 0, 16, 5, 2021),
(15, 'Rifa', 0, 1499.99, 0, 16, 5, 2021),
(16, 'Publicidad', 0, 489.18, 0, 16, 5, 2021),
(17, 'Luz', 1, 499.99, 0, 18, 5, 2021),
(19, 'Reparacion iphone', 0, 999.99, 0, 18, 5, 2021),
(20, 'Test', 0, 1000, 0, 4, 10, 2021),
(21, 'Test2', 1, 149.99, 0, 4, 10, 2021),
(22, 'accesorios', 0, 499.99, 0, 21, 10, 2021),
(23, 'Accesorios', 0, 199.99, 0, 21, 10, 2021),
(24, '1', 1, 1, 0, 24, 10, 2021),
(25, 'dasdas - dadas', 0, 12, 0, 24, 10, 2021),
(26, 'Nokia - Lumia', 0, 200, 0, 24, 10, 2021),
(27, 'Xiaomi - Galaxy', 0, 499, 0, 24, 10, 2021),
(28, 'Xiaomi - Galaxy', 0, 300, 0, 24, 10, 2021);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `pedidos`
--

CREATE TABLE `pedidos` (
  `pedido` int(11) NOT NULL,
  `cantidad` int(10) NOT NULL,
  `refaccion` varchar(40) NOT NULL,
  `marca` varchar(40) NOT NULL,
  `modelo` varchar(40) NOT NULL,
  `costoTotal` float NOT NULL,
  `concepto` longtext DEFAULT NULL,
  `dia` int(2) NOT NULL,
  `mes` int(2) NOT NULL,
  `yearTime` int(4) NOT NULL,
  `surtido` tinyint(4) NOT NULL COMMENT '[0 - No] [1 - Si]',
  `sucursal` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `pedidos`
--

INSERT INTO `pedidos` (`pedido`, `cantidad`, `refaccion`, `marca`, `modelo`, `costoTotal`, `concepto`, `dia`, `mes`, `yearTime`, `surtido`, `sucursal`) VALUES
(12, 3, 'Centro carga', 'Apple', 'Iphone 5', 0, NULL, 17, 5, 2021, 1, 1),
(13, 2, 'Mica', 'GlassPro', 'Iphone 5', 0, NULL, 17, 5, 2021, 1, 2),
(14, 1, 'Funda uso rudo', 'GlassPro', 'Iphone 5', 0, NULL, 17, 5, 2021, 1, 1),
(15, 1, 'Camara frontal', 'Nokia', 'Lumia', 0, NULL, 18, 5, 2021, 1, 1),
(16, 1, 'Camara trasera', 'Nokia', 'Lumia', 0, NULL, 18, 5, 2021, 0, 1),
(17, 1, 'Samsumg', 'Samsumg', 'Galaxy', 0, NULL, 2, 10, 2021, 1, 1),
(18, 1, 'Xiaomi', 'Xiaomi', 'Xiaomi', 0, NULL, 2, 10, 2021, 0, 1),
(19, 2, 'Pantalla generica', 'Xiaomi', 'Mi2Lite', 0, NULL, 3, 10, 2021, 0, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `reparacion_estatus`
--

CREATE TABLE `reparacion_estatus` (
  `id` int(11) NOT NULL,
  `descripcion` varchar(30) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `reparacion_estatus`
--

INSERT INTO `reparacion_estatus` (`id`, `descripcion`) VALUES
(1, 'En reparacion'),
(2, 'Reparado'),
(3, 'No reparado');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `rols`
--

CREATE TABLE `rols` (
  `id` int(11) NOT NULL,
  `descripcion` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `rols`
--

INSERT INTO `rols` (`id`, `descripcion`) VALUES
(1, 'PC'),
(2, 'Movil'),
(3, 'Super Admin');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `rotation`
--

CREATE TABLE `rotation` (
  `id` int(11) NOT NULL,
  `tecnico` int(11) NOT NULL,
  `cantidad` int(11) NOT NULL,
  `precioCompra` decimal(20,2) NOT NULL,
  `total` decimal(20,2) NOT NULL,
  `fecha` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `rotation`
--

INSERT INTO `rotation` (`id`, `tecnico`, `cantidad`, `precioCompra`, `total`, `fecha`) VALUES
(22, 3, 1, '200.00', '200.00', '2020-10-09 00:00:00'),
(23, 3, 1, '200.00', '200.00', '2021-09-02 00:00:00'),
(24, 3, 1, '200.00', '200.00', '2021-10-09 00:00:00'),
(25, 4, 4, '200.00', '800.00', '2021-10-09 00:00:00'),
(26, 4, 1, '200.00', '200.00', '2021-10-09 00:00:00'),
(27, 4, 1, '200.00', '200.00', '2021-10-09 00:00:00'),
(28, 4, 1, '150.00', '150.00', '2021-10-10 00:00:00');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `servicios`
--

CREATE TABLE `servicios` (
  `idServicio` int(11) NOT NULL,
  `nombre` varchar(255) DEFAULT NULL,
  `descripcion` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `servicios`
--

INSERT INTO `servicios` (`idServicio`, `nombre`, `descripcion`) VALUES
(1, 'Pantalla', 'Pantalla'),
(2, 'Bateria', 'Bateria'),
(3, 'Wifi', 'Wifi'),
(4, 'Memoria', 'Memoria'),
(5, 'Camara', 'Camara');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `sucursales`
--

CREATE TABLE `sucursales` (
  `id` int(11) NOT NULL,
  `municipio` varchar(30) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `sucursales`
--

INSERT INTO `sucursales` (`id`, `municipio`) VALUES
(1, 'San Nicolas'),
(2, 'Monterrey'),
(3, 'Guadalupe'),
(4, 'Apodaca');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `ticket`
--

CREATE TABLE `ticket` (
  `idTicket` int(11) NOT NULL,
  `diaRecoleccion` int(2) DEFAULT NULL,
  `mesRecoleccion` int(2) DEFAULT NULL,
  `recolectionYear` int(4) DEFAULT NULL,
  `diaEntrega` int(2) DEFAULT NULL,
  `mesEntrega` int(2) DEFAULT NULL,
  `entregaYear` int(4) DEFAULT NULL,
  `modelo` varchar(30) DEFAULT NULL,
  `marca` varchar(30) DEFAULT NULL,
  `descripcion` varchar(50) DEFAULT NULL,
  `servicio` varchar(50) DEFAULT NULL,
  `cotizacion` float DEFAULT NULL,
  `medioContactoId` int(11) DEFAULT NULL,
  `medioPagoId` int(11) DEFAULT NULL COMMENT '[1-Efectivo]■[0-Tarjeta]',
  `totalPago` float DEFAULT NULL,
  `tecnico` int(11) DEFAULT NULL,
  `estadoReparacion` int(1) DEFAULT NULL COMMENT '[0-Reparado] [1-No Reparado]',
  `estadoEquipo` int(11) DEFAULT NULL,
  `nombreCliente` varchar(50) DEFAULT NULL,
  `numeroCliente` bigint(15) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `ticket`
--

INSERT INTO `ticket` (`idTicket`, `diaRecoleccion`, `mesRecoleccion`, `recolectionYear`, `diaEntrega`, `mesEntrega`, `entregaYear`, `modelo`, `marca`, `descripcion`, `servicio`, `cotizacion`, `medioContactoId`, `medioPagoId`, `totalPago`, `tecnico`, `estadoReparacion`, `estadoEquipo`, `nombreCliente`, `numeroCliente`) VALUES
(100, 9, 10, 2021, 13, 10, 2021, 'Galaxy', 'Samsumg', 'Se ve oscuro', '5', 499, NULL, 1, 769, 3, 2, NULL, 'Juan  Perez Coronado', 8111985483),
(101, 9, 10, 2021, 11, 10, 2021, 'M2', 'Xiaomi', 'Se descarga rapido', '2', 899, NULL, 1, 1299, 5, 2, NULL, 'Maria  Garza Del Angel', 8819648494987),
(102, 9, 10, 2021, 17, 10, 2021, 'Iphone 13', 'Apple', 'Quiere un case', '1', 239, NULL, 1, 439, 3, 3, NULL, 'Maria  Santos Torres', 811868498414),
(103, 10, 10, 2021, 12, 10, 2021, 'Redmi', 'Xiaomi', 'AAAA', '5', 455, NULL, 2, 790, 5, 1, NULL, 'Sandra  Chacon Olivarez', 81654894834),
(104, 10, 10, 2021, 14, 10, 2021, '10', 'Iphone', 'BBBBB', '4', 689, NULL, 1, 1000, 5, 2, NULL, 'Mario  Leal Cardenas', 8184898494),
(105, 22, 10, 2021, 27, 10, 2021, 'Mia2lite', 'Xiaomi', 'a', '4', 499, NULL, 1, 679, 3, 2, NULL, 'Juana  Del arco Real', 81189484848),
(106, 24, 10, 2021, 26, 10, 2021, 'dadas', 'dasdas', 'adasda', '5', 12, NULL, 1, 12, 3, 2, NULL, 'aaa aaa aa aa', 31231231232),
(107, 24, 10, 2021, 27, 10, 2021, 'Lumia', 'Nokia', 'adasdas', '5', 100, NULL, 1, 200, 3, 2, NULL, 'adas dasdas dasdas dasdas', 3112321312),
(108, 24, 10, 2021, 26, 10, 2021, 'Mia2lite', 'Xiaomi', 'dasdasdas', '2', 100, NULL, 2, 150, 3, 1, NULL, 'fdsfsdfsdfsd fsdfsdfsd fsdfsdfsd fsdfsd', 123213123123),
(109, 24, 10, 2021, 27, 10, 2021, 'Galaxy', 'Xiaomi', 'adasd', '4', 12, NULL, 1, 20, 3, 3, NULL, 'dsfsdfs fsdfsdfsd sfsdfsdf fsdfdssd', 321312321342),
(110, 3, 10, 2021, 13, 10, 2021, 'Test', 'Test', 'Test', '2', 123, NULL, 2, 123, 3, 1, NULL, 'Test  Test Test', 123123123123312),
(111, 3, 10, 2021, 13, 10, 2021, 'Test', 'Test', 'Test', '2', 123, NULL, 2, 123, 3, 1, NULL, 'Test  Test Test', 123123123123312),
(112, 3, 10, 2021, 13, 10, 2021, 'Test', 'Test', 'Test', '2', 123, NULL, 2, 123, 3, 1, NULL, 'Test  Test Test', 123123123123312),
(113, 3, 10, 2021, 13, 10, 2021, 'Test', 'Test', 'Test', '2', 123, NULL, 2, 123, 3, 1, NULL, 'Test  Test Test', 123123123123312),
(114, 3, 10, 2021, 13, 10, 2021, 'Test', 'Test', 'Test', '2', 123, NULL, 2, 123, 3, 1, NULL, 'Test  Test Test', 123123123123312),
(115, 3, 10, 2021, 13, 10, 2021, 'Test', 'Test', 'Test', '2', 123, NULL, 2, 123, 3, 1, NULL, 'Test  Test Test', 123123123123312),
(116, 3, 10, 2021, 13, 10, 2021, 'Test', 'Test', 'Test', '2', 123, NULL, 2, 123, 3, 1, NULL, 'Test  Test Test', 123123123123312),
(117, 3, 10, 2021, 13, 10, 2021, 'Test', 'Test', 'Test', '2', 123, NULL, 2, 123, 3, 1, NULL, 'Test  Test Test', 123123123123312),
(118, 3, 10, 2021, 13, 10, 2021, 'Test', 'Test', 'Test', '2', 123, NULL, 2, 123, 3, 1, NULL, 'Test  Test Test', 123123123123312),
(119, 3, 10, 2021, 13, 10, 2021, 'Test', 'Test', 'Test', '2', 123, NULL, 2, 123, 3, 1, NULL, 'Test  Test Test', 123123123123312),
(120, 24, 10, 2021, 28, 10, 2021, 'Galaxy', 'Xiaomi', '', '4', 399, NULL, 1, 499, 3, 2, NULL, 'Mario  Bros Perez', 45148488484),
(121, 24, 10, 2021, 24, 10, 2021, 'Galaxy', 'Xiaomi', '', '4', 250, NULL, 1, 300, 3, 2, NULL, 'Luigi  Bros Perez', 51548484949);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `ticketestados`
--

CREATE TABLE `ticketestados` (
  `idTicketsEstado` int(11) NOT NULL,
  `idEstadoTicketNombre` int(11) NOT NULL,
  `ticketCorresponde` int(11) NOT NULL,
  `estado` tinyint(4) NOT NULL COMMENT '[1-Check]■[0-NotCheck]'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `ticketestados`
--

INSERT INTO `ticketestados` (`idTicketsEstado`, `idEstadoTicketNombre`, `ticketCorresponde`, `estado`) VALUES
(13, 1, 38, 1),
(14, 2, 38, 1),
(15, 3, 38, 0),
(16, 4, 38, 1),
(17, 1, 39, 0),
(18, 2, 39, 1),
(19, 3, 39, 1),
(20, 4, 39, 1),
(21, 1, 40, 0),
(22, 2, 40, 1),
(23, 3, 40, 1),
(24, 4, 40, 1),
(25, 1, 41, 1),
(26, 2, 41, 0),
(27, 3, 41, 0),
(28, 4, 41, 0);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuario`
--

CREATE TABLE `usuario` (
  `id` int(11) NOT NULL,
  `username` varchar(15) NOT NULL,
  `password` varchar(100) NOT NULL,
  `rol` int(11) NOT NULL,
  `sucursal` int(11) NOT NULL,
  `nombre` varchar(20) CHARACTER SET utf8 DEFAULT NULL,
  `nombre2` varchar(20) CHARACTER SET utf8 DEFAULT NULL,
  `paterno` varchar(20) CHARACTER SET utf8 DEFAULT NULL,
  `materno` varchar(20) CHARACTER SET utf8 DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `usuario`
--

INSERT INTO `usuario` (`id`, `username`, `password`, `rol`, `sucursal`, `nombre`, `nombre2`, `paterno`, `materno`) VALUES
(3, 'prog51', '$2b$10$337buhKls4t87PRgiPi6seL3YRwfdELTiDC7xtFFuhTh1gMROBf3O', 1, 1, 'Jose', 'Luis', 'Perez', 'Olguin'),
(4, 'JLPO1', '$2b$10$W9rc7kxqkMRLL4.2nMgeOuvVP9adgf4rcV8h2mCnzVM3qkuTMM/zS', 3, 1, 'Adrian', NULL, 'Alardin', 'Iracheta'),
(5, 'JLPO2', '$2b$10$UsxltFKWhGMHBm.y2TWx6OYeUxWaWhWBH6.NdFwI0ZsZDFCLxhYqy', 3, 1, 'Luis', '', 'Jaramillo', 'Nose');

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `categoria`
--
ALTER TABLE `categoria`
  ADD PRIMARY KEY (`idCategoria`);

--
-- Indices de la tabla `clientes`
--
ALTER TABLE `clientes`
  ADD PRIMARY KEY (`idCliente`);

--
-- Indices de la tabla `contacto`
--
ALTER TABLE `contacto`
  ADD PRIMARY KEY (`idContacto`);

--
-- Indices de la tabla `dinero`
--
ALTER TABLE `dinero`
  ADD PRIMARY KEY (`idEstadoCaja`);

--
-- Indices de la tabla `estados`
--
ALTER TABLE `estados`
  ADD PRIMARY KEY (`idEstado`);

--
-- Indices de la tabla `formaspago`
--
ALTER TABLE `formaspago`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `gastos`
--
ALTER TABLE `gastos`
  ADD PRIMARY KEY (`idGasto`);

--
-- Indices de la tabla `gestion`
--
ALTER TABLE `gestion`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `inventario`
--
ALTER TABLE `inventario`
  ADD PRIMARY KEY (`codigo`),
  ADD KEY `categoria` (`categoria`);

--
-- Indices de la tabla `movimientos`
--
ALTER TABLE `movimientos`
  ADD PRIMARY KEY (`idMovimiento`);

--
-- Indices de la tabla `pedidos`
--
ALTER TABLE `pedidos`
  ADD PRIMARY KEY (`pedido`);

--
-- Indices de la tabla `reparacion_estatus`
--
ALTER TABLE `reparacion_estatus`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `rols`
--
ALTER TABLE `rols`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `rotation`
--
ALTER TABLE `rotation`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `servicios`
--
ALTER TABLE `servicios`
  ADD PRIMARY KEY (`idServicio`);

--
-- Indices de la tabla `sucursales`
--
ALTER TABLE `sucursales`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `ticket`
--
ALTER TABLE `ticket`
  ADD PRIMARY KEY (`idTicket`);

--
-- Indices de la tabla `ticketestados`
--
ALTER TABLE `ticketestados`
  ADD PRIMARY KEY (`idTicketsEstado`);

--
-- Indices de la tabla `usuario`
--
ALTER TABLE `usuario`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `categoria`
--
ALTER TABLE `categoria`
  MODIFY `idCategoria` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT de la tabla `clientes`
--
ALTER TABLE `clientes`
  MODIFY `idCliente` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `contacto`
--
ALTER TABLE `contacto`
  MODIFY `idContacto` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `dinero`
--
ALTER TABLE `dinero`
  MODIFY `idEstadoCaja` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

--
-- AUTO_INCREMENT de la tabla `estados`
--
ALTER TABLE `estados`
  MODIFY `idEstado` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `formaspago`
--
ALTER TABLE `formaspago`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `gastos`
--
ALTER TABLE `gastos`
  MODIFY `idGasto` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `gestion`
--
ALTER TABLE `gestion`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `inventario`
--
ALTER TABLE `inventario`
  MODIFY `codigo` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- AUTO_INCREMENT de la tabla `movimientos`
--
ALTER TABLE `movimientos`
  MODIFY `idMovimiento` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=29;

--
-- AUTO_INCREMENT de la tabla `pedidos`
--
ALTER TABLE `pedidos`
  MODIFY `pedido` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

--
-- AUTO_INCREMENT de la tabla `reparacion_estatus`
--
ALTER TABLE `reparacion_estatus`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `rols`
--
ALTER TABLE `rols`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `rotation`
--
ALTER TABLE `rotation`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=29;

--
-- AUTO_INCREMENT de la tabla `servicios`
--
ALTER TABLE `servicios`
  MODIFY `idServicio` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `sucursales`
--
ALTER TABLE `sucursales`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `ticket`
--
ALTER TABLE `ticket`
  MODIFY `idTicket` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=122;

--
-- AUTO_INCREMENT de la tabla `ticketestados`
--
ALTER TABLE `ticketestados`
  MODIFY `idTicketsEstado` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=29;

--
-- AUTO_INCREMENT de la tabla `usuario`
--
ALTER TABLE `usuario`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `gastos`
--
ALTER TABLE `gastos`
  ADD CONSTRAINT `gastos_ibfk_1` FOREIGN KEY (`idGasto`) REFERENCES `gestion` (`id`);

--
-- Filtros para la tabla `inventario`
--
ALTER TABLE `inventario`
  ADD CONSTRAINT `inventario_ibfk_1` FOREIGN KEY (`categoria`) REFERENCES `categoria` (`idCategoria`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
