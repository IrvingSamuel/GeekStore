-- ============================================
-- SCRIPT 04: POPULAÇÃO DE DADOS
-- Sistema: GeekStore - Loja Virtual de Artigos Geeks e Games
-- Database: PostgreSQL 18
-- ============================================

-- Conectar ao banco
\c geekstore_db

-- Definir schema
SET search_path TO geekstore, public;

-- ============================================
-- DESABILITAR CONSTRAINTS TEMPORARIAMENTE
-- ============================================
SET session_replication_role = replica;

-- ============================================
-- POPULAR TABELAS AUXILIARES
-- ============================================

-- ESTADOS (27 estados brasileiros)
INSERT INTO estados (nome, sigla, regiao) VALUES
('Acre', 'AC', 'Norte'),
('Alagoas', 'AL', 'Nordeste'),
('Amapá', 'AP', 'Norte'),
('Amazonas', 'AM', 'Norte'),
('Bahia', 'BA', 'Nordeste'),
('Ceará', 'CE', 'Nordeste'),
('Distrito Federal', 'DF', 'Centro-Oeste'),
('Espírito Santo', 'ES', 'Sudeste'),
('Goiás', 'GO', 'Centro-Oeste'),
('Maranhão', 'MA', 'Nordeste'),
('Mato Grosso', 'MT', 'Centro-Oeste'),
('Mato Grosso do Sul', 'MS', 'Centro-Oeste'),
('Minas Gerais', 'MG', 'Sudeste'),
('Pará', 'PA', 'Norte'),
('Paraíba', 'PB', 'Nordeste'),
('Paraná', 'PR', 'Sul'),
('Pernambuco', 'PE', 'Nordeste'),
('Piauí', 'PI', 'Nordeste'),
('Rio de Janeiro', 'RJ', 'Sudeste'),
('Rio Grande do Norte', 'RN', 'Nordeste'),
('Rio Grande do Sul', 'RS', 'Sul'),
('Rondônia', 'RO', 'Norte'),
('Roraima', 'RR', 'Norte'),
('Santa Catarina', 'SC', 'Sul'),
('São Paulo', 'SP', 'Sudeste'),
('Sergipe', 'SE', 'Nordeste'),
('Tocantins', 'TO', 'Norte');

-- CIDADES (principais cidades)
INSERT INTO cidades (nome, estado_id, codigo_ibge) VALUES
-- São Paulo
('São Paulo', (SELECT estado_id FROM estados WHERE sigla = 'SP'), '3550308'),
('Campinas', (SELECT estado_id FROM estados WHERE sigla = 'SP'), '3509502'),
('Santos', (SELECT estado_id FROM estados WHERE sigla = 'SP'), '3548500'),
('Ribeirão Preto', (SELECT estado_id FROM estados WHERE sigla = 'SP'), '3543402'),
('São José dos Campos', (SELECT estado_id FROM estados WHERE sigla = 'SP'), '3549904'),
('Sorocaba', (SELECT estado_id FROM estados WHERE sigla = 'SP'), '3552205'),
('Guarulhos', (SELECT estado_id FROM estados WHERE sigla = 'SP'), '3518800'),
('Osasco', (SELECT estado_id FROM estados WHERE sigla = 'SP'), '3534401'),
-- Rio de Janeiro
('Rio de Janeiro', (SELECT estado_id FROM estados WHERE sigla = 'RJ'), '3304557'),
('Niterói', (SELECT estado_id FROM estados WHERE sigla = 'RJ'), '3303302'),
('Petrópolis', (SELECT estado_id FROM estados WHERE sigla = 'RJ'), '3303906'),
('Nova Iguaçu', (SELECT estado_id FROM estados WHERE sigla = 'RJ'), '3303500'),
-- Minas Gerais
('Belo Horizonte', (SELECT estado_id FROM estados WHERE sigla = 'MG'), '3106200'),
('Uberlândia', (SELECT estado_id FROM estados WHERE sigla = 'MG'), '3170206'),
('Juiz de Fora', (SELECT estado_id FROM estados WHERE sigla = 'MG'), '3136702'),
('Contagem', (SELECT estado_id FROM estados WHERE sigla = 'MG'), '3118601'),
-- Sul
('Curitiba', (SELECT estado_id FROM estados WHERE sigla = 'PR'), '4106902'),
('Londrina', (SELECT estado_id FROM estados WHERE sigla = 'PR'), '4113700'),
('Porto Alegre', (SELECT estado_id FROM estados WHERE sigla = 'RS'), '4314902'),
('Caxias do Sul', (SELECT estado_id FROM estados WHERE sigla = 'RS'), '4305108'),
('Florianópolis', (SELECT estado_id FROM estados WHERE sigla = 'SC'), '4205407'),
('Joinville', (SELECT estado_id FROM estados WHERE sigla = 'SC'), '4209102'),
-- Nordeste
('Salvador', (SELECT estado_id FROM estados WHERE sigla = 'BA'), '2927408'),
('Fortaleza', (SELECT estado_id FROM estados WHERE sigla = 'CE'), '2304400'),
('Recife', (SELECT estado_id FROM estados WHERE sigla = 'PE'), '2611606'),
('Natal', (SELECT estado_id FROM estados WHERE sigla = 'RN'), '2408102'),
('João Pessoa', (SELECT estado_id FROM estados WHERE sigla = 'PB'), '2507507'),
('Maceió', (SELECT estado_id FROM estados WHERE sigla = 'AL'), '2704302'),
-- Centro-Oeste
('Brasília', (SELECT estado_id FROM estados WHERE sigla = 'DF'), '5300108'),
('Goiânia', (SELECT estado_id FROM estados WHERE sigla = 'GO'), '5208707'),
('Cuiabá', (SELECT estado_id FROM estados WHERE sigla = 'MT'), '5103403'),
('Campo Grande', (SELECT estado_id FROM estados WHERE sigla = 'MS'), '5002704'),
-- Norte
('Manaus', (SELECT estado_id FROM estados WHERE sigla = 'AM'), '1302603'),
('Belém', (SELECT estado_id FROM estados WHERE sigla = 'PA'), '1501402'),
('Porto Velho', (SELECT estado_id FROM estados WHERE sigla = 'RO'), '1100205');

