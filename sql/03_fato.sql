BEGIN;

-- Recarga segura: apaga as competências presentes no staging antes de inserir
DELETE FROM fato_beneficiarios f
USING dim_tempo t
WHERE f.tempo_sk = t.tempo_sk
  AND t.ano_mes IN (SELECT DISTINCT id_cmpt_movel FROM stg_beneficiarios);

INSERT INTO fato_beneficiarios (
    tempo_sk, operadora_sk, plano_sk, localidade_sk, perfil_sk,
    qt_beneficiario_ativo, qt_beneficiario_aderido, qt_beneficiario_cancelado
)
SELECT t.tempo_sk,
       o.operadora_sk,
       p.plano_sk,
       l.localidade_sk,
       pe.perfil_sk,
       s.qt_beneficiario_ativo::integer,
       s.qt_beneficiario_aderido::integer,
       s.qt_beneficiario_cancelado::integer
FROM stg_beneficiarios s
JOIN dim_tempo t       ON t.ano_mes = s.id_cmpt_movel
JOIN dim_operadora o   ON o.cd_operadora = s.cd_operadora
JOIN dim_plano p       ON p.cd_operadora = s.cd_operadora
                      AND p.cd_plano = s.cd_plano
                      AND p.tp_vigencia_plano = s.tp_vigencia_plano
                      AND p.de_contratacao_plano = s.de_contratacao_plano
                      AND p.de_segmentacao_plano = s.de_segmentacao_plano
                      AND p.de_abrg_geografica_plano = s.de_abrg_geografica_plano
                      AND p.cobertura_assist_plan = s.cobertura_assist_plan
JOIN dim_localidade l  ON l.cd_municipio = s.cd_municipio
JOIN dim_perfil pe     ON pe.tp_sexo = s.tp_sexo
                      AND pe.de_faixa_etaria = s.de_faixa_etaria
                      AND pe.de_faixa_etaria_reaj = s.de_faixa_etaria_reaj
                      AND pe.tipo_vinculo = s.tipo_vinculo;

COMMIT;