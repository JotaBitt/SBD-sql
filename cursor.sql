-- Desabilitar modo que auto-incrementa colunas sem valor definido
SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";

-- Iniciar uma transação
START TRANSACTION;

-- Definir o fuso horário para UTC
SET time_zone = "+00:00";

-- Definir o delimitador para separar comandos SQL
DELIMITER $$

-- Criar um procedimento armazenado chamado 'processa_entrega'
CREATE DEFINER=`root`@`localhost` PROCEDURE `processa_entrega` ()   
    BEGIN
    -- Declarar variáveis para uso dentro do procedimento
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_id_pedido INT;
    DECLARE v_id_produto INT;
    DECLARE v_quantidade INT;
    DECLARE v_preco_unitario DECIMAL(10,2);
    DECLARE v_total_item DECIMAL(10,2);
    DECLARE v_estoque_atual INT;

 -- Definir um cursor para iterar sobre os pedidos, com itens e preços correspondentes
    DECLARE cursor_pedidos CURSOR FOR
        SELECT ip.pedido_id, ip.produto_id, ip.quantidade, p.preco_unitario, 
               (ip.quantidade * p.preco_unitario) AS total_item
        FROM itens_pedido ip
        JOIN produtos p ON ip.produto_id = p.produto_id
        ORDER BY total_item DESC;

    -- Manipular caso o cursor chegue ao fim
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- Abrir cursor
    OPEN cursor_pedidos;

    -- começar o Loop para processar os itens do pedido
    read_loop: LOOP
        -- Buscar os dados do próximo registro no cursor
        FETCH cursor_pedidos INTO v_id_pedido, v_id_produto, v_quantidade, v_preco_unitario, v_total_item;

        -- Sair do loop quando todos os registros tiverem sido processados
        IF done THEN
            LEAVE read_loop;
        END IF;

       -- Verificar a quantidade atual do produto em estoque
        SELECT quantidade INTO v_estoque_atual FROM estoque WHERE produto_id = v_id_produto;
        
        - -- Se o estoque for suficiente para atender o pedido
        IF v_estoque_atual >= v_quantidade THEN
            -- Atualiza a tabela entrega com o total do pedido
            INSERT INTO entregas (pedido_id, produto_id, quantidade, total_item)
            VALUES (v_id_pedido, v_id_produto, v_quantidade, v_total_item);
            
            -- Atualizar a quantidade no estoque subtraindo a quantidade vendida
            UPDATE estoque
            SET quantidade = quantidade - v_quantidade
            WHERE produto_id = v_id_produto;

        ELSE
            -- Se o estoque não for suficiente, registrar a necessidade de compra
            INSERT INTO compras (produto_id, quantidade_necessaria)
            VALUES (v_id_produto, v_quantidade - v_estoque_atual);
            
            -- Atualizar o estoque para 0, já que está esgotado
            UPDATE estoque
            SET quantidade = 0
            WHERE produto_id = v_id_produto;
        END IF;
    END LOOP;

    -- Fechar o cursor após o loop terminar
    CLOSE cursor_pedidos;
END$$
-- Restaurar o delimitador padrão
DELIMITER ;

-- --------------------------------------------------------

-- Estrutura para tabela `cliente`

--Criar tabela de cliente
CREATE TABLE `cliente` (
  `codigoComprador` varchar(32) NOT NULL,
  `email` varchar(100) NOT NULL,
  `nomeComprador` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Inserir dados na tabela cliente
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

-- Criar tabela de compras
CREATE TABLE `compras` (
  `codigoPedido` varchar(32) NOT NULL,
  `valor` float NOT NULL,
  `frete` float NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Inserir dados na tabela de entregas
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

-- criar tabela de entregas
CREATE TABLE `entregas` (
  `codigoPedido` varchar(32) NOT NULL,
  `endereco` varchar(255) NOT NULL,
  `CEP` varchar(11) NOT NULL,
  `UF` varchar(2) NOT NULL,
  `pais` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Inserir dados na tabela de entregass
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
    
-- Criar tabela de estoque
CREATE TABLE `estoque` (
  `SKU` varchar(20) NOT NULL,
  `quantidade` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Inserir dados na tabela de estoque
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
    
-- Criar a tabela de itens de pedidos
CREATE TABLE `itens_pedido` (
  `codigoPedido` varchar(20) NOT NULL,
  `SKU` varchar(20) NOT NULL,
  `quantidade` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Inserir dados na tabela de itens de pedidos
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

-- Criar a tabela de pedidos
CREATE TABLE `pedidos` (
  `codigoPedido` varchar(32) NOT NULL,
  `dataPedido` date NOT NULL,
  `codigoComprador` varchar(32) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Inserir dados na tabela de pedidos
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

-- Criar a tabela de produtos
CREATE TABLE `produtos` (
  `SKU` varchar(20) NOT NULL,
  `UPC` varchar(20) NOT NULL,
  `nomeProduto` varchar(50) NOT NULL,
  `valor` float NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


-- Inserir dados na tabela de produtos
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

-- Criar uma tabela temporária para armazenar os dados dos pedidos
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

-- Inserir dados na tabela temporária
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

-- Adição de chaves primárias nas tabelas
ALTER TABLE `pedidos`
  ADD PRIMARY KEY (`codigoPedido`),
  ADD KEY `FK_PedidosCliente` (`codigoComprador`);

ALTER TABLE `cliente`
  ADD PRIMARY KEY (`codigoComprador`),
  ADD UNIQUE KEY `email` (`email`);

ALTER TABLE `produtos`
  ADD PRIMARY KEY (`SKU`),
  ADD UNIQUE KEY `UPC` (`UPC`);

ALTER TABLE `compras`
  ADD PRIMARY KEY (`codigoPedido`);

ALTER TABLE `estoque`
  ADD PRIMARY KEY (`SKU`);

ALTER TABLE `entregas`
  ADD PRIMARY KEY (`codigoPedido`);

ALTER TABLE `itens_pedido`
  ADD KEY `FK_ItensPedido` (`codigoPedido`),
  ADD KEY `FK_ItensSKU` (`SKU`);

ALTER TABLE `tempdata`
  ADD PRIMARY KEY (`codigoPedido`);

-- Adição de chaves estrangeiras nas tabelas
ALTER TABLE `entregas`
  ADD CONSTRAINT `FK_EntregasPedido` FOREIGN KEY (`codigoPedido`) REFERENCES `pedidos` (`codigoPedido`);

ALTER TABLE `compras`
  ADD CONSTRAINT `FK_ComprasPedido` FOREIGN KEY (`codigoPedido`) REFERENCES `pedidos` (`codigoPedido`);

ALTER TABLE `itens_pedido`
  ADD CONSTRAINT `FK_ItensPedido` FOREIGN KEY (`codigoPedido`) REFERENCES `pedidos` (`codigoPedido`),
  ADD CONSTRAINT `FK_ItensSKU` FOREIGN KEY (`SKU`) REFERENCES `produtos` (`SKU`);

ALTER TABLE `estoque`
  ADD CONSTRAINT `FK_EstoqueProduto` FOREIGN KEY (`SKU`) REFERENCES `produtos` (`SKU`);
COMMIT;

