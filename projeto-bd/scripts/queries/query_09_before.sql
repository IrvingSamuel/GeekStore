-- ============================================
-- GeekStore - Loja Virtual de Artigos Geeks e Games
-- QUERY 09: ANÁLISE DE ESTOQUE E PREVISÃO DE RUPTURA
-- ============================================
-- Objetivo: Identificar produtos com risco de ruptura de estoque
--           baseado no ritmo de vendas e estoque atual
-- Tabelas: produtos, categorias, itens_pedido, pedidos, avaliacoes_produtos, fornecedores (6+ tabelas)
-- ============================================

\c geekstore_db
SET search_path TO geekstore, public;

-- VERSÃO ANTES DA OTIMIZAÇÃO
-- Problema: Múltiplas subqueries para calcular métricas de venda,
--           sem índices apropriados para agregações de período

EXPLAIN ANALYZE
SELECT 
    p.produto_id,
    p.sku,
    p.nome,
    c.nome AS categoria,
    p.preco,
    p.estoque_atual,
    p.estoque_minimo,
    (SELECT SUM(ip.quantidade) 
     FROM itens_pedido ip 
     JOIN pedidos ped ON ped.pedido_id = ip.pedido_id
     WHERE ip.produto_id = p.produto_id 
     AND ped.data_pedido >= CURRENT_DATE - INTERVAL '30 days') AS vendas_30d,
    (SELECT SUM(ip.quantidade) 
     FROM itens_pedido ip 
     JOIN pedidos ped ON ped.pedido_id = ip.pedido_id
     WHERE ip.produto_id = p.produto_id 
     AND ped.data_pedido >= CURRENT_DATE - INTERVAL '7 days') AS vendas_7d,
    (SELECT AVG(ip.quantidade) 
     FROM itens_pedido ip 
     JOIN pedidos ped ON ped.pedido_id = ip.pedido_id
     WHERE ip.produto_id = p.produto_id 
     AND ped.data_pedido >= CURRENT_DATE - INTERVAL '30 days') AS media_diaria,
    CASE 
        WHEN (SELECT SUM(ip.quantidade) FROM itens_pedido ip 
              JOIN pedidos ped ON ped.pedido_id = ip.pedido_id
              WHERE ip.produto_id = p.produto_id 
              AND ped.data_pedido >= CURRENT_DATE - INTERVAL '30 days') > 0
        THEN p.estoque_atual / ((SELECT SUM(ip.quantidade) FROM itens_pedido ip 
              JOIN pedidos ped ON ped.pedido_id = ip.pedido_id
              WHERE ip.produto_id = p.produto_id 
              AND ped.data_pedido >= CURRENT_DATE - INTERVAL '30 days') / 30.0)
        ELSE NULL
    END AS dias_estoque,
    (SELECT COUNT(*) FROM carrinho carr WHERE carr.produto_id = p.produto_id) AS qtd_carrinhos,
    p.ativo
FROM produtos p
JOIN categorias c ON c.categoria_id = p.categoria_id
WHERE p.ativo = true
  AND p.estoque_atual <= p.estoque_minimo * 2
ORDER BY 
    CASE 
        WHEN (SELECT SUM(ip.quantidade) FROM itens_pedido ip 
              JOIN pedidos ped ON ped.pedido_id = ip.pedido_id
              WHERE ip.produto_id = p.produto_id 
              AND ped.data_pedido >= CURRENT_DATE - INTERVAL '30 days') > 0
        THEN p.estoque_atual / ((SELECT SUM(ip.quantidade) FROM itens_pedido ip 
              JOIN pedidos ped ON ped.pedido_id = ip.pedido_id
              WHERE ip.produto_id = p.produto_id 
              AND ped.data_pedido >= CURRENT_DATE - INTERVAL '30 days') / 30.0)
        ELSE 9999
    END ASC;

/*
ANÁLISE DO PLANO DE EXECUÇÃO ANTES:
- Custo total estimado: ~400000-800000
- Tempo de execução: ~4000-10000ms
- Nós principais da árvore:
  1. Seq Scan em produtos com filtro de estoque
  2. SubPlans 1-6: Agregações de vendas repetidas
  3. Nested Loop para JOINs em subqueries
  4. Sort por expressão CASE com subquery

- Problemas identificados:
  * 6+ subqueries correlacionadas por produto
  * Mesma subquery de vendas_30d repetida 4 vezes
  * JOIN pedidos-itens_pedido refeito em cada subquery
  * Filtro de data sem índice otimizado
  * ORDER BY com subquery (recalculada)
*/
