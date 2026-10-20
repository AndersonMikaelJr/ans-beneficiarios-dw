import zipfile
from pathlib import Path

import requests


BASE_URL = (
    "https://dadosabertos.ans.gov.br/FTP/PDA/"
    "informacoes_consolidadas_de_beneficiarios-024"
)

PROJECT_ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = PROJECT_ROOT / "data" / "raw"


def build_zip_name(uf: str, competencia: str) -> str:
    """Monta o nome do ZIP, por exemplo pda-024-icb-ES-2026_08.zip."""

    ano, mes = competencia[:4], competencia[4:]
    return f"pda-024-icb-{uf}-{ano}_{mes}.zip"


def build_url(uf: str, competencia: str) -> str:
    """Monta a URL do ZIP de um estado em uma competência (AAAAMM)."""

    return f"{BASE_URL}/{competencia}/{build_zip_name(uf, competencia)}"


def extract(uf: str, competencia: str, destination_dir: Path) -> list[Path]:
    """Baixa o ZIP do estado e descompacta em data/raw/AAAAMM."""

    print(f"Iniciando extração: {uf} {competencia}")

    url = build_url(uf, competencia)
    competencia_dir = destination_dir / competencia
    competencia_dir.mkdir(parents=True, exist_ok=True)

    zip_path = competencia_dir / build_zip_name(uf, competencia)

    try:
        with requests.get(url, timeout=60, stream=True) as response:
            response.raise_for_status()
            with open(zip_path, "wb") as file:
                for chunk in response.iter_content(chunk_size=1024 * 1024):
                    file.write(chunk)
    except requests.RequestException as error:
        raise RuntimeError(f"Falha ao baixar {url}: {error}") from error

    with zipfile.ZipFile(zip_path) as zip_file:
        zip_file.extractall(competencia_dir)
        names = zip_file.namelist()

    extracted = [competencia_dir / name for name in names]

    print(f"ZIP salvo em: {zip_path}")
    for path in extracted:
        print(f"Arquivo extraído: {path}")

    return extracted


if __name__ == "__main__":
    extract("ES", "202608", RAW_DIR)