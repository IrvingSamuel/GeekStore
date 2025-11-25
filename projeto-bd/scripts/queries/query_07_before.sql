-- ============================================
-- GeekStore - Loja Virtual de Artigos Geeks e Games
-- QUERY 07: ANÁLISE DE FORMAS DE PAGAMENTO E INADIMPLÊNCIA
-- ============================================
-- Objetivo: Analisar desempenho de formas de pagamento, taxa de sucesso,
--           tempo médio de confirmação e comparativo por região
-- Tabelas: pedidos, formas_pagamento, status_pedido, clientes, enderecos, cidades, estados (7 tabelas)
-- ============================================

\c geekstore_db
SET search_path TO geekstore, public;

-- VERSÃO ANTES DA OTIMIZAÇÃO
-- Problema: Múltiplas subqueries para calcular métricas,
--           join complexo para dados regionais, cálculos repetitivos

EXPLAIN ANALYZE
SELECT 
    fp.nome AS forma_pagamento,
    fp.parcelas_max,
    fp.taxa_percentual,
    (SELECT COUNT(*) FROM pedidos p WHERE p.forma_pagamento_id = fp.forma_pagamento_id) AS total_pedidos,
    (SELECT SUM(total) FROM pedidos p WHERE p.forma_pagamento_id = fp.forma_pagamento_id) AS valor_total,
    (SELECT AVG(total) FROM pedidos p WHERE p.forma_pagamento_id = fp.forma_pagamento_id) AS ticket_medio,
    (SELECT COUNT(*) FROM pedidos p 
     JOIN status_pedido sp ON sp.status_id = p.status_id
     WHERE p.forma_pagamento_id = fp.forma_pagamento_id 
     AND sp.nome = 'Pagamento Confirmado') AS pagamentos_confirmados,
    (SELECT COUNT(*) FROM pedidos p 
     JOIN status_pedido sp ON sp.status_id = p.status_id
     WHERE p.forma_pagamento_id = fp.forma_pagamento_id 
     AND sp.nome = 'Aguardando Pagamento') AS aguardando_pagamento,
    (SELECT COUNT(*) FROM pedidos p 
     JOIN status_pedido sp ON sp.status_id = p.status_id
     WHERE p.forma_pagamento_id = fp.forma_pagamento_id 
     AND sp.nome = 'Cancelado') AS cancelados,
    (SELECT AVG(EXTRACT(EPOCH FROM (p.data_pagamento - p.data_pedido))/3600)
     FROM pedidos p 
     WHERE p.forma_pagamento_id = fp.forma_pagamento_id 
     AND p.data_pagamento IS NOT NULL) AS horas_ate_pagamento,
    (SELECT e.regiao FROM pedidos p
     JOIN enderecos en ON en.endereco_id = p.endereco_entrega_id
     JOIN cidades ci ON ci.cidade_id = en.cidade_id
     JOIN estados e ON e.estado_id = ci.estado_id
     WHERE p.forma_pagamento_id = fp.forma_pagamento_id
     GROUP BY e.regiao ORDER BY COUNT(*) DESC LIMIT 1) AS regiao_mais_usa
FROM formas_pagamento fp
WHERE fp.ativo = true
ORDER BY (SELECT SUM(total) FROM pedidos p WHERE p.forma_pagamento_id = fp.forma_pagamento_id) DESC NULLS LAST;

/*
ANÁLISE DO PLANO DE EXECUÇÃO ANTES:
- Custo total estimado: ~200000-400000
- Tempo de execução: ~2000-5000ms
- Nós principais da árvore:
  1. Seq Scan em formas_pagamento (8 registros)
  2. SubPlans 1-9: Diversas agregações por forma de pagamento
  3. Nested Loop com JOINs complexos para região
  4. SubPlan no ORDER BY

- Problemas identificados:
  * 9+ subqueries correlacionadas para cada forma de pagamento
  * Mesma tabela pedidos consultada 9 vezes por linha
  * Subquery complexa com 4 JOINs para região
  * JOIN com status_pedido repetido em 3 subqueries
  * Cálculo de tempo em subquery com EXTRACT
*/
