# 🎮 GeekStore - Sistema de Gerenciamento de Loja Virtual

## 🎯 Sobre o Projeto

Este projeto apresenta um banco de dados PostgreSQL completo para uma **loja virtual de artigos geeks e games**, desenvolvido como trabalho acadêmico da disciplina de Banco de Dados. O sistema foi projetado para gerenciar desde cadastro de clientes até vendas, incluindo:

- 🦸 **Action Figures** (Marvel, DC, Star Wars)
- 🎭 **Funko Pops** (diversas franquias)
- 🎮 **Games** (PS5, Xbox, Nintendo Switch, PC)
- 📺 **Consoles** (PlayStation, Xbox, Nintendo)
- 📚 **HQs e Mangás**
- 👕 **Vestuário Geek**
- 🏆 **Colecionáveis Raros**
- 🎲 **Board Games e Card Games**
- 🖼️ **Decoração Geek**
- 🎧 **Acessórios Gamer**

## ✅ Objetivos Atendidos

- ✅ **10+ tabelas** relacionadas com constraints e integridade referencial
- ✅ **5 tabelas principais** com 1.000 registros cada
- ✅ **10 queries complexas** com JOIN de 4+ tabelas
- ✅ **EXPLAIN ANALYZE** antes e depois da otimização
- ✅ **Procedures, Functions e Triggers** em PL/pgSQL
- ✅ **Documentação completa** com instruções de execução

## 🗂️ Estrutura do Projeto

```
projeto-bd/
├── README.md                           # Este arquivo
├── scripts/
│   ├── 01_create_database.sql          # Criação do banco de dados
│   ├── 02_create_tables.sql            # Criação das 10+ tabelas
│   ├── 03_create_indexes.sql           # Criação de índices
│   ├── 04_populate_data.sql            # População com dados temáticos
│   ├── 05_procedures_functions.sql     # Procedures, Functions e Triggers
│   └── queries/
│       ├── query_01_before.sql         # Query 1 - Não otimizada
│       ├── query_01_after.sql          # Query 1 - Otimizada
│       ├── query_01_analysis.md        # Query 1 - Análise detalhada
│       ├── query_02_before.sql         # Query 2 - Não otimizada
│       ├── query_02_after.sql          # Query 2 - Otimizada
│       ├── query_02_analysis.md        # Query 2 - Análise
│       ├── ... (queries 3-9)
│       ├── query_10_before.sql         # Query 10 - Não otimizada
│       ├── query_10_after.sql          # Query 10 - Otimizada
│       └── query_10_analysis.md        # Query 10 - Análise
└── docs/
    └── explicacao_otimizacoes.md       # Documento explicativo das otimizações
```

## 🏗️ Modelo de Dados

### Diagrama de Relacionamentos

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────────────┐
│   CATEGORIAS    │     │  FORMAS_PAGTO   │     │       CLIENTES          │
│   (Auxiliar)    │     │   (Auxiliar)    │     │      (Principal)        │
├─────────────────┤     ├─────────────────┤     ├─────────────────────────┤
│ categoria_id PK │     │ forma_pagto_id  │     │ cliente_id PK           │
│ nome            │     │ nome            │     │ nome, email, cpf        │
│ descricao       │     │ taxa_percentual │     │ nickname 🎮             │
│ categoria_pai   │     │ parcelas_max    │     │ nivel_geek (1-10) 🏆    │
└────────┬────────┘     └────────┬────────┘     │ pontos_xp 💎            │
         │                       │              └───────────┬─────────────┘
         │                       │                          │
         ▼                       │                          │
┌──────────────────────────────────────────────┐            │
│           PRODUTOS (Principal - 1000)        │            │
├──────────────────────────────────────────────┤            │
│ produto_id PK                                │            │
│ sku, nome, descricao                         │            │
│ categoria_id FK → CATEGORIAS                 │            │
│ franquia 🎬 (Marvel, DC, Star Wars, etc)     │            │
│ fabricante 🏭 (Funko, NECA, Hasbro, etc)     │            │
│ preco, preco_promocional                     │            │
│ lancamento, exclusivo, pre_venda 🆕          │            │
│ classificacao_indicativa 🎮                  │            │
└──────────────────────┬───────────────────────┘            │
                       │                                    │
         ┌─────────────┼─────────────┐                      │
         │             │             │                      │
         ▼             │             ▼                      │
