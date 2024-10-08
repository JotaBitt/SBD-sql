-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Tempo de geração: 09/10/2024 às 01:39
-- Versão do servidor: 10.4.32-MariaDB
-- Versão do PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Banco de dados: `sbd`
--

DELIMITER $$
--
-- Procedimentos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `processar_pedidos` ()   BEGIN

    DECLARE v_codigoPedido INT;
    DECLARE v_statusPedido VARCHAR(20);
    DECLARE v_codigoProduto VARCHAR(20);
    DECLARE v_quantidade INT;
    DECLARE pronto INT DEFAULT 0;
    DECLARE cursor_pedidos CURSOR FOR SELECT codigoPedido, status FROM pedidos;
    DECLARE cursor_itens CURSOR FOR SELECT SKU, quantidade FROM itens_pedidos;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET pronto = 1;


    -- Inserir os dados na tabela de produtos 
    INSERT INTO produtos (SKU, UPC, nomeProduto, valor) 
    SELECT DISTINCT t.SKU, t.UPC, t.nomeProduto, t.valor 
    FROM tempdata t
    LEFT JOIN produtos p ON t.SKU = p.SKU
    WHERE p.SKU IS NULL;

    -- Insere os produtos na tabela de pedidos
    INSERT INTO pedidos (codigoPedido, codigoComprador, dataPedido, valor, status) 
    SELECT DISTINCT t.codigoPedido, t.codigoComprador, t.dataPedido, t.valor, 'pendente' 
    FROM tempdata t
    LEFT JOIN pedidos p ON t.codigoPedido = p.codigoPedido
    WHERE p.codigoPedido IS NULL;

    -- Insere os dados na tabela de itens de pedido
    INSERT INTO itens_pedidos (codigoPedido, SKU, quantidade, valor_unitario) 
    SELECT DISTINCT t.codigoPedido, t.SKU, t.qtd, t.valor
    FROM tempdata t
    LEFT JOIN itens_pedidos ip ON t.codigoPedido = ip.codigoPedido AND t.SKU = ip.SKU
    WHERE ip.codigoPedido IS NULL;

    -- Insere os dados na tabela de entregas
    INSERT INTO entregas (codigoPedido, endereco, CEP, UF, pais, valor)
    SELECT DISTINCT t.codigoPedido, t.endereco, t.CEP, t.UF, t.pais, t.frete
    FROM tempdata t
    LEFT JOIN entregas e ON t.codigoPedido = e.codigoPedido
    WHERE e.codigoPedido IS NULL
    GROUP BY t.codigoPedido, t.endereco, t.CEP, t.UF, t.pais, t.frete;

    -- Insere os clientes na tabela de clientes
    INSERT INTO clientes (codigoComprador, nomeComprador, email) 
    SELECT DISTINCT t.codigoComprador, t.nomeComprador, t.email
    FROM tempdata t
    LEFT JOIN clientes c ON t.codigoComprador = c.codigoComprador
    WHERE c.codigoComprador IS NULL;


    -- Insere os dados na tabela de estoque 
    INSERT INTO estoque (SKU) SELECT SKU FROM tempdata GROUP BY SKU;

    -- Limpar a tabela `tempdata`
    TRUNCATE TABLE tempdata;

    OPEN cursor_pedidos;

    -- Loop para processar os pedidos pendentes
    pedidos_loop: LOOP

        -- armazenar a cada execução nas variáveis
        FETCH cursor_pedidos INTO v_codigoPedido, v_statusPedido;
        
        -- acabou as linhas, sair do loop
        IF pronto THEN
            LEAVE pedidos_loop;
        END IF;

        -- Verifica se o pedido está em análise ou pendente
        IF v_statusPedido = 'pendente' THEN

            OPEN cursor_itens;

            itens_loop: LOOP

                FETCH cursor_itens INTO v_codigoProduto, v_quantidade;

                -- Acabou as linhas, sair do loop
                IF pronto THEN
                    LEAVE itens_loop;
                END IF;

                -- Para cada item do pedido, verificar se existe estoque
                IF (SELECT quantidade FROM estoque WHERE SKU = v_codigoProduto) >= v_quantidade THEN

                    -- Atualizar o status do pedido
                    UPDATE itens_pedidos SET status = 'aprovado' WHERE codigoPedido = v_codigoPedido AND SKU = v_codigoProduto;

                    -- Atualizar a qtd do SKU na tabela de estoque
                    UPDATE estoque SET quantidade = quantidade - v_quantidade WHERE SKU = v_codigoProduto;

                ELSE
                    
                        -- Se não tiver estoque, atualizar o status do pedido para "pendente"
                        UPDATE pedidos SET status = 'pendente' WHERE codigoPedido = v_codigoPedido;

                        -- Atualizar o status do item do pedido para "pendente"
                        UPDATE itens_pedidos SET status = 'pendente' WHERE codigoPedido = v_codigoPedido AND SKU = v_codigoProduto;

                        -- Solicitar compra
                        -- Se tiver na lista de compras, atualizar a qtd
                        IF EXISTS (SELECT 1 FROM compras WHERE SKU = v_codigoProduto) THEN
                            UPDATE compras SET quantidade = quantidade + v_quantidade WHERE SKU = v_codigoProduto;
                        ELSE
                            
                            INSERT INTO compras (SKU, quantidade) VALUES (v_codigoProduto, v_quantidade - (SELECT quantidade FROM estoque WHERE SKU = v_codigoProduto));
                        
                        END IF;
    
                    END IF;

            END LOOP;

            CLOSE cursor_itens;

            -- Se todos os itens do pedido foram aprovados, atualizar o status do pedido
            IF NOT EXISTS (SELECT 1 FROM itens_pedidos WHERE codigoPedido = v_codigoPedido AND status = 'pendente') THEN
                UPDATE pedidos SET status = 'aprovado' WHERE codigoPedido = v_codigoPedido;
            END IF;

        END IF;

    END LOOP;

    CLOSE cursor_pedidos;

