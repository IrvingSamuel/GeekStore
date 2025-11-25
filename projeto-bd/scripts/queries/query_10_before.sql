-- ============================================
-- GeekStore - Loja Virtual de Artigos Geeks e Games
-- QUERY 10: DASHBOARD EXECUTIVO COMPLETO
-- ============================================
-- Objetivo: Gerar dashboard consolidado com KPIs principais,
--           comparativos de período e métricas de negócio
-- Tabelas: pedidos, clientes, produtos, itens_pedido, categorias, 
--          status_pedido, formas_pagamento, enderecos, cidades, estados (10 tabelas)
-- ============================================

\c geekstore_db
SET search_path TO geekstore, public;

-- VERSÃO ANTES DA OTIMIZAÇÃO
-- Problema: Query monolítica com múltiplas subqueries não correlacionadas
--           mas sem otimização de execução paralela

EXPLAIN ANALYZE
SELECT 
    -- KPIs de Vendas
    (SELECT COUNT(*) FROM pedidos WHERE data_pedido >= DATE_TRUNC('month', CURRENT_DATE)) AS pedidos_mes_atual,
    (SELECT COUNT(*) FROM pedidos WHERE data_pedido >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month' 
                                    AND data_pedido < DATE_TRUNC('month', CURRENT_DATE)) AS pedidos_mes_anterior,
    (SELECT SUM(total) FROM pedidos WHERE data_pedido >= DATE_TRUNC('month', CURRENT_DATE)) AS faturamento_mes,
    (SELECT SUM(total) FROM pedidos WHERE data_pedido >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month'
                                      AND data_pedido < DATE_TRUNC('month', CURRENT_DATE)) AS faturamento_mes_anterior,
    (SELECT AVG(total) FROM pedidos WHERE data_pedido >= DATE_TRUNC('month', CURRENT_DATE)) AS ticket_medio_mes,
    -- KPIs de Clientes
    (SELECT COUNT(*) FROM clientes WHERE created_at >= DATE_TRUNC('month', CURRENT_DATE)) AS novos_clientes_mes,
    (SELECT COUNT(DISTINCT cliente_id) FROM pedidos WHERE data_pedido >= DATE_TRUNC('month', CURRENT_DATE)) AS clientes_ativos_mes,
    (SELECT COUNT(*) FROM clientes WHERE ativo = true) AS total_clientes_ativos,
    -- KPIs de Produtos
    (SELECT COUNT(*) FROM produtos WHERE ativo = true) AS produtos_ativos,
    (SELECT COUNT(*) FROM produtos WHERE estoque_atual <= estoque_minimo AND ativo = true) AS produtos_estoque_baixo,
    (SELECT COUNT(*) FROM produtos WHERE estoque_atual = 0 AND ativo = true) AS produtos_sem_estoque,
    -- KPIs de Conversão
    (SELECT COUNT(*) FROM carrinho) AS itens_carrinho,
    (SELECT COUNT(DISTINCT COALESCE(cliente_id, 0)) FROM carrinho) AS carrinhos_unicos,
    -- Top Categoria
    (SELECT c.nome FROM categorias c 
     JOIN produtos p ON p.categoria_id = c.categoria_id
     JOIN itens_pedido ip ON ip.produto_id = p.produto_id
     JOIN pedidos ped ON ped.pedido_id = ip.pedido_id
     WHERE ped.data_pedido >= DATE_TRUNC('month', CURRENT_DATE)
     GROUP BY c.nome ORDER BY SUM(ip.subtotal) DESC LIMIT 1) AS top_categoria_mes,
    -- Pedidos por Status
    (SELECT COUNT(*) FROM pedidos p JOIN status_pedido s ON s.status_id = p.status_id 
     WHERE s.nome = 'Aguardando Pagamento') AS aguardando_pagamento,
    (SELECT COUNT(*) FROM pedidos p JOIN status_pedido s ON s.status_id = p.status_id 
     WHERE s.nome = 'Enviado' OR s.nome = 'Em Trânsito') AS em_transporte;

/*
ANÁLISE DO PLANO DE EXECUÇÃO ANTES:
- Custo total estimado: ~150000-300000
- Tempo de execução: ~1500-4000ms
- Nós principais da árvore:
  1. Result - Retorna uma única linha
  2. InitPlans 1-16: 16 subqueries independentes
  3. Seq Scans repetidos nas mesmas tabelas
  4. Múltiplos JOINs em subqueries de top categoria

- Problemas identificados:
  * 16+ subqueries executadas sequencialmente
  * Mesma tabela pedidos escaneada ~8 vezes
  * Filtros de data repetidos sem reutilização
  * JOIN com status_pedido repetido em 2 subqueries
  * Não aproveita execução paralela de CTEs
*/
