-- ============================================
-- GeekStore - Loja Virtual de Artigos Geeks e Games
-- ============================================
-- QUERY 02: ANÁLISE DE PRODUTOS MAIS VENDIDOS POR CATEGORIA
-- ============================================
-- Objetivo: Identificar os produtos mais vendidos em cada categoria,
--           com métricas de quantidade, faturamento e avaliações
-- Tabelas: produtos, categorias, itens_pedido, pedidos, avaliacoes_produtos, status_pedido (6 tabelas)
-- ============================================

\c geekstore_db
SET search_path TO geekstore, public;

-- VERSÃO ANTES DA OTIMIZAÇÃO
-- Problema: Subqueries agregadas, falta de índices para agregação,
--           cálculos redundantes

EXPLAIN ANALYZE
SELECT 
    cat.nome AS categoria,
    p.nome AS produto,
    p.sku,
    p.preco,
    (SELECT SUM(ip2.quantidade) FROM itens_pedido ip2 WHERE ip2.produto_id = p.produto_id) AS total_vendido,
    (SELECT SUM(ip2.subtotal) FROM itens_pedido ip2 WHERE ip2.produto_id = p.produto_id) AS faturamento,
    (SELECT COUNT(*) FROM pedidos ped 
     JOIN itens_pedido ip3 ON ip3.pedido_id = ped.pedido_id 
     WHERE ip3.produto_id = p.produto_id 
     AND ped.status_id IN (SELECT status_id FROM status_pedido WHERE nome = 'Entregue')) AS pedidos_entregues,
    (SELECT AVG(nota) FROM avaliacoes_produtos WHERE produto_id = p.produto_id AND aprovado = true) AS media_avaliacao,
    (SELECT COUNT(*) FROM avaliacoes_produtos WHERE produto_id = p.produto_id AND aprovado = true) AS total_avaliacoes,
    p.estoque_atual
FROM produtos p
JOIN categorias cat ON cat.categoria_id = p.categoria_id
WHERE p.ativo = true
ORDER BY 
    (SELECT SUM(ip2.quantidade) FROM itens_pedido ip2 WHERE ip2.produto_id = p.produto_id) DESC NULLS LAST;

/*
ANÁLISE DO PLANO DE EXECUÇÃO ANTES:
- Custo total estimado: ~50000-100000
- Tempo de execução: ~500-1500ms
- Nós principais da árvore:
  1. Seq Scan em produtos - Filtra ativos
  2. SubPlan 1-5: Agregações repetidas para cada produto
  3. Sort usando subquery - Muito ineficiente
  4. Nested Loop com status_pedido

- Problemas identificados:
  * 5 subqueries correlacionadas executadas para cada produto
  * Subquery no ORDER BY (executada 2x por linha)
  * Falta de índice em itens_pedido(produto_id) para agregações
  * Join com status_pedido dentro de subquery
  * Não usa índice parcial para produtos ativos
*/
