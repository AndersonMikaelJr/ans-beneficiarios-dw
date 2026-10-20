-- Staging (bronze): CSV cru, tudo como texto.
CREATE TABLE stg_beneficiarios (
    id_cmpt_movel             TEXT,
    cd_operadora              TEXT,
    nm_razao_social           TEXT,
    nr_cnpj                   TEXT,
    modalidade_operadora      TEXT,
    sg_uf                     TEXT,
    cd_municipio              TEXT,
    nm_municipio              TEXT,
    tp_sexo                   TEXT,
    de_faixa_etaria           TEXT,
    de_faixa_etaria_reaj      TEXT,
    cd_plano                  TEXT,
    tp_vigencia_plano         TEXT,
    de_contratacao_plano      TEXT,
    de_segmentacao_plano      TEXT,
    de_abrg_geografica_plano  TEXT,
    cobertura_assist_plan     TEXT,
    tipo_vinculo              TEXT,
    qt_beneficiario_ativo     TEXT,
    qt_beneficiario_aderido   TEXT,
    qt_beneficiario_cancelado TEXT,
    dt_carga                  TEXT,
    arquivo_origem            TEXT,
    carregado_em              TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Dimensões (gold)
CREATE TABLE dim_tempo (
    tempo_sk     INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ano_mes      CHAR(7)  NOT NULL UNIQUE,
    competencia  DATE     NOT NULL UNIQUE,
    ano          SMALLINT NOT NULL,
    trimestre    SMALLINT NOT NULL,
    mes          SMALLINT NOT NULL
);

CREATE TABLE dim_operadora (
    operadora_sk          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cd_operadora          VARCHAR(10)  NOT NULL UNIQUE,
    nm_razao_social       VARCHAR(255) NOT NULL,
    nr_cnpj               VARCHAR(14)  NOT NULL,
    modalidade_operadora  VARCHAR(100) NOT NULL
);

CREATE TABLE dim_plano (
    plano_sk                  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cd_operadora              VARCHAR(10)  NOT NULL,
    cd_plano                  VARCHAR(50)  NOT NULL,
    tp_vigencia_plano         VARCHAR(10)  NOT NULL,
    de_contratacao_plano      VARCHAR(100) NOT NULL,
    de_segmentacao_plano      VARCHAR(100) NOT NULL,
    de_abrg_geografica_plano  VARCHAR(100) NOT NULL,
    cobertura_assist_plan     VARCHAR(100) NOT NULL,
    UNIQUE (cd_operadora, cd_plano, tp_vigencia_plano, de_contratacao_plano,
            de_segmentacao_plano, de_abrg_geografica_plano, cobertura_assist_plan)
);

CREATE TABLE dim_localidade (
    localidade_sk  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sg_uf          CHAR(2)      NOT NULL,
    cd_municipio   VARCHAR(6)   NOT NULL UNIQUE,
    nm_municipio   VARCHAR(100) NOT NULL
);

CREATE TABLE dim_perfil (
    perfil_sk             INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tp_sexo               CHAR(1)     NOT NULL,
    de_faixa_etaria       VARCHAR(30) NOT NULL,
    faixa_etaria_ordem    SMALLINT    NOT NULL,
    de_faixa_etaria_reaj  VARCHAR(30) NOT NULL,
    tipo_vinculo          VARCHAR(30) NOT NULL,
    UNIQUE (tp_sexo, de_faixa_etaria, de_faixa_etaria_reaj, tipo_vinculo)
);

-- Fato
CREATE TABLE fato_beneficiarios (
    tempo_sk                   INTEGER NOT NULL REFERENCES dim_tempo (tempo_sk),
    operadora_sk               INTEGER NOT NULL REFERENCES dim_operadora (operadora_sk),
    plano_sk                   INTEGER NOT NULL REFERENCES dim_plano (plano_sk),
    localidade_sk              INTEGER NOT NULL REFERENCES dim_localidade (localidade_sk),
    perfil_sk                  INTEGER NOT NULL REFERENCES dim_perfil (perfil_sk),
    qt_beneficiario_ativo      INTEGER NOT NULL,
    qt_beneficiario_aderido    INTEGER NOT NULL,
    qt_beneficiario_cancelado  INTEGER NOT NULL,
    PRIMARY KEY (tempo_sk, operadora_sk, plano_sk, localidade_sk, perfil_sk)
);

CREATE INDEX ix_fato_operadora  ON fato_beneficiarios (operadora_sk);
CREATE INDEX ix_fato_plano      ON fato_beneficiarios (plano_sk);
CREATE INDEX ix_fato_localidade ON fato_beneficiarios (localidade_sk);
CREATE INDEX ix_fato_perfil     ON fato_beneficiarios (perfil_sk);