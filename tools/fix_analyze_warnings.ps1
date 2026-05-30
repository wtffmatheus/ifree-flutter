param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"

$projectRoot = Resolve-Path $Root

if (-not (Test-Path (Join-Path $projectRoot "pubspec.yaml"))) {
  Write-Host ""
  Write-Host "ERRO: rode este script na RAIZ do projeto Flutter, onde fica o pubspec.yaml." -ForegroundColor Red
  Write-Host "Exemplo:"
  Write-Host "cd `"C:\Users\userm\OneDrive\Área de Trabalho\novoIfree\ifree_app`""
  Write-Host ".\tools\fix_analyze_warnings.ps1"
  exit 1
}

Write-Host ""
Write-Host "Projeto encontrado em: $projectRoot" -ForegroundColor Cyan

$backupRoot = Join-Path $projectRoot ("backup_warning_fix_" + (Get-Date -Format "yyyyMMdd_HHmmss"))
New-Item -ItemType Directory -Path $backupRoot | Out-Null

Write-Host "Backup será salvo em: $backupRoot" -ForegroundColor Yellow

$dartFiles = Get-ChildItem -Path $projectRoot -Recurse -Filter "*.dart" |
  Where-Object {
    $_.FullName -notmatch "\\build\\" -and
    $_.FullName -notmatch "\\.dart_tool\\" -and
    $_.FullName -notmatch "\\windows\\flutter\\ephemeral\\" -and
    $_.FullName -notmatch "\\linux\\flutter\\ephemeral\\" -and
    $_.FullName -notmatch "\\macos\\Flutter\\ephemeral\\"
  }

foreach ($file in $dartFiles) {
  $relative = Resolve-Path -Path $file.FullName -Relative
  $relativeClean = $relative.TrimStart(".\").TrimStart("./")
  $backupPath = Join-Path $backupRoot $relativeClean
  $backupDir = Split-Path $backupPath -Parent

  if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
  }

  Copy-Item $file.FullName $backupPath -Force

  $content = Get-Content $file.FullName -Raw

  # 1) Remove imports duplicados, mantendo a primeira ocorrência.
  $lines = $content -split "`r?`n"
  $seenImports = @{}
  $newLines = New-Object System.Collections.Generic.List[string]

  foreach ($line in $lines) {
    $trimmed = $line.Trim()

    if ($trimmed.StartsWith("import ")) {
      if ($seenImports.ContainsKey($trimmed)) {
        continue
      }

      $seenImports[$trimmed] = $true
    }

    $newLines.Add($line)
  }

  $content = $newLines -join "`r`n"

  # 2) Troca simples de withOpacity(...) para withValues(alpha: ...).
  # Funciona para casos simples como:
  # Colors.black.withOpacity(0.2)
  # colorScheme.primary.withOpacity(0.12)
  $content = [regex]::Replace(
    $content,
    "\.withOpacity\(([^()]*)\)",
    ".withValues(alpha: `$1)"
  )

  Set-Content -Path $file.FullName -Value $content -Encoding UTF8
}

Write-Host ""
Write-Host "Rodando dart fix --apply..." -ForegroundColor Cyan
dart fix --apply

Write-Host ""
Write-Host "Rodando flutter format..." -ForegroundColor Cyan
dart format .

Write-Host ""
Write-Host "Rodando flutter analyze..." -ForegroundColor Cyan
flutter analyze

Write-Host ""
Write-Host "Concluído." -ForegroundColor Green
Write-Host "Se sobrar warning de desiredAccuracy ou value deprecated, mande o log, porque esses precisam de ajuste manual seguro."
Write-Host "Backup criado em: $backupRoot"