┌─────────────────┐    │    ┌─────────────────┐             │
│   AVALIACOES    │    │    │    ENDERECOS    │◄────────────┤
│   (Auxiliar)    │    │    │   (Principal)   │             │
├─────────────────┤    │    ├─────────────────┤             │
│ avaliacao_id PK │    │    │ endereco_id PK  │             │
│ produto_id FK   │    │    │ cliente_id FK   │             │
│ cliente_id FK ──┼────┼────│ cidade_id FK    │             │
│ nota (1-5) ⭐   │    │    │ logradouro      │             │
│ pros / contras  │    │    └────────┬────────┘             │
│ recomenda? 👍   │    │             │                      │
└─────────────────┘    │             ▼                      │
                       │    ┌─────────────────┐             │
                       │    │     CIDADES     │             │
                       │    │   (Auxiliar)    │             │
                       │    └─────────────────┘             │
                       │                                    │
                       ▼                                    │
         ┌─────────────────────────────────────────────────┐
         │           PEDIDOS (Principal - 1000)            │
         ├─────────────────────────────────────────────────┤
         │ pedido_id PK, numero_pedido                     │
         │ cliente_id FK → CLIENTES                        │
         │ endereco_entrega_id FK → ENDERECOS              │
         │ status_id FK → STATUS_PEDIDO                    │
         │ forma_pagamento_id FK → FORMAS_PAGAMENTO        │
         │ subtotal, desconto, frete, total                │
         │ cupom_codigo → CUPONS_DESCONTO                  │
         └──────────────────────┬──────────────────────────┘
                                │
         ┌──────────────────────┼──────────────────────┐
         │                      │                      │
         ▼                      ▼                      ▼
┌───────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│   ITENS_PEDIDO    │  │  STATUS_PEDIDO  │  │ CUPONS_DESCONTO │
│   (Principal)     │  │   (Auxiliar)    │  │   (Auxiliar)    │
├───────────────────┤  ├─────────────────┤  ├─────────────────┤
│ item_id PK        │  │ status_id PK    │  │ cupom_id PK     │
│ pedido_id FK      │  │ nome            │  │ codigo          │
│ produto_id FK     │  │ ordem_fluxo     │  │ tipo_desconto   │
│ quantidade        │  │ cor_exibicao    │  │ franquia_rest.  │
│ preco_unitario    │  └─────────────────┘  └─────────────────┘
└───────────────────┘
```

### Tabelas do Sistema

| # | Tabela | Tipo | Registros | Descrição |
|---|--------|------|-----------|-----------|
| 1 | `clientes` | Principal | 1.000 | Cadastro de clientes geeks com nickname e nível |
| 2 | `produtos` | Principal | 1.000 | Catálogo com franquia e fabricante |
| 3 | `pedidos` | Principal | 1.000 | Pedidos realizados |
| 4 | `itens_pedido` | Principal | ~3.000 | Itens de cada pedido |
| 5 | `enderecos` | Principal | 1.000 | Endereços de entrega |
| 6 | `categorias` | Auxiliar | 30 | Categorias geeks (Action Figures, Funko, etc) |
| 7 | `formas_pagamento` | Auxiliar | 8 | Formas de pagamento (inclui Pontos XP) |
| 8 | `status_pedido` | Auxiliar | 10 | Status do fluxo de pedido |
| 9 | `cidades` | Auxiliar | 35 | Cidades brasileiras |
| 10 | `estados` | Auxiliar | 27 | Estados brasileiros |
| 11 | `avaliacoes_produtos` | Auxiliar | ~500 | Reviews com pros/contras |
| 12 | `cupons_desconto` | Auxiliar | 8 | Cupons temáticos (MARVEL20, etc) |
| 13 | `carrinho` | Auxiliar | - | Carrinho de compras |
| 14 | `historico_status` | Auxiliar | ~1.000 | Auditoria de status |
| 15 | `log_auditoria` | Auxiliar | - | Log geral de alterações |

## 🚀 Instruções de Execução

### Pré-requisitos

- PostgreSQL 12+ instalado
- Acesso de superusuário (para criar banco de dados)
- Cliente psql ou pgAdmin

### Execução Passo a Passo

#### 1️⃣ Criar o Banco de Dados

```bash
# Conectar como superusuário
sudo -u postgres psql

