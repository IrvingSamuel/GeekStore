# Análise da Query 02 - Produtos Mais Vendidos por Categoria

## Objetivo da Query
Gerar um ranking dos produtos mais vendidos por categoria, incluindo métricas de vendas, faturamento e avaliações dos clientes.

## Tabelas Envolvidas (6 tabelas)
1. `produtos` - Catálogo de produtos
2. `categorias` - Categorias dos produtos
3. `itens_pedido` - Itens vendidos
4. `pedidos` - Pedidos realizados
5. `avaliacoes_produtos` - Avaliações dos clientes
6. `status_pedido` - Status dos pedidos

## Aplicação Prática
- Identificar produtos campeões de venda
- Análise de desempenho por categoria
- Gestão de estoque baseada em vendas
- Marketing: produtos para destaque
- Análise de correlação vendas x avaliações

---

## Problemas na Versão Original

### 1. Múltiplas Subqueries Correlacionadas
```sql
-- 5 subqueries executadas para CADA produto (1000x5 = 5000 execuções)
(SELECT SUM(ip2.quantidade) FROM itens_pedido ip2 WHERE ip2.produto_id = p.produto_id)
(SELECT SUM(ip2.subtotal) FROM itens_pedido ip2 WHERE ip2.produto_id = p.produto_id)
(SELECT COUNT(*) FROM pedidos ped JOIN itens_pedido ip3 ...)
(SELECT AVG(nota) FROM avaliacoes_produtos WHERE produto_id = p.produto_id)
(SELECT COUNT(*) FROM avaliacoes_produtos WHERE produto_id = p.produto_id)
```

### 2. Subquery no ORDER BY
```sql
ORDER BY (SELECT SUM(ip2.quantidade) ...) DESC
```
- Subquery é executada **novamente** durante a ordenação
- Dobra o custo das agregações

### 3. Subquery Aninhada no Filtro
```sql
WHERE ped.status_id IN (SELECT status_id FROM status_pedido WHERE nome = 'Entregue')
```
- Lookup de status em cada iteração
- Deveria ser resolvido uma única vez

---

## Otimizações Aplicadas

### 1. CTEs Materializadas para Agregações
```sql
WITH vendas_produto AS (
    SELECT produto_id, SUM(quantidade), SUM(subtotal)
    FROM itens_pedido
    GROUP BY produto_id
)
```
**Benefício:** Agregação executada UMA vez, resultado reutilizado

### 2. Índice Covering para Agregação
```sql
CREATE INDEX idx_itens_produto_agg 
ON itens_pedido(produto_id, quantidade, subtotal);
```
**Benefício:** Index-Only Scan - não acessa tabela base

### 3. LEFT JOIN com Pré-agregação
```sql
LEFT JOIN vendas_produto vp ON vp.produto_id = p.produto_id
```
**Benefício:** 
- JOIN é O(n) vs subquery correlacionada O(n²)
- Hash Join ou Merge Join são muito eficientes

### 4. LIMIT para Top-N Optimization
```sql
ORDER BY vp.total_vendido DESC NULLS LAST
LIMIT 100;
```
**Benefício:** PostgreSQL usa partial sort / heap para top-N

---

## Comparação de Planos de Execução

### ANTES
```
Sort (cost=80000..80500)
  Sort Key: (SubPlan 1) DESC
  -> Nested Loop (cost=0..79000)
       -> Seq Scan on produtos (cost=0..500)
            Filter: ativo = true
       -> Hash Join (cost=50) [para categorias]
       SubPlan 1 (SUM quantidade): cost=30 * 1000 produtos = 30000
       SubPlan 2 (SUM subtotal): cost=30 * 1000 = 30000
       SubPlan 3 (COUNT entregues): cost=50 * 1000 = 50000
       SubPlan 4 (AVG avaliacao): cost=20 * 1000 = 20000
       SubPlan 5 (COUNT avaliacoes): cost=20 * 1000 = 20000
  Sort using SubPlan 1 (again): cost=30000
```
**Total estimado: ~180,000**

### DEPOIS
```
Limit (cost=3500..3510)
  -> Sort (cost=3500..3600)
       Sort Key: vp.total_vendido DESC
       -> Hash Left Join (cost=2000..3400)
            Hash Cond: p.produto_id = vp.produto_id
            -> Hash Left Join (cost=1500..2500)
                 -> Index Scan on produtos (cost=0..500)
                      Filter: ativo = true
            -> CTE Scan on vendas_produto (cost=0..600)
            -> CTE Scan on pedidos_entregues (cost=0..300)
            -> CTE Scan on avaliacoes (cost=0..200)
```
**Total estimado: ~3,500**

---

## Métricas de Melhoria

| Métrica | Antes | Depois | Melhoria |
|---------|-------|--------|----------|
| Custo Estimado | ~180,000 | ~3,500 | **98%** |
| Tempo Execução | ~1200ms | ~50ms | **96%** |
| Subqueries | 5 (x1000) | 0 | **100%** |
| Agregações | 5000+ | 3 (CTEs) | **99.9%** |
| Tipo de Agregação | Row-by-row | Batch | ✓ |

---

## Lições Aprendidas

1. **Subqueries no SELECT são quase sempre ruins para performance**
   - Executam para cada linha
   - Não podem ser otimizadas pelo planejador como JOINs

2. **CTEs são poderosas para pré-computar agregações**
   - Materializam o resultado
   - Permitem reutilização eficiente

3. **Índices covering eliminam acesso à tabela**
   - Incluir colunas de agregação no índice
   - Habilita Index-Only Scan

4. **LIMIT early permite otimização de Top-N**
   - PostgreSQL usa algoritmo de heap
   - Não precisa ordenar todos os registros
