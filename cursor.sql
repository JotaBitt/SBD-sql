SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `processa_entrega` ()   BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_id_pedido INT;
    DECLARE v_id_produto INT;
    DECLARE v_quantidade INT;
    DECLARE v_preco_unitario DECIMAL(10,2);
    DECLARE v_total_item DECIMAL(10,2);
    DECLARE v_estoque_atual INT;
  
    DECLARE cursor_pedidos CURSOR FOR
        SELECT ip.pedido_id, ip.produto_id, ip.quantidade, p.preco_unitario, 
               (ip.quantidade * p.preco_unitario) AS total_item
        FROM itens_pedido ip
        JOIN produtos p ON ip.produto_id = p.produto_id
        ORDER BY total_item DESC;

    -- Manipular caso o cursor chegue ao fim
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN cursor_pedidos;

    -- Começar o loop pelo cursor
    read_loop: LOOP
        FETCH cursor_pedidos INTO v_id_pedido, v_id_produto, v_quantidade, v_preco_unitario, v_total_item;
        
        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Checar o estoque atual do produto
        SELECT quantidade INTO v_estoque_atual FROM estoque WHERE produto_id = v_id_produto;
        
        -- Se o estoque for suficiente
        IF v_estoque_atual >= v_quantidade THEN
            -- Atualiza a tabela entrega com o total do pedido
            INSERT INTO entregas (pedido_id, produto_id, quantidade, total_item)
            VALUES (v_id_pedido, v_id_produto, v_quantidade, v_total_item);
            
            -- Debitar a quantidade do estoque
            UPDATE estoque
            SET quantidade = quantidade - v_quantidade
            WHERE produto_id = v_id_produto;

        ELSE
            -- Quando o estoque acabar, insira na tabela de compra
            INSERT INTO compras (produto_id, quantidade_necessaria)
            VALUES (v_id_produto, v_quantidade - v_estoque_atual);
            
            -- Atualiza o estoque para zero
            UPDATE estoque
            SET quantidade = 0
            WHERE produto_id = v_id_produto;
        END IF;
    END LOOP;

    CLOSE cursor_pedidos;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estrutura para tabela `cliente`
--

