-- ============================================
-- GeekStore - Loja Virtual de Artigos Geeks e Games
-- QUERY 08: ANÁLISE DE CLIENTES POR COHORT DE CADASTRO
-- ============================================
-- Objetivo: Análise de cohort - comportamento de clientes agrupados
--           pela data de cadastro, com retenção e valor ao longo do tempo
-- Tabelas: clientes, pedidos, itens_pedido, produtos, enderecos, cidades, estados (7 tabelas)
-- ============================================

\c geekstore_db
SET search_path TO geekstore, public;

-- VERSÃO ANTES DA OTIMIZAÇÃO
-- Problema: Cálculos de cohort com subqueries, múltiplas agregações
--           aninhadas, sem uso de window functions para análise temporal

EXPLAIN ANALYZE
SELECT 
    DATE_TRUNC('month', c.created_at)::DATE AS cohort_mes,
    COUNT(DISTINCT c.cliente_id) AS clientes_cadastrados,
    (SELECT COUNT(DISTINCT p.cliente_id) 
     FROM pedidos p 
     WHERE p.cliente_id IN (SELECT cliente_id FROM clientes WHERE DATE_TRUNC('month', created_at) = DATE_TRUNC('month', c.created_at))
     AND p.data_pedido <= DATE_TRUNC('month', c.created_at) + INTERVAL '1 month'
    ) AS compraram_mes_1,
    (SELECT COUNT(DISTINCT p.cliente_id) 
     FROM pedidos p 
     WHERE p.cliente_id IN (SELECT cliente_id FROM clientes WHERE DATE_TRUNC('month', created_at) = DATE_TRUNC('month', c.created_at))
     AND p.data_pedido BETWEEN DATE_TRUNC('month', c.created_at) + INTERVAL '1 month' 
                           AND DATE_TRUNC('month', c.created_at) + INTERVAL '2 months'
    ) AS compraram_mes_2,
    (SELECT COUNT(DISTINCT p.cliente_id) 
     FROM pedidos p 
     WHERE p.cliente_id IN (SELECT cliente_id FROM clientes WHERE DATE_TRUNC('month', created_at) = DATE_TRUNC('month', c.created_at))
     AND p.data_pedido BETWEEN DATE_TRUNC('month', c.created_at) + INTERVAL '2 months' 
                           AND DATE_TRUNC('month', c.created_at) + INTERVAL '3 months'
    ) AS compraram_mes_3,
    (SELECT SUM(p.total) 
     FROM pedidos p 
     WHERE p.cliente_id IN (SELECT cliente_id FROM clientes WHERE DATE_TRUNC('month', created_at) = DATE_TRUNC('month', c.created_at))
    ) AS valor_total_cohort,
    (SELECT AVG(p.total) 
     FROM pedidos p 
     WHERE p.cliente_id IN (SELECT cliente_id FROM clientes WHERE DATE_TRUNC('month', created_at) = DATE_TRUNC('month', c.created_at))
    ) AS ticket_medio_cohort
FROM clientes c
WHERE c.created_at >= '2024-01-01'
GROUP BY DATE_TRUNC('month', c.created_at)
ORDER BY cohort_mes;

/*
ANÁLISE DO PLANO DE EXECUÇÃO ANTES:
- Custo total estimado: ~300000-600000
- Tempo de execução: ~3000-8000ms
- Nós principais da árvore:
  1. GroupAggregate por mês de cadastro
  2. SubPlans 1-5: Subqueries com IN (SELECT...) aninhado
  3. Nested Loop para cada subquery IN
  4. Seq Scan repetido em clientes dentro de cada IN

- Problemas identificados:
  * 6 subqueries correlacionadas com IN (SELECT) aninhado
  * Subquery de clientes repetida em cada IN
  * Cálculos de período hardcoded (mes_1, mes_2, mes_3)
  * Sem índice para cohort (DATE_TRUNC de created_at)
  * Padrão anti-SQL: IN com subquery correlacionada
*/