# Executar script de criação do banco
\i /caminho/para/projeto-bd/scripts/01_create_database.sql
```

#### 2️⃣ Criar as Tabelas

```bash
# Conectar ao banco geekstore_db
sudo -u postgres psql -d geekstore_db

# Executar script de criação das tabelas
\i /caminho/para/projeto-bd/scripts/02_create_tables.sql
```

#### 3️⃣ Criar os Índices

```bash
\i /caminho/para/projeto-bd/scripts/03_create_indexes.sql
```

#### 4️⃣ Popular os Dados

```bash
\i /caminho/para/projeto-bd/scripts/04_populate_data.sql
```

#### 5️⃣ Criar Procedures, Functions e Triggers

```bash
\i /caminho/para/projeto-bd/scripts/05_procedures_functions.sql
```

### Script de Execução Completa

```bash
#!/bin/bash
# Script para executar todos os arquivos em ordem

SCRIPTS_DIR="/home/irving/Documentos/Projeto BD/projeto-bd/scripts"

echo "🎮 Iniciando setup do GeekStore Database..."

sudo -u postgres psql -f "$SCRIPTS_DIR/01_create_database.sql"
echo "✅ Banco de dados criado!"

sudo -u postgres psql -d geekstore_db -f "$SCRIPTS_DIR/02_create_tables.sql"
echo "✅ Tabelas criadas!"

sudo -u postgres psql -d geekstore_db -f "$SCRIPTS_DIR/03_create_indexes.sql"
echo "✅ Índices criados!"

sudo -u postgres psql -d geekstore_db -f "$SCRIPTS_DIR/04_populate_data.sql"
echo "✅ Dados populados!"

sudo -u postgres psql -d geekstore_db -f "$SCRIPTS_DIR/05_procedures_functions.sql"
echo "✅ Procedures e Functions criadas!"

echo "🎉 GeekStore Database configurado com sucesso!"
```

## 📊 Queries Desenvolvidas

### Resumo das 10 Queries

| # | Nome | Tabelas | Descrição |
|---|------|---------|-----------|
| 1 | Relatório de Vendas | 9 | Vendas por período com cliente, produto, franquia e pagamento |
| 2 | Clientes VIP Geek | 5 | Ranking de clientes por nível geek e valor gasto |
| 3 | Gestão de Estoque | 6 | Análise de estoque por categoria e franquia |
| 4 | Análise Temporal | 5 | Vendas mensais com crescimento |
| 5 | Produtos Mais Avaliados | 6 | Ranking por nota e quantidade de reviews |
| 6 | Inadimplência | 5 | Pedidos pendentes por região |
| 7 | Performance Categorias | 6 | Métricas por categoria geek |
| 8 | Comportamento Compra | 6 | Padrões de consumo por perfil |
| 9 | Análise Geográfica | 5 | Distribuição de vendas por região |
| 10 | Dashboard Executivo | 7 | KPIs consolidados da GeekStore |

### Técnicas de Otimização Utilizadas

1. **Índices Compostos** - Multi-coluna para queries frequentes
2. **Índices Parciais** - Filtrados para subconjuntos (produtos ativos, lançamentos)
3. **Covering Indexes (INCLUDE)** - Index-Only Scan
4. **Índices por Franquia** - Busca rápida por Marvel, DC, Star Wars, etc
5. **CTEs** - Materialização de subconsultas
6. **Window Functions** - Rankings e agregações eficientes
7. **Hash Joins** - Otimização de JOINs grandes
8. **Index-Only Scans** - Consultas atendidas apenas pelo índice

## 🔧 Procedures e Functions

### Stored Procedures

| Nome | Descrição |
|------|-----------|
| `sp_criar_pedido` | Cria pedido com validação de estoque e XP |
| `sp_atualizar_status_pedido` | Atualiza status com histórico |
| `sp_adicionar_carrinho` | Adiciona item ao carrinho |
| `sp_repor_estoque` | Reposição com auditoria |

### Functions

| Nome | Retorno | Descrição |
|------|---------|-----------|
| `fn_calcular_idade` | INTEGER | Calcula idade do cliente |
| `fn_preco_final` | DECIMAL | Retorna preço (promocional se houver) |
| `fn_percentual_desconto` | DECIMAL | Calcula % de desconto |
| `fn_verificar_estoque` | BOOLEAN | Verifica disponibilidade |
| `fn_calcular_frete` | DECIMAL | Calcula frete por região |
| `fn_estatisticas_cliente` | TABLE | Stats do cliente geek |
| `fn_produtos_mais_vendidos` | TABLE | Top produtos por franquia |
| `fn_faturamento_periodo` | TABLE | Faturamento diário |

### Triggers

| Nome | Tabela | Evento | Descrição |
|------|--------|--------|-----------|
| `trg_*_updated_at` | Várias | UPDATE | Atualiza timestamp |
| `trg_auditoria_produtos` | produtos | INSERT/UPDATE/DELETE | Log de alterações |
| `trg_verificar_estoque_minimo` | produtos | UPDATE | Alerta estoque baixo |
| `trg_validar_email` | clientes | INSERT/UPDATE | Normaliza email |
| `trg_calcular_subtotal_item` | itens_pedido | INSERT/UPDATE | Calcula subtotal |
| `trg_proteger_cliente` | clientes | DELETE | Impede exclusão |

## 📈 Resultados de Otimização

### Métricas de Melhoria

| Query | Tempo Antes | Tempo Depois | Melhoria |
|-------|-------------|--------------|----------|
| Query 1 | ~450ms | ~85ms | **81%** |
| Query 2 | ~380ms | ~65ms | **83%** |
| Query 3 | ~520ms | ~95ms | **82%** |
| Query 4 | ~280ms | ~55ms | **80%** |
| Query 5 | ~350ms | ~70ms | **80%** |
| Query 6 | ~420ms | ~75ms | **82%** |
| Query 7 | ~480ms | ~90ms | **81%** |
| Query 8 | ~550ms | ~100ms | **82%** |
| Query 9 | ~320ms | ~60ms | **81%** |
| Query 10 | ~680ms | ~120ms | **82%** |

> ⚠️ **Nota**: Tempos estimados. Execute com EXPLAIN ANALYZE para métricas reais.

## 🔍 Como Analisar as Queries

### Executando EXPLAIN ANALYZE

```sql
-- Conectar ao banco
\c geekstore_db
SET search_path TO geekstore, public;

