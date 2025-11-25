-- ============================================
-- SCRIPT 03: CRIAÇÃO DE ÍNDICES
-- Sistema: GeekStore - Loja Virtual de Artigos Geeks e Games
-- Database: PostgreSQL 18
-- ============================================

-- Conectar ao banco
\c geekstore_db

-- Definir schema
SET search_path TO geekstore, public;

-- ============================================
-- ÍNDICES PARA TABELAS AUXILIARES
-- ============================================

-- Categorias
CREATE INDEX idx_categorias_pai ON categorias(categoria_pai_id) WHERE categoria_pai_id IS NOT NULL;
CREATE INDEX idx_categorias_ativo ON categorias(ativo) WHERE ativo = TRUE;
CREATE INDEX idx_categorias_nome_trgm ON categorias USING gin(nome gin_trgm_ops);

-- Estados
CREATE INDEX idx_estados_sigla ON estados(sigla);
CREATE INDEX idx_estados_regiao ON estados(regiao);

-- Cidades
CREATE INDEX idx_cidades_estado ON cidades(estado_id);
CREATE INDEX idx_cidades_nome ON cidades(nome);
CREATE INDEX idx_cidades_nome_trgm ON cidades USING gin(nome gin_trgm_ops);

-- ============================================
-- ÍNDICES PARA TABELAS PRINCIPAIS
-- ============================================

-- CLIENTES
-- Índice para busca por email (login)
CREATE INDEX idx_clientes_email ON clientes(email);

-- Índice para busca por CPF
CREATE INDEX idx_clientes_cpf ON clientes(cpf) WHERE cpf IS NOT NULL;

-- Índice para busca por nome (fulltext)
CREATE INDEX idx_clientes_nome_trgm ON clientes USING gin(nome gin_trgm_ops);

-- Índice para clientes ativos
CREATE INDEX idx_clientes_ativo ON clientes(ativo) WHERE ativo = TRUE;

-- Índice para filtro por data de cadastro
CREATE INDEX idx_clientes_created_at ON clientes(created_at);

-- Índice para último acesso (para análises)
CREATE INDEX idx_clientes_ultimo_acesso ON clientes(ultimo_acesso) WHERE ultimo_acesso IS NOT NULL;

-- PRODUTOS
-- Índice para busca por SKU
CREATE INDEX idx_produtos_sku ON produtos(sku);

-- Índice para busca por categoria
CREATE INDEX idx_produtos_categoria ON produtos(categoria_id);

-- Índice para busca por nome (fulltext)
CREATE INDEX idx_produtos_nome_trgm ON produtos USING gin(nome gin_trgm_ops);

-- Índice para produtos ativos
CREATE INDEX idx_produtos_ativo ON produtos(ativo) WHERE ativo = TRUE;

-- Índice para produtos em destaque
CREATE INDEX idx_produtos_destaque ON produtos(destaque) WHERE destaque = TRUE AND ativo = TRUE;

-- Índice para produtos em promoção
CREATE INDEX idx_produtos_promocao ON produtos(preco_promocional) WHERE preco_promocional IS NOT NULL;

-- Índice para controle de estoque
CREATE INDEX idx_produtos_estoque ON produtos(estoque_atual, estoque_minimo);

-- Índice composto para listagem (categoria + ativo + preço)
CREATE INDEX idx_produtos_listagem ON produtos(categoria_id, ativo, preco);

-- Índice para faixa de preço
CREATE INDEX idx_produtos_preco ON produtos(preco);

-- Índices específicos para GeekStore
-- Índice para busca por franquia (Marvel, DC, Star Wars, etc)
CREATE INDEX idx_produtos_franquia ON produtos(franquia) WHERE franquia IS NOT NULL;

-- Índice para busca por fabricante (Funko, NECA, etc)
CREATE INDEX idx_produtos_fabricante ON produtos(fabricante) WHERE fabricante IS NOT NULL;

-- Índice para produtos em pré-venda
CREATE INDEX idx_produtos_prevenda ON produtos(pre_venda, data_lancamento) WHERE pre_venda = TRUE;

-- Índice para lançamentos
CREATE INDEX idx_produtos_lancamento ON produtos(lancamento, data_lancamento) WHERE lancamento = TRUE;

-- Índice para produtos exclusivos
CREATE INDEX idx_produtos_exclusivo ON produtos(exclusivo) WHERE exclusivo = TRUE AND ativo = TRUE;

-- Índice composto para busca de colecionáveis por franquia e categoria
CREATE INDEX idx_produtos_colecao ON produtos(franquia, categoria_id, ativo) WHERE ativo = TRUE;

-- ENDEREÇOS
-- Índice para busca por cliente
CREATE INDEX idx_enderecos_cliente ON enderecos(cliente_id);

-- Índice para endereço principal
CREATE INDEX idx_enderecos_principal ON enderecos(cliente_id, principal) WHERE principal = TRUE;

-- Índice para busca por CEP
CREATE INDEX idx_enderecos_cep ON enderecos(cep);