-- CATEGORIAS (hierárquicas) - Temáticas Geek/Games
INSERT INTO categorias (nome, descricao, categoria_pai_id, ativo) VALUES
-- Categorias principais
('Action Figures', 'Bonecos e figuras de ação colecionáveis', NULL, TRUE),
('Funko Pop', 'Coleção completa de Funko Pops', NULL, TRUE),
('Games', 'Jogos para todas as plataformas', NULL, TRUE),
('Consoles', 'Consoles e acessórios para games', NULL, TRUE),
('HQs e Mangás', 'Quadrinhos, mangás e graphic novels', NULL, TRUE),
('Vestuário Geek', 'Camisetas, moletons e acessórios', NULL, TRUE),
('Colecionáveis', 'Itens raros e de coleção', NULL, TRUE),
('Board Games', 'Jogos de tabuleiro e card games', NULL, TRUE),
('Decoração Geek', 'Itens de decoração temáticos', NULL, TRUE),
('Acessórios Gamer', 'Periféricos e acessórios para gamers', NULL, TRUE);

-- Subcategorias
INSERT INTO categorias (nome, descricao, categoria_pai_id, ativo) VALUES
-- Subcategorias Action Figures
('Marvel Legends', 'Action Figures Marvel Legends Series', (SELECT categoria_id FROM categorias WHERE nome = 'Action Figures'), TRUE),
('DC Multiverse', 'Action Figures DC Multiverse', (SELECT categoria_id FROM categorias WHERE nome = 'Action Figures'), TRUE),
('Star Wars Black Series', 'Action Figures Star Wars 6"', (SELECT categoria_id FROM categorias WHERE nome = 'Action Figures'), TRUE),
('Anime Figures', 'Figuras de anime e mangá', (SELECT categoria_id FROM categorias WHERE nome = 'Action Figures'), TRUE),
-- Subcategorias Funko Pop
('Pop Marvel', 'Funko Pop linha Marvel', (SELECT categoria_id FROM categorias WHERE nome = 'Funko Pop'), TRUE),
('Pop DC', 'Funko Pop linha DC Comics', (SELECT categoria_id FROM categorias WHERE nome = 'Funko Pop'), TRUE),
('Pop Anime', 'Funko Pop linha Anime', (SELECT categoria_id FROM categorias WHERE nome = 'Funko Pop'), TRUE),
('Pop Games', 'Funko Pop linha Games', (SELECT categoria_id FROM categorias WHERE nome = 'Funko Pop'), TRUE),
('Pop Movies', 'Funko Pop linha Filmes', (SELECT categoria_id FROM categorias WHERE nome = 'Funko Pop'), TRUE),
-- Subcategorias Games
('PlayStation 5', 'Jogos para PS5', (SELECT categoria_id FROM categorias WHERE nome = 'Games'), TRUE),
('Xbox Series', 'Jogos para Xbox Series X/S', (SELECT categoria_id FROM categorias WHERE nome = 'Games'), TRUE),
('Nintendo Switch', 'Jogos para Switch', (SELECT categoria_id FROM categorias WHERE nome = 'Games'), TRUE),
('PC Games', 'Jogos para PC', (SELECT categoria_id FROM categorias WHERE nome = 'Games'), TRUE),
-- Subcategorias Consoles
('PlayStation', 'Consoles PlayStation', (SELECT categoria_id FROM categorias WHERE nome = 'Consoles'), TRUE),
('Xbox', 'Consoles Xbox', (SELECT categoria_id FROM categorias WHERE nome = 'Consoles'), TRUE),
('Nintendo', 'Consoles Nintendo', (SELECT categoria_id FROM categorias WHERE nome = 'Consoles'), TRUE),
('Retro Games', 'Consoles retrô e clássicos', (SELECT categoria_id FROM categorias WHERE nome = 'Consoles'), TRUE),
-- Subcategorias Vestuário
('Camisetas', 'Camisetas geek temáticas', (SELECT categoria_id FROM categorias WHERE nome = 'Vestuário Geek'), TRUE),
('Moletons', 'Moletons e jaquetas geek', (SELECT categoria_id FROM categorias WHERE nome = 'Vestuário Geek'), TRUE);

-- FORMAS DE PAGAMENTO
INSERT INTO formas_pagamento (nome, descricao, taxa_percentual, parcelas_max, ativo) VALUES
('Cartão de Crédito', 'Pagamento via cartão de crédito', 2.99, 12, TRUE),
('Cartão de Débito', 'Pagamento via cartão de débito', 1.49, 1, TRUE),
('PIX', 'Pagamento instantâneo via PIX - 5% desconto', 0.00, 1, TRUE),
('Boleto Bancário', 'Pagamento via boleto', 1.99, 1, TRUE),
('PayPal', 'Pagamento via PayPal', 4.99, 6, TRUE),
('Mercado Pago', 'Pagamento via Mercado Pago', 3.49, 12, TRUE),
('PagSeguro', 'Pagamento via PagSeguro', 3.99, 12, TRUE),
('Pontos XP', 'Pagamento com pontos de fidelidade', 0.00, 1, TRUE);

-- STATUS DE PEDIDO
INSERT INTO status_pedido (nome, descricao, cor_exibicao, ordem_fluxo) VALUES
('Aguardando Pagamento', 'Pedido aguardando confirmação de pagamento', '#FFA500', 1),
('Pagamento Confirmado', 'Pagamento foi confirmado', '#4169E1', 2),
('Em Separação', 'Produtos sendo separados no estoque', '#9370DB', 3),
('Enviado', 'Pedido foi enviado para transportadora', '#20B2AA', 4),
('Em Trânsito', 'Pedido em trânsito para entrega', '#32CD32', 5),
('Saiu para Entrega', 'Pedido saiu para entrega hoje', '#00CED1', 6),
('Entregue', 'Pedido foi entregue com sucesso', '#228B22', 7),
('Cancelado', 'Pedido foi cancelado', '#DC143C', 8),
('Devolvido', 'Pedido foi devolvido', '#8B0000', 9),
('Reembolsado', 'Valor foi reembolsado ao cliente', '#708090', 10);

