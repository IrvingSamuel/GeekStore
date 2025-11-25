-- ============================================
-- GeekStore - Loja Virtual de Artigos Geeks e Games
-- ============================================
-- QUERY 05: ANÁLISE DE CARRINHO ABANDONADO E CONVERSÃO
-- ============================================
-- Objetivo: Identificar produtos frequentemente abandonados no carrinho,
--           comparando com taxa de conversão em vendas efetivas
-- Tabelas: carrinho, clientes, produtos, categorias, itens_pedido, pedidos (6 tabelas)
-- ============================================

\c geekstore_db
SET search_path TO geekstore, public;

-- VERSÃO ANTES DA OTIMIZAÇÃO
-- Problema: Subqueries aninhadas com agregações, JOINs ineficientes,
--           cálculos repetitivos de taxa de conversão

EXPLAIN ANALYZE
SELECT 
    pr.produto_id,
    pr.nome AS produto,
    pr.sku,
    cat.nome AS categoria,
    pr.preco,
    pr.estoque_atual,
    (SELECT COUNT(*) FROM carrinho c WHERE c.produto_id = pr.produto_id) AS vezes_no_carrinho,
    (SELECT SUM(c.quantidade) FROM carrinho c WHERE c.produto_id = pr.produto_id) AS qtd_carrinho,
    (SELECT COUNT(DISTINCT c.cliente_id) FROM carrinho c WHERE c.produto_id = pr.produto_id) AS clientes_interessados,
    (SELECT SUM(ip.quantidade) FROM itens_pedido ip WHERE ip.produto_id = pr.produto_id) AS qtd_vendida,
    (SELECT COUNT(DISTINCT p.pedido_id) 
     FROM itens_pedido ip 
     JOIN pedidos p ON p.pedido_id = ip.pedido_id
     JOIN status_pedido sp ON sp.status_id = p.status_id
     WHERE ip.produto_id = pr.produto_id 
     AND sp.nome NOT IN ('Cancelado', 'Reembolsado')) AS pedidos_concluidos,
    CASE 
        WHEN (SELECT COUNT(*) FROM carrinho c WHERE c.produto_id = pr.produto_id) > 0 
        THEN ROUND(
            (SELECT SUM(ip.quantidade) FROM itens_pedido ip WHERE ip.produto_id = pr.produto_id)::NUMERIC /
            (SELECT SUM(c.quantidade) FROM carrinho c WHERE c.produto_id = pr.produto_id)::NUMERIC * 100,
        2)
        ELSE 0 
    END AS taxa_conversao
FROM produtos pr
JOIN categorias cat ON cat.categoria_id = pr.categoria_id
WHERE pr.ativo = true
  AND EXISTS (SELECT 1 FROM carrinho c WHERE c.produto_id = pr.produto_id)
ORDER BY (SELECT COUNT(*) FROM carrinho c WHERE c.produto_id = pr.produto_id) DESC
LIMIT 50;

/*
ANÁLISE DO PLANO DE EXECUÇÃO ANTES:
- Custo total estimado: ~60000-120000
- Tempo de execução: ~600-1500ms
- Nós principais da árvore:
  1. Seq Scan em produtos com filtro EXISTS
  2. SubPlans 1-6: Múltiplas agregações na tabela carrinho
  3. SubPlan para ORDER BY (repetido)
  4. Nested Loop para JOIN com pedidos em subquery

- Problemas identificados:
  * 7 subqueries correlacionadas (incluindo ORDER BY e CASE)
  * Mesma tabela carrinho consultada 4 vezes por produto
  * EXISTS com subquery não usa índice eficientemente
  * Cálculo de taxa_conversao repete 3 subqueries
  * Sem índice em carrinho(produto_id)
*/
