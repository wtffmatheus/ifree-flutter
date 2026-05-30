from __future__ import annotations

from pathlib import Path
from datetime import datetime
import shutil
import sys

PROJECT_ROOT = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path.cwd().resolve()

if not (PROJECT_ROOT / "pubspec.yaml").exists():
    print("\nERRO: rode este script na RAIZ do projeto Flutter, onde fica o pubspec.yaml.")
    print(r'Exemplo: cd "C:\Users\userm\OneDrive\Área de Trabalho\novoIfree\ifree_app"')
    print(r"Depois: python tools\fix_mojibake_all.py")
    raise SystemExit(1)

BACKUP_ROOT = PROJECT_ROOT / f"backup_mojibake_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
BACKUP_ROOT.mkdir(parents=True, exist_ok=True)

EXTENSIONS = {
    ".dart",
    ".md",
    ".txt",
    ".yaml",
    ".yml",
    ".json",
    ".html",
}

BAD_MARKERS = ("Ã", "Â", "â€", "â€“", "â€”", "�")

MANUAL_REPLACEMENTS = {
    "AvaliaÃ§Ã£o": "Avaliação",
    "avaliaÃ§Ã£o": "avaliação",
    "AvaliaÃ§Ãµes": "Avaliações",
    "avaliaÃ§Ãµes": "avaliações",
    "DisponÃ­vel": "Disponível",
    "disponÃ­vel": "disponível",
    "IndisponÃ­vel": "Indisponível",
    "indisponÃ­vel": "indisponível",
    "NÃ£o": "Não",
    "nÃ£o": "não",
    "VocÃª": "Você",
    "vocÃª": "você",
    "VocÃŠ": "Você",
    "InformaÃ§Ãµes": "Informações",
    "informaÃ§Ãµes": "informações",
    "DescriÃ§Ã£o": "Descrição",
    "descriÃ§Ã£o": "descrição",
    "AlteraÃ§Ãµes": "Alterações",
    "alteraÃ§Ãµes": "alterações",
    "PrÃ³xima": "Próxima",
    "prÃ³xima": "próxima",
    "PrÃ³ximo": "Próximo",
    "prÃ³ximo": "próximo",
    "DiÃ¡ria": "Diária",
    "diÃ¡ria": "diária",
    "GarÃ§om": "Garçom",
    "garÃ§om": "garçom",
    "NÃºmero": "Número",
    "nÃºmero": "número",
    "possÃ­vel": "possível",
    "PossÃ­vel": "Possível",
    "E-mail nÃ£o informado": "E-mail não informado",
    "Em anÃ¡lise": "Em análise",
    "anÃ¡lise": "análise",
    "UsuÃ¡rio": "Usuário",
    "usuÃ¡rio": "usuário",
    "UsuÃ¡rios": "Usuários",
    "usuÃ¡rios": "usuários",
    "AprovaÃ§Ã£o": "Aprovação",
    "aprovaÃ§Ã£o": "aprovação",
    "NotificaÃ§Ãµes": "Notificações",
    "notificaÃ§Ãµes": "notificações",
    "coraÃ§Ã£o": "coração",
    "CoraÃ§Ã£o": "Coração",
    "Ã¡": "á",
    "Ã ": "à",
    "Ã¢": "â",
    "Ã£": "ã",
    "Ã©": "é",
    "Ãª": "ê",
    "Ã­": "í",
    "Ã³": "ó",
    "Ã´": "ô",
    "Ãµ": "õ",
    "Ãº": "ú",
    "Ã¼": "ü",
    "Ã§": "ç",
    "Ã": "Á",
    "Ã‰": "É",
    "ÃŠ": "Ê",
    "Ã": "Í",
    "Ã“": "Ó",
    "Ã”": "Ô",
    "Ã•": "Õ",
    "Ãš": "Ú",
    "Ã‡": "Ç",
    "Â°": "°",
    "Âª": "ª",
    "Âº": "º",
    "â€“": "–",
    "â€”": "—",
    "â€˜": "‘",
    "â€™": "’",
    "â€œ": "“",
    "â€": "”",
    "â€¦": "…",
}

def looks_bad(text: str) -> bool:
    return any(marker in text for marker in BAD_MARKERS)

def try_repair_latin1_utf8(text: str) -> str:
    # Corrige o caso clássico:
    # "AvaliaÃ§Ã£o" -> bytes latin1 -> decode utf-8 -> "Avaliação"
    try:
        repaired = text.encode("latin1").decode("utf-8")
    except UnicodeError:
        return text

    # Só aceita se realmente reduzir caracteres típicos de mojibake.
    old_bad = sum(text.count(marker) for marker in BAD_MARKERS)
    new_bad = sum(repaired.count(marker) for marker in BAD_MARKERS)

    if new_bad < old_bad:
        return repaired

    return text

def repair_text(text: str) -> str:
    original = text

    # 1) tentativa geral
    if looks_bad(text):
        text = try_repair_latin1_utf8(text)

    # 2) fallback por substituições
    for bad, good in MANUAL_REPLACEMENTS.items():
        text = text.replace(bad, good)

    # 3) uma segunda passada resolve casos duplamente corrompidos
    if looks_bad(text):
        text2 = try_repair_latin1_utf8(text)
        for bad, good in MANUAL_REPLACEMENTS.items():
            text2 = text2.replace(bad, good)
        text = text2

    return text

def should_skip(path: Path) -> bool:
    parts = set(path.parts)
    return (
        "build" in parts
        or ".dart_tool" in parts
        or ".git" in parts
        or any(part.startswith("backup_mojibake_") for part in parts)
        or any(part.startswith("backup_textos_ptbr_") for part in parts)
    )

changed_files: list[Path] = []

for path in PROJECT_ROOT.rglob("*"):
    if not path.is_file():
        continue

    if should_skip(path):
        continue

    if path.suffix.lower() not in EXTENSIONS:
        continue

    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        try:
            text = path.read_text(encoding="latin1")
        except UnicodeDecodeError:
            continue

    fixed = repair_text(text)

    if fixed != text:
        relative = path.relative_to(PROJECT_ROOT)
        backup_path = BACKUP_ROOT / relative
        backup_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, backup_path)

        path.write_text(fixed, encoding="utf-8", newline="")
        changed_files.append(relative)

print("\nArquivos corrigidos:")
if not changed_files:
    print("Nenhum arquivo precisava de correção.")
else:
    for item in changed_files:
        print(f"- {item}")

print(f"\nBackup criado em: {BACKUP_ROOT}")
print("\nAgora rode:")
print("dart format lib")
print("flutter analyze")
print("flutter run -d chrome --web-port 5000")
