-- 04_qualidade.sql
-- Verificações de qualidade do DW. Rodar depois de cada carga.
-- Cada resultado termina em OK ou FALHA.

-- 1) Reconciliação por competência: staging x fato (linhas)
WITH stg AS (
    SELECT id_cmpt_movel AS ano_mes, count(*) AS linhas
    FROM stg_beneficiarios
    GROUP BY id_cmpt_movel
),
fat AS (
    SELECT t.ano_mes, count(*) AS linhas
    FROM fato_beneficiarios f
    JOIN dim_tempo t ON t.tempo_sk = f.tempo_sk
    GROUP BY t.ano_mes
)
SELECT s.ano_mes,
       s.linhas                AS linhas_staging,
       COALESCE(f.linhas, 0)   AS linhas_fato,
       CASE WHEN s.linhas = COALESCE(f.linhas, 0) THEN 'OK' ELSE 'FALHA' END AS status
FROM stg s
LEFT JOIN fat f ON f.ano_mes = s.ano_mes
ORDER BY s.ano_mes;

-- 2) Chaves órfãs: linhas do staging que não encontram dimensão
SELECT count(*)                                         AS linhas_staging,
       count(*) FILTER (WHERE t.tempo_sk      IS NULL)  AS sem_tempo,
       count(*) FILTER (WHERE o.operadora_sk  IS NULL)  AS sem_operadora,
       count(*) FILTER (WHERE p.plano_sk      IS NULL)  AS sem_plano,
       count(*) FILTER (WHERE l.localidade_sk IS NULL)  AS sem_localidade,
       count(*) FILTER (WHERE pe.perfil_sk    IS NULL)  AS sem_perfil
FROM stg_beneficiarios s
LEFT JOIN dim_tempo t       ON t.ano_mes = s.id_cmpt_movel
LEFT JOIN dim_operadora o   ON o.cd_operadora = s.cd_operadora
LEFT JOIN dim_plano p       ON p.cd_operadora = s.cd_operadora
                           AND p.cd_plano = s.cd_plano
                           AND p.tp_vigencia_plano = s.tp_vigencia_plano
                           AND p.de_contratacao_plano = s.de_contratacao_plano
                           AND p.de_segmentacao_plano = s.de_segmentacao_plano
                           AND p.de_abrg_geografica_plano = s.de_abrg_geografica_plano
                           AND p.cobertura_assist_plan = s.cobertura_assist_plan
LEFT JOIN dim_localidade l  ON l.cd_municipio = s.cd_municipio
LEFT JOIN dim_perfil pe     ON pe.tp_sexo = s.tp_sexo
                           AND pe.de_faixa_etaria = s.de_faixa_etaria
                           AND pe.de_faixa_etaria_reaj = s.de_faixa_etaria_reaj
                           AND pe.tipo_vinculo = s.tipo_vinculo;

-- 3) Consistência interna do modelo
SELECT verificacao, qtd,
       CASE WHEN qtd = 0 THEN 'OK' ELSE 'FALHA' END AS status
FROM (
    SELECT 'dim_operadora sem nenhuma linha na fato' AS verificacao, count(*) AS qtd
    FROM dim_operadora o
    WHERE NOT EXISTS (SELECT 1 FROM fato_beneficiarios f WHERE f.operadora_sk = o.operadora_sk)
    UNION ALL
    SELECT 'dim_plano sem nenhuma linha na fato', count(*)
    FROM dim_plano p
    WHERE NOT EXISTS (SELECT 1 FROM fato_beneficiarios f WHERE f.plano_sk = p.plano_sk)
    UNION ALL
    SELECT 'dim_localidade sem nenhuma linha na fato', count(*)
    FROM dim_localidade l
    WHERE NOT EXISTS (SELECT 1 FROM fato_beneficiarios f WHERE f.localidade_sk = l.localidade_sk)
    UNION ALL
    SELECT 'dim_perfil sem nenhuma linha na fato', count(*)
    FROM dim_perfil pe
    WHERE NOT EXISTS (SELECT 1 FROM fato_beneficiarios f WHERE f.perfil_sk = pe.perfil_sk)
    UNION ALL
    SELECT 'operadora da fato diferente da operadora do plano', count(*)
    FROM fato_beneficiarios f
    JOIN dim_operadora o ON o.operadora_sk = f.operadora_sk
    JOIN dim_plano p     ON p.plano_sk = f.plano_sk
    WHERE o.cd_operadora <> p.cd_operadora
    UNION ALL
    SELECT 'faixa etária nova (ordem 99 além de Informada Incorr)', count(*)
    FROM dim_perfil
    WHERE faixa_etaria_ordem = 99
      AND de_faixa_etaria NOT LIKE 'Informada Incorr%'
) v;

-- 4) Reconciliação das medidas: soma no staging x soma na fato, por competência
WITH stg AS (
    SELECT id_cmpt_movel AS ano_mes,
           sum(qt_beneficiario_ativo::integer)     AS ativos,
           sum(qt_beneficiario_aderido::integer)   AS aderidos,
           sum(qt_beneficiario_cancelado::integer) AS cancelados
    FROM stg_beneficiarios
    GROUP BY id_cmpt_movel
),
fat AS (
    SELECT t.ano_mes,
           sum(f.qt_beneficiario_ativo)     AS ativos,
           sum(f.qt_beneficiario_aderido)   AS aderidos,
           sum(f.qt_beneficiario_cancelado) AS cancelados
    FROM fato_beneficiarios f
    JOIN dim_tempo t ON t.tempo_sk = f.tempo_sk
    GROUP BY t.ano_mes
)
SELECT s.ano_mes,
       s.ativos    AS ativos_staging,    f.ativos    AS ativos_fato,
       s.aderidos  AS aderidos_staging,  f.aderidos  AS aderidos_fato,
       s.cancelados AS cancelados_staging, f.cancelados AS cancelados_fato,
       CASE WHEN s.ativos     = f.ativos
             AND s.aderidos   = f.aderidos
             AND s.cancelados = f.cancelados
            THEN 'OK' ELSE 'FALHA' END AS status
FROM stg s
LEFT JOIN fat f ON f.ano_mes = s.ano_mes
ORDER BY s.ano_mes;

-- 5) Medidas inválidas na fato: valores negativos
SELECT count(*) AS linhas_com_medida_negativa,
       CASE WHEN count(*) = 0 THEN 'OK' ELSE 'FALHA' END AS status
FROM fato_beneficiarios
WHERE qt_beneficiario_ativo < 0
   OR qt_beneficiario_aderido < 0
   OR qt_beneficiario_cancelado < 0;