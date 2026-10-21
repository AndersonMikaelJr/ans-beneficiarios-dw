from pathlib import Path

from db import get_connection
from extract import RAW_DIR, extract
from load_staging import load_staging


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SQL_DIR = PROJECT_ROOT / "sql"

UF = "ES"
COMPETENCIAS = ["202606", "202607", "202608"]


def run_sql_file(path: Path) -> None:
    """Executa um arquivo .sql inteiro no banco."""

    print(f"Executando {path.name}...")

    sql = path.read_text(encoding="utf-8")

    with get_connection(autocommit=True) as connection:
        connection.execute(sql)


def main() -> None:
    """Executa o pipeline: extração, staging, dimensões e fato."""

    print("=== Pipeline ANS: beneficiários ===")

    for competencia in COMPETENCIAS:
        extracted = extract(UF, competencia, RAW_DIR)

        for path in extracted:
            if path.suffix.lower() == ".csv":
                load_staging(path)

    run_sql_file(SQL_DIR / "02_dimensoes.sql")
    run_sql_file(SQL_DIR / "03_fato.sql")

    print("=== Pipeline concluído ===")


if __name__ == "__main__":
    main()