-- ============================================
-- SCRIPT 01: CRIAÇÃO DO BANCO DE DADOS
-- Sistema: GeekStore - Loja Virtual de Artigos Geeks e Games
-- Database: PostgreSQL 18
-- Autor: Projeto BD
-- Data: 2025
-- ============================================

-- Encerrar conexões existentes (se houver)
SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = 'geekstore_db'
AND pid <> pg_backend_pid();

-- Remover banco existente (se houver)
DROP DATABASE IF EXISTS geekstore_db;

-- Criar o banco de dados
CREATE DATABASE geekstore_db
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'pt_BR.UTF-8'
    LC_CTYPE = 'pt_BR.UTF-8'
    TEMPLATE = template0
    CONNECTION LIMIT = -1;

-- Comentário do banco
COMMENT ON DATABASE geekstore_db IS 'Banco de dados GeekStore - Loja Virtual de Artigos Geeks e Games - Projeto BD';

-- Conectar ao banco criado
\c geekstore_db

-- Criar schema principal
CREATE SCHEMA IF NOT EXISTS geekstore;

-- Definir search_path
SET search_path TO geekstore, public;

-- Criar extensões úteis
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";      -- Para gerar UUIDs
CREATE EXTENSION IF NOT EXISTS "pg_trgm";        -- Para buscas por similaridade
CREATE EXTENSION IF NOT EXISTS "unaccent";       -- Para remover acentos em buscas

-- Mensagem de sucesso
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Banco de dados geekstore_db criado com sucesso!';
    RAISE NOTICE 'Schema: geekstore';
    RAISE NOTICE 'Extensões: uuid-ossp, pg_trgm, unaccent';
    RAISE NOTICE '========================================';
END $$;
