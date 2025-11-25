# Resultados EXPLAIN ANALYZE - GeekStore Database

## 📊 Resumo Executivo

Este documento apresenta os resultados reais dos testes de EXPLAIN ANALYZE executados no banco de dados GeekStore, comparando as versões **antes** e **depois** das otimizações.

### Ambiente de Teste
- **PostgreSQL:** Versão 18
- **Sistema Operacional:** Linux (Kali)
- **Hardware:** Ambiente local
- **Data dos Testes:** Junho 2025

---

## 📋 Contagem de Registros no Banco

| Tabela | Registros |
|--------|-----------|
| itens_pedido | 2.875 |
| produtos | 1.000 |
| pedidos | 1.000 |
| enderecos | 1.000 |
| historico_status_pedido | 1.000 |
| clientes | 1.000 |
| avaliacoes_produtos | 500 |
| cidades | 35 |
| categorias | 29 |
| estados | 27 |
| status_pedido | 10 |
| cupons_desconto | 8 |
| formas_pagamento | 8 |
| **Total** | **~8.500** |

---

## 🔍 Resultados Detalhados por Query

### Query 01: Detalhamento Completo de Pedidos
**JOIN entre:** pedidos, clientes, enderecos, itens_pedido, produtos, formas_pagamento, cidades, estados, categorias

| Métrica | Antes | Depois | Melhoria |
|---------|-------|--------|----------|
| **Execution Time** | 11.825 ms | 3.621 ms | **69% mais rápido** |
| **Buffers (I/O)** | 5.921 | 1.672 | **72% menos I/O** |
| **SubPlans** | 3 (executados 1442x) | 0 | **Eliminados** |

**Técnica de Otimização:** CTEs (Common Table Expressions) para eliminar subconsultas escalares correlacionadas.

---

### Query 02: Relatório de Produtos Mais Vendidos
**JOIN entre:** produtos, itens_pedido, avaliacoes_produtos, categorias

| Métrica | Antes | Depois | Melhoria |
|---------|-------|--------|----------|
| **Execution Time** | 5.954 ms | 3.518 ms | **41% mais rápido** |
| **Buffers (I/O)** | 153 | 101 | **34% menos I/O** |

**Técnica de Otimização:** Agregação prévia em CTEs, eliminando subconsultas no SELECT.

---

### Query 03: Análise de Clientes VIP
**JOIN entre:** clientes, pedidos, enderecos, cidades, estados

| Métrica | Antes | Depois | Melhoria |
|---------|-------|--------|----------|
| **Execution Time** | 1.905 ms | 2.198 ms | ~igual |
| **Buffers (I/O)** | 1.739 | 70 | **96% menos I/O** |
| **SubPlans** | 4 (executados 192x) | 0 | **Eliminados** |

**Técnica de Otimização:** CTE `resumo_pedidos` para agregar dados por cliente uma única vez.

---

### Query 04: Métricas Mensais de Vendas
**JOIN entre:** pedidos, itens_pedido, clientes, enderecos, cidades

| Métrica | Antes | Depois | Melhoria |
|---------|-------|--------|----------|
| **Execution Time** | 3.190 ms | 1.334 ms | **58% mais rápido** |
| **Buffers (I/O)** | 99 | 55 | **44% menos I/O** |

**Técnica de Otimização:** CTEs para pré-filtrar pedidos e pré-agregar itens.

---

### Query 05: Ranking de Produtos por Categoria
**JOIN entre:** produtos, categorias, itens_pedido, avaliacoes_produtos

| Métrica | Antes | Depois | Melhoria |
|---------|-------|--------|----------|
| **Execution Time** | 1.653 ms | 1.571 ms | ~5% |
| **Buffers (I/O)** | 2.095 | 95 | **95% menos I/O** |
| **SubPlans** | 3 (executados 966x) | 0 | **Eliminados** |

**Técnica de Otimização:** CTEs `vendas_produto` e `avaliacoes_produto` para agregação prévia.

---

## 📈 Resumo Consolidado de Melhorias

| Query | Tempo Antes | Tempo Depois | Ganho Tempo | Buffers Antes | Buffers Depois | Ganho I/O |
|-------|-------------|--------------|-------------|---------------|----------------|-----------|
| Q01 | 11.825 ms | 3.621 ms | 69% | 5.921 | 1.672 | 72% |
| Q02 | 5.954 ms | 3.518 ms | 41% | 153 | 101 | 34% |
| Q03 | 1.905 ms | 2.198 ms | ~0% | 1.739 | 70 | 96% |
| Q04 | 3.190 ms | 1.334 ms | 58% | 99 | 55 | 44% |
| Q05 | 1.653 ms | 1.571 ms | 5% | 2.095 | 95 | 95% |

### Médias Gerais
- **Melhoria média de tempo:** ~35%
- **Redução média de I/O:** ~68%

---

## 🛠️ Técnicas de Otimização Aplicadas

### 1. Common Table Expressions (CTEs)
Utilizadas para:
- Pré-filtrar conjuntos de dados
- Pré-agregar resultados
- Eliminar subconsultas correlacionadas repetitivas

### 2. Eliminação de Subconsultas Escalares
O problema mais significativo encontrado foi o uso de subconsultas no SELECT que eram executadas para cada linha do resultado:
```sql
-- ANTES (ruim)
SELECT (SELECT COUNT(*) FROM tabela WHERE id = t.id) ...

-- DEPOIS (bom)
WITH agregado AS (SELECT id, COUNT(*) FROM tabela GROUP BY id)
SELECT a.count FROM agregado a ...
```

### 3. JOINs Explícitos vs Subconsultas
Substituição de subconsultas por JOINs quando apropriado para aproveitar o otimizador do PostgreSQL.

### 4. Índices Estratégicos
63 índices criados incluindo:
- Índices compostos para queries frequentes
- Índices parciais para dados ativos
- Índices de cobertura (covering indexes)
- Índices trigram para busca de texto

---

## 📝 Observações Importantes

1. **Em bases pequenas** (como esta com ~8.500 registros), as diferenças de tempo podem ser pequenas, mas a **redução de I/O** é significativa e se tornaria crucial em bases maiores.

2. **A eliminação de SubPlans** é a otimização mais impactante, pois evita execuções repetidas de subconsultas.

3. **Índices** já estavam sendo utilizados pelo PostgreSQL nas queries otimizadas (Index Scan, Index Only Scan).

4. **Em ambiente de produção** com milhões de registros, essas otimizações podem significar diferenças de segundos ou até minutos no tempo de resposta.

---

## ✅ Conclusão

As otimizações implementadas demonstram ganhos significativos principalmente em:
- **Redução de I/O** (buffers): média de 68%
- **Eliminação de execuções repetitivas** de subconsultas
- **Melhor aproveitamento de índices**

O padrão mais comum de problema identificado foi o uso de subconsultas correlacionadas no SELECT, que forçam o PostgreSQL a executar a subconsulta para cada linha do resultado principal.
