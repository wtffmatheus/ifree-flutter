from pathlib import Path
from datetime import datetime
import shutil
import sys

root = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path.cwd().resolve()

if not (root / "pubspec.yaml").exists():
    print("Rode este script na raiz do projeto Flutter.")
    raise SystemExit(1)

backup = root / f"backup_restaurant_textos_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
backup.mkdir(parents=True, exist_ok=True)

replacements = {
    "GarÃ§om": "Garçom",
    "garÃ§om": "garçom",
    "InÃ­cio": "Início",
    "CriaÃ§Ã£o": "Criação",
    "criaÃ§Ã£o": "criação",
    "NotificaÃ§Ãµes": "Notificações",
    "notificaÃ§Ãµes": "notificações",
    "ConfiguraÃ§Ãµes": "Configurações",
    "configuraÃ§Ãµes": "configurações",
    "InformaÃ§Ãµes": "Informações",
    "informaÃ§Ãµes": "informações",
    "DescriÃ§Ã£o": "Descrição",
    "descriÃ§Ã£o": "descrição",
    "AprovaÃ§Ãµes": "Aprovações",
    "aprovaÃ§Ãµes": "aprovações",
    "CandidataÃ§Ãµes": "Candidaturas",
    "candidataÃ§Ãµes": "candidaturas",
    "AÃ§Ãµes": "Ações",
    "aÃ§Ãµes": "ações",
    "NÃ£o": "Não",
    "nÃ£o": "não",
    "VocÃª": "Você",
    "vocÃª": "você",
    "OlÃ¡": "Olá",
    "olÃ¡": "olá",
    "PrÃ³xima": "Próxima",
    "prÃ³xima": "próxima",
    "diÃ¡ria": "diária",
    "DiÃ¡ria": "Diária",
    "DisponÃ­vel": "Disponível",
    "disponÃ­vel": "disponível",
    "possÃ­vel": "possível",
    "PossÃ­vel": "Possível",
    "AnÃ¡lise": "Análise",
    "anÃ¡lise": "análise",
    "PublicaÃ§Ã£o": "Publicação",
    "publicaÃ§Ã£o": "publicação",
    "Restaurante": "Restaurante",
    "Freelancer": "Freelancer",
}

extensions = {".dart", ".md", ".txt", ".yaml", ".yml", ".json", ".html"}
changed = []

for path in root.rglob("*"):
    if not path.is_file() or path.suffix.lower() not in extensions:
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

    # Try automatic repair safely twice.
    for _ in range(2):
        if "Ã" not in fixed and "Â" not in fixed:
            break
        try:
            candidate = fixed.encode("latin1").decode("utf-8")
        except UnicodeError:
            break
        if candidate.count("Ã") + candidate.count("Â") <= fixed.count("Ã") + fixed.count("Â"):
            fixed = candidate
        else:
            break

    for bad, good in replacements.items():
        fixed = fixed.replace(bad, good)

    if fixed != text:
        rel = path.relative_to(root)
        target = backup / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, target)
        path.write_text(fixed, encoding="utf-8")
        changed.append(rel)

print("Arquivos corrigidos:")
for item in changed:
    print(f"- {item}")
if not changed:
    print("Nenhum arquivo alterado.")
print(f"Backup: {backup}")
