-- ============================================
-- SCRIPT 02: CRIAÇÃO DAS TABELAS
-- Sistema: GeekStore - Loja Virtual de Artigos Geeks e Games
-- Database: PostgreSQL 18
-- ============================================

-- Conectar ao banco
\c geekstore_db

-- Definir schema
SET search_path TO geekstore, public;

-- ============================================
-- TABELAS AUXILIARES (5 tabelas)
-- ============================================

-- 1. TABELA: categorias (Auxiliar)
-- Categorias de produtos geek/games
DROP TABLE IF EXISTS categorias CASCADE;
CREATE TABLE categorias (
    categoria_id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE,
    descricao TEXT,
    categoria_pai_id INTEGER REFERENCES categorias(categoria_id),
    ativo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE categorias IS 'Categorias e subcategorias de produtos geeks e games';
COMMENT ON COLUMN categorias.categoria_pai_id IS 'Auto-relacionamento para subcategorias';

-- 2. TABELA: estados (Auxiliar)
-- Estados brasileiros
DROP TABLE IF EXISTS estados CASCADE;
CREATE TABLE estados (
    estado_id SERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL,
    sigla CHAR(2) NOT NULL UNIQUE,
    regiao VARCHAR(20) NOT NULL
);

COMMENT ON TABLE estados IS 'Estados brasileiros para endereços';

-- 3. TABELA: cidades (Auxiliar)
-- Cidades brasileiras
DROP TABLE IF EXISTS cidades CASCADE;
CREATE TABLE cidades (
    cidade_id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    estado_id INTEGER NOT NULL REFERENCES estados(estado_id),
    codigo_ibge VARCHAR(10),
    UNIQUE(nome, estado_id)
);

COMMENT ON TABLE cidades IS 'Cidades para endereços de entrega';

-- 4. TABELA: formas_pagamento (Auxiliar)
-- Formas de pagamento disponíveis
DROP TABLE IF EXISTS formas_pagamento CASCADE;
CREATE TABLE formas_pagamento (
    forma_pagamento_id SERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL UNIQUE,
    descricao TEXT,
    taxa_percentual DECIMAL(5,2) DEFAULT 0,
    parcelas_max INTEGER DEFAULT 1,
    ativo BOOLEAN DEFAULT TRUE
);

COMMENT ON TABLE formas_pagamento IS 'Métodos de pagamento aceitos';

-- 5. TABELA: status_pedido (Auxiliar)
-- Status possíveis para pedidos
DROP TABLE IF EXISTS status_pedido CASCADE;
CREATE TABLE status_pedido (
    status_id SERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL UNIQUE,
    descricao TEXT,
    cor_exibicao VARCHAR(7), -- Hex color para UI
    ordem_fluxo INTEGER NOT NULL -- Ordem no fluxo do pedido
);

COMMENT ON TABLE status_pedido IS 'Estados possíveis de um pedido no fluxo';

-- ============================================
-- TABELAS PRINCIPAIS (5 tabelas - 1000 registros cada)
-- ============================================

-- 6. TABELA: clientes (Principal - 1000 registros)
-- Clientes da GeekStore
DROP TABLE IF EXISTS clientes CASCADE;
CREATE TABLE clientes (
    cliente_id SERIAL PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    email VARCHAR(200) NOT NULL UNIQUE,
    cpf CHAR(11) UNIQUE,
    telefone VARCHAR(15),
    data_nascimento DATE,
    genero CHAR(1) CHECK (genero IN ('M', 'F', 'O')),
    senha_hash VARCHAR(255) NOT NULL,
    nickname VARCHAR(50),  -- Apelido gamer do cliente
    nivel_geek INTEGER DEFAULT 1 CHECK (nivel_geek BETWEEN 1 AND 10),  -- Nível de fidelidade
    pontos_xp INTEGER DEFAULT 0,  -- Pontos de experiência acumulados
    ativo BOOLEAN DEFAULT TRUE,
    newsletter BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ultimo_acesso TIMESTAMP
);

COMMENT ON TABLE clientes IS 'Clientes cadastrados na GeekStore';
COMMENT ON COLUMN clientes.nivel_geek IS 'Nível de fidelidade do cliente (1-10)';
COMMENT ON COLUMN clientes.pontos_xp IS 'Pontos de experiência para programa de fidelidade';

-- Constraint para validar email
ALTER TABLE clientes ADD CONSTRAINT chk_email_valido 
    CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

-- 7. TABELA: produtos (Principal - 1000 registros)
-- Produtos geeks e games disponíveis para venda
DROP TABLE IF EXISTS produtos CASCADE;
CREATE TABLE produtos (
    produto_id SERIAL PRIMARY KEY,
    sku VARCHAR(50) NOT NULL UNIQUE,
    nome VARCHAR(200) NOT NULL,
    descricao TEXT,
    descricao_curta VARCHAR(500),
    categoria_id INTEGER NOT NULL REFERENCES categorias(categoria_id),
    franquia VARCHAR(100),  -- Ex: Marvel, DC, Star Wars, Pokemon
    fabricante VARCHAR(100),  -- Ex: Funko, NECA, Hasbro
    preco DECIMAL(12,2) NOT NULL CHECK (preco >= 0),
    preco_promocional DECIMAL(12,2) CHECK (preco_promocional >= 0),
    custo DECIMAL(12,2) CHECK (custo >= 0),
    peso_kg DECIMAL(8,3),
    largura_cm DECIMAL(8,2),
    altura_cm DECIMAL(8,2),
    profundidade_cm DECIMAL(8,2),
    estoque_atual INTEGER DEFAULT 0 CHECK (estoque_atual >= 0),
    estoque_minimo INTEGER DEFAULT 5,
    ativo BOOLEAN DEFAULT TRUE,
    destaque BOOLEAN DEFAULT FALSE,
    lancamento BOOLEAN DEFAULT FALSE,  -- Produto recém lançado
    exclusivo BOOLEAN DEFAULT FALSE,   -- Produto exclusivo da loja
    pre_venda BOOLEAN DEFAULT FALSE,   -- Produto em pré-venda
    data_lancamento DATE,              -- Data de lançamento oficial
    classificacao_indicativa VARCHAR(10),  -- Para games: Livre, 10+, 12+, 14+, 16+, 18+
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE produtos IS 'Catálogo de produtos geeks e games da GeekStore';
COMMENT ON COLUMN produtos.franquia IS 'Franquia do produto (Marvel, DC, Star Wars, etc)';
COMMENT ON COLUMN produtos.fabricante IS 'Fabricante do produto (Funko, NECA, etc)';

-- Constraint para preço promocional menor que preço
ALTER TABLE produtos ADD CONSTRAINT chk_preco_promocional 
    CHECK (preco_promocional IS NULL OR preco_promocional < preco);

-- 8. TABELA: enderecos (Principal - 1000 registros)
-- Endereços de entrega dos geeks
DROP TABLE IF EXISTS enderecos CASCADE;
CREATE TABLE enderecos (
    endereco_id SERIAL PRIMARY KEY,
    cliente_id INTEGER NOT NULL REFERENCES clientes(cliente_id) ON DELETE CASCADE,
    tipo VARCHAR(20) DEFAULT 'ENTREGA' CHECK (tipo IN ('ENTREGA', 'COBRANCA', 'AMBOS')),
    cep CHAR(8) NOT NULL,
    logradouro VARCHAR(200) NOT NULL,
    numero VARCHAR(20) NOT NULL,
    complemento VARCHAR(100),
    bairro VARCHAR(100) NOT NULL,
    cidade_id INTEGER NOT NULL REFERENCES cidades(cidade_id),
    referencia TEXT,
    principal BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE enderecos IS 'Endereços de entrega e cobrança dos clientes';

-- 9. TABELA: pedidos (Principal - 1000 registros)
-- Pedidos realizados
DROP TABLE IF EXISTS pedidos CASCADE;
CREATE TABLE pedidos (
    pedido_id SERIAL PRIMARY KEY,
    numero_pedido VARCHAR(20) NOT NULL UNIQUE,
    cliente_id INTEGER NOT NULL REFERENCES clientes(cliente_id),
    endereco_entrega_id INTEGER NOT NULL REFERENCES enderecos(endereco_id),
    status_id INTEGER NOT NULL REFERENCES status_pedido(status_id),
    forma_pagamento_id INTEGER NOT NULL REFERENCES formas_pagamento(forma_pagamento_id),
    subtotal DECIMAL(12,2) NOT NULL CHECK (subtotal >= 0),
    desconto DECIMAL(12,2) DEFAULT 0 CHECK (desconto >= 0),
    frete DECIMAL(12,2) DEFAULT 0 CHECK (frete >= 0),
    total DECIMAL(12,2) NOT NULL CHECK (total >= 0),
    parcelas INTEGER DEFAULT 1,
    cupom_codigo VARCHAR(50),
    observacoes TEXT,
    ip_cliente VARCHAR(45),
    data_pedido TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_pagamento TIMESTAMP,
    data_envio TIMESTAMP,
    data_entrega TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE pedidos IS 'Pedidos realizados pelos clientes';

-- 10. TABELA: itens_pedido (Principal - múltiplos por pedido, ~3000 registros)
-- Itens de cada pedido
DROP TABLE IF EXISTS itens_pedido CASCADE;
CREATE TABLE itens_pedido (
    item_id SERIAL PRIMARY KEY,
    pedido_id INTEGER NOT NULL REFERENCES pedidos(pedido_id) ON DELETE CASCADE,
    produto_id INTEGER NOT NULL REFERENCES produtos(produto_id),
    quantidade INTEGER NOT NULL CHECK (quantidade > 0),
    preco_unitario DECIMAL(12,2) NOT NULL CHECK (preco_unitario >= 0),
    desconto_unitario DECIMAL(12,2) DEFAULT 0,
    subtotal DECIMAL(12,2) NOT NULL CHECK (subtotal >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(pedido_id, produto_id)
);

COMMENT ON TABLE itens_pedido IS 'Itens que compõem cada pedido';

-- ============================================
-- TABELAS ADICIONAIS PARA COMPLETAR O MODELO
-- ============================================

-- 11. TABELA: avaliacoes_produtos
-- Avaliações e reviews dos produtos geeks
DROP TABLE IF EXISTS avaliacoes_produtos CASCADE;
CREATE TABLE avaliacoes_produtos (
    avaliacao_id SERIAL PRIMARY KEY,
    produto_id INTEGER NOT NULL REFERENCES produtos(produto_id) ON DELETE CASCADE,
    cliente_id INTEGER NOT NULL REFERENCES clientes(cliente_id),
    nota INTEGER NOT NULL CHECK (nota BETWEEN 1 AND 5),
    titulo VARCHAR(100),
    comentario TEXT,
    pros TEXT,  -- Pontos positivos do produto
    contras TEXT,  -- Pontos negativos
    recomenda BOOLEAN DEFAULT TRUE,  -- Recomenda o produto?
    aprovado BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(produto_id, cliente_id)
);

COMMENT ON TABLE avaliacoes_produtos IS 'Avaliações e reviews de produtos pelos clientes geeks';

-- 12. TABELA: carrinho
-- Carrinho de compras atual dos clientes
DROP TABLE IF EXISTS carrinho CASCADE;
CREATE TABLE carrinho (
    carrinho_id SERIAL PRIMARY KEY,
    cliente_id INTEGER REFERENCES clientes(cliente_id),
    sessao_id VARCHAR(100), -- Para usuários não logados
    produto_id INTEGER NOT NULL REFERENCES produtos(produto_id),
    quantidade INTEGER NOT NULL CHECK (quantidade > 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_cliente_ou_sessao CHECK (cliente_id IS NOT NULL OR sessao_id IS NOT NULL)
);

COMMENT ON TABLE carrinho IS 'Carrinho de compras temporário';

-- 13. TABELA: historico_status_pedido
-- Histórico de mudanças de status dos pedidos
DROP TABLE IF EXISTS historico_status_pedido CASCADE;
CREATE TABLE historico_status_pedido (
    historico_id SERIAL PRIMARY KEY,
    pedido_id INTEGER NOT NULL REFERENCES pedidos(pedido_id) ON DELETE CASCADE,
    status_anterior_id INTEGER REFERENCES status_pedido(status_id),
    status_novo_id INTEGER NOT NULL REFERENCES status_pedido(status_id),
    observacao TEXT,
    usuario_responsavel VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE historico_status_pedido IS 'Auditoria de mudanças de status dos pedidos';

-- 14. TABELA: cupons_desconto
-- Cupons de desconto temáticos
DROP TABLE IF EXISTS cupons_desconto CASCADE;
CREATE TABLE cupons_desconto (
    cupom_id SERIAL PRIMARY KEY,
    codigo VARCHAR(50) NOT NULL UNIQUE,
    descricao TEXT,
    tipo_desconto VARCHAR(20) NOT NULL CHECK (tipo_desconto IN ('PERCENTUAL', 'VALOR_FIXO')),
    valor_desconto DECIMAL(12,2) NOT NULL,
    valor_minimo_pedido DECIMAL(12,2) DEFAULT 0,
    quantidade_maxima INTEGER,
    quantidade_usada INTEGER DEFAULT 0,
    data_inicio DATE NOT NULL,
    data_fim DATE NOT NULL,
    franquia_restrita VARCHAR(100),  -- Cupom válido só para franquia específica
    categoria_restrita INTEGER REFERENCES categorias(categoria_id),  -- Cupom válido só para categoria
    ativo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_datas_cupom CHECK (data_fim >= data_inicio)
);

COMMENT ON TABLE cupons_desconto IS 'Cupons promocionais temáticos da GeekStore';

-- 15. TABELA: log_auditoria
-- Log de auditoria geral
DROP TABLE IF EXISTS log_auditoria CASCADE;
CREATE TABLE log_auditoria (
    log_id SERIAL PRIMARY KEY,
    tabela_nome VARCHAR(100) NOT NULL,
    operacao VARCHAR(10) NOT NULL CHECK (operacao IN ('INSERT', 'UPDATE', 'DELETE')),
    registro_id INTEGER,
    dados_antigos JSONB,
    dados_novos JSONB,
    usuario VARCHAR(100),
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE log_auditoria IS 'Log de auditoria para rastreamento de alterações';

-- ============================================
-- MENSAGEM DE CONCLUSÃO
-- ============================================
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Tabelas criadas com sucesso!';
    RAISE NOTICE 'Total: 15 tabelas';
    RAISE NOTICE '- 5 tabelas auxiliares';
    RAISE NOTICE '- 5 tabelas principais (1000 registros cada)';
    RAISE NOTICE '- 5 tabelas complementares';
    RAISE NOTICE '========================================';
END $$;
