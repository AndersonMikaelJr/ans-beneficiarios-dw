-- consultas.sql
-- Perguntas de negócio respondidas pelo modelo estrela (ANS, beneficiários, ES).
-- Grão da fato: competência x plano x município x perfil.

-- ---------------------------------------------------------------------
-- Q1. Quantos beneficiários ativos, aderidos e cancelados existem em
--     cada competência carregada?
-- ---------------------------------------------------------------------
SELECT t.ano_mes,
       SUM(f.qt_beneficiario_ativo)     AS ativos,
       SUM(f.qt_beneficiario_aderido)   AS aderidos,
       SUM(f.qt_beneficiario_cancelado) AS cancelados
FROM fato_beneficiarios f
JOIN dim_tempo t ON t.tempo_sk = f.tempo_sk
GROUP BY t.ano_mes
ORDER BY t.ano_mes;

-- ---------------------------------------------------------------------
-- Q2. Quais são as 10 operadoras com mais beneficiários ativos na
--     competência mais recente carregada?
-- ---------------------------------------------------------------------
WITH ultima AS (
    SELECT MAX(t.ano_mes) AS ano_mes
    FROM fato_beneficiarios f
    JOIN dim_tempo t ON t.tempo_sk = f.tempo_sk
)
SELECT o.nm_razao_social,
       o.modalidade_operadora,
       SUM(f.qt_beneficiario_ativo) AS ativos
FROM fato_beneficiarios f
JOIN dim_tempo t     ON t.tempo_sk = f.tempo_sk
JOIN dim_operadora o ON o.operadora_sk = f.operadora_sk
JOIN ultima u        ON u.ano_mes = t.ano_mes
GROUP BY o.nm_razao_social, o.modalidade_operadora
ORDER BY ativos DESC
LIMIT 10;

-- ---------------------------------------------------------------------
-- Q3. Como os beneficiários ativos se distribuem por faixa etária e
--     sexo na competência mais recente?
-- ---------------------------------------------------------------------
WITH ultima AS (
    SELECT MAX(t.ano_mes) AS ano_mes
    FROM fato_beneficiarios f
    JOIN dim_tempo t ON t.tempo_sk = f.tempo_sk
)
SELECT pe.faixa_etaria_ordem,
       pe.de_faixa_etaria,
       pe.tp_sexo,
       SUM(f.qt_beneficiario_ativo) AS ativos
FROM fato_beneficiarios f
JOIN dim_tempo t  ON t.tempo_sk = f.tempo_sk
JOIN dim_perfil pe ON pe.perfil_sk = f.perfil_sk
JOIN ultima u     ON u.ano_mes = t.ano_mes
GROUP BY pe.faixa_etaria_ordem, pe.de_faixa_etaria, pe.tp_sexo
ORDER BY pe.faixa_etaria_ordem, pe.tp_sexo;