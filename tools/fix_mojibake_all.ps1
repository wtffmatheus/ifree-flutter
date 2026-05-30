param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
  Write-Host "Python nao encontrado no PATH. Rode diretamente pelo Python instalado ou instale Python." -ForegroundColor Red
  exit 1
}

python .\tools\fix_mojibake_all.py $Root