-- CUPONS DE DESCONTO - Temáticos Geek
INSERT INTO cupons_desconto (codigo, descricao, tipo_desconto, valor_desconto, valor_minimo_pedido, quantidade_maxima, data_inicio, data_fim, ativo) VALUES
('GEEK10', 'Desconto de boas-vindas 10% para novos geeks', 'PERCENTUAL', 10.00, 100.00, 1000, '2025-01-01', '2025-12-31', TRUE),
('MAYTHEFORCEBEWITHYOU', 'Dia de Star Wars - 15% OFF', 'PERCENTUAL', 15.00, 150.00, 500, '2025-05-01', '2025-05-05', TRUE),
('MARVEL20', 'Desconto em produtos Marvel', 'PERCENTUAL', 20.00, 200.00, 800, '2025-01-01', '2025-12-31', TRUE),
('FUNKOFRIDAY', 'Sexta do Funko - 25% OFF', 'PERCENTUAL', 25.00, 100.00, 2000, '2025-01-01', '2025-12-31', TRUE),
('GAMERPASS', 'Desconto para gamers - R$50 OFF', 'VALOR_FIXO', 50.00, 300.00, 1000, '2025-01-01', '2025-12-31', TRUE),
('BLACKFRIDAYGEEK', 'Black Friday Geek 30% OFF', 'PERCENTUAL', 30.00, 200.00, 3000, '2025-11-20', '2025-11-30', TRUE),
('ANIME25', 'Desconto em produtos de Anime', 'PERCENTUAL', 25.00, 150.00, 600, '2025-01-01', '2025-12-31', TRUE),
('LEVELUP', 'Subiu de nível! R$30 OFF', 'VALOR_FIXO', 30.00, 150.00, 500, '2025-01-01', '2025-12-31', TRUE);

-- ============================================
-- FUNÇÃO PARA GERAR DADOS ALEATÓRIOS
-- ============================================

-- Função para gerar CPF válido (formato)
CREATE OR REPLACE FUNCTION gerar_cpf()
RETURNS CHAR(11) AS $$
DECLARE
    cpf TEXT;
BEGIN
    cpf := LPAD(FLOOR(RANDOM() * 99999999999)::TEXT, 11, '0');
    RETURN cpf;
END;
$$ LANGUAGE plpgsql;

-- Função para gerar telefone
CREATE OR REPLACE FUNCTION gerar_telefone()
RETURNS VARCHAR(15) AS $$
BEGIN
    RETURN '(' || LPAD(FLOOR(RANDOM() * 89 + 11)::TEXT, 2, '0') || ') 9' ||
           LPAD(FLOOR(RANDOM() * 9999)::TEXT, 4, '0') || '-' ||
           LPAD(FLOOR(RANDOM() * 9999)::TEXT, 4, '0');
END;
$$ LANGUAGE plpgsql;

-- Função para gerar CEP
CREATE OR REPLACE FUNCTION gerar_cep()
RETURNS CHAR(8) AS $$
BEGIN
    RETURN LPAD(FLOOR(RANDOM() * 89999999 + 10000000)::TEXT, 8, '0');
END;
$$ LANGUAGE plpgsql;

-- Função para gerar SKU
CREATE OR REPLACE FUNCTION gerar_sku(prefixo TEXT)
RETURNS VARCHAR(50) AS $$
BEGIN
    RETURN prefixo || '-' || UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 8));
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- POPULAR CLIENTES (1000 registros)
-- ============================================

-- Arrays de nomes para geração
DO $$
DECLARE
    nomes_m TEXT[] := ARRAY['João', 'Pedro', 'Lucas', 'Gabriel', 'Matheus', 'Rafael', 'Bruno', 'Felipe', 'Gustavo', 'Ricardo', 
                            'Carlos', 'Daniel', 'André', 'Marcos', 'Paulo', 'Eduardo', 'Fernando', 'Rodrigo', 'Alexandre', 'Thiago',
                            'Leonardo', 'Diego', 'Vinícius', 'Henrique', 'Caio', 'Murilo', 'Leandro', 'Fábio', 'Marcelo', 'Renato'];
    nomes_f TEXT[] := ARRAY['Maria', 'Ana', 'Juliana', 'Fernanda', 'Patricia', 'Camila', 'Larissa', 'Amanda', 'Beatriz', 'Carolina',
                            'Letícia', 'Mariana', 'Gabriela', 'Rafaela', 'Isabela', 'Bianca', 'Natália', 'Bruna', 'Vanessa', 'Tatiane',
                            'Priscila', 'Daniela', 'Renata', 'Aline', 'Cristina', 'Michele', 'Luciana', 'Adriana', 'Simone', 'Sandra'];
    sobrenomes TEXT[] := ARRAY['Silva', 'Santos', 'Oliveira', 'Souza', 'Rodrigues', 'Ferreira', 'Alves', 'Pereira', 'Lima', 'Gomes',
                               'Costa', 'Ribeiro', 'Martins', 'Carvalho', 'Almeida', 'Lopes', 'Soares', 'Fernandes', 'Vieira', 'Barbosa',
                               'Rocha', 'Dias', 'Nascimento', 'Andrade', 'Moreira', 'Nunes', 'Marques', 'Machado', 'Mendes', 'Freitas',
                               'Cardoso', 'Ramos', 'Gonçalves', 'Santana', 'Teixeira', 'Correia', 'Araújo', 'Pinto', 'Monteiro', 'Campos'];
    nicknames_geek TEXT[] := ARRAY['DarkKnight', 'IronFan', 'WebHead', 'Padawan', 'DragonSlayer', 'PixelHero', 'NinjaGamer', 'ShadowHunter',
                                   'ThunderBolt', 'FrostMage', 'StormBreaker', 'StarLord', 'GrootFan', 'WandaLover', 'ThorOdinson',
                                   'BatFan', 'Jokerized', 'GothamKnight', 'KryptonSon', 'FlashRunner', 'AquaKing', 'WonderFan',
                                   'PikachuMaster', 'AshKetchum', 'NarutoFan', 'SasukeUchiha', 'GokuSSJ', 'VegetaPrince', 'OnePieceFan',
                                   'LuffyKing', 'ZoroSword', 'AnimeLover', 'MangaReader', 'OtakuLife', 'CosplayKing', 'RetroGamer',
                                   'SpeedRunner', 'ProGamer', 'NoobMaster', 'EliteGamer', 'BossKiller', 'LootHunter', 'QuestMaster'];
    nome_completo TEXT;
    email TEXT;
    genero CHAR(1);
    nickname TEXT;
    nivel INTEGER;
    pontos INTEGER;
    i INTEGER;
