from pathlib import Path
from datetime import datetime
import shutil
import sys

root = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path.cwd().resolve()

if not (root / "pubspec.yaml").exists():
    print("Rode este script na raiz do projeto Flutter.")
    raise SystemExit(1)

backup = root / f"backup_textos_v4_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
backup.mkdir(parents=True, exist_ok=True)

replacements = {
    "OlÃƒÂ¡": "Olá",
    "OlÃ¡": "Olá",
    "rÃƒÂ¡pidas": "rápidas",
    "rÃ¡pidas": "rápidas",
    "aprovaÃƒÂ§ÃƒÂµes": "aprovações",
    "aprovaÃ§Ãµes": "aprovações",
    "AvaliaÃƒÂ§ÃƒÂ£o": "Avaliação",
    "AvaliaÃ§Ã£o": "Avaliação",
    "DisponÃƒÂ­vel": "Disponível",
    "DisponÃ­vel": "Disponível",
    "NÃƒÂ£o": "Não",
    "NÃ£o": "Não",
    "VocÃƒÂª": "Você",
    "VocÃª": "Você",
    "GarÃƒÂ§om": "Garçom",
    "GarÃ§om": "Garçom",
    "PrÃƒÂ³xima": "Próxima",
    "PrÃ³xima": "Próxima",
    "diÃƒÂ¡ria": "diária",
    "diÃ¡ria": "diária",
    "InformaÃƒÂ§ÃƒÂµes": "Informações",
    "InformaÃ§Ãµes": "Informações",
    "DescriÃƒÂ§ÃƒÂ£o": "Descrição",
    "DescriÃ§Ã£o": "Descrição",
    "CandidataÃƒÂ§ÃƒÂµes": "Candidaturas",
    "CandidataÃ§Ãµes": "Candidaturas",
    "anÃƒÂ¡lise": "análise",
    "anÃ¡lise": "análise",
    "NotificaÃƒÂ§ÃƒÂµes": "Notificações",
    "NotificaÃ§Ãµes": "Notificações",
}

extensions = {".dart", ".md", ".txt", ".yaml", ".yml", ".json", ".html"}

changed = []
for path in root.rglob("*"):
    if not path.is_file():
        continue
    if path.suffix.lower() not in extensions:
        continue
    if any(part in {"build", ".dart_tool", ".git"} for part in path.parts):
        continue
    if any(part.startswith("backup_") for part in path.parts):
        continue

    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        continue

    fixed = text
    for bad, good in replacements.items():
        fixed = fixed.replace(bad, good)

    # Tenta duas passadas seguras em linhas com mojibake.
    lines = []
    for line in fixed.splitlines(keepends=True):
        repaired = line
        for _ in range(2):
            if "Ã" not in repaired and "Â" not in repaired:
                break
            try:
                candidate = repaired.encode("latin1").decode("utf-8")
            except UnicodeError:
                break
            if candidate.count("Ã") + candidate.count("Â") <= repaired.count("Ã") + repaired.count("Â"):
                repaired = candidate
            else:
                break
        lines.append(repaired)
    fixed = "".join(lines)

    if fixed != text:
        rel = path.relative_to(root)
        bpath = backup / rel
        bpath.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, bpath)
        path.write_text(fixed, encoding="utf-8")
        changed.append(rel)

print("Arquivos corrigidos:")
if changed:
    for item in changed:
        print(f"- {item}")
else:
    print("Nenhum arquivo alterado.")

print(f"Backup: {backup}")
print("Agora rode: dart format lib && flutter analyze")
