-- ============================================
-- GeekStore - Loja Virtual de Artigos Geeks e Games
-- QUERY 06: ANÁLISE DE TENDÊNCIA DE VENDAS (SÉRIE TEMPORAL)
-- ============================================
-- Objetivo: Analisar tendência de vendas mês a mês com comparativo
--           ano anterior, média móvel e crescimento percentual
-- Tabelas: pedidos, itens_pedido, produtos, categorias, status_pedido, clientes (6 tabelas)
-- ============================================

\c geekstore_db
SET search_path TO geekstore, public;

-- VERSÃO ANTES DA OTIMIZAÇÃO
-- Problema: Subqueries para período anterior, cálculos repetitivos,
--           sem uso de window functions para séries temporais

EXPLAIN ANALYZE
SELECT 
    DATE_TRUNC('month', p.data_pedido) AS mes,
    COUNT(DISTINCT p.pedido_id) AS total_pedidos,
    COUNT(DISTINCT p.cliente_id) AS clientes_unicos,
    SUM(p.total) AS faturamento,
    AVG(p.total) AS ticket_medio,
    SUM(ip.quantidade) AS itens_vendidos,
    (SELECT SUM(p2.total) 
     FROM pedidos p2 
     WHERE DATE_TRUNC('month', p2.data_pedido) = DATE_TRUNC('month', p.data_pedido) - INTERVAL '1 year'
     AND p2.status_id NOT IN (SELECT status_id FROM status_pedido WHERE nome IN ('Cancelado', 'Reembolsado'))
    ) AS faturamento_ano_anterior,
    (SELECT SUM(p2.total) 
     FROM pedidos p2 
     WHERE DATE_TRUNC('month', p2.data_pedido) = DATE_TRUNC('month', p.data_pedido) - INTERVAL '1 month'
     AND p2.status_id NOT IN (SELECT status_id FROM status_pedido WHERE nome IN ('Cancelado', 'Reembolsado'))
    ) AS faturamento_mes_anterior,
    CASE 
        WHEN (SELECT SUM(p2.total) FROM pedidos p2 
              WHERE DATE_TRUNC('month', p2.data_pedido) = DATE_TRUNC('month', p.data_pedido) - INTERVAL '1 month') > 0
        THEN ROUND(((SUM(p.total) - (SELECT SUM(p2.total) FROM pedidos p2 
                    WHERE DATE_TRUNC('month', p2.data_pedido) = DATE_TRUNC('month', p.data_pedido) - INTERVAL '1 month')) /
                    (SELECT SUM(p2.total) FROM pedidos p2 
                    WHERE DATE_TRUNC('month', p2.data_pedido) = DATE_TRUNC('month', p.data_pedido) - INTERVAL '1 month')) * 100, 2)
        ELSE 0
    END AS crescimento_mensal_pct
FROM pedidos p
JOIN itens_pedido ip ON ip.pedido_id = p.pedido_id
JOIN status_pedido sp ON sp.status_id = p.status_id
WHERE sp.nome NOT IN ('Cancelado', 'Reembolsado')
  AND p.data_pedido >= '2024-01-01'
GROUP BY DATE_TRUNC('month', p.data_pedido)
ORDER BY mes;

/*
ANÁLISE DO PLANO DE EXECUÇÃO ANTES:
- Custo total estimado: ~150000-300000
- Tempo de execução: ~1500-4000ms
- Nós principais da árvore:
  1. GroupAggregate por mês
  2. SubPlans 1-4: Busca ano/mês anterior (repetida)
  3. Seq Scan em pedidos para cada subquery
  4. Subquery aninhada para status em cada SubPlan

- Problemas identificados:
  * 4+ subqueries correlacionadas por mês
  * Subquery de status repetida dentro de cada subquery
  * Cálculo de crescimento repete subqueries 3x
  * Sem uso de LAG() ou window functions
  * DATE_TRUNC repetido múltiplas vezes
*/