END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estrutura para tabela `clientes`
--

CREATE TABLE `clientes` (
  `id` int(11) NOT NULL,
  `codigoComprador` varchar(32) NOT NULL,
  `nomeComprador` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `clientes`
--

INSERT INTO `clientes` (`id`, `codigoComprador`, `nomeComprador`, `email`) VALUES
(9, '789', 'Fulano', 'teste@gmail.com');
(4, '1004', 'Ana Souza', 'ana@gmail.com'),
(2, '1002', 'Maria Oliveira', 'maria@gmail.com'),
(5, '1005', 'Lucas Costa', 'lucas@gmail.com'),
(3, '1003', 'Pedro Santos', 'pedro@gmail.com'),
(8, '123', 'Samir', 'samir@gmail.com'),
(1, '1001', 'João Silva', 'joao@gmail.com'),

-- --------------------------------------------------------

--
-- Estrutura para tabela `compras`
--

CREATE TABLE `compras` (
  `id` int(11) NOT NULL,
  `SKU` varchar(20) NOT NULL,
  `quantidade` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `compras`
--

INSERT INTO `compras` (`id`, `SKU`, `quantidade`) VALUES
(9, 'roupa123rio', 10);
(2, 'CAL002', 3202),
(1, 'BON005', 3008),
(5, 'JAQ004', 3357),
(7, 'brinq456rio', 5),
(6, 'CAM001', 2731),
(4, 'TEN003', 2967),
(8, 'brinq789rio', 10),
(3, 'MOC006', 3522),

-- --------------------------------------------------------

--
-- Estrutura para tabela `entregas`
--

CREATE TABLE `entregas` (
  `id` int(11) NOT NULL,
  `codigoPedido` varchar(32) NOT NULL,
  `endereco` varchar(255) NOT NULL,
  `CEP` varchar(11) NOT NULL,
  `UF` varchar(2) NOT NULL,
  `pais` varchar(20) NOT NULL,
  `valor` float(5,2) NOT NULL DEFAULT 0.00
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `entregas`
--

INSERT INTO `entregas` (`id`, `codigoPedido`, `endereco`, `CEP`, `UF`, `pais`, `valor`) VALUES
(1, 'P001', 'Av. E, 202', '56789-012', 'RS', 'Brasil\r', 34.00),
(2, 'P002', 'Rua A, 123', '12345-678', 'SP', 'Brasil\r', 21.00),
(3, 'P003', 'Av. B, 456', '23456-789', 'RJ', 'Brasil\r', 44.00),
(4, 'P004', 'Rua C, 789', '34567-890', 'MG', 'Brasil\r', 30.00),
(5, 'P005', 'Av. E, 202', '56789-012', 'RS', 'Brasil\r', 43.00),
(6, 'P006', 'Av. B, 456', '23456-789', 'RJ', 'Brasil\r', 32.00),
(7, 'P007', 'Av. E, 202', '56789-012', 'RS', 'Brasil\r', 18.00),
(8, 'P008', 'Av. E, 202', '56789-012', 'RS', 'Brasil\r', 47.00),
(9, 'P009', 'Rua D, 101', '45678-901', 'BA', 'Brasil\r', 22.00),
(10, 'P010', 'Rua A, 123', '12345-678', 'SP', 'Brasil\r', 12.00),
(11, 'P011', 'Rua A, 123', '12345-678', 'SP', 'Brasil\r', 17.00),
(12, 'P012', 'Rua C, 789', '34567-890', 'MG', 'Brasil\r', 49.00),
(13, 'P013', 'Av. E, 202', '56789-012', 'RS', 'Brasil\r', 20.00),
(14, 'P014', 'Rua C, 789', '34567-890', 'MG', 'Brasil\r', 18.00),
(15, 'P015', 'Rua C, 789', '34567-890', 'MG', 'Brasil\r', 41.00),
(16, 'P016', 'Rua C, 789', '34567-890', 'MG', 'Brasil\r', 25.00),
(17, 'P017', 'Rua D, 101', '45678-901', 'BA', 'Brasil\r', 34.00),
(18, 'P018', 'Av. E, 202', '56789-012', 'RS', 'Brasil\r', 45.00),
(19, 'P019', 'Rua D, 101', '45678-901', 'BA', 'Brasil\r', 43.00),
(20, 'P020', 'Rua C, 789', '34567-890', 'MG', 'Brasil\r', 32.00),
(21, 'P021', 'Av. E, 202', '56789-012', 'RS', 'Brasil\r', 49.00),
(22, 'P022', 'Av. B, 456', '23456-789', 'RJ', 'Brasil\r', 38.00),
(23, 'P023', 'Rua C, 789', '34567-890', 'MG', 'Brasil\r', 30.00),
(24, 'P024', 'Av. B, 456', '23456-789', 'RJ', 'Brasil\r', 11.00),
(25, 'P025', 'Av. B, 456', '23456-789', 'RJ', 'Brasil\r', 44.00),
(26, 'P026', 'Av. B, 456', '23456-789', 'RJ', 'Brasil\r', 11.00),
(27, 'P027', 'Av. E, 202', '56789-012', 'RS', 'Brasil\r', 45.00),
(28, 'P028', 'Av. B, 456', '23456-789', 'RJ', 'Brasil\r', 30.00),
(29, 'P029', 'Rua C, 789', '34567-890', 'MG', 'Brasil\r', 29.00),
(30, 'P030', 'Rua A, 123', '12345-678', 'SP', 'Brasil\r', 32.00),
(31, 'P031', 'Rua D, 101', '45678-901', 'BA', 'Brasil\r', 17.00),
(32, 'P032', 'Av. B, 456', '23456-789', 'RJ', 'Brasil\r', 37.00),
(33, 'P033', 'Av. E, 202', '56789-012', 'RS', 'Brasil\r', 14.00),
(34, 'P034', 'Av. E, 202', '56789-012', 'RS', 'Brasil\r', 33.00),
(35, 'P035', 'Rua D, 101', '45678-901', 'BA', 'Brasil\r', 19.00),
(36, 'P036', 'Av. E, 202', '56789-012', 'RS', 'Brasil\r', 30.00),
(37, 'P037', 'Rua A, 123', '12345-678', 'SP', 'Brasil\r', 30.00),
(38, 'P038', 'Rua A, 123', '12345-678', 'SP', 'Brasil\r', 29.00),
(39, 'P039', 'Rua C, 789', '34567-890', 'MG', 'Brasil\r', 23.00),
(40, 'P040', 'Av. B, 456', '23456-789', 'RJ', 'Brasil\r', 19.00),
(41, 'P041', 'Rua A, 123', '12345-678', 'SP', 'Brasil\r', 42.00),
(42, 'P042', 'Rua C, 789', '34567-890', 'MG', 'Brasil\r', 28.00),
(43, 'P043', 'Av. E, 202', '56789-012', 'RS', 'Brasil\r', 22.00),
(44, 'P044', 'Av. B, 456', '23456-789', 'RJ', 'Brasil\r', 24.00),
(45, 'P045', 'Rua C, 789', '34567-890', 'MG', 'Brasil\r', 25.00),
(46, 'P046', 'Rua D, 101', '45678-901', 'BA', 'Brasil\r', 33.00),
(47, 'P047', 'Av. E, 202', '56789-012', 'RS', 'Brasil\r', 12.00),
(48, 'P048', 'Av. E, 202', '56789-012', 'RS', 'Brasil\r', 49.00),
(49, 'P049', 'Av. E, 202', '56789-012', 'RS', 'Brasil\r', 28.00),
(50, 'P050', 'Rua C, 789', '34567-890', 'MG', 'Brasil\r', 36.00),


-- --------------------------------------------------------

--
-- Estrutura para tabela `estoque`
--

CREATE TABLE `estoque` (
  `id` int(11) NOT NULL,
  `SKU` varchar(20) NOT NULL,
  `quantidade` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `estoque`
--

INSERT INTO `estoque` (`id`, `SKU`, `quantidade`) VALUES
(9, 'brinq789rio', 0),
(2, 'CAL002', 0),
(6, 'TEN003', 0),
(8, 'brinq456rio', 0),
(4, 'JAQ004', 0),
(3, 'CAM001', 0),
(5, 'MOC006', 0),
(1, 'BON005', 0),
(10, 'roupa123rio', 0);

-- --------------------------------------------------------

--
-- Estrutura para tabela `itens_pedidos`
--

CREATE TABLE `itens_pedidos` (
  `id` int(11) NOT NULL,
  `codigoPedido` varchar(20) NOT NULL,
  `SKU` varchar(20) NOT NULL,
  `quantidade` int(11) NOT NULL,
  `valor` float(5,2) NOT NULL DEFAULT 0.00,
  `status` enum('aprovado','cancelado','pendente') NOT NULL DEFAULT 'pendente'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `itens_pedidos`
--

INSERT INTO `itens_pedidos` (`id`, `codigoPedido`, `SKU`, `quantidade`, `valor`, `status`) VALUES
(1, 'P001', 'BON005', 1, 214.62, 'pendente'),
(2, 'P002', 'CAL002', 2, 86.89, 'pendente'),
(3, 'P003', 'BON005', 2, 53.24, 'pendente'),
(4, 'P003', 'MOC006', 1, 289.89, 'pendente'),
(5, 'P004', 'BON005', 5, 37.43, 'pendente'),
(6, 'P004', 'MOC006', 1, 286.64, 'pendente'),
(7, 'P004', 'TEN003', 1, 239.65, 'pendente'),
(8, 'P005', 'CAL002', 3, 98.79, 'pendente'),
(9, 'P005', 'MOC006', 3, 57.65, 'pendente'),
(10, 'P006', 'BON005', 5, 22.15, 'pendente'),
(11, 'P006', 'CAL002', 1, 83.42, 'pendente'),
(12, 'P007', 'JAQ004', 1, 295.25, 'pendente'),
(13, 'P007', 'MOC006', 4, 32.10, 'pendente'),
(14, 'P008', 'CAM001', 3, 80.36, 'pendente'),
(15, 'P008', 'MOC006', 1, 159.26, 'pendente'),
(16, 'P009', 'CAL002', 1, 159.21, 'pendente'),
(17, 'P009', 'TEN003', 3, 84.51, 'pendente'),
(18, 'P010', 'CAM001', 5, 20.18, 'pendente'),
(19, 'P010', 'JAQ004', 2, 141.02, 'pendente'),
(20, 'P011', 'TEN003', 3, 24.75, 'pendente'),
(21, 'P012', 'CAL002', 5, 20.80, 'pendente'),
(22, 'P012', 'CAM001', 4, 45.17, 'pendente'),
(23, 'P012', 'MOC006', 4, 34.69, 'pendente'),
(24, 'P013', 'BON005', 1, 289.31, 'pendente'),
(25, 'P013', 'MOC006', 1, 105.04, 'pendente'),
(26, 'P014', 'TEN003', 2, 73.94, 'pendente'),
(27, 'P015', 'BON005', 3, 84.51, 'pendente'),
(28, 'P015', 'TEN003', 1, 206.13, 'pendente'),
(29, 'P016', 'TEN003', 5, 53.28, 'pendente'),
(30, 'P017', 'CAM001', 4, 23.94, 'pendente'),
(31, 'P017', 'JAQ004', 4, 35.24, 'pendente'),
(32, 'P018', 'JAQ004', 3, 70.75, 'pendente'),
(33, 'P018', 'MOC006', 5, 43.94, 'pendente'),
(34, 'P019', 'JAQ004', 3, 61.21, 'pendente'),
(35, 'P020', 'MOC006', 5, 10.73, 'pendente'),
(36, 'P020', 'TEN003', 1, 231.20, 'pendente'),
(37, 'P021', 'CAL002', 2, 106.88, 'pendente'),
(38, 'P022', 'BON005', 2, 124.60, 'pendente'),
(39, 'P023', 'CAL002', 1, 95.32, 'pendente'),
(40, 'P023', 'JAQ004', 1, 195.15, 'pendente'),
(41, 'P024', 'MOC006', 3, 58.49, 'pendente'),
(42, 'P025', 'BON005', 2, 40.30, 'pendente'),
(43, 'P025', 'TEN003', 4, 73.43, 'pendente'),
(44, 'P026', 'TEN003', 3, 65.64, 'pendente'),
(45, 'P027', 'JAQ004', 5, 27.97, 'pendente'),
(46, 'P027', 'MOC006', 1, 269.04, 'pendente'),
(47, 'P028', 'JAQ004', 5, 37.45, 'pendente'),
(48, 'P029', 'BON005', 3, 44.26, 'pendente'),
(49, 'P030', 'BON005', 2, 143.36, 'pendente'),
(50, 'P031', 'CAM001', 5, 11.55, 'pendente'),
(51, 'P031', 'JAQ004', 3, 24.56, 'pendente'),
(52, 'P031', 'MOC006', 3, 65.69, 'pendente'),
(53, 'P032', 'BON005', 4, 19.23, 'pendente'),
(54, 'P032', 'CAL002', 3, 41.86, 'pendente'),
(55, 'P033', 'MOC006', 1, 85.95, 'pendente'),
(56, 'P033', 'TEN003', 1, 227.23, 'pendente'),
(57, 'P034', 'CAM001', 1, 275.39, 'pendente'),
(58, 'P035', 'MOC006', 3, 63.19, 'pendente'),
(59, 'P035', 'TEN003', 2, 55.10, 'pendente'),
(60, 'P036', 'MOC006', 2, 62.01, 'pendente'),
(61, 'P036', 'TEN003', 2, 134.90, 'pendente'),
(62, 'P037', 'CAM001', 2, 81.94, 'pendente'),
(63, 'P038', 'BON005', 3, 41.74, 'pendente'),
(64, 'P039', 'BON005', 2, 104.82, 'pendente'),
(65, 'P039', 'CAL002', 4, 16.96, 'pendente'),
(66, 'P039', 'TEN003', 5, 12.89, 'pendente'),
(67, 'P040', 'JAQ004', 3, 59.23, 'pendente'),
(68, 'P040', 'TEN003', 3, 94.26, 'pendente'),
(69, 'P041', 'CAL002', 5, 39.76, 'pendente'),
(70, 'P041', 'JAQ004', 1, 265.06, 'pendente'),
(71, 'P041', 'TEN003', 5, 33.42, 'pendente'),
(72, 'P042', 'CAL002', 3, 48.43, 'pendente'),
(73, 'P042', 'CAM001', 5, 19.77, 'pendente'),
(74, 'P042', 'MOC006', 2, 42.17, 'pendente'),
(75, 'P043', 'JAQ004', 3, 78.49, 'pendente'),
(76, 'P043', 'TEN003', 1, 234.49, 'pendente'),
(77, 'P044', 'BON005', 5, 26.36, 'pendente'),
(78, 'P044', 'JAQ004', 5, 52.23, 'pendente'),
(79, 'P045', 'BON005', 5, 18.41, 'pendente'),
(80, 'P045', 'CAL002', 4, 55.17, 'pendente'),
(81, 'P045', 'JAQ004', 1, 265.34, 'pendente'),
(82, 'P046', 'BON005', 5, 58.24, 'pendente'),
(83, 'P046', 'CAL002', 4, 25.25, 'pendente'),
(84, 'P046', 'TEN003', 2, 35.54, 'pendente'),
(85, 'P047', 'CAL002', 5, 14.50, 'pendente'),
(86, 'P047', 'JAQ004', 5, 35.89, 'pendente'),
(87, 'P048', 'TEN003', 5, 14.99, 'pendente'),
(88, 'P049', 'JAQ004', 5, 55.37, 'pendente'),
(89, 'P049', 'MOC006', 2, 135.09, 'pendente'),
(90, 'P049', 'TEN003', 2, 120.36, 'pendente'),
(91, 'P050', 'JAQ004', 2, 26.54, 'pendente'),
(92, 'P051', 'CAM001', 4, 53.22, 'pendente'),
(93, 'P052', 'CAM001', 4, 62.97, 'pendente'),
(94, 'P053', 'CAL002', 1, 179.67, 'pendente'),
(95, 'P054', 'CAL002', 1, 297.00, 'pendente'),
(96, 'P055', 'CAM001', 5, 46.19, 'pendente'),
(97, 'P055', 'JAQ004', 3, 80.85, 'pendente'),
(98, 'P055', 'TEN003', 4, 45.94, 'pendente'),
(99, 'P056', 'TEN003', 1, 130.66, 'pendente'),
(100, 'P057', 'CAM001', 4, 40.59, 'pendente'),


-- --------------------------------------------------------

--
-- Estrutura para tabela `pedidos`
--

CREATE TABLE `pedidos` (
  `id` int(11) NOT NULL,
  `codigoPedido` varchar(32) NOT NULL,
  `codigoComprador` varchar(32) NOT NULL,
  `dataPedido` date NOT NULL,
  `valor` float(5,2) NOT NULL,
  `status` enum('aprovado','cancelado','pendente') NOT NULL DEFAULT 'pendente'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `pedidos`
--

INSERT INTO `pedidos` (`id`, `codigoPedido`, `codigoComprador`, `dataPedido`, `valor`, `status`) VALUES
(1, 'P001', '1005', '2024-09-09', 214.62, 'pendente'),
(2, 'P002', '1001', '2024-09-11', 173.78, 'pendente'),
(3, 'P003', '1002', '2024-09-22', 289.89, 'pendente'),
(4, 'P004', '1003', '2024-09-20', 239.65, 'pendente'),
(5, 'P005', '1005', '2024-09-04', 296.36, 'pendente'),
(6, 'P006', '1002', '2024-09-02', 110.73, 'pendente'),
(7, 'P007', '1005', '2024-09-30', 128.39, 'pendente'),
(8, 'P008', '1005', '2024-09-26', 159.26, 'pendente'),
(9, 'P009', '1004', '2024-09-28', 159.21, 'pendente'),
(10, 'P010', '1001', '2024-09-21', 100.89, 'pendente'),
(11, 'P011', '1001', '2024-09-16', 74.24, 'pendente'),
(12, 'P012', '1003', '2024-09-02', 180.70, 'pendente'),
(13, 'P013', '1005', '2024-09-27', 289.31, 'pendente'),
(14, 'P014', '1003', '2024-09-06', 147.89, 'pendente'),
(15, 'P015', '1003', '2024-09-26', 206.13, 'pendente'),
(16, 'P016', '1003', '2024-09-16', 266.41, 'pendente'),
(17, 'P017', '1004', '2024-09-16', 95.76, 'pendente'),
(18, 'P018', '1005', '2024-09-18', 219.68, 'pendente'),
(19, 'P019', '1004', '2024-09-20', 183.64, 'pendente'),
(20, 'P020', '1003', '2024-09-27', 231.20, 'pendente'),
(21, 'P021', '1005', '2024-09-20', 213.76, 'pendente'),
(22, 'P022', '1002', '2024-09-25', 249.20, 'pendente'),
(23, 'P023', '1003', '2024-09-19', 95.32, 'pendente'),
(24, 'P024', '1002', '2024-09-29', 175.46, 'pendente'),
(25, 'P025', '1002', '2024-09-07', 80.60, 'pendente'),
(26, 'P026', '1002', '2024-09-14', 196.92, 'pendente'),
(27, 'P027', '1005', '2024-09-09', 269.04, 'pendente'),
(28, 'P028', '1002', '2024-09-06', 187.23, 'pendente'),
(29, 'P029', '1003', '2024-09-24', 132.77, 'pendente'),
(30, 'P030', '1001', '2024-09-12', 286.72, 'pendente'),
(31, 'P031', '1004', '2024-09-23', 73.68, 'pendente'),
(32, 'P032', '1002', '2024-09-24', 76.93, 'pendente'),
(33, 'P033', '1005', '2024-09-01', 85.95, 'pendente'),
(34, 'P034', '1005', '2024-09-26', 275.39, 'pendente'),
(35, 'P035', '1004', '2024-09-14', 110.19, 'pendente'),
(36, 'P036', '1005', '2024-09-01', 269.79, 'pendente'),
(37, 'P037', '1001', '2024-09-08', 163.88, 'pendente'),
(38, 'P038', '1001', '2024-09-09', 125.23, 'pendente'),
(39, 'P039', '1003', '2024-09-03', 64.43, 'pendente'),
(40, 'P040', '1002', '2024-09-10', 282.79, 'pendente'),
(41, 'P041', '1001', '2024-09-29', 198.78, 'pendente'),
(42, 'P042', '1003', '2024-09-03', 84.35, 'pendente'),
(43, 'P043', '1005', '2024-09-23', 235.48, 'pendente'),
(44, 'P044', '1002', '2024-09-04', 261.15, 'pendente'),
(45, 'P045', '1003', '2024-09-14', 220.66, 'pendente'),
(46, 'P046', '1004', '2024-09-29', 71.09, 'pendente'),
(47, 'P047', '1005', '2024-09-08', 179.47, 'pendente'),
(48, 'P048', '1005', '2024-09-06', 74.94, 'pendente'),
(49, 'P049', '1005', '2024-09-24', 276.83, 'pendente'),
(50, 'P050', '1003', '2024-09-22', 53.08, 'pendente'),


-- --------------------------------------------------------

--
-- Estrutura para tabela `produtos`
--

CREATE TABLE `produtos` (
  `id` int(11) NOT NULL,
  `SKU` varchar(20) NOT NULL,
  `UPC` varchar(20) NOT NULL,
  `nomeProduto` varchar(50) NOT NULL,
  `valor` float NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `produtos`
--

INSERT INTO `produtos` (`id`, `SKU`, `UPC`, `nomeProduto`, `valor`) VALUES
(10, 'roupa123rio', '123', 'camisa', 23.5);
(2, 'CAL002', '987654321098', 'Calça Jeans', 86.89),
(4, 'JAQ004', '345678901234', 'Jaqueta', 295.25),
(5, 'MOC006', '890123456789', 'Mochila', 289.89),
(8, 'brinq456rio', '456', 'quebra-cabeca', 43),
(6, 'TEN003', '567890123456', 'Tênis', 239.65),
(1, 'BON005', '765432109876', 'Boné', 214.62),
(9, 'brinq789rio', '789', 'jogo', 43),
(3, 'CAM001', '123456789012', 'Camiseta', 80.36),

-- --------------------------------------------------------

--
-- Estrutura para tabela `tempdata`
--

CREATE TABLE `tempdata` (
  `codigoPedido` varchar(30) NOT NULL,
  `dataPedido` date NOT NULL,
  `SKU` varchar(20) NOT NULL,
  `UPC` varchar(20) NOT NULL,
  `nomeProduto` varchar(100) NOT NULL,
  `qtd` int(11) NOT NULL,
  `valor` float NOT NULL,
  `frete` int(11) NOT NULL,
  `email` varchar(200) NOT NULL,
  `codigoComprador` varchar(3) NOT NULL,
  `nomeComprador` varchar(50) NOT NULL,
  `endereco` varchar(255) NOT NULL,
  `CEP` varchar(11) NOT NULL,
  `UF` varchar(2) NOT NULL,
  `pais` varchar(15) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Índices para tabelas despejadas
--

--
-- Índices de tabela `clientes`
--
ALTER TABLE `clientes`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `codigoComprador` (`codigoComprador`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Índices de tabela `compras`
--
ALTER TABLE `compras`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `SKU` (`SKU`);

--
-- Índices de tabela `entregas`
--
ALTER TABLE `entregas`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `codigoPedido` (`codigoPedido`);

--
-- Índices de tabela `estoque`
--
ALTER TABLE `estoque`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `SKU` (`SKU`);

--
-- Índices de tabela `itens_pedidos`
--
ALTER TABLE `itens_pedidos`
  ADD PRIMARY KEY (`id`),
  ADD KEY `FK_ItensPedidosCodigoComprador` (`codigoPedido`),
  ADD KEY `FK_ItensPedidosSKU` (`SKU`);

--
-- Índices de tabela `pedidos`
--
ALTER TABLE `pedidos`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `codigoPedido` (`codigoPedido`),
  ADD KEY `FK_PedidosComprador` (`codigoComprador`);

--
-- Índices de tabela `produtos`
--
ALTER TABLE `produtos`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `SKU` (`SKU`),
  ADD UNIQUE KEY `UPC` (`UPC`);

--
-- AUTO_INCREMENT para tabelas despejadas
--

--
-- AUTO_INCREMENT de tabela `clientes`
--
ALTER TABLE `clientes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT de tabela `compras`
--
ALTER TABLE `compras`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT de tabela `entregas`
--
ALTER TABLE `entregas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=515;

--
-- AUTO_INCREMENT de tabela `estoque`
--
ALTER TABLE `estoque`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT de tabela `itens_pedidos`
--
ALTER TABLE `itens_pedidos`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1031;

--
-- AUTO_INCREMENT de tabela `pedidos`
--
ALTER TABLE `pedidos`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=515;

--
-- AUTO_INCREMENT de tabela `produtos`
--
ALTER TABLE `produtos`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