BEGIN
    FOR i IN 1..1000 LOOP
        -- Alternar entre masculino e feminino
        IF RANDOM() > 0.5 THEN
            genero := 'M';
            nome_completo := nomes_m[1 + FLOOR(RANDOM() * ARRAY_LENGTH(nomes_m, 1))::INT] || ' ' ||
                            sobrenomes[1 + FLOOR(RANDOM() * ARRAY_LENGTH(sobrenomes, 1))::INT] || ' ' ||
                            sobrenomes[1 + FLOOR(RANDOM() * ARRAY_LENGTH(sobrenomes, 1))::INT];
        ELSE
            genero := 'F';
            nome_completo := nomes_f[1 + FLOOR(RANDOM() * ARRAY_LENGTH(nomes_f, 1))::INT] || ' ' ||
                            sobrenomes[1 + FLOOR(RANDOM() * ARRAY_LENGTH(sobrenomes, 1))::INT] || ' ' ||
                            sobrenomes[1 + FLOOR(RANDOM() * ARRAY_LENGTH(sobrenomes, 1))::INT];
        END IF;
        
        email := LOWER(unaccent(REPLACE(REPLACE(nome_completo, ' ', '.'), '''', ''))) || i::TEXT || '@' ||
                 (ARRAY['gmail.com', 'hotmail.com', 'yahoo.com.br', 'outlook.com', 'uol.com.br'])[1 + FLOOR(RANDOM() * 5)::INT];
        
        -- Gerar nickname geek único
        nickname := nicknames_geek[1 + FLOOR(RANDOM() * ARRAY_LENGTH(nicknames_geek, 1))::INT] || '_' || i::TEXT;
        
        -- Nível geek baseado em tempo de cadastro (simulado)
        nivel := 1 + FLOOR(RANDOM() * 10)::INT;
        pontos := nivel * 100 + FLOOR(RANDOM() * 500)::INT;
        
        INSERT INTO clientes (nome, email, cpf, telefone, data_nascimento, genero, senha_hash, nickname, nivel_geek, pontos_xp, ativo, newsletter, created_at, ultimo_acesso)
        VALUES (
            nome_completo,
            email,
            gerar_cpf(),
            gerar_telefone(),
            DATE '1960-01-01' + (RANDOM() * 16000)::INT,
            genero,
            MD5(RANDOM()::TEXT),
            nickname,
            nivel,
            pontos,
            RANDOM() > 0.05, -- 95% ativos
            RANDOM() > 0.4,  -- 60% newsletter (geeks gostam de novidades!)
            TIMESTAMP '2023-01-01' + (RANDOM() * 700)::INT * INTERVAL '1 day',
            CASE WHEN RANDOM() > 0.3 THEN TIMESTAMP '2025-01-01' + (RANDOM() * 320)::INT * INTERVAL '1 day' ELSE NULL END
        );
    END LOOP;
    
    RAISE NOTICE 'Clientes inseridos: 1000';
END $$;

-- ============================================
-- POPULAR PRODUTOS (1000 registros)
-- ============================================

DO $$
DECLARE
    prefixos TEXT[] := ARRAY['ACFG', 'FUNK', 'GAME', 'CONS', 'HQMG', 'VEST', 'COLE', 'BRDG', 'DECO', 'ACES'];
    franquias TEXT[] := ARRAY['Marvel', 'DC Comics', 'Star Wars', 'Harry Potter', 'Dragon Ball', 'Naruto', 'One Piece', 
                               'Pokemon', 'Nintendo', 'PlayStation', 'Xbox', 'The Lord of the Rings', 'Game of Thrones',
                               'Stranger Things', 'The Witcher', 'Zelda', 'Mario', 'Sonic', 'Resident Evil', 'Final Fantasy'];
    fabricantes TEXT[] := ARRAY['Funko', 'Hasbro', 'NECA', 'Hot Toys', 'Bandai', 'Good Smile Company', 'Kotobukiya', 
                                 'McFarlane Toys', 'Diamond Select', 'Mezco', 'Sideshow', 'Iron Studios', 'Prime 1 Studio'];
    nomes_produtos TEXT[][] := ARRAY[
        -- Action Figures (cat 1)
        ARRAY['Spider-Man Action Figure', 'Iron Man Mark LXXXV', 'Batman Arkham Knight', 'Darth Vader Black Series',
              'Goku Super Saiyan Blue', 'Naruto Uzumaki Sage Mode', 'Luffy Gear 5', 'Wolverine X-Men',
              'Captain America Shield Edition', 'Thor Love and Thunder', 'Wonder Woman 1984', 'Thanos Infinity Gauntlet',
              'Venom Lethal Protector', 'Deadpool Maximum Effort', 'Black Panther Wakanda Forever',
              'Superman Man of Steel', 'Flash Speed Force', 'Aquaman King of Atlantis', 'Joker Killing Joke',
              'Hulk Immortal Edition'],
        -- Funko Pop (cat 2)
        ARRAY['Funko Pop Spider-Man No Way Home', 'Funko Pop Iron Man Endgame', 'Funko Pop Batman 1989',
              'Funko Pop Darth Vader Chrome', 'Funko Pop Goku Ultra Instinct', 'Funko Pop Naruto Six Paths',
              'Funko Pop Luffy Wano', 'Funko Pop Harry Potter Patronus', 'Funko Pop Pikachu Flocked',
              'Funko Pop The Mandalorian with Grogu', 'Funko Pop Thanos Snapping', 'Funko Pop Venom Leaping',
              'Funko Pop Deadpool Unicorn', 'Funko Pop Wolverine Adamantium', 'Funko Pop Stranger Things Eleven',
              'Funko Pop Geralt The Witcher', 'Funko Pop Master Chief Halo', 'Funko Pop Kratos God of War',
              'Funko Pop Link Zelda TOTK', 'Funko Pop Mario Tanooki'],
        -- Games (cat 3)
        ARRAY['God of War Ragnarök PS5', 'Spider-Man 2 PS5', 'The Last of Us Part II Remastered', 'Hogwarts Legacy',
              'Final Fantasy XVI', 'Resident Evil 4 Remake', 'Zelda Tears of the Kingdom', 'Mario Kart 8 Deluxe',
              'Animal Crossing New Horizons', 'Pokemon Scarlet', 'Call of Duty Modern Warfare III', 'FIFA 25',
              'Elden Ring Shadow of Erdtree', 'Baldurs Gate 3', 'Starfield', 'Halo Infinite', 'Forza Horizon 5',
              'Diablo IV', 'Street Fighter 6', 'Mortal Kombat 1'],
        -- Consoles (cat 4)
        ARRAY['PlayStation 5 Digital Edition', 'PlayStation 5 Standard', 'Xbox Series X', 'Xbox Series S',
              'Nintendo Switch OLED', 'Nintendo Switch Lite', 'Steam Deck 512GB', 'PS5 DualSense Controller',
              'Xbox Elite Controller Series 2', 'Nintendo Pro Controller', 'PS5 Pulse 3D Headset',
              'Xbox Wireless Headset', 'PS5 Media Remote', 'Xbox Play and Charge Kit', 'Switch Joy-Con Pair',
              'Retro Console NES Classic', 'Retro Console SNES Classic', 'Sega Genesis Mini', 'Atari 2600+',
              'PlayStation Portal'],
        -- HQs e Mangás (cat 5)
        ARRAY['Batman O Cavaleiro das Trevas', 'Watchmen Edição Definitiva', 'Sandman Box Set', 'V de Vingança',
              'Saga Compendium', 'The Walking Dead Compendium', 'One Piece Box Set 1', 'Naruto Box Set 1',
              'Dragon Ball Super Vol 1-20', 'Attack on Titan Box Set', 'Demon Slayer Box Set', 'My Hero Academia Vol 1-35',
              'Jujutsu Kaisen Vol 1-25', 'Chainsaw Man Box Set', 'Spy x Family Vol 1-12', 'Death Note Black Edition',
              'Fullmetal Alchemist Box Set', 'Berserk Deluxe Edition', 'Vagabond Vizbig Edition', 'Akira Box Set'],
        -- Vestuário Geek (cat 6)
        ARRAY['Camiseta Marvel Avengers Logo', 'Camiseta DC Justice League', 'Camiseta Star Wars Darth Vader',
              'Moletom Harry Potter Hogwarts', 'Camiseta Dragon Ball Goku', 'Camiseta Naruto Akatsuki',
              'Moletom PlayStation Controller', 'Camiseta Xbox Achievement Unlocked', 'Camiseta Nintendo Retro',
              'Jaqueta Bomber Star Wars', 'Moletom The Witcher School of Wolf', 'Camiseta Zelda Triforce',
              'Camiseta Mario Bros Pixel Art', 'Moletom Pokemon Pikachu', 'Camiseta Stranger Things Hellfire Club',
              'Jaqueta Varsity Hogwarts', 'Camiseta Game of Thrones Winter', 'Moletom Lord of the Rings Fellowship',
              'Camiseta Resident Evil Umbrella Corp', 'Bone Trucker Geek Culture'],
        -- Colecionáveis (cat 7)
        ARRAY['Replica Escudo Capitão América', 'Replica Mjolnir Thor', 'Sabre de Luz Luke Skywalker Force FX',
              'Varinha Harry Potter Ollivanders', 'Replica Anel Um Anel LOTR', 'Replica Dragon Balls Set',
              'Diorama Avengers Endgame', 'Estátua Batman Jim Lee', 'Busto Darth Vader 1:1', 'Replica Omnitrix Ben 10',
              'Replica Naruto Kunai Set', 'Chaveiro Keyblade Kingdom Hearts', 'Miniatura DeLorean Back to Future',
              'Replica Portal Gun Rick Morty', 'Coin Set Mario Bros', 'Replica Master Sword Zelda',
              'Estátua Spider-Man Daily Bugle', 'Diorama Jurassic Park Gates', 'Replica Infinity Gauntlet', 
              'Estátua Goku Ultra Instinct'],
        -- Board Games (cat 8)
        ARRAY['Monopoly Marvel Edition', 'Risk Game of Thrones', 'Clue Harry Potter', 'Catan Base Game',
              'Ticket to Ride', 'Pandemic Legacy', 'Gloomhaven', 'Terraforming Mars', 'Wingspan',
              'Azul', 'Splendor', '7 Wonders', 'Codenames', 'Dixit', 'Carcassonne',
              'Magic The Gathering Starter Kit', 'Pokemon TCG Elite Trainer Box', 'Yu-Gi-Oh Starter Deck',
              'Dungeons Dragons Starter Set', 'Star Wars X-Wing Core Set'],
        -- Decoração Geek (cat 9)
        ARRAY['Luminária Lightsaber Star Wars', 'Quadro Metal Marvel Comics', 'Relógio Parede Batman',
              'Caneca Termossensível Harry Potter', 'Almofada Pikachu Pokemon', 'Tapete Gamer RGB',
              'Luminária Neon PlayStation', 'Porta Retrato Digital Geek', 'Estante Livros TARDIS Doctor Who',
              'Luminária Baby Yoda Grogu', 'Kit Copos Shot Avengers', 'Banco Bar Star Wars Cantina',
              'Quadro LED Arcade Retro', 'Luminária Minecraft Torch', 'Relogio Digital Pip-Boy Fallout',
              'Caneca 3D Groot', 'Porta Canetas Stormtrooper', 'Luminária Death Star', 'Cabideiro Mjolnir',
              'Espelho Batman Signal'],
        -- Acessórios Gamer (cat 10)
        ARRAY['Headset Gamer HyperX Cloud II', 'Mouse Gamer Logitech G502', 'Teclado Mecânico Razer',
              'Mousepad XXL RGB Gaming', 'Cadeira Gamer ThunderX3', 'Monitor Gamer 27" 144Hz',
              'Webcam Logitech StreamCam', 'Microfone Blue Yeti', 'Ring Light Streamer', 'Capture Card Elgato',
              'Controle Arcade Fightstick', 'Volante Logitech G29', 'Flight Stick Thrustmaster',
              'VR Headset Meta Quest 3', 'Stand Headset RGB', 'Hub USB Gamer', 'SSD NVMe Gaming 1TB',
              'Cooler Laptop Gamer', 'Stream Deck Elgato', 'Suporte Monitor Articulado']
    ];
    classificacoes TEXT[] := ARRAY['Livre', '10+', '12+', '14+', '16+', '18+'];
    cat_ids INTEGER[];
    i INTEGER;
    cat_idx INTEGER;
    prod_idx INTEGER;
    preco_base DECIMAL;
    franquia_escolhida TEXT;
    fabricante_escolhido TEXT;
BEGIN
    -- Obter IDs das categorias
    SELECT ARRAY_AGG(categoria_id ORDER BY RANDOM()) INTO cat_ids FROM categorias WHERE ativo = TRUE;
    
    FOR i IN 1..1000 LOOP
        cat_idx := 1 + (i % 10);  -- Ciclar entre as 10 categorias de produtos
        prod_idx := 1 + ((i / 10) % 20);  -- Ciclar entre os 20 produtos de cada categoria
        
        -- Selecionar franquia e fabricante aleatórios
        franquia_escolhida := franquias[1 + FLOOR(RANDOM() * ARRAY_LENGTH(franquias, 1))::INT];
        fabricante_escolhido := fabricantes[1 + FLOOR(RANDOM() * ARRAY_LENGTH(fabricantes, 1))::INT];
        
        -- Preço base varia por categoria
        preco_base := CASE cat_idx
            WHEN 1 THEN 150 + RANDOM() * 800   -- Action Figures
            WHEN 2 THEN 80 + RANDOM() * 200    -- Funko Pop
            WHEN 3 THEN 150 + RANDOM() * 350   -- Games
            WHEN 4 THEN 300 + RANDOM() * 4500  -- Consoles
            WHEN 5 THEN 50 + RANDOM() * 400    -- HQs e Mangás
            WHEN 6 THEN 60 + RANDOM() * 200    -- Vestuário Geek
            WHEN 7 THEN 200 + RANDOM() * 2000  -- Colecionáveis
            WHEN 8 THEN 100 + RANDOM() * 400   -- Board Games
            WHEN 9 THEN 50 + RANDOM() * 300    -- Decoração Geek
            WHEN 10 THEN 150 + RANDOM() * 1500 -- Acessórios Gamer
        END;
        
        INSERT INTO produtos (
            sku, nome, descricao, descricao_curta, categoria_id, franquia, fabricante,
            preco, preco_promocional, custo, 
            peso_kg, largura_cm, altura_cm, profundidade_cm,
            estoque_atual, estoque_minimo, ativo, destaque, lancamento, exclusivo, pre_venda,
            data_lancamento, classificacao_indicativa, created_at
        )
        VALUES (
            gerar_sku(prefixos[cat_idx]),
            nomes_produtos[cat_idx][prod_idx] || ' Ed.' || LPAD(i::TEXT, 4, '0'),
            'Produto oficial licenciado ' || franquia_escolhida || '. ' ||
            'Item de alta qualidade para colecionadores e fãs. ' ||
            'Fabricado por ' || fabricante_escolhido || '. ' ||
            'Produto original com garantia de autenticidade. Ideal para sua coleção geek!',
            nomes_produtos[cat_idx][prod_idx] || ' - ' || franquia_escolhida,
            cat_ids[1 + (i % ARRAY_LENGTH(cat_ids, 1))],
            franquia_escolhida,
            fabricante_escolhido,
            ROUND(preco_base::NUMERIC, 2),
            CASE WHEN RANDOM() > 0.7 THEN ROUND((preco_base * (0.7 + RANDOM() * 0.2))::NUMERIC, 2) ELSE NULL END,
            ROUND((preco_base * (0.4 + RANDOM() * 0.2))::NUMERIC, 2),
            ROUND((0.1 + RANDOM() * 5)::NUMERIC, 3),
            ROUND((5 + RANDOM() * 40)::NUMERIC, 2),
            ROUND((5 + RANDOM() * 30)::NUMERIC, 2),
            ROUND((5 + RANDOM() * 30)::NUMERIC, 2),
            FLOOR(RANDOM() * 200)::INT,
            3 + FLOOR(RANDOM() * 10)::INT,
            RANDOM() > 0.03, -- 97% ativos
            RANDOM() > 0.85, -- 15% destaque
            RANDOM() > 0.90, -- 10% lançamento
            RANDOM() > 0.95, -- 5% exclusivo
            RANDOM() > 0.97, -- 3% pré-venda
            CASE WHEN RANDOM() > 0.8 THEN DATE '2025-01-01' + (RANDOM() * 365)::INT ELSE NULL END,
            CASE WHEN cat_idx = 3 THEN classificacoes[1 + FLOOR(RANDOM() * ARRAY_LENGTH(classificacoes, 1))::INT] ELSE NULL END,
            TIMESTAMP '2023-01-01' + (RANDOM() * 700)::INT * INTERVAL '1 day'
        );
    END LOOP;
    
    RAISE NOTICE 'Produtos geeks inseridos: 1000';
END $$;

-- ============================================
-- POPULAR ENDEREÇOS (1000 registros)
-- ============================================

DO $$
DECLARE
    logradouros TEXT[] := ARRAY['Rua', 'Avenida', 'Alameda', 'Travessa', 'Praça', 'Estrada'];
    nomes_ruas TEXT[] := ARRAY['das Flores', 'Brasil', 'Independência', 'São Paulo', 'Rio Branco', 
                                'Santos Dumont', 'Tiradentes', 'Getúlio Vargas', 'JK', 'das Nações',
                                'Principal', 'do Comércio', 'XV de Novembro', 'Sete de Setembro',
                                'Dom Pedro II', 'Marechal Deodoro', 'Presidente Vargas', 'Central'];
    bairros TEXT[] := ARRAY['Centro', 'Jardim América', 'Vila Nova', 'Santa Cruz', 'Boa Vista',
                            'São José', 'Jardim Europa', 'Vila Mariana', 'Pinheiros', 'Moema',
                            'Copacabana', 'Ipanema', 'Botafogo', 'Barra', 'Leblon'];
    cidade_ids INTEGER[];
    cliente_ids INTEGER[];
    i INTEGER;
BEGIN
    SELECT ARRAY_AGG(cidade_id) INTO cidade_ids FROM cidades;
    SELECT ARRAY_AGG(cliente_id) INTO cliente_ids FROM clientes;
    
    FOR i IN 1..1000 LOOP
        INSERT INTO enderecos (
            cliente_id, tipo, cep, logradouro, numero, complemento, bairro, cidade_id, referencia, principal
        )
        VALUES (
            cliente_ids[1 + (i % ARRAY_LENGTH(cliente_ids, 1))],
            (ARRAY['ENTREGA', 'COBRANCA', 'AMBOS'])[1 + FLOOR(RANDOM() * 3)::INT],
            gerar_cep(),
            logradouros[1 + FLOOR(RANDOM() * ARRAY_LENGTH(logradouros, 1))::INT] || ' ' ||
            nomes_ruas[1 + FLOOR(RANDOM() * ARRAY_LENGTH(nomes_ruas, 1))::INT],
            (1 + FLOOR(RANDOM() * 5000))::TEXT,
            CASE WHEN RANDOM() > 0.5 THEN 'Apto ' || (100 + FLOOR(RANDOM() * 900))::TEXT ELSE NULL END,
            bairros[1 + FLOOR(RANDOM() * ARRAY_LENGTH(bairros, 1))::INT],
            cidade_ids[1 + FLOOR(RANDOM() * ARRAY_LENGTH(cidade_ids, 1))::INT],
            CASE WHEN RANDOM() > 0.7 THEN 'Próximo ao ' || (ARRAY['Shopping', 'Mercado', 'Parque', 'Hospital', 'Escola'])[1 + FLOOR(RANDOM() * 5)::INT] ELSE NULL END,
            i <= 800 AND (i % 4 = 1) -- Aproximadamente 200 endereços principais
        );
    END LOOP;
    
    RAISE NOTICE 'Endereços inseridos: 1000';
END $$;

-- ============================================
-- POPULAR PEDIDOS (1000 registros)
-- ============================================

DO $$
DECLARE
    cliente_ids INTEGER[];
    endereco_map INTEGER[][];
    status_ids INTEGER[];
    pagamento_ids INTEGER[];
    i INTEGER;
    cli_id INTEGER;
    end_id INTEGER;
    subtotal_calc DECIMAL;
    desconto_calc DECIMAL;
    frete_calc DECIMAL;
    data_ped TIMESTAMP;
BEGIN
    SELECT ARRAY_AGG(cliente_id) INTO cliente_ids FROM clientes;
    SELECT ARRAY_AGG(status_id) INTO status_ids FROM status_pedido;
    SELECT ARRAY_AGG(forma_pagamento_id) INTO pagamento_ids FROM formas_pagamento;
    
    FOR i IN 1..1000 LOOP
        cli_id := cliente_ids[1 + FLOOR(RANDOM() * ARRAY_LENGTH(cliente_ids, 1))::INT];
        
        -- Buscar endereço do cliente
        SELECT endereco_id INTO end_id 
        FROM enderecos 
        WHERE cliente_id = cli_id 
        ORDER BY principal DESC, RANDOM() 
        LIMIT 1;
        
        -- Se não encontrou, pegar qualquer endereço
        IF end_id IS NULL THEN
            SELECT endereco_id INTO end_id FROM enderecos ORDER BY RANDOM() LIMIT 1;
        END IF;
        
        subtotal_calc := ROUND((100 + RANDOM() * 5000)::NUMERIC, 2);
        desconto_calc := CASE WHEN RANDOM() > 0.6 THEN ROUND((subtotal_calc * RANDOM() * 0.15)::NUMERIC, 2) ELSE 0 END;
        frete_calc := CASE WHEN subtotal_calc > 299 AND RANDOM() > 0.5 THEN 0 ELSE ROUND((15 + RANDOM() * 45)::NUMERIC, 2) END;
        data_ped := TIMESTAMP '2024-01-01' + (RANDOM() * 690)::INT * INTERVAL '1 day' + 
                    (RANDOM() * 86400)::INT * INTERVAL '1 second';
        
        INSERT INTO pedidos (
            numero_pedido, cliente_id, endereco_entrega_id, status_id, forma_pagamento_id,
            subtotal, desconto, frete, total, parcelas, cupom_codigo, observacoes,
            ip_cliente, data_pedido, data_pagamento, data_envio, data_entrega
        )
        VALUES (
            'PED' || TO_CHAR(data_ped, 'YYYYMMDD') || LPAD(i::TEXT, 6, '0'),
            cli_id,
            end_id,
            status_ids[1 + FLOOR(RANDOM() * 7)::INT], -- Mais pedidos em status normais
            pagamento_ids[1 + FLOOR(RANDOM() * ARRAY_LENGTH(pagamento_ids, 1))::INT],
            subtotal_calc,
            desconto_calc,
            frete_calc,
            subtotal_calc - desconto_calc + frete_calc,
            CASE WHEN RANDOM() > 0.5 THEN 1 ELSE 1 + FLOOR(RANDOM() * 12)::INT END,
            CASE WHEN desconto_calc > 0 AND RANDOM() > 0.5 THEN (ARRAY['BEMVINDO10', 'BLACKFRIDAY', 'NATAL2025'])[1 + FLOOR(RANDOM() * 3)::INT] ELSE NULL END,
            CASE WHEN RANDOM() > 0.8 THEN 'Entregar no período da tarde' ELSE NULL END,
            '192.168.' || FLOOR(RANDOM() * 255)::INT || '.' || FLOOR(RANDOM() * 255)::INT,
            data_ped,
            CASE WHEN RANDOM() > 0.1 THEN data_ped + INTERVAL '1 hour' * (1 + FLOOR(RANDOM() * 48)::INT) ELSE NULL END,
            CASE WHEN RANDOM() > 0.2 THEN data_ped + INTERVAL '1 day' * (1 + FLOOR(RANDOM() * 3)::INT) ELSE NULL END,
            CASE WHEN RANDOM() > 0.3 THEN data_ped + INTERVAL '1 day' * (3 + FLOOR(RANDOM() * 10)::INT) ELSE NULL END
        );
    END LOOP;
    
    RAISE NOTICE 'Pedidos inseridos: 1000';
END $$;

-- ============================================
-- POPULAR ITENS_PEDIDO (~3000 registros)
-- ============================================

DO $$
DECLARE
    pedido_rec RECORD;
    produto_ids INTEGER[];
    prod_id INTEGER;
    qtd INTEGER;
    preco DECIMAL;
    desconto DECIMAL;
    items_count INTEGER := 0;
BEGIN
    SELECT ARRAY_AGG(produto_id) INTO produto_ids FROM produtos WHERE ativo = TRUE;
    
    FOR pedido_rec IN SELECT pedido_id, subtotal FROM pedidos LOOP
        -- Cada pedido terá de 1 a 5 itens
        FOR i IN 1..(1 + FLOOR(RANDOM() * 5)::INT) LOOP
            prod_id := produto_ids[1 + FLOOR(RANDOM() * ARRAY_LENGTH(produto_ids, 1))::INT];
            qtd := 1 + FLOOR(RANDOM() * 3)::INT;
            
            SELECT COALESCE(p.preco_promocional, p.preco) INTO preco 
            FROM produtos p WHERE p.produto_id = prod_id;
            
            desconto := CASE WHEN RANDOM() > 0.8 THEN ROUND((preco * 0.05)::NUMERIC, 2) ELSE 0 END;
            
            INSERT INTO itens_pedido (pedido_id, produto_id, quantidade, preco_unitario, desconto_unitario, subtotal)
            VALUES (
                pedido_rec.pedido_id,
                prod_id,
                qtd,
                preco,
                desconto,
                (preco - desconto) * qtd
            )
            ON CONFLICT (pedido_id, produto_id) DO UPDATE 
            SET quantidade = itens_pedido.quantidade + EXCLUDED.quantidade,
                subtotal = (EXCLUDED.preco_unitario - EXCLUDED.desconto_unitario) * (itens_pedido.quantidade + EXCLUDED.quantidade);
            
            items_count := items_count + 1;
        END LOOP;
    END LOOP;
    
    RAISE NOTICE 'Itens de pedido inseridos: %', items_count;
END $$;

-- ============================================
-- POPULAR AVALIAÇÕES (~500 registros)
-- ============================================

DO $$
DECLARE
    produto_ids INTEGER[];
    cliente_ids INTEGER[];
    titulos TEXT[] := ARRAY['Produto incrível! 🔥', 'Perfeito para coleção!', 'Recomendo demais!', 'Superou expectativas!', 
                            'Muito bom!', 'Ótima qualidade!', 'Vale cada centavo!', 'Item essencial para geeks!',
                            'Entrega rápida e segura!', 'Melhor compra do ano!', 'Produto original!', 'Chegou perfeito!',
                            'Amei! Vou colecionar mais!', 'Presente perfeito!', 'Qualidade premium!'];
    pros_arr TEXT[] := ARRAY['Qualidade excelente', 'Embalagem perfeita', 'Produto original', 'Cores vibrantes',
                              'Acabamento impecável', 'Tamanho ideal', 'Material resistente', 'Detalhes incríveis',
                              'Fiel ao personagem', 'Ótimo custo-benefício'];
    contras_arr TEXT[] := ARRAY['Preço um pouco alto', 'Poderia ter mais acessórios', 'Embalagem simples', 'Demorou para chegar',
                                 'Base poderia ser melhor', 'Faltou manual', 'Caixa amassada', NULL, NULL, NULL];
    i INTEGER;
BEGIN
    SELECT ARRAY_AGG(produto_id) INTO produto_ids FROM produtos WHERE ativo = TRUE;
    SELECT ARRAY_AGG(cliente_id) INTO cliente_ids FROM clientes WHERE ativo = TRUE;
    
    FOR i IN 1..500 LOOP
        INSERT INTO avaliacoes_produtos (produto_id, cliente_id, nota, titulo, comentario, pros, contras, recomenda, aprovado)
        VALUES (
            produto_ids[1 + FLOOR(RANDOM() * ARRAY_LENGTH(produto_ids, 1))::INT],
            cliente_ids[1 + FLOOR(RANDOM() * ARRAY_LENGTH(cliente_ids, 1))::INT],
            3 + FLOOR(RANDOM() * 3)::INT, -- Notas 3, 4 ou 5 (produtos geek costumam ter boas avaliações)
            titulos[1 + FLOOR(RANDOM() * ARRAY_LENGTH(titulos, 1))::INT],
            CASE WHEN RANDOM() > 0.2 THEN 
                'Produto ' || 
                (ARRAY['sensacional', 'incrível', 'fantástico', 'maravilhoso', 'perfeito'])[1 + FLOOR(RANDOM() * 5)::INT] ||
                '! ' || 
                (ARRAY['Chegou antes do prazo.', 'A qualidade é top!', 'Recomendo para todos os geeks.', 
                       'Vou comprar mais!', 'Superou minhas expectativas.', 'Perfeito para minha coleção!',
                       'Meus amigos ficaram com inveja!', 'Item obrigatório para fãs!'])[1 + FLOOR(RANDOM() * 8)::INT]
            ELSE NULL END,
            pros_arr[1 + FLOOR(RANDOM() * ARRAY_LENGTH(pros_arr, 1))::INT],
            contras_arr[1 + FLOOR(RANDOM() * ARRAY_LENGTH(contras_arr, 1))::INT],
            RANDOM() > 0.1, -- 90% recomenda
            RANDOM() > 0.15  -- 85% aprovado
        )
        ON CONFLICT (produto_id, cliente_id) DO NOTHING;
    END LOOP;
    
    RAISE NOTICE 'Avaliações inseridas: ~500';
END $$;

-- ============================================
-- POPULAR HISTÓRICO DE STATUS
-- ============================================

INSERT INTO historico_status_pedido (pedido_id, status_anterior_id, status_novo_id, observacao, usuario_responsavel)
SELECT 
    p.pedido_id,
    CASE WHEN p.status_id > 1 THEN p.status_id - 1 ELSE NULL END,
    p.status_id,
    'Atualização automática de status',
    'sistema'
FROM pedidos p;

-- ============================================
-- REABILITAR CONSTRAINTS
-- ============================================
SET session_replication_role = DEFAULT;

-- ============================================
-- ATUALIZAR ESTATÍSTICAS
-- ============================================
ANALYZE;

-- ============================================
-- VERIFICAÇÃO FINAL
-- ============================================
DO $$
DECLARE
    rec RECORD;
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'RESUMO DA POPULAÇÃO DE DADOS';
    RAISE NOTICE '========================================';
    
    FOR rec IN 
        SELECT 'clientes' as tabela, COUNT(*) as total FROM clientes
        UNION ALL SELECT 'produtos', COUNT(*) FROM produtos
        UNION ALL SELECT 'enderecos', COUNT(*) FROM enderecos
        UNION ALL SELECT 'pedidos', COUNT(*) FROM pedidos
        UNION ALL SELECT 'itens_pedido', COUNT(*) FROM itens_pedido
        UNION ALL SELECT 'avaliacoes_produtos', COUNT(*) FROM avaliacoes_produtos
        UNION ALL SELECT 'categorias', COUNT(*) FROM categorias
        UNION ALL SELECT 'estados', COUNT(*) FROM estados
        UNION ALL SELECT 'cidades', COUNT(*) FROM cidades
        ORDER BY 1
    LOOP
        RAISE NOTICE '% : % registros', RPAD(rec.tabela, 20), rec.total;
    END LOOP;
    
    RAISE NOTICE '========================================';
END $$;
