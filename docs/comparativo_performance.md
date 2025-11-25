# 📊 Comparativo de Performance - GeekStore Database

## Análise EXPLAIN ANALYZE: Antes vs Depois das Otimizações

Este documento apresenta uma análise comparativa detalhada do desempenho das queries antes e depois das otimizações aplicadas no banco de dados GeekStore.

---

## 🎯 Resumo Executivo

| Métrica | Média Antes | Média Depois | Melhoria |
|---------|-------------|--------------|----------|
| **Tempo de Execução** | 4.89 ms | 2.45 ms | **50% mais rápido** |
| **Buffers (I/O)** | 2.001 | 399 | **80% menos I/O** |
| **SubPlans Eliminados** | 10+ | 0 | **100%** |

---

## 📈 Comparativo Detalhado por Query

### Query 01: Detalhamento Completo de Pedidos
> JOIN: pedidos, clientes, enderecos, itens_pedido, produtos, formas_pagamento, cidades, estados, categorias

| Métrica | ⏱️ Antes | ⏱️ Depois | 📉 Diferença | 📊 Melhoria |
|---------|----------|-----------|--------------|-------------|
| **Execution Time** | 11.825 ms | 3.621 ms | -8.204 ms | **🟢 69.4%** |
| **Buffers (shared hit)** | 5,921 | 1,672 | -4,249 | **🟢 71.8%** |
| **Planning Time** | 2.737 ms | 2.900 ms | +0.163 ms | 🔴 -6.0% |
| **SubPlans** | 3 (1442x cada) | 0 | -3 | **🟢 100%** |

**Técnica:** CTEs para eliminar subconsultas escalares correlacionadas

---

### Query 02: Relatório de Produtos Mais Vendidos
> JOIN: produtos, itens_pedido, avaliacoes_produtos, categorias

| Métrica | ⏱️ Antes | ⏱️ Depois | 📉 Diferença | 📊 Melhoria |
|---------|----------|-----------|--------------|-------------|
| **Execution Time** | 5.954 ms | 3.518 ms | -2.436 ms | **🟢 40.9%** |
| **Buffers (shared hit)** | 153 | 101 | -52 | **🟢 34.0%** |
| **Planning Time** | 1.312 ms | 2.783 ms | +1.471 ms | 🔴 -112.1% |
| **SubPlans** | 1 (50x) | 0 | -1 | **🟢 100%** |

**Técnica:** Agregação prévia em CTEs

---

### Query 03: Análise de Clientes VIP
> JOIN: clientes, pedidos, enderecos, cidades, estados

| Métrica | ⏱️ Antes | ⏱️ Depois | 📉 Diferença | 📊 Melhoria |
|---------|----------|-----------|--------------|-------------|
| **Execution Time** | 1.905 ms | 2.198 ms | +0.293 ms | 🔴 -15.4% |
| **Buffers (shared hit)** | 1,739 | 70 | -1,669 | **🟢 96.0%** |
| **Planning Time** | 1.457 ms | 1.082 ms | -0.375 ms | **🟢 25.7%** |
| **SubPlans** | 4 (192x cada) | 0 | -4 | **🟢 100%** |

**Técnica:** CTE `resumo_pedidos` para agregação única

---

### Query 04: Métricas Mensais de Vendas
> JOIN: pedidos, itens_pedido, clientes, enderecos, cidades

| Métrica | ⏱️ Antes | ⏱️ Depois | 📉 Diferença | 📊 Melhoria |
|---------|----------|-----------|--------------|-------------|
| **Execution Time** | 3.190 ms | 1.334 ms | -1.856 ms | **🟢 58.2%** |
| **Buffers (shared hit)** | 99 | 55 | -44 | **🟢 44.4%** |
| **Planning Time** | 1.497 ms | 0.604 ms | -0.893 ms | **🟢 59.7%** |
| **SubPlans** | 0 | 0 | 0 | ⚪ N/A |

**Técnica:** CTEs para pré-filtrar e pré-agregar

---

### Query 05: Ranking de Produtos por Categoria
> JOIN: produtos, categorias, itens_pedido, avaliacoes_produtos

| Métrica | ⏱️ Antes | ⏱️ Depois | 📉 Diferença | 📊 Melhoria |
|---------|----------|-----------|--------------|-------------|
| **Execution Time** | 1.653 ms | 1.571 ms | -0.082 ms | **🟢 5.0%** |
| **Buffers (shared hit)** | 2,095 | 95 | -2,000 | **🟢 95.5%** |
| **Planning Time** | 1.122 ms | 0.967 ms | -0.155 ms | **🟢 13.8%** |
| **SubPlans** | 3 (966x cada) | 0 | -3 | **🟢 100%** |

**Técnica:** CTEs `vendas_produto` e `avaliacoes_produto`

---

## 📊 Gráfico Comparativo de Tempo de Execução

```
Query   | Antes (ms)  | Depois (ms) | Barra Visual
--------|-------------|-------------|------------------------------------------
Q01     | 11.825      | 3.621       | ████████████ → ████
Q02     | 5.954       | 3.518       | ██████ → ████
Q03     | 1.905       | 2.198       | ██ → ██
Q04     | 3.190       | 1.334       | ███ → █
Q05     | 1.653       | 1.571       | ██ → ██
--------|-------------|-------------|------------------------------------------
TOTAL   | 24.527 ms   | 12.242 ms   | 50.1% de redução
```

---

## 📊 Gráfico Comparativo de I/O (Buffers)

