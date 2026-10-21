-- dim_tempo: calendário mensal gerado, sem depender do staging
INSERT INTO dim_tempo (ano_mes, competencia, ano, trimestre, mes)
SELECT to_char(d, 'YYYY-MM'),
       d::date,
       EXTRACT(YEAR FROM d)::smallint,
       EXTRACT(QUARTER FROM d)::smallint,
       EXTRACT(MONTH FROM d)::smallint
FROM generate_series(
         TIMESTAMP '2021-05-01',
         TIMESTAMP '2030-12-01',
         INTERVAL '1 month'
     ) AS d
ON CONFLICT DO NOTHING;

-- dim_operadora: uma linha por operadora (versão mais recente no staging)
INSERT INTO dim_operadora (cd_operadora, nm_razao_social, nr_cnpj, modalidade_operadora)
SELECT DISTINCT ON (cd_operadora)
       cd_operadora, nm_razao_social, nr_cnpj, modalidade_operadora
FROM stg_beneficiarios
ORDER BY cd_operadora, id_cmpt_movel DESC
ON CONFLICT DO NOTHING;

-- dim_plano: uma linha por combinação das 7 colunas que definem o plano
INSERT INTO dim_plano (
    cd_operadora, cd_plano, tp_vigencia_plano, de_contratacao_plano,
    de_segmentacao_plano, de_abrg_geografica_plano, cobertura_assist_plan
)
SELECT DISTINCT
       cd_operadora, cd_plano, tp_vigencia_plano, de_contratacao_plano,
       de_segmentacao_plano, de_abrg_geografica_plano, cobertura_assist_plan
FROM stg_beneficiarios
ON CONFLICT DO NOTHING;

-- dim_localidade: uma linha por município (versão mais recente no staging)
INSERT INTO dim_localidade (sg_uf, cd_municipio, nm_municipio)
SELECT DISTINCT ON (cd_municipio)
       sg_uf, cd_municipio, nm_municipio
FROM stg_beneficiarios
ORDER BY cd_municipio, id_cmpt_movel DESC
ON CONFLICT DO NOTHING;

-- dim_perfil: combinações de sexo, faixas etárias e vínculo, com ordem da faixa
INSERT INTO dim_perfil (
    tp_sexo, de_faixa_etaria, faixa_etaria_ordem,
    de_faixa_etaria_reaj, tipo_vinculo
)
SELECT DISTINCT
       tp_sexo,
       de_faixa_etaria,
       CASE de_faixa_etaria
            WHEN 'Menos de 1 ano'  THEN 1
            WHEN '1 a 4 anos'      THEN 2
            WHEN '5 a 9 anos'      THEN 3
            WHEN '10 a 14 anos'    THEN 4
            WHEN '15 a 17 anos'    THEN 5
            WHEN '18 a 19 anos'    THEN 6
            WHEN '20 a 24 anos'    THEN 7
            WHEN '25 a 29 anos'    THEN 8
            WHEN '30 a 34 anos'    THEN 9
            WHEN '35 a 39 anos'    THEN 10
            WHEN '40 a 44 anos'    THEN 11
            WHEN '45 a 49 anos'    THEN 12
            WHEN '50 a 54 anos'    THEN 13
            WHEN '55 a 59 anos'    THEN 14
            WHEN '60 a 64 anos'    THEN 15
            WHEN '65 a 69 anos'    THEN 16
            WHEN '70 a 74 anos'    THEN 17
            WHEN '75 a 79 anos'    THEN 18
            WHEN '80 anos ou mais' THEN 19
            ELSE 99
       END,
       de_faixa_etaria_reaj,
       tipo_vinculo
FROM stg_beneficiarios
ON CONFLICT DO NOTHING;