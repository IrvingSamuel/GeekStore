-- ============================================
-- SCRIPT 05: PROCEDURES, FUNCTIONS E TRIGGERS
-- Sistema: GeekStore - Loja Virtual de Artigos Geeks e Games
-- Database: PostgreSQL 18
-- Linguagem: PL/pgSQL
-- ============================================

-- Conectar ao banco
\c geekstore_db

-- Definir schema
SET search_path TO geekstore, public;

-- ============================================
-- FUNCTIONS UTILITÁRIAS
-- ============================================

-- Function: Calcular idade do cliente
CREATE OR REPLACE FUNCTION fn_calcular_idade(p_data_nascimento DATE)
RETURNS INTEGER AS $$
BEGIN
    RETURN EXTRACT(YEAR FROM AGE(CURRENT_DATE, p_data_nascimento))::INTEGER;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION fn_calcular_idade IS 'Calcula a idade baseada na data de nascimento';

-- Function: Formatar CPF
CREATE OR REPLACE FUNCTION fn_formatar_cpf(p_cpf CHAR(11))
RETURNS VARCHAR(14) AS $$
BEGIN
    IF p_cpf IS NULL OR LENGTH(p_cpf) != 11 THEN
        RETURN NULL;
    END IF;
    RETURN SUBSTRING(p_cpf, 1, 3) || '.' || 
           SUBSTRING(p_cpf, 4, 3) || '.' || 
           SUBSTRING(p_cpf, 7, 3) || '-' || 
           SUBSTRING(p_cpf, 10, 2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION fn_formatar_cpf IS 'Formata CPF no padrão XXX.XXX.XXX-XX';

-- Function: Calcular preço final do produto
CREATE OR REPLACE FUNCTION fn_preco_final(p_produto_id INTEGER)
RETURNS DECIMAL(12,2) AS $$
DECLARE
    v_preco DECIMAL(12,2);
    v_promo DECIMAL(12,2);
BEGIN
    SELECT preco, preco_promocional 
    INTO v_preco, v_promo
    FROM produtos 
    WHERE produto_id = p_produto_id;
    
    RETURN COALESCE(v_promo, v_preco);
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION fn_preco_final IS 'Retorna o preço final do produto (promocional se houver)';

-- Function: Calcular desconto percentual
CREATE OR REPLACE FUNCTION fn_percentual_desconto(p_produto_id INTEGER)
RETURNS DECIMAL(5,2) AS $$
DECLARE
    v_preco DECIMAL(12,2);
    v_promo DECIMAL(12,2);
BEGIN
    SELECT preco, preco_promocional 
    INTO v_preco, v_promo
    FROM produtos 
    WHERE produto_id = p_produto_id;
    
    IF v_promo IS NULL OR v_preco = 0 THEN
        RETURN 0;
    END IF;
    
    RETURN ROUND(((v_preco - v_promo) / v_preco * 100)::NUMERIC, 2);
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION fn_percentual_desconto IS 'Calcula o percentual de desconto promocional';

-- Function: Verificar disponibilidade de estoque
CREATE OR REPLACE FUNCTION fn_verificar_estoque(
    p_produto_id INTEGER, 
    p_quantidade INTEGER
)
RETURNS BOOLEAN AS $$
DECLARE
    v_estoque INTEGER;
BEGIN
    SELECT estoque_atual INTO v_estoque
    FROM produtos
    WHERE produto_id = p_produto_id AND ativo = TRUE;
    
    IF v_estoque IS NULL THEN
        RETURN FALSE;
    END IF;
    
    RETURN v_estoque >= p_quantidade;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION fn_verificar_estoque IS 'Verifica se há estoque disponível para a quantidade solicitada';

-- Function: Calcular frete baseado no CEP e valor
CREATE OR REPLACE FUNCTION fn_calcular_frete(
    p_cep_destino CHAR(8),
    p_valor_pedido DECIMAL(12,2),
    p_peso_total DECIMAL(8,3) DEFAULT 1
)
RETURNS DECIMAL(12,2) AS $$
DECLARE
    v_regiao CHAR(1);
    v_frete_base DECIMAL(12,2);
BEGIN
    -- Determinar região pelo primeiro dígito do CEP
    v_regiao := SUBSTRING(p_cep_destino, 1, 1);
    
    -- Frete grátis para pedidos acima de R$ 299
    IF p_valor_pedido >= 299.00 THEN
        RETURN 0.00;
    END IF;
    
    -- Calcular frete base por região
    v_frete_base := CASE v_regiao
        WHEN '0' THEN 25.00  -- SP
        WHEN '1' THEN 25.00  -- SP
        WHEN '2' THEN 30.00  -- RJ/ES
        WHEN '3' THEN 30.00  -- MG
        WHEN '4' THEN 35.00  -- BA/SE
        WHEN '5' THEN 40.00  -- PE/AL/PB/RN
        WHEN '6' THEN 45.00  -- CE/PI/MA
        WHEN '7' THEN 50.00  -- Norte
        WHEN '8' THEN 35.00  -- PR/SC
        WHEN '9' THEN 40.00  -- RS/MS/MT/GO/DF
        ELSE 40.00
    END;
    
    -- Adicionar valor por peso
    RETURN ROUND((v_frete_base + (p_peso_total * 2))::NUMERIC, 2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION fn_calcular_frete IS 'Calcula o frete baseado no CEP, valor do pedido e peso';

-- Function: Calcular valor do cupom
CREATE OR REPLACE FUNCTION fn_calcular_desconto_cupom(
    p_codigo_cupom VARCHAR(50),
    p_valor_pedido DECIMAL(12,2)
)
RETURNS DECIMAL(12,2) AS $$
DECLARE
    v_cupom RECORD;
    v_desconto DECIMAL(12,2);
BEGIN
    -- Buscar cupom válido
    SELECT * INTO v_cupom
    FROM cupons_desconto
    WHERE codigo = UPPER(p_codigo_cupom)
      AND ativo = TRUE
      AND CURRENT_DATE BETWEEN data_inicio AND data_fim
      AND (quantidade_maxima IS NULL OR quantidade_usada < quantidade_maxima);
    
    IF NOT FOUND THEN
        RETURN 0.00;
    END IF;
    
    -- Verificar valor mínimo
    IF p_valor_pedido < v_cupom.valor_minimo_pedido THEN
        RETURN 0.00;
    END IF;
    
    -- Calcular desconto
    IF v_cupom.tipo_desconto = 'PERCENTUAL' THEN
        v_desconto := ROUND((p_valor_pedido * v_cupom.valor_desconto / 100)::NUMERIC, 2);
    ELSE
        v_desconto := v_cupom.valor_desconto;
    END IF;
    
    -- Desconto não pode ser maior que o valor do pedido
    RETURN LEAST(v_desconto, p_valor_pedido);
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION fn_calcular_desconto_cupom IS 'Calcula o valor de desconto de um cupom';

-- ============================================
-- FUNCTIONS DE RELATÓRIOS
-- ============================================

-- Function: Retornar estatísticas do cliente geek
CREATE OR REPLACE FUNCTION fn_estatisticas_cliente(p_cliente_id INTEGER)
RETURNS TABLE (
    total_pedidos BIGINT,
    valor_total_gasto DECIMAL(12,2),
    ticket_medio DECIMAL(12,2),
    primeiro_pedido DATE,
    ultimo_pedido DATE,
    status_mais_comum VARCHAR(50),
    nivel_geek INTEGER,
    pontos_xp INTEGER,
    franquia_favorita VARCHAR(100)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(p.pedido_id)::BIGINT,
        COALESCE(SUM(p.total), 0)::DECIMAL(12,2),
        COALESCE(AVG(p.total), 0)::DECIMAL(12,2),
        MIN(p.data_pedido)::DATE,
        MAX(p.data_pedido)::DATE,
        (SELECT s.nome 
         FROM pedidos p2 
         JOIN status_pedido s ON p2.status_id = s.status_id 
         WHERE p2.cliente_id = p_cliente_id 
         GROUP BY s.nome 
         ORDER BY COUNT(*) DESC 
         LIMIT 1)::VARCHAR(50),
        c.nivel_geek,
        c.pontos_xp,
        (SELECT pr.franquia
         FROM itens_pedido ip
         JOIN pedidos ped ON ip.pedido_id = ped.pedido_id
         JOIN produtos pr ON ip.produto_id = pr.produto_id
         WHERE ped.cliente_id = p_cliente_id AND pr.franquia IS NOT NULL
         GROUP BY pr.franquia
         ORDER BY COUNT(*) DESC
         LIMIT 1)::VARCHAR(100)
    FROM pedidos p
    JOIN clientes c ON c.cliente_id = p_cliente_id
    WHERE p.cliente_id = p_cliente_id
    GROUP BY c.nivel_geek, c.pontos_xp;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION fn_estatisticas_cliente IS 'Retorna estatísticas de compras de um cliente geek incluindo franquia favorita';

-- Function: Produtos mais vendidos por categoria ou franquia
CREATE OR REPLACE FUNCTION fn_produtos_mais_vendidos(
    p_categoria_id INTEGER DEFAULT NULL,
    p_franquia VARCHAR(100) DEFAULT NULL,
    p_limite INTEGER DEFAULT 10
)
RETURNS TABLE (
    produto_id INTEGER,
    nome_produto VARCHAR(200),
    categoria VARCHAR(100),
    franquia VARCHAR(100),
    quantidade_vendida BIGINT,
    valor_total_vendas DECIMAL(12,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.produto_id,
        p.nome::VARCHAR(200),
        c.nome::VARCHAR(100),
        p.franquia::VARCHAR(100),
        COALESCE(SUM(ip.quantidade), 0)::BIGINT,
        COALESCE(SUM(ip.subtotal), 0)::DECIMAL(12,2)
    FROM produtos p
    JOIN categorias c ON p.categoria_id = c.categoria_id
    LEFT JOIN itens_pedido ip ON p.produto_id = ip.produto_id
    WHERE (p_categoria_id IS NULL OR p.categoria_id = p_categoria_id)
      AND (p_franquia IS NULL OR p.franquia = p_franquia)
      AND p.ativo = TRUE
    GROUP BY p.produto_id, p.nome, c.nome, p.franquia
    ORDER BY SUM(ip.quantidade) DESC NULLS LAST
    LIMIT p_limite;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION fn_produtos_mais_vendidos IS 'Retorna os produtos mais vendidos da GeekStore, opcionalmente por categoria ou franquia';

-- Function: Faturamento por período
CREATE OR REPLACE FUNCTION fn_faturamento_periodo(
    p_data_inicio DATE,
    p_data_fim DATE
)
RETURNS TABLE (
    data DATE,
    total_pedidos BIGINT,
    valor_bruto DECIMAL(12,2),
    valor_descontos DECIMAL(12,2),
    valor_frete DECIMAL(12,2),
    valor_liquido DECIMAL(12,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.data_pedido::DATE,
        COUNT(*)::BIGINT,
        SUM(p.subtotal)::DECIMAL(12,2),
        SUM(p.desconto)::DECIMAL(12,2),
        SUM(p.frete)::DECIMAL(12,2),
        SUM(p.total)::DECIMAL(12,2)
    FROM pedidos p
    WHERE p.data_pedido::DATE BETWEEN p_data_inicio AND p_data_fim
      AND p.status_id NOT IN (SELECT status_id FROM status_pedido WHERE nome IN ('Cancelado', 'Reembolsado'))
    GROUP BY p.data_pedido::DATE
    ORDER BY p.data_pedido::DATE;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION fn_faturamento_periodo IS 'Retorna o faturamento diário em um período';

-- ============================================
-- STORED PROCEDURES
-- ============================================

-- Procedure: Criar novo pedido
CREATE OR REPLACE PROCEDURE sp_criar_pedido(
    p_cliente_id INTEGER,
    p_endereco_id INTEGER,
    p_forma_pagamento_id INTEGER,
    p_cupom_codigo VARCHAR(50) DEFAULT NULL,
    p_parcelas INTEGER DEFAULT 1,
    p_observacoes TEXT DEFAULT NULL,
    INOUT p_pedido_id INTEGER DEFAULT NULL
)
LANGUAGE plpgsql AS $$
DECLARE
    v_numero_pedido VARCHAR(20);
    v_subtotal DECIMAL(12,2) := 0;
    v_desconto DECIMAL(12,2) := 0;
    v_frete DECIMAL(12,2);
    v_cep CHAR(8);
    v_item RECORD;
    v_status_inicial INTEGER;
BEGIN
    -- Gerar número do pedido
    v_numero_pedido := 'PED' || TO_CHAR(CURRENT_TIMESTAMP, 'YYYYMMDDHH24MISS') || 
                       LPAD(FLOOR(RANDOM() * 999)::TEXT, 3, '0');
    
    -- Obter status inicial
    SELECT status_id INTO v_status_inicial 
    FROM status_pedido 
    WHERE ordem_fluxo = 1;
    
    -- Calcular subtotal do carrinho
    SELECT COALESCE(SUM(c.quantidade * fn_preco_final(c.produto_id)), 0)
    INTO v_subtotal
    FROM carrinho c
    WHERE c.cliente_id = p_cliente_id;
    
    IF v_subtotal = 0 THEN
        RAISE EXCEPTION 'Carrinho vazio para o cliente %', p_cliente_id;
    END IF;
    
    -- Obter CEP para cálculo de frete
    SELECT cep INTO v_cep FROM enderecos WHERE endereco_id = p_endereco_id;
    
    -- Calcular frete
    v_frete := fn_calcular_frete(v_cep, v_subtotal);
    
    -- Calcular desconto do cupom
    IF p_cupom_codigo IS NOT NULL THEN
        v_desconto := fn_calcular_desconto_cupom(p_cupom_codigo, v_subtotal);
    END IF;
    
    -- Criar pedido
    INSERT INTO pedidos (
        numero_pedido, cliente_id, endereco_entrega_id, status_id, 
        forma_pagamento_id, subtotal, desconto, frete, total, 
        parcelas, cupom_codigo, observacoes, data_pedido
    )
    VALUES (
        v_numero_pedido, p_cliente_id, p_endereco_id, v_status_inicial,
        p_forma_pagamento_id, v_subtotal, v_desconto, v_frete,
        v_subtotal - v_desconto + v_frete, p_parcelas, p_cupom_codigo,
        p_observacoes, CURRENT_TIMESTAMP
    )
    RETURNING pedido_id INTO p_pedido_id;
    
    -- Transferir itens do carrinho para o pedido
    FOR v_item IN 
        SELECT c.produto_id, c.quantidade, fn_preco_final(c.produto_id) as preco
        FROM carrinho c
        WHERE c.cliente_id = p_cliente_id
    LOOP
        -- Verificar estoque
        IF NOT fn_verificar_estoque(v_item.produto_id, v_item.quantidade) THEN
            RAISE EXCEPTION 'Estoque insuficiente para o produto %', v_item.produto_id;
        END IF;
        
        -- Inserir item do pedido
        INSERT INTO itens_pedido (pedido_id, produto_id, quantidade, preco_unitario, subtotal)
        VALUES (p_pedido_id, v_item.produto_id, v_item.quantidade, v_item.preco, 
                v_item.quantidade * v_item.preco);
        
        -- Atualizar estoque
        UPDATE produtos 
        SET estoque_atual = estoque_atual - v_item.quantidade,
            updated_at = CURRENT_TIMESTAMP
        WHERE produto_id = v_item.produto_id;
    END LOOP;
    
    -- Limpar carrinho
    DELETE FROM carrinho WHERE cliente_id = p_cliente_id;
    
    -- Atualizar uso do cupom
    IF p_cupom_codigo IS NOT NULL AND v_desconto > 0 THEN
        UPDATE cupons_desconto 
        SET quantidade_usada = quantidade_usada + 1
        WHERE codigo = UPPER(p_cupom_codigo);
    END IF;
    
    -- Registrar histórico
    INSERT INTO historico_status_pedido (pedido_id, status_novo_id, observacao, usuario_responsavel)
    VALUES (p_pedido_id, v_status_inicial, 'Pedido criado', 'sistema');
    
    RAISE NOTICE 'Pedido % criado com sucesso! ID: %', v_numero_pedido, p_pedido_id;
END;
$$;

COMMENT ON PROCEDURE sp_criar_pedido IS 'Cria um novo pedido a partir do carrinho do cliente';

-- Procedure: Atualizar status do pedido
CREATE OR REPLACE PROCEDURE sp_atualizar_status_pedido(
    p_pedido_id INTEGER,
    p_novo_status_id INTEGER,
    p_observacao TEXT DEFAULT NULL,
    p_usuario VARCHAR(100) DEFAULT 'sistema'
)
LANGUAGE plpgsql AS $$
DECLARE
    v_status_atual INTEGER;
    v_ordem_atual INTEGER;
    v_ordem_novo INTEGER;
BEGIN
    -- Obter status atual
    SELECT status_id INTO v_status_atual FROM pedidos WHERE pedido_id = p_pedido_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Pedido % não encontrado', p_pedido_id;
    END IF;
    
    -- Obter ordem dos status
    SELECT ordem_fluxo INTO v_ordem_atual FROM status_pedido WHERE status_id = v_status_atual;
    SELECT ordem_fluxo INTO v_ordem_novo FROM status_pedido WHERE status_id = p_novo_status_id;
    
    -- Validar transição (exceto para cancelamento/devolução)
    IF v_ordem_novo < v_ordem_atual AND v_ordem_novo < 8 THEN
        RAISE EXCEPTION 'Não é permitido retroceder o status do pedido (atual: %, novo: %)', 
                        v_ordem_atual, v_ordem_novo;
    END IF;
    
    -- Atualizar pedido
    UPDATE pedidos 
    SET status_id = p_novo_status_id,
        updated_at = CURRENT_TIMESTAMP,
        data_pagamento = CASE WHEN p_novo_status_id = 2 THEN CURRENT_TIMESTAMP ELSE data_pagamento END,
        data_envio = CASE WHEN p_novo_status_id = 4 THEN CURRENT_TIMESTAMP ELSE data_envio END,
        data_entrega = CASE WHEN p_novo_status_id = 7 THEN CURRENT_TIMESTAMP ELSE data_entrega END
    WHERE pedido_id = p_pedido_id;
    
    -- Registrar histórico
    INSERT INTO historico_status_pedido (
        pedido_id, status_anterior_id, status_novo_id, observacao, usuario_responsavel
    )
    VALUES (p_pedido_id, v_status_atual, p_novo_status_id, p_observacao, p_usuario);
    
    -- Se cancelado, devolver estoque
    IF p_novo_status_id = (SELECT status_id FROM status_pedido WHERE nome = 'Cancelado') THEN
        UPDATE produtos p
        SET estoque_atual = estoque_atual + ip.quantidade
        FROM itens_pedido ip
        WHERE ip.pedido_id = p_pedido_id AND p.produto_id = ip.produto_id;
    END IF;
    
    RAISE NOTICE 'Status do pedido % atualizado de % para %', p_pedido_id, v_status_atual, p_novo_status_id;
END;
$$;

COMMENT ON PROCEDURE sp_atualizar_status_pedido IS 'Atualiza o status de um pedido com validação e histórico';

-- Procedure: Adicionar item ao carrinho
CREATE OR REPLACE PROCEDURE sp_adicionar_carrinho(
    p_cliente_id INTEGER,
    p_produto_id INTEGER,
    p_quantidade INTEGER DEFAULT 1
)
LANGUAGE plpgsql AS $$
DECLARE
    v_carrinho_id INTEGER;
BEGIN
    -- Verificar se produto existe e está ativo
    IF NOT EXISTS (SELECT 1 FROM produtos WHERE produto_id = p_produto_id AND ativo = TRUE) THEN
        RAISE EXCEPTION 'Produto % não encontrado ou inativo', p_produto_id;
    END IF;
    
    -- Verificar estoque
    IF NOT fn_verificar_estoque(p_produto_id, p_quantidade) THEN
        RAISE EXCEPTION 'Estoque insuficiente para o produto %', p_produto_id;
    END IF;
    
    -- Verificar se já existe no carrinho
    SELECT carrinho_id INTO v_carrinho_id
    FROM carrinho
    WHERE cliente_id = p_cliente_id AND produto_id = p_produto_id;
    
    IF FOUND THEN
        -- Atualizar quantidade
        UPDATE carrinho 
        SET quantidade = quantidade + p_quantidade,
            updated_at = CURRENT_TIMESTAMP
        WHERE carrinho_id = v_carrinho_id;
    ELSE
        -- Inserir novo item
        INSERT INTO carrinho (cliente_id, produto_id, quantidade)
        VALUES (p_cliente_id, p_produto_id, p_quantidade);
    END IF;
    
    RAISE NOTICE 'Produto % adicionado ao carrinho do cliente %', p_produto_id, p_cliente_id;
END;
$$;

COMMENT ON PROCEDURE sp_adicionar_carrinho IS 'Adiciona um produto ao carrinho do cliente';

-- Procedure: Reposição de estoque
CREATE OR REPLACE PROCEDURE sp_repor_estoque(
    p_produto_id INTEGER,
    p_quantidade INTEGER,
    p_usuario VARCHAR(100) DEFAULT 'sistema'
)
LANGUAGE plpgsql AS $$
DECLARE
    v_estoque_anterior INTEGER;
    v_estoque_novo INTEGER;
BEGIN
    -- Obter estoque atual
    SELECT estoque_atual INTO v_estoque_anterior
    FROM produtos WHERE produto_id = p_produto_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Produto % não encontrado', p_produto_id;
    END IF;
    
    -- Atualizar estoque
    UPDATE produtos 
    SET estoque_atual = estoque_atual + p_quantidade,
        updated_at = CURRENT_TIMESTAMP
    WHERE produto_id = p_produto_id
    RETURNING estoque_atual INTO v_estoque_novo;
    
    -- Registrar no log de auditoria
    INSERT INTO log_auditoria (
        tabela_nome, operacao, registro_id, 
        dados_antigos, dados_novos, usuario
    )
    VALUES (
        'produtos', 'UPDATE', p_produto_id,
        jsonb_build_object('estoque_atual', v_estoque_anterior),
        jsonb_build_object('estoque_atual', v_estoque_novo, 'quantidade_reposta', p_quantidade),
        p_usuario
    );
    
    RAISE NOTICE 'Estoque do produto % atualizado: % -> % (+%)', 
                 p_produto_id, v_estoque_anterior, v_estoque_novo, p_quantidade;
END;
$$;

COMMENT ON PROCEDURE sp_repor_estoque IS 'Repõe estoque de um produto com registro em auditoria';

-- ============================================
-- TRIGGERS
-- ============================================

-- Trigger Function: Atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION fn_trigger_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger em todas as tabelas com updated_at
CREATE OR REPLACE TRIGGER trg_clientes_updated_at
    BEFORE UPDATE ON clientes
    FOR EACH ROW EXECUTE FUNCTION fn_trigger_updated_at();

CREATE OR REPLACE TRIGGER trg_produtos_updated_at
    BEFORE UPDATE ON produtos
    FOR EACH ROW EXECUTE FUNCTION fn_trigger_updated_at();

CREATE OR REPLACE TRIGGER trg_pedidos_updated_at
    BEFORE UPDATE ON pedidos
    FOR EACH ROW EXECUTE FUNCTION fn_trigger_updated_at();

CREATE OR REPLACE TRIGGER trg_carrinho_updated_at
    BEFORE UPDATE ON carrinho
    FOR EACH ROW EXECUTE FUNCTION fn_trigger_updated_at();

CREATE OR REPLACE TRIGGER trg_categorias_updated_at
    BEFORE UPDATE ON categorias
    FOR EACH ROW EXECUTE FUNCTION fn_trigger_updated_at();

-- Trigger Function: Auditoria de alterações em produtos
CREATE OR REPLACE FUNCTION fn_trigger_auditoria_produtos()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO log_auditoria (tabela_nome, operacao, registro_id, dados_novos, usuario)
        VALUES ('produtos', 'INSERT', NEW.produto_id, row_to_json(NEW)::JSONB, current_user);
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO log_auditoria (tabela_nome, operacao, registro_id, dados_antigos, dados_novos, usuario)
        VALUES ('produtos', 'UPDATE', NEW.produto_id, row_to_json(OLD)::JSONB, row_to_json(NEW)::JSONB, current_user);
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO log_auditoria (tabela_nome, operacao, registro_id, dados_antigos, usuario)
        VALUES ('produtos', 'DELETE', OLD.produto_id, row_to_json(OLD)::JSONB, current_user);
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_auditoria_produtos
    AFTER INSERT OR UPDATE OR DELETE ON produtos
    FOR EACH ROW EXECUTE FUNCTION fn_trigger_auditoria_produtos();

-- Trigger Function: Verificar estoque mínimo
CREATE OR REPLACE FUNCTION fn_trigger_verificar_estoque_minimo()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.estoque_atual <= NEW.estoque_minimo THEN
        -- Em produção, aqui enviaria um alerta/notificação
        RAISE NOTICE 'ALERTA: Produto % (%) com estoque baixo: % unidades (mínimo: %)',
                     NEW.produto_id, NEW.nome, NEW.estoque_atual, NEW.estoque_minimo;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_verificar_estoque_minimo
    AFTER UPDATE OF estoque_atual ON produtos
    FOR EACH ROW
    WHEN (NEW.estoque_atual <= NEW.estoque_minimo AND OLD.estoque_atual > OLD.estoque_minimo)
    EXECUTE FUNCTION fn_trigger_verificar_estoque_minimo();

-- Trigger Function: Validar email único case-insensitive
CREATE OR REPLACE FUNCTION fn_trigger_validar_email()
RETURNS TRIGGER AS $$
BEGIN
    NEW.email = LOWER(TRIM(NEW.email));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_validar_email
    BEFORE INSERT OR UPDATE OF email ON clientes
    FOR EACH ROW EXECUTE FUNCTION fn_trigger_validar_email();

-- Trigger Function: Calcular subtotal do item automaticamente
CREATE OR REPLACE FUNCTION fn_trigger_calcular_subtotal_item()
RETURNS TRIGGER AS $$
BEGIN
    NEW.subtotal = (NEW.preco_unitario - COALESCE(NEW.desconto_unitario, 0)) * NEW.quantidade;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_calcular_subtotal_item
    BEFORE INSERT OR UPDATE ON itens_pedido
    FOR EACH ROW EXECUTE FUNCTION fn_trigger_calcular_subtotal_item();

-- Trigger Function: Impedir exclusão de cliente com pedidos
CREATE OR REPLACE FUNCTION fn_trigger_proteger_cliente()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM pedidos WHERE cliente_id = OLD.cliente_id) THEN
        RAISE EXCEPTION 'Não é possível excluir cliente % pois possui pedidos associados. Use desativação.', OLD.cliente_id;
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_proteger_cliente
    BEFORE DELETE ON clientes
    FOR EACH ROW EXECUTE FUNCTION fn_trigger_proteger_cliente();

-- ============================================
-- VIEWS ÚTEIS
-- ============================================

-- View: Resumo de produtos
CREATE OR REPLACE VIEW vw_produtos_resumo AS
SELECT 
    p.produto_id,
    p.sku,
    p.nome,
    c.nome AS categoria,
    p.preco,
    p.preco_promocional,
    fn_percentual_desconto(p.produto_id) AS desconto_percentual,
    fn_preco_final(p.produto_id) AS preco_final,
    p.estoque_atual,
    p.estoque_minimo,
    CASE 
        WHEN p.estoque_atual = 0 THEN 'Sem estoque'
        WHEN p.estoque_atual <= p.estoque_minimo THEN 'Estoque baixo'
        ELSE 'Disponível'
    END AS status_estoque,
    p.ativo,
    p.destaque,
    COALESCE(AVG(av.nota), 0)::DECIMAL(3,2) AS media_avaliacoes,
    COUNT(av.avaliacao_id) AS total_avaliacoes
FROM produtos p
JOIN categorias c ON p.categoria_id = c.categoria_id
LEFT JOIN avaliacoes_produtos av ON p.produto_id = av.produto_id AND av.aprovado = TRUE
GROUP BY p.produto_id, p.sku, p.nome, c.nome, p.preco, p.preco_promocional, 
         p.estoque_atual, p.estoque_minimo, p.ativo, p.destaque;

COMMENT ON VIEW vw_produtos_resumo IS 'Visão consolidada de produtos com estatísticas';

-- View: Resumo de pedidos
CREATE OR REPLACE VIEW vw_pedidos_resumo AS
SELECT 
    p.pedido_id,
    p.numero_pedido,
    c.nome AS cliente,
    c.email AS cliente_email,
    s.nome AS status,
    fp.nome AS forma_pagamento,
    p.subtotal,
    p.desconto,
    p.frete,
    p.total,
    p.parcelas,
    p.data_pedido,
    p.data_entrega,
    COUNT(ip.item_id) AS qtd_itens,
    ci.nome || '/' || e.sigla AS cidade_entrega
FROM pedidos p
JOIN clientes c ON p.cliente_id = c.cliente_id
JOIN status_pedido s ON p.status_id = s.status_id
JOIN formas_pagamento fp ON p.forma_pagamento_id = fp.forma_pagamento_id
JOIN enderecos en ON p.endereco_entrega_id = en.endereco_id
JOIN cidades ci ON en.cidade_id = ci.cidade_id
JOIN estados e ON ci.estado_id = e.estado_id
LEFT JOIN itens_pedido ip ON p.pedido_id = ip.pedido_id
GROUP BY p.pedido_id, p.numero_pedido, c.nome, c.email, s.nome, fp.nome,
         p.subtotal, p.desconto, p.frete, p.total, p.parcelas, 
         p.data_pedido, p.data_entrega, ci.nome, e.sigla;

COMMENT ON VIEW vw_pedidos_resumo IS 'Visão consolidada de pedidos com informações do cliente';

-- View: Dashboard de vendas
CREATE OR REPLACE VIEW vw_dashboard_vendas AS
SELECT 
    DATE_TRUNC('month', p.data_pedido) AS mes,
    COUNT(DISTINCT p.pedido_id) AS total_pedidos,
    COUNT(DISTINCT p.cliente_id) AS clientes_unicos,
    SUM(p.total) AS faturamento_total,
    AVG(p.total) AS ticket_medio,
    SUM(p.desconto) AS total_descontos,
    SUM(p.frete) AS total_frete
FROM pedidos p
JOIN status_pedido s ON p.status_id = s.status_id
WHERE s.nome NOT IN ('Cancelado', 'Reembolsado')
GROUP BY DATE_TRUNC('month', p.data_pedido)
ORDER BY mes DESC;

COMMENT ON VIEW vw_dashboard_vendas IS 'Dashboard mensal de vendas';

-- ============================================
-- MENSAGEM DE CONCLUSÃO
-- ============================================
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Procedures, Functions e Triggers criados!';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Functions: 9';
    RAISE NOTICE 'Procedures: 4';
    RAISE NOTICE 'Triggers: 8';
    RAISE NOTICE 'Views: 3';
    RAISE NOTICE '========================================';
END $$;