```
Query   | Antes       | Depois      | Redução | Barra Visual
--------|-------------|-------------|---------|----------------------------------
Q01     | 5,921       | 1,672       | 71.8%   | ██████████████████████████ → ████████
Q02     | 153         | 101         | 34.0%   | █ → █
Q03     | 1,739       | 70          | 96.0%   | ████████ → ▏
Q04     | 99          | 55          | 44.4%   | █ → ▏
Q05     | 2,095       | 95          | 95.5%   | ██████████ → ▏
--------|-------------|-------------|---------|----------------------------------
TOTAL   | 10,007      | 1,993       | 80.1%   | 
```

---

## 🔍 Análise de SubPlans Eliminados

| Query | SubPlans Antes | Execuções/SubPlan | Total Execuções | SubPlans Depois |
|-------|----------------|-------------------|-----------------|-----------------|
| Q01 | 3 | 1,442 | **4,326** | 0 |
| Q02 | 1 | 50 | **50** | 0 |
| Q03 | 4 | 192 | **768** | 0 |
| Q04 | 0 | - | 0 | 0 |
| Q05 | 3 | 966 | **2,898** | 0 |
| **TOTAL** | **11** | - | **8,042** | **0** |

> ⚠️ **Impacto:** 8.042 execuções de subconsultas eliminadas!

---

## 📈 Tabela Consolidada de Performance

| Query | Tempo Antes | Tempo Depois | Δ Tempo | Buffers Antes | Buffers Depois | Δ I/O |
|-------|-------------|--------------|---------|---------------|----------------|-------|
| Q01 | 11.825 ms | 3.621 ms | **-69.4%** | 5,921 | 1,672 | **-71.8%** |
| Q02 | 5.954 ms | 3.518 ms | **-40.9%** | 153 | 101 | **-34.0%** |
| Q03 | 1.905 ms | 2.198 ms | +15.4% | 1,739 | 70 | **-96.0%** |
| Q04 | 3.190 ms | 1.334 ms | **-58.2%** | 99 | 55 | **-44.4%** |
| Q05 | 1.653 ms | 1.571 ms | **-5.0%** | 2,095 | 95 | **-95.5%** |

### Médias Gerais

| Métrica | Valor |
|---------|-------|
| **Redução média de tempo** | 31.6% |
| **Redução média de I/O** | 68.3% |
| **SubPlans eliminados** | 100% |

---

## 🏆 Ranking de Melhorias

### Por Tempo de Execução
1. 🥇 **Query 01** - 69.4% mais rápida
2. 🥈 **Query 04** - 58.2% mais rápida
3. 🥉 **Query 02** - 40.9% mais rápida

### Por Redução de I/O
1. 🥇 **Query 03** - 96.0% menos I/O
2. 🥈 **Query 05** - 95.5% menos I/O
3. 🥉 **Query 01** - 71.8% menos I/O

---

## 🛠️ Técnicas de Otimização Utilizadas

### 1. Common Table Expressions (CTEs)
```sql
-- ❌ Antes: Subconsulta executada N vezes
SELECT (SELECT nome FROM categorias WHERE categoria_id = p.categoria_id)
FROM produtos p;

-- ✅ Depois: Agregação única via CTE
WITH cat AS (SELECT categoria_id, nome FROM categorias)
SELECT c.nome FROM produtos p JOIN cat c ON c.categoria_id = p.categoria_id;
```

### 2. Pré-agregação de Dados
```sql
-- ❌ Antes: Agregação durante JOIN
SELECT SUM(ip.quantidade) FROM produtos p JOIN itens_pedido ip...

-- ✅ Depois: Agregação prévia
WITH vendas AS (SELECT produto_id, SUM(quantidade) as total FROM itens_pedido GROUP BY produto_id)
SELECT v.total FROM produtos p JOIN vendas v ON v.produto_id = p.produto_id;
```

### 3. Eliminação de Subconsultas Correlacionadas
```sql
-- ❌ Antes: SubPlan executado para cada linha
SELECT (SELECT COUNT(*) FROM pedidos WHERE cliente_id = c.cliente_id)
FROM clientes c;

-- ✅ Depois: JOIN com agregação
WITH resumo AS (SELECT cliente_id, COUNT(*) as total FROM pedidos GROUP BY cliente_id)
SELECT r.total FROM clientes c LEFT JOIN resumo r ON r.cliente_id = c.cliente_id;
```

---

## 📝 Conclusões

### ✅ Pontos Positivos
- **Redução significativa de I/O** (média 68%)
- **Eliminação total de SubPlans** repetitivos
- **Melhor aproveitamento de índices**
- **Queries mais previsíveis** em termos de performance

### ⚠️ Observações
- Em bases pequenas (~8.500 registros), diferenças de tempo são menores
- O Planning Time pode aumentar levemente com CTEs
- **Em produção** (milhões de registros), ganhos seriam exponencialmente maiores

### 🎯 Recomendação Final
As otimizações demonstram que **eliminar subconsultas correlacionadas** é a técnica mais impactante para melhorar performance em PostgreSQL. O uso de CTEs torna as queries mais legíveis e eficientes.

---

## 📚 Referências

- [PostgreSQL EXPLAIN Documentation](https://www.postgresql.org/docs/current/sql-explain.html)
- [PostgreSQL Query Planning](https://www.postgresql.org/docs/current/planner-optimizer.html)
- [Use The Index, Luke!](https://use-the-index-luke.com/)

---

*Documento gerado em: 25 de Novembro de 2025*  
*Projeto: GeekStore - Loja Virtual de Artigos Geeks e Games*  
*PostgreSQL: Versão 18*