CREATE TABLE `cliente` (
  `codigoComprador` varchar(32) NOT NULL,
  `email` varchar(100) NOT NULL,
  `nomeComprador` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `cliente`
--

INSERT INTO `cliente` (`codigoComprador`, `email`, `nomeComprador`) VALUES
('123', 'samir@gmail.com', 'Samir'),
('456', 'jose@gmail.com', 'Jose'),
('457', 'marcia@gmail.com', 'Marcia'),
('458', 'lucas@gmail.com', 'Lucas'),
('459', 'ana@gmail.com', 'Ana'),
('460', 'paula@gmail.com', 'Paula'),
('461', 'marcio@gmail.com', 'Marcio'),
('462', 'laura@gmail.com', 'Laura'),
('463', 'felipe@gmail.com', 'Felipe'),
('464', 'julia@gmail.com', 'Julia'),
('465', 'carla@gmail.com', 'Carla'),
('466', 'roberto@gmail.com', 'Roberto'),
('467', 'mariana@gmail.com', 'Mariana'),
('468', 'bruno@gmail.com', 'Bruno'),
('469', 'isabela@gmail.com', 'Isabela'),
('470', 'eduardo@gmail.com', 'Eduardo'),
('471', 'natasha@gmail.com', 'Natasha'),
('472', 'andre@gmail.com', 'Andre'),
('474', 'andre2@gmail.com', 'Andre'),
('475', 'marina@gmail.com', 'Marina'),
('477', 'pedro@gmail.com', 'Pedro'),
('478', 'leticia@gmail.com', 'Leticia'),
('479', 'andreia@gmail.com', 'Andreia'),
('480', 'jose2@gmail.com', 'Jose'),
('481', 'aline@gmail.com', 'Aline'),
('483', 'rafael@gmail.com', 'Rafael'),
('484', 'leticia2@gmail.com', 'Leticia'),
('485', 'luan@gmail.com', 'Luan'),
('486', 'vinicius@gmail.com', 'Vinicius'),
('487', 'rosana@gmail.com', 'Rosana'),
('488', 'joao@gmail.com', 'Joao'),
('489', 'carla2@gmail.com', 'Carla'),
('789', 'teste@gmail.com', 'Fulano');

-- --------------------------------------------------------

--
-- Estrutura para tabela `compras`
--

CREATE TABLE `compras` (
  `codigoPedido` varchar(32) NOT NULL,
  `valor` float NOT NULL,
  `frete` float NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `compras`
--

INSERT INTO `compras` (`codigoPedido`, `valor`, `frete`) VALUES
('abc124', 299, 12),
('abc125', 699, 15),
('abc126', 1199, 20),
('abc127', 12, 7),
('abc128', 19, 6),
('abc129', 55, 8),
('abc130', 89, 10),
('abc131', 129, 12),
('abc132', 54, 8),
('abc133', 249, 11),
('abc134', 89, 7),
('abc135', 699, 15),
('abc136', 99, 10),
('abc137', 49, 8),
('abc138', 79, 9),
('abc139', 25, 5),
('abc140', 99, 7),
('abc141', 69, 8),
('abc142', 399, 18),
('abc143', 499, 20),
('abc144', 159, 12),
('abc145', 15, 7),
('abc146', 99, 10),
('abc147', 129, 12),
('abc148', 35, 6),
('abc149', 89, 8),
('abc150', 179, 15),
('abc151', 1499, 25),
('abc152', 799, 22),
('abc153', 399, 15),
('abc154', 59, 8),
('abc155', 69, 9),
('abc156', 45, 7),
('abc157', 49, 6),
('abc158', 89, 7),
('abc159', 59, 8),
('abc741', 43, 5),
('abc789', 47, 6);

-- --------------------------------------------------------

--
-- Estrutura para tabela `entregas`
--

CREATE TABLE `entregas` (
  `codigoPedido` varchar(32) NOT NULL,
  `endereco` varchar(255) NOT NULL,
  `CEP` varchar(11) NOT NULL,
  `UF` varchar(2) NOT NULL,
  `pais` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `entregas`
--

INSERT INTO `entregas` (`codigoPedido`, `endereco`, `CEP`, `UF`, `pais`) VALUES
('abc124', 'Avenida Principal 10', '12345678', 'SP', 'Brasil\r'),
('abc125', 'Avenida Secundária 20', '23456789', 'SP', 'Brasil\r'),
('abc126', 'Rua das Flores 30', '34567890', 'SP', 'Brasil\r'),
('abc127', 'Rua do Campo 40', '45678901', 'SP', 'Brasil\r'),
('abc128', 'Rua das Palmeiras 50', '56789012', 'SP', 'Brasil\r'),
('abc129', 'Rua dos Jacarandás 60', '67890123', 'SP', 'Brasil\r'),
('abc130', 'Rua dos Coqueiros 70', '78901234', 'SP', 'Brasil\r'),
('abc131', 'Rua das Acácias 80', '89012345', 'SP', 'Brasil\r'),
('abc132', 'Rua das Palmeiras 90', '90123456', 'SP', 'Brasil\r'),
('abc133', 'Avenida do Sol 100', '01234567', 'RJ', 'Brasil\r'),
('abc134', 'Avenida do Mar 110', '12345678', 'RJ', 'Brasil\r'),
('abc135', 'Rua do Sol 120', '23456789', 'RJ', 'Brasil\r'),
('abc136', 'Rua dos Casuar', '34567890', 'RJ', 'Brasil\r'),
('abc137', 'Rua do Limoeiro 130', '45678901', 'RJ', 'Brasil\r'),
('abc138', 'Rua da Alegria 140', '56789012', 'RJ', 'Brasil\r'),
('abc139', 'Avenida das Rosas 150', '67890123', 'RJ', 'Brasil\r'),
('abc140', 'Avenida das Margaridas 160', '78901234', 'RJ', 'Brasil\r'),
('abc141', 'Rua do Girassol 170', '89012345', 'RJ', 'Brasil\r'),
('abc142', 'Rua da Alegria 180', '90123456', 'RJ', 'Brasil\r'),
('abc143', 'Rua dos Pinheiros 190', '01234567', 'RJ', 'Brasil\r'),
('abc144', 'Rua das Orquídeas 200', '12345678', 'RJ', 'Brasil\r'),
('abc145', 'Avenida das Palmeiras 210', '23456789', 'RJ', 'Brasil\r'),
('abc146', 'Rua do Verde 220', '34567890', 'RJ', 'Brasil\r'),
('abc147', 'Rua do Lago 230', '45678901', 'RJ', 'Brasil\r'),
('abc148', 'Rua das Laranjeiras 240', '56789012', 'RJ', 'Brasil\r'),
('abc149', 'Rua dos Coqueiros 250', '67890123', 'RJ', 'Brasil\r'),
('abc150', 'Rua dos Jabuticabeiras 260', '78901234', 'RJ', 'Brasil\r'),
('abc151', 'Rua das Amendoeiras 270', '89012345', 'RJ', 'Brasil\r'),
('abc152', 'Rua do Aconchego 280', '90123456', 'RJ', 'Brasil\r'),
('abc153', 'Rua da Brisa 290', '01234567', 'RJ', 'Brasil\r'),
('abc154', 'Rua das Flores 300', '12345678', 'SP', 'Brasil\r'),
('abc155', 'Rua do Jardim 310', '23456789', 'SP', 'Brasil\r'),
('abc156', 'Rua das Orquideas 320', '34567890', 'SP', 'Brasil\r'),
('abc157', 'Rua dos Jequitibás 330', '45678901', 'SP', 'Brasil\r'),
('abc158', 'Rua dos Cerejeiras 340', '56789012', 'SP', 'Brasil\r'),
('abc159', 'Rua dos Lírios 350', '67890123', 'SP', 'Brasil\r'),
('abc741', 'Rua Exemplo 1', '21212322', 'RJ', 'Brasil\r'),
('abc789', 'Rua Exemplo 2', '14784520', 'RJ', 'Brasil\r');

-- --------------------------------------------------------

--
-- Estrutura para tabela `estoque`
--

CREATE TABLE `estoque` (
  `SKU` varchar(20) NOT NULL,
  `quantidade` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `estoque`
--

INSERT INTO `estoque` (`SKU`, `quantidade`) VALUES
('brinq123sp', 3),
('brinq321rj', 1),
('brinq321sp', 2),
('brinq456sp', 2),
('brinq654rj', 4),
('brinq654sp', 1),
('brinq789rio', 1),
('brinq789sp', 1),
('brinq987rj', 2),
('brinq987sp', 2),
('eletr123', 1),
('eletr123rj', 1),
('eletr321rj', 2),
('eletr321sp', 1),
('eletr456', 1),
('eletr456rj', 1),
('eletr654rj', 1),
('eletr654sp', 1),
('eletr789', 1),
('eletr789rj', 1),
('eletr987rj', 1),
('eletr987sp', 1),
('roupa123rio', 2),
('roupa123sp', 2),
('roupa321rj', 2),
('roupa321sp', 5),
('roupa456sp', 1),
('roupa654rj', 1),
('roupa654sp', 1),
('roupa789sp', 1),
('roupa987rj', 1),
('roupa987sp', 3);

-- --------------------------------------------------------

--
-- Estrutura para tabela `itens_pedido`
--

CREATE TABLE `itens_pedido` (
  `codigoPedido` varchar(20) NOT NULL,
  `SKU` varchar(20) NOT NULL,
  `quantidade` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `itens_pedido`
--

INSERT INTO `itens_pedido` (`codigoPedido`, `SKU`, `quantidade`) VALUES
('abc124', 'eletr123', 1),
('abc125', 'eletr456', 1),
('abc126', 'eletr789', 1),
('abc127', 'brinq123sp', 3),
('abc128', 'brinq456sp', 2),
('abc129', 'brinq789sp', 1),
('abc130', 'roupa456sp', 1),
('abc131', 'roupa789sp', 1),
('abc132', 'roupa123sp', 2),
('abc133', 'eletr321sp', 1),
('abc134', 'eletr654sp', 1),
('abc135', 'eletr987sp', 1),
('abc136', 'brinq321sp', 2),
('abc137', 'brinq654sp', 1),
('abc138', 'brinq987sp', 2),
('abc139', 'roupa321sp', 5),
('abc140', 'roupa654sp', 1),
('abc141', 'roupa987sp', 3),
('abc142', 'eletr987rj', 1),
('abc143', 'eletr654rj', 1),
('abc144', 'eletr321rj', 2),
('abc145', 'brinq654rj', 4),
('abc146', 'brinq321rj', 1),
('abc147', 'brinq987rj', 2),
('abc148', 'roupa321rj', 2),
('abc149', 'roupa654rj', 1),
('abc150', 'roupa987rj', 1),
('abc151', 'eletr123rj', 1),
('abc152', 'eletr456rj', 1),
('abc153', 'eletr789rj', 1),
('abc154', 'brinq456sp', 2),
('abc155', 'brinq789sp', 1),
('abc156', 'brinq123sp', 3),
('abc157', 'roupa456sp', 2),
('abc158', 'roupa789sp', 1),
('abc159', 'roupa123sp', 2),
('abc741', 'brinq789rio', 1),
('abc789', 'roupa123rio', 2);

-- --------------------------------------------------------

--
-- Estrutura para tabela `pedidos`
--

CREATE TABLE `pedidos` (
  `codigoPedido` varchar(32) NOT NULL,
  `dataPedido` date NOT NULL,
  `codigoComprador` varchar(32) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `pedidos`
--

INSERT INTO `pedidos` (`codigoPedido`, `dataPedido`, `codigoComprador`) VALUES
('abc124', '2024-03-22', '456'),
('abc125', '2024-03-22', '457'),
('abc126', '2024-03-22', '458'),
('abc127', '2024-03-23', '459'),
('abc128', '2024-03-23', '460'),
('abc129', '2024-03-23', '461'),
('abc130', '2024-03-24', '462'),
('abc131', '2024-03-24', '463'),
('abc132', '2024-03-24', '464'),
('abc133', '2024-03-25', '465'),
('abc134', '2024-03-25', '466'),
('abc135', '2024-03-25', '467'),
('abc136', '2024-03-26', '468'),
('abc137', '2024-03-26', '469'),
('abc138', '2024-03-26', '470'),
('abc139', '2024-03-27', '471'),
('abc140', '2024-03-27', '472'),
('abc141', '2024-03-27', '473'),
('abc142', '2024-03-28', '474'),
('abc143', '2024-03-28', '475'),
('abc144', '2024-03-28', '476'),
('abc145', '2024-03-29', '477'),
('abc146', '2024-03-29', '478'),
('abc147', '2024-03-29', '479'),
('abc148', '2024-03-30', '480'),
('abc149', '2024-03-30', '481'),
('abc150', '2024-03-30', '482'),
('abc151', '2024-03-31', '483'),
('abc152', '2024-03-31', '484'),
('abc153', '2024-03-31', '485'),
('abc154', '2024-04-01', '486'),
('abc155', '2024-04-01', '487'),
('abc156', '2024-04-01', '488'),
('abc157', '2024-04-02', '489'),
('abc158', '2024-04-02', '490'),
('abc159', '2024-04-02', '491'),
('abc741', '2024-03-21', '123'),
('abc789', '2024-03-20', '789');

-- --------------------------------------------------------

--
-- Estrutura para tabela `produtos`
--

CREATE TABLE `produtos` (
  `SKU` varchar(20) NOT NULL,
  `UPC` varchar(20) NOT NULL,
  `nomeProduto` varchar(50) NOT NULL,
  `valor` float NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `produtos`
--

INSERT INTO `produtos` (`SKU`, `UPC`, `nomeProduto`, `valor`) VALUES
('brinq123sp', '77746', 'bola', 12),
('brinq321rj', '105609', 'skate', 99),
('brinq321sp', '83761', 'carro de corrida', 99),
('brinq456sp', '150615', 'boneco', 19),
('brinq654rj', '96599', 'bola de futebol', 15),
('brinq654sp', '55079', 'casinha', 49),
('brinq789rio', '87098', 'jogo', 43),
('brinq789sp', '59683', 'carro', 55),
('brinq987rj', '85711', 'patins', 129),
('brinq987sp', '76653', 'boneco articulado', 79),
('eletr123', '123', 'telefone', 299),
('eletr123rj', '140251', 'console', 1499),
('eletr321rj', '143309', 'monitor', 159),
('eletr321sp', '321', 'smartwatch', 249),
('eletr456', '456', 'tablet', 699),
('eletr456rj', '103727', 'home theater', 799),
('eletr654rj', '121622', 'videogame', 499),
('eletr654sp', '654', 'fones', 89),
('eletr789', '789', 'notebook', 1199),
('eletr789rj', '150422', 'projector', 399),
('eletr987rj', '69908', 'impressora', 399),
('eletr987sp', '987', 'camera', 699),
('roupa123rio', '93116', 'camisa', 47),
('roupa123sp', '71467', 'camiseta', 54),
('roupa321rj', '61728', 'boné', 35),
('roupa321sp', '65488', 'meia', 25),
('roupa456sp', '104186', 'calça', 89),
('roupa654rj', '104046', 'calça de moletom', 89),
('roupa654sp', '150021', 'suéter', 99),
('roupa789sp', '86805', 'jaqueta', 129),
('roupa987rj', '79970', 'jaqueta impermeável', 179),
('roupa987sp', '93487', 'blusa', 69);

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
-- Despejando dados para a tabela `tempdata`
--

INSERT INTO `tempdata` (`codigoPedido`, `dataPedido`, `SKU`, `UPC`, `nomeProduto`, `qtd`, `valor`, `frete`, `email`, `codigoComprador`, `nomeComprador`, `endereco`, `CEP`, `UF`, `pais`) VALUES
('abc124', '2024-03-22', 'eletr123', '103621', 'telefone', 1, 299, 12, 'jose@gmail.com', '456', 'Jose', 'Avenida Principal 10', '12345678', 'SP', 'Brasil\r'),
('abc125', '2024-03-22', 'eletr456', '50534', 'tablet', 1, 699, 15, 'marcia@gmail.com', '457', 'Marcia', 'Avenida Secundária 20', '23456789', 'SP', 'Brasil\r'),
('abc126', '2024-03-22', 'eletr789', '96885', 'notebook', 1, 1199, 20, 'lucas@gmail.com', '458', 'Lucas', 'Rua das Flores 30', '34567890', 'SP', 'Brasil\r'),
('abc127', '2024-03-23', 'brinq123sp', '77746', 'bola', 3, 12, 7, 'ana@gmail.com', '459', 'Ana', 'Rua do Campo 40', '45678901', 'SP', 'Brasil\r'),
('abc128', '2024-03-23', 'brinq456sp', '150615', 'boneco', 2, 19, 6, 'paula@gmail.com', '460', 'Paula', 'Rua das Palmeiras 50', '56789012', 'SP', 'Brasil\r'),
('abc129', '2024-03-23', 'brinq789sp', '59683', 'carro', 1, 55, 8, 'marcio@gmail.com', '461', 'Marcio', 'Rua dos Jacarandás 60', '67890123', 'SP', 'Brasil\r'),
('abc130', '2024-03-24', 'roupa456sp', '104186', 'calça', 1, 89, 10, 'laura@gmail.com', '462', 'Laura', 'Rua dos Coqueiros 70', '78901234', 'SP', 'Brasil\r'),
('abc131', '2024-03-24', 'roupa789sp', '86805', 'jaqueta', 1, 129, 12, 'felipe@gmail.com', '463', 'Felipe', 'Rua das Acácias 80', '89012345', 'SP', 'Brasil\r'),
('abc132', '2024-03-24', 'roupa123sp', '71467', 'camiseta', 2, 54, 8, 'julia@gmail.com', '464', 'Julia', 'Rua das Palmeiras 90', '90123456', 'SP', 'Brasil\r'),
('abc133', '2024-03-25', 'eletr321sp', '149459', 'smartwatch', 1, 249, 11, 'carla@gmail.com', '465', 'Carla', 'Avenida do Sol 100', '01234567', 'RJ', 'Brasil\r'),
('abc134', '2024-03-25', 'eletr654sp', '72739', 'fones', 1, 89, 7, 'roberto@gmail.com', '466', 'Roberto', 'Avenida do Mar 110', '12345678', 'RJ', 'Brasil\r'),
('abc135', '2024-03-25', 'eletr987sp', '70395', 'camera', 1, 699, 15, 'mariana@gmail.com', '467', 'Mariana', 'Rua do Sol 120', '23456789', 'RJ', 'Brasil\r'),
('abc136', '2024-03-26', 'brinq321sp', '83761', 'carro de corrida', 2, 99, 10, 'bruno@gmail.com', '468', 'Bruno', 'Rua dos Casuar', '34567890', 'RJ', 'Brasil\r'),
('abc137', '2024-03-26', 'brinq654sp', '55079', 'casinha', 1, 49, 8, 'isabela@gmail.com', '469', 'Isabela', 'Rua do Limoeiro 130', '45678901', 'RJ', 'Brasil\r'),
('abc138', '2024-03-26', 'brinq987sp', '76653', 'boneco articulado', 2, 79, 9, 'eduardo@gmail.com', '470', 'Eduardo', 'Rua da Alegria 140', '56789012', 'RJ', 'Brasil\r'),
('abc139', '2024-03-27', 'roupa321sp', '65488', 'meia', 5, 25, 5, 'natasha@gmail.com', '471', 'Natasha', 'Avenida das Rosas 150', '67890123', 'RJ', 'Brasil\r'),
('abc140', '2024-03-27', 'roupa654sp', '150021', 'suéter', 1, 99, 7, 'andre@gmail.com', '472', 'Andre', 'Avenida das Margaridas 160', '78901234', 'RJ', 'Brasil\r'),
('abc141', '2024-03-27', 'roupa987sp', '93487', 'blusa', 3, 69, 8, 'carla@gmail.com', '473', 'Carla', 'Rua do Girassol 170', '89012345', 'RJ', 'Brasil\r'),
('abc142', '2024-03-28', 'eletr987rj', '69908', 'impressora', 1, 399, 18, 'andre2@gmail.com', '474', 'Andre', 'Rua da Alegria 180', '90123456', 'RJ', 'Brasil\r'),
('abc143', '2024-03-28', 'eletr654rj', '121622', 'videogame', 1, 499, 20, 'marina@gmail.com', '475', 'Marina', 'Rua dos Pinheiros 190', '01234567', 'RJ', 'Brasil\r'),
('abc144', '2024-03-28', 'eletr321rj', '143309', 'monitor', 2, 159, 12, 'marcio@gmail.com', '476', 'Marcio', 'Rua das Orquídeas 200', '12345678', 'RJ', 'Brasil\r'),
('abc145', '2024-03-29', 'brinq654rj', '96599', 'bola de futebol', 4, 15, 7, 'pedro@gmail.com', '477', 'Pedro', 'Avenida das Palmeiras 210', '23456789', 'RJ', 'Brasil\r'),
('abc146', '2024-03-29', 'brinq321rj', '105609', 'skate', 1, 99, 10, 'leticia@gmail.com', '478', 'Leticia', 'Rua do Verde 220', '34567890', 'RJ', 'Brasil\r'),
('abc147', '2024-03-29', 'brinq987rj', '85711', 'patins', 2, 129, 12, 'andreia@gmail.com', '479', 'Andreia', 'Rua do Lago 230', '45678901', 'RJ', 'Brasil\r'),
('abc148', '2024-03-30', 'roupa321rj', '61728', 'boné', 2, 35, 6, 'jose2@gmail.com', '480', 'Jose', 'Rua das Laranjeiras 240', '56789012', 'RJ', 'Brasil\r'),
('abc149', '2024-03-30', 'roupa654rj', '104046', 'calça de moletom', 1, 89, 8, 'aline@gmail.com', '481', 'Aline', 'Rua dos Coqueiros 250', '67890123', 'RJ', 'Brasil\r'),
('abc150', '2024-03-30', 'roupa987rj', '79970', 'jaqueta impermeável', 1, 179, 15, 'marcio@gmail.com', '482', 'Marcio', 'Rua dos Jabuticabeiras 260', '78901234', 'RJ', 'Brasil\r'),
('abc151', '2024-03-31', 'eletr123rj', '140251', 'console', 1, 1499, 25, 'rafael@gmail.com', '483', 'Rafael', 'Rua das Amendoeiras 270', '89012345', 'RJ', 'Brasil\r'),
('abc152', '2024-03-31', 'eletr456rj', '103727', 'home theater', 1, 799, 22, 'leticia2@gmail.com', '484', 'Leticia', 'Rua do Aconchego 280', '90123456', 'RJ', 'Brasil\r'),
('abc153', '2024-03-31', 'eletr789rj', '150422', 'projector', 1, 399, 15, 'luan@gmail.com', '485', 'Luan', 'Rua da Brisa 290', '01234567', 'RJ', 'Brasil\r'),
('abc154', '2024-04-01', 'brinq456sp', '83313', 'boneca', 2, 59, 8, 'vinicius@gmail.com', '486', 'Vinicius', 'Rua das Flores 300', '12345678', 'SP', 'Brasil\r'),
('abc155', '2024-04-01', 'brinq789sp', '120379', 'trenzinho', 1, 69, 9, 'rosana@gmail.com', '487', 'Rosana', 'Rua do Jardim 310', '23456789', 'SP', 'Brasil\r'),
('abc156', '2024-04-01', 'brinq123sp', '96876', 'puzzle', 3, 45, 7, 'joao@gmail.com', '488', 'Joao', 'Rua das Orquideas 320', '34567890', 'SP', 'Brasil\r'),
('abc157', '2024-04-02', 'roupa456sp', '73242', 'short', 2, 49, 6, 'carla2@gmail.com', '489', 'Carla', 'Rua dos Jequitibás 330', '45678901', 'SP', 'Brasil\r'),
('abc158', '2024-04-02', 'roupa789sp', '128124', 'camisa polo', 1, 89, 7, 'marcio@gmail.com', '490', 'Marcio', 'Rua dos Cerejeiras 340', '56789012', 'SP', 'Brasil\r'),
('abc159', '2024-04-02', 'roupa123sp', '63279', 'blusa de frio', 2, 59, 8, 'luan@gmail.com', '491', 'Luan', 'Rua dos Lírios 350', '67890123', 'SP', 'Brasil\r'),
('abc741', '2024-03-21', 'brinq789rio', '87098', 'jogo', 1, 43, 5, 'samir@gmail.com', '123', 'Samir', 'Rua Exemplo 1', '21212322', 'RJ', 'Brasil\r'),
('abc789', '2024-03-20', 'roupa123rio', '93116', 'camisa', 2, 47, 6, 'teste@gmail.com', '789', 'Fulano', 'Rua Exemplo 2', '14784520', 'RJ', 'Brasil\r');

--
-- Índices para tabelas despejadas
--

--
-- Índices de tabela `cliente`
--
ALTER TABLE `cliente`
  ADD PRIMARY KEY (`codigoComprador`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Índices de tabela `compras`
--
ALTER TABLE `compras`
  ADD PRIMARY KEY (`codigoPedido`);

--
-- Índices de tabela `entregas`
--
ALTER TABLE `entregas`
  ADD PRIMARY KEY (`codigoPedido`);

--
-- Índices de tabela `estoque`
--
ALTER TABLE `estoque`
  ADD PRIMARY KEY (`SKU`);

--
-- Índices de tabela `itens_pedido`
--
ALTER TABLE `itens_pedido`
  ADD KEY `FK_ItensPedido` (`codigoPedido`),
  ADD KEY `FK_ItensSKU` (`SKU`);

--
-- Índices de tabela `pedidos`
--
ALTER TABLE `pedidos`
  ADD PRIMARY KEY (`codigoPedido`),
  ADD KEY `FK_PedidosCliente` (`codigoComprador`);

--
-- Índices de tabela `produtos`
--
ALTER TABLE `produtos`
  ADD PRIMARY KEY (`SKU`),
  ADD UNIQUE KEY `UPC` (`UPC`);

--
-- Índices de tabela `tempdata`
--
ALTER TABLE `tempdata`
  ADD PRIMARY KEY (`codigoPedido`);

--
-- Restrições para tabelas despejadas
--

--
-- Restrições para tabelas `compras`
--
ALTER TABLE `compras`
  ADD CONSTRAINT `FK_ComprasPedido` FOREIGN KEY (`codigoPedido`) REFERENCES `pedidos` (`codigoPedido`);

--
-- Restrições para tabelas `entregas`
--
ALTER TABLE `entregas`
  ADD CONSTRAINT `FK_EntregasPedido` FOREIGN KEY (`codigoPedido`) REFERENCES `pedidos` (`codigoPedido`);

--
-- Restrições para tabelas `estoque`
--
ALTER TABLE `estoque`
  ADD CONSTRAINT `FK_EstoqueProduto` FOREIGN KEY (`SKU`) REFERENCES `produtos` (`SKU`);

--
-- Restrições para tabelas `itens_pedido`
--
ALTER TABLE `itens_pedido`
  ADD CONSTRAINT `FK_ItensPedido` FOREIGN KEY (`codigoPedido`) REFERENCES `pedidos` (`codigoPedido`),
  ADD CONSTRAINT `FK_ItensSKU` FOREIGN KEY (`SKU`) REFERENCES `produtos` (`SKU`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
