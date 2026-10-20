from pathlib import Path

from db import get_connection
from extract import RAW_DIR


STAGING_COLUMNS = [
    "id_cmpt_movel",
    "cd_operadora",
    "nm_razao_social",
    "nr_cnpj",
    "modalidade_operadora",
    "sg_uf",
    "cd_municipio",
    "nm_municipio",
    "tp_sexo",
    "de_faixa_etaria",
    "de_faixa_etaria_reaj",
    "cd_plano",
    "tp_vigencia_plano",
    "de_contratacao_plano",
    "de_segmentacao_plano",
    "de_abrg_geografica_plano",
    "cobertura_assist_plan",
    "tipo_vinculo",
    "qt_beneficiario_ativo",
    "qt_beneficiario_aderido",
    "qt_beneficiario_cancelado",
    "dt_carga",
]

COPY_SQL = f"""
    COPY stg_beneficiarios ({", ".join(STAGING_COLUMNS)})
    FROM STDIN
    WITH (FORMAT csv, HEADER true, DELIMITER ';', ENCODING 'UTF8')
"""


def load_staging(csv_path: Path) -> int:
    """Carrega o CSV cru em stg_beneficiarios e devolve o total de linhas."""

    print(f"Iniciando carga no staging: {csv_path.name}")

    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                "DELETE FROM stg_beneficiarios WHERE arquivo_origem = %s",
                (csv_path.name,),
            )

            with cursor.copy(COPY_SQL) as copy:
                with open(csv_path, "rb") as file:
                    while chunk := file.read(1024 * 1024):
                        copy.write(chunk)

            cursor.execute(
                "UPDATE stg_beneficiarios SET arquivo_origem = %s "
                "WHERE arquivo_origem IS NULL",
                (csv_path.name,),
            )

            cursor.execute(
                "SELECT count(*) FROM stg_beneficiarios WHERE arquivo_origem = %s",
                (csv_path.name,),
            )
            total = cursor.fetchone()[0]

    print(f"Linhas carregadas no staging: {total}")
    return total


if __name__ == "__main__":
    load_staging(RAW_DIR / "202608" / "pda-024-icb-ES-2026_08.csv")