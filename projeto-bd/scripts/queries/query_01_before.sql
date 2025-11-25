-- ============================================
-- QUERY 01: RELATÓRIO DE VENDAS POR PERÍODO COM DETALHES
-- GeekStore - Loja Virtual de Artigos Geeks e Games
-- ============================================
-- Objetivo: Gerar relatório completo de vendas por período incluindo
--           cliente (com nickname), produtos (com franquia), categoria, 
--           forma de pagamento e cidade
-- Tabelas envolvidas: pedidos, clientes, itens_pedido, produtos, 
--                     categorias, formas_pagamento, enderecos, cidades, estados (9 tabelas)
-- ============================================

-- Conectar ao banco
\c geekstore_db
SET search_path TO geekstore, public;

-- VERSÃO ANTES DA OTIMIZAÇÃO
-- Problema: Query sem índices otimizados, subqueries desnecessárias,
--           e ordenação em campo não indexado

EXPLAIN ANALYZE
SELECT 
    p.numero_pedido,
    p.data_pedido,
    c.nome AS cliente,
    c.nickname AS nickname_geek,
    c.nivel_geek,
    c.email,
    (SELECT nome FROM cidades WHERE cidade_id = e.cidade_id) AS cidade,
    (SELECT sigla FROM estados WHERE estado_id = (SELECT estado_id FROM cidades WHERE cidade_id = e.cidade_id)) AS estado,
    pr.nome AS produto,
    pr.franquia,
    (SELECT nome FROM categorias WHERE categoria_id = pr.categoria_id) AS categoria,
    ip.quantidade,
    ip.preco_unitario,
    ip.subtotal AS valor_item,
    fp.nome AS forma_pagamento,
    p.parcelas,
    p.desconto AS desconto_pedido,
    p.frete,
    p.total AS valor_total
FROM pedidos p
JOIN clientes c ON c.cliente_id = p.cliente_id
JOIN enderecos e ON e.endereco_id = p.endereco_entrega_id
JOIN itens_pedido ip ON ip.pedido_id = p.pedido_id
JOIN produtos pr ON pr.produto_id = ip.produto_id
JOIN formas_pagamento fp ON fp.forma_pagamento_id = p.forma_pagamento_id
WHERE p.data_pedido BETWEEN '2024-01-01' AND '2024-12-31'
ORDER BY p.data_pedido DESC, c.nome;

/*
ANÁLISE DO PLANO DE EXECUÇÃO ANTES:
- Custo total estimado: ~15000-25000
- Tempo de execução: ~150-300ms
- Nós principais da árvore:
  1. Sequential Scan em pedidos - Alto custo por falta de índice em data_pedido
  2. Subqueries escalares - Executadas para cada linha (N+1 problem)
  3. Sort em múltiplas colunas - Custo adicional por não usar índice
  4. Nested Loop Joins - Podem ser ineficientes sem índices adequados

- Problemas identificados:
  * Subqueries correlacionadas em SELECT (executam para cada linha)
  * Falta de índice composto para filtro de data + ordenação
  * Joins sem índices otimizados nas foreign keys
  * Ordenação em campos não indexados
  * Falta de índice para a busca de cidade/estado
*/