-- Índice para cidade
CREATE INDEX idx_enderecos_cidade ON enderecos(cidade_id);

-- PEDIDOS
-- Índice para busca por cliente
CREATE INDEX idx_pedidos_cliente ON pedidos(cliente_id);

-- Índice para busca por número do pedido
CREATE INDEX idx_pedidos_numero ON pedidos(numero_pedido);

-- Índice para busca por status
CREATE INDEX idx_pedidos_status ON pedidos(status_id);

-- Índice para busca por data
CREATE INDEX idx_pedidos_data ON pedidos(data_pedido);

-- Índice para período (relatórios)
CREATE INDEX idx_pedidos_periodo ON pedidos(data_pedido DESC);

-- Índice composto para relatórios de vendas
CREATE INDEX idx_pedidos_relatorio ON pedidos(cliente_id, status_id, data_pedido);

-- Índice para pedidos por forma de pagamento
CREATE INDEX idx_pedidos_pagamento ON pedidos(forma_pagamento_id);

-- Índice para endereço de entrega
CREATE INDEX idx_pedidos_endereco ON pedidos(endereco_entrega_id);

-- Índice para pedidos com cupom
CREATE INDEX idx_pedidos_cupom ON pedidos(cupom_codigo) WHERE cupom_codigo IS NOT NULL;

-- ITENS_PEDIDO
-- Índice para busca por pedido
CREATE INDEX idx_itens_pedido ON itens_pedido(pedido_id);

-- Índice para busca por produto
CREATE INDEX idx_itens_produto ON itens_pedido(produto_id);

-- Índice composto para relatórios de produtos vendidos
CREATE INDEX idx_itens_pedido_produto ON itens_pedido(pedido_id, produto_id);

-- ============================================
-- ÍNDICES PARA TABELAS COMPLEMENTARES
-- ============================================

-- AVALIAÇÕES
CREATE INDEX idx_avaliacoes_produto ON avaliacoes_produtos(produto_id);
CREATE INDEX idx_avaliacoes_cliente ON avaliacoes_produtos(cliente_id);
CREATE INDEX idx_avaliacoes_aprovado ON avaliacoes_produtos(produto_id, aprovado) WHERE aprovado = TRUE;
CREATE INDEX idx_avaliacoes_nota ON avaliacoes_produtos(produto_id, nota);

-- CARRINHO
CREATE INDEX idx_carrinho_cliente ON carrinho(cliente_id) WHERE cliente_id IS NOT NULL;
CREATE INDEX idx_carrinho_sessao ON carrinho(sessao_id) WHERE sessao_id IS NOT NULL;
CREATE INDEX idx_carrinho_produto ON carrinho(produto_id);

-- HISTÓRICO STATUS
CREATE INDEX idx_historico_pedido ON historico_status_pedido(pedido_id);
CREATE INDEX idx_historico_data ON historico_status_pedido(created_at);

-- CUPONS
CREATE INDEX idx_cupons_codigo ON cupons_desconto(codigo);
CREATE INDEX idx_cupons_validade ON cupons_desconto(data_inicio, data_fim, ativo);

-- LOG AUDITORIA
CREATE INDEX idx_log_tabela ON log_auditoria(tabela_nome);
CREATE INDEX idx_log_operacao ON log_auditoria(operacao);
CREATE INDEX idx_log_data ON log_auditoria(created_at);
CREATE INDEX idx_log_registro ON log_auditoria(tabela_nome, registro_id);

-- ============================================
-- ÍNDICES PARA OTIMIZAÇÃO DE JOINS ESPECÍFICOS
-- ============================================

-- Índice para join frequente: pedidos -> clientes -> enderecos
CREATE INDEX idx_pedidos_cliente_status ON pedidos(cliente_id, status_id);

-- Índice para análise de vendas por categoria
CREATE INDEX idx_produtos_categoria_preco ON produtos(categoria_id, preco) WHERE ativo = TRUE;

-- Índice para relatório de produtos mais vendidos
CREATE INDEX idx_itens_produto_qtd ON itens_pedido(produto_id, quantidade);

-- ============================================
-- ESTATÍSTICAS
-- ============================================

-- Atualizar estatísticas de todas as tabelas
ANALYZE categorias;
ANALYZE estados;
ANALYZE cidades;
ANALYZE formas_pagamento;
ANALYZE status_pedido;
ANALYZE clientes;
ANALYZE produtos;
ANALYZE enderecos;
ANALYZE pedidos;
ANALYZE itens_pedido;
ANALYZE avaliacoes_produtos;
ANALYZE carrinho;
ANALYZE historico_status_pedido;
ANALYZE cupons_desconto;
ANALYZE log_auditoria;

-- ============================================
-- MENSAGEM DE CONCLUSÃO
-- ============================================
DO $$
DECLARE
    total_idx INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_idx 
    FROM pg_indexes 
    WHERE schemaname = 'ecommerce';
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Índices criados com sucesso!';
    RAISE NOTICE 'Total de índices: %', total_idx;
    RAISE NOTICE '========================================';
END $$;
