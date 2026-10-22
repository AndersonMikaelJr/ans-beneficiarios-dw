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


-- ---------------------------------------------------------------------
-- Q4. Qual a participação percentual de cada modalidade de operadora no
--     total de beneficiários ativos da competência mais recente?
-- ---------------------------------------------------------------------
WITH ultima AS (
    SELECT MAX(t.ano_mes) AS ano_mes
    FROM fato_beneficiarios f
    JOIN dim_tempo t ON t.tempo_sk = f.tempo_sk
),
por_modalidade AS (
    SELECT o.modalidade_operadora,
           SUM(f.qt_beneficiario_ativo) AS ativos
    FROM fato_beneficiarios f
    JOIN dim_tempo t     ON t.tempo_sk = f.tempo_sk
    JOIN dim_operadora o ON o.operadora_sk = f.operadora_sk
    JOIN ultima u        ON u.ano_mes = t.ano_mes
    GROUP BY o.modalidade_operadora
)
SELECT modalidade_operadora,
       ativos,
       ROUND(100.0 * ativos / SUM(ativos) OVER (), 2) AS participacao_pct
FROM por_modalidade
ORDER BY ativos DESC;

-- ---------------------------------------------------------------------
-- Q5. Como variou o número de ativos de cada operadora entre a primeira
--     e a última competência carregadas? (10 maiores crescimentos)
-- ---------------------------------------------------------------------
WITH por_operadora AS (
    SELECT o.nm_razao_social,
           t.ano_mes,
           SUM(f.qt_beneficiario_ativo) AS ativos
    FROM fato_beneficiarios f
    JOIN dim_tempo t     ON t.tempo_sk = f.tempo_sk
    JOIN dim_operadora o ON o.operadora_sk = f.operadora_sk
    GROUP BY o.nm_razao_social, t.ano_mes
),
extremos AS (
    SELECT MIN(ano_mes) AS primeira, MAX(ano_mes) AS ultima
    FROM por_operadora
)
SELECT ini.nm_razao_social,
       ini.ativos                                   AS ativos_inicial,
       fim.ativos                                   AS ativos_final,
       fim.ativos - ini.ativos                      AS variacao,
       ROUND(100.0 * (fim.ativos - ini.ativos)
             / NULLIF(ini.ativos, 0), 2)            AS variacao_pct
FROM por_operadora ini
JOIN extremos e         ON ini.ano_mes = e.primeira
JOIN por_operadora fim  ON fim.nm_razao_social = ini.nm_razao_social
                       AND fim.ano_mes = e.ultima
ORDER BY variacao DESC
LIMIT 10;

-- Q5b. Variação mês a mês do total de ativos (LAG)
WITH total AS (
    SELECT t.ano_mes, SUM(f.qt_beneficiario_ativo) AS ativos
    FROM fato_beneficiarios f
    JOIN dim_tempo t ON t.tempo_sk = f.tempo_sk
    GROUP BY t.ano_mes
)
SELECT ano_mes,
       ativos,
       ativos - LAG(ativos) OVER (ORDER BY ano_mes) AS variacao_mes_anterior
FROM total
ORDER BY ano_mes;

-- ---------------------------------------------------------------------
-- Q6. Qual é a operadora líder (mais beneficiários ativos) em cada
--     município na competência mais recente, e qual sua participação?
-- ---------------------------------------------------------------------
WITH ultima AS (
    SELECT MAX(t.ano_mes) AS ano_mes
    FROM fato_beneficiarios f
    JOIN dim_tempo t ON t.tempo_sk = f.tempo_sk
),
por_municipio_operadora AS (
    SELECT l.cd_municipio,
           l.nm_municipio,
           o.nm_razao_social,
           SUM(f.qt_beneficiario_ativo) AS ativos
    FROM fato_beneficiarios f
    JOIN dim_tempo t       ON t.tempo_sk = f.tempo_sk
    JOIN dim_operadora o   ON o.operadora_sk = f.operadora_sk
    JOIN dim_localidade l  ON l.localidade_sk = f.localidade_sk
    JOIN ultima u          ON u.ano_mes = t.ano_mes
    GROUP BY l.cd_municipio, l.nm_municipio, o.nm_razao_social
),
ranqueado AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY cd_municipio
                              ORDER BY ativos DESC, nm_razao_social) AS posicao,
           SUM(ativos)  OVER (PARTITION BY cd_municipio)             AS total_municipio
    FROM por_municipio_operadora
)
SELECT nm_municipio,
       nm_razao_social AS operadora_lider,
       ativos,
       total_municipio,
       ROUND(100.0 * ativos / NULLIF(total_municipio, 0), 1) AS participacao_pct
FROM ranqueado
WHERE posicao = 1
ORDER BY total_municipio DESC;

-- ---------------------------------------------------------------------
-- Q7. Como os beneficiários ativos se distribuem por tipo de contratação
--     e segmentação do plano na competência mais recente?
-- ---------------------------------------------------------------------
WITH ultima AS (
    SELECT MAX(t.ano_mes) AS ano_mes
    FROM fato_beneficiarios f
    JOIN dim_tempo t ON t.tempo_sk = f.tempo_sk
)
SELECT p.de_contratacao_plano,
       p.de_segmentacao_plano,
       SUM(f.qt_beneficiario_ativo) AS ativos,
       ROUND(100.0 * SUM(f.qt_beneficiario_ativo)
             / SUM(SUM(f.qt_beneficiario_ativo)) OVER (), 2) AS participacao_pct
FROM fato_beneficiarios f
JOIN dim_tempo t ON t.tempo_sk = f.tempo_sk
JOIN dim_plano p ON p.plano_sk = f.plano_sk
JOIN ultima u    ON u.ano_mes = t.ano_mes
GROUP BY p.de_contratacao_plano, p.de_segmentacao_plano
ORDER BY ativos DESC;