-- ============================================
-- GeekStore - Loja Virtual de Artigos Geeks e Games
-- ============================================
-- QUERY 03: CLIENTES COM MAIOR VALOR DE COMPRAS E HISTÓRICO
-- ============================================
-- Objetivo: Identificar os melhores clientes (VIPs) com histórico completo,
--           ticket médio, frequência e última compra
-- Tabelas: clientes, pedidos, itens_pedido, produtos, enderecos, cidades, estados (7 tabelas)
-- ============================================

\c geekstore_db
SET search_path TO geekstore, public;

-- VERSÃO ANTES DA OTIMIZAÇÃO
-- Problema: Agregações com DISTINCT em subqueries, filtros não otimizados,
--           ordenação por cálculo

EXPLAIN ANALYZE
SELECT 
    c.cliente_id,
    c.nome,
    c.email,
    c.data_nascimento,
    EXTRACT(YEAR FROM AGE(c.data_nascimento)) AS idade,
    (SELECT ci.nome || '/' || e.sigla 
     FROM enderecos en 
     JOIN cidades ci ON ci.cidade_id = en.cidade_id 
     JOIN estados e ON e.estado_id = ci.estado_id
     WHERE en.cliente_id = c.cliente_id AND en.principal = true
     LIMIT 1) AS cidade_principal,
    (SELECT COUNT(DISTINCT p.pedido_id) FROM pedidos p WHERE p.cliente_id = c.cliente_id) AS total_pedidos,
    (SELECT SUM(p.total) FROM pedidos p WHERE p.cliente_id = c.cliente_id) AS valor_total,
    (SELECT AVG(p.total) FROM pedidos p WHERE p.cliente_id = c.cliente_id) AS ticket_medio,
    (SELECT MAX(p.data_pedido) FROM pedidos p WHERE p.cliente_id = c.cliente_id) AS ultima_compra,
    (SELECT MIN(p.data_pedido) FROM pedidos p WHERE p.cliente_id = c.cliente_id) AS primeira_compra,
    (SELECT COUNT(DISTINCT ip.produto_id) 
     FROM itens_pedido ip 
     JOIN pedidos p ON p.pedido_id = ip.pedido_id 
     WHERE p.cliente_id = c.cliente_id) AS produtos_diferentes,
    c.created_at AS cliente_desde
FROM clientes c
WHERE c.ativo = true
ORDER BY (SELECT SUM(p.total) FROM pedidos p WHERE p.cliente_id = c.cliente_id) DESC NULLS LAST
LIMIT 50;

/*
ANÁLISE DO PLANO DE EXECUÇÃO ANTES:
- Custo total estimado: ~80000-150000
- Tempo de execução: ~800-2000ms
- Nós principais da árvore:
  1. Seq Scan em clientes - Filtra ativos (sem índice parcial)
  2. SubPlans 1-7: Executados para cada cliente (~950 clientes ativos)
  3. Sort por subquery (executada novamente)
  4. Nested Loop para cidade dentro de subquery

- Problemas identificados:
  * 8 subqueries correlacionadas (incluindo ORDER BY)
  * Subqueries de agregação executadas milhares de vezes
  * Subquery com múltiplos JOINs para cidade
  * COUNT(DISTINCT) em subquery aninhada
  * Sem uso de índices otimizados para agregações
*/