-- Executar versão antes da otimização
\i /caminho/scripts/queries/query_01_before.sql

-- Ver plano de execução detalhado
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT ... -- sua query aqui
```

### Comparando Planos

1. Execute a versão "before" e salve o plano
2. Execute o script de criação de índices da versão "after"
3. Execute a versão "after" e compare
4. Observe:
   - Tipo de scan (Sequential vs Index)
   - Tempo de execução (actual time)
   - Buffers lidos (shared hit/read)
   - Método de JOIN

## 🎨 Exemplos de Dados Temáticos

### Categorias Geek
- Action Figures (Marvel Legends, DC Multiverse, Star Wars Black Series)
- Funko Pop (Marvel, DC, Anime, Games, Movies)
- Games (PS5, Xbox Series, Nintendo Switch, PC)
- HQs e Mangás (One Piece, Naruto, Dragon Ball, Batman)

### Franquias Disponíveis
Marvel, DC Comics, Star Wars, Harry Potter, Dragon Ball, Naruto, One Piece, Pokemon, Nintendo, PlayStation, Xbox, Lord of the Rings, Game of Thrones, Stranger Things, The Witcher, Zelda, Mario, Sonic, Resident Evil, Final Fantasy

### Cupons Temáticos
- `GEEK10` - 10% desconto boas-vindas
- `MARVEL20` - 20% produtos Marvel
- `FUNKOFRIDAY` - 25% Funko Pops
- `MAYTHEFORCEBEWITHYOU` - 15% Star Wars
- `ANIME25` - 25% produtos de Anime

## 👨‍💻 Autor

- **Nome**: Irving
- **Disciplina**: Banco de Dados
- **Data**: Novembro 2025

## 📝 Licença

Este projeto é de uso acadêmico. Sinta-se livre para usar como referência.

## 📚 Referências

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [PostgreSQL EXPLAIN](https://www.postgresql.org/docs/current/sql-explain.html)
- [Index Types](https://www.postgresql.org/docs/current/indexes-types.html)
- [PL/pgSQL](https://www.postgresql.org/docs/current/plpgsql.html)

---

**🎮 May the Force be with your queries! 🚀**
