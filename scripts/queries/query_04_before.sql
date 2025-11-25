-- ============================================
-- GeekStore - Loja Virtual de Artigos Geeks e Games
-- ============================================
-- QUERY 04: ANÁLISE DE FATURAMENTO POR REGIÃO E CATEGORIA
-- ============================================
-- Objetivo: Relatório de faturamento agrupado por região geográfica e 
--           categoria de produto, com métricas de comparação
-- Tabelas: pedidos, itens_pedido, produtos, categorias, enderecos, cidades, estados (7 tabelas)
-- ============================================

\c geekstore_db
SET search_path TO geekstore, public;

-- VERSÃO ANTES DA OTIMIZAÇÃO
-- Problema: Múltiplos GROUP BY em subconsultas, JOINs não otimizados,
--           cálculos repetitivos sem uso de window functions

EXPLAIN ANALYZE
SELECT 
    e.regiao,
    e.sigla AS estado,
    ci.nome AS cidade,
    cat.nome AS categoria,
    COUNT(DISTINCT p.pedido_id) AS total_pedidos,
    SUM(ip.quantidade) AS itens_vendidos,
    SUM(ip.subtotal) AS faturamento,
    AVG(ip.subtotal) AS valor_medio_item,
    (SELECT SUM(ip2.subtotal) 
     FROM itens_pedido ip2 
     JOIN pedidos p2 ON p2.pedido_id = ip2.pedido_id
     JOIN enderecos en2 ON en2.endereco_id = p2.endereco_entrega_id
     JOIN cidades ci2 ON ci2.cidade_id = en2.cidade_id
     JOIN estados e2 ON e2.estado_id = ci2.estado_id
     WHERE e2.regiao = e.regiao) AS faturamento_regiao,
    SUM(ip.subtotal) / (SELECT SUM(ip2.subtotal) 
     FROM itens_pedido ip2 
     JOIN pedidos p2 ON p2.pedido_id = ip2.pedido_id
     JOIN enderecos en2 ON en2.endereco_id = p2.endereco_entrega_id
     JOIN cidades ci2 ON ci2.cidade_id = en2.cidade_id
     JOIN estados e2 ON e2.estado_id = ci2.estado_id
     WHERE e2.regiao = e.regiao) * 100 AS percentual_regiao
FROM pedidos p
JOIN itens_pedido ip ON ip.pedido_id = p.pedido_id
JOIN produtos pr ON pr.produto_id = ip.produto_id
JOIN categorias cat ON cat.categoria_id = pr.categoria_id
JOIN enderecos en ON en.endereco_id = p.endereco_entrega_id
JOIN cidades ci ON ci.cidade_id = en.cidade_id
JOIN estados e ON e.estado_id = ci.estado_id
GROUP BY e.regiao, e.sigla, ci.nome, cat.nome
ORDER BY e.regiao, faturamento DESC;

/*
ANÁLISE DO PLANO DE EXECUÇÃO ANTES:
- Custo total estimado: ~100000-200000
- Tempo de execução: ~1000-3000ms
- Nós principais da árvore:
  1. Hash Join múltiplos - 7 tabelas encadeadas
  2. GroupAggregate - Agrupamento com múltiplas colunas
  3. SubPlan 1 e 2 - Subqueries para total regional (executadas N vezes)
  4. Sort - Ordenação final

- Problemas identificados:
  * Subqueries correlacionadas recalculam total regional para cada grupo
  * Mesma subquery duplicada para cálculo de percentual
  * JOINs extensos sem otimização de ordem
  * GROUP BY com muitas colunas
  * Falta de índices para agregação regional
*/
