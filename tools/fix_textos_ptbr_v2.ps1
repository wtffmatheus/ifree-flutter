param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"

$projectRoot = Resolve-Path $Root

if (-not (Test-Path (Join-Path $projectRoot "pubspec.yaml"))) {
  Write-Host ""
  Write-Host "ERRO: rode este script na RAIZ do projeto Flutter, onde fica o pubspec.yaml." -ForegroundColor Red
  Write-Host "Exemplo:"
  Write-Host "cd `"C:\Users\userm\OneDrive\Area de Trabalho\novoIfree\ifree_app`""
  Write-Host ".\tools\fix_textos_ptbr_v2.ps1"
  exit 1
}

Write-Host ""
Write-Host "Corrigindo textos quebrados em: $projectRoot" -ForegroundColor Cyan

$backupRoot = Join-Path $projectRoot ("backup_textos_ptbr_" + (Get-Date -Format "yyyyMMdd_HHmmss"))
New-Item -ItemType Directory -Path $backupRoot | Out-Null

Write-Host "Backup sera salvo em: $backupRoot" -ForegroundColor Yellow

# Lista feita com arrays para evitar erro de hash duplicado/quebrado.
# Mantive somente padroes comuns e seguros.
$replacements = @(
  @("AvaliaÃ§Ã£o", "Avaliação"),
  @("avaliaÃ§Ã£o", "avaliação"),
  @("AvaliaÃ§Ãµes", "Avaliações"),
  @("avaliaÃ§Ãµes", "avaliações"),
  @("DisponÃ­vel", "Disponível"),
  @("disponÃ­vel", "disponível"),
  @("IndisponÃ­vel", "Indisponível"),
  @("indisponÃ­vel", "indisponível"),
  @("NÃ£o", "Não"),
  @("nÃ£o", "não"),
  @("VocÃª", "Você"),
  @("vocÃª", "você"),
  @("InformaÃ§Ãµes", "Informações"),
  @("informaÃ§Ãµes", "informações"),
  @("DescriÃ§Ã£o", "Descrição"),
  @("descriÃ§Ã£o", "descrição"),
  @("AlteraÃ§Ãµes", "Alterações"),
  @("alteraÃ§Ãµes", "alterações"),
  @("PrÃ³xima", "Próxima"),
  @("prÃ³xima", "próxima"),
  @("PrÃ³ximo", "Próximo"),
  @("prÃ³ximo", "próximo"),
  @("DiÃ¡ria", "Diária"),
  @("diÃ¡ria", "diária"),
  @("GarÃ§om", "Garçom"),
  @("garÃ§om", "garçom"),
  @("Candidatura enviada com sucesso!", "Candidatura enviada com sucesso!"),
  @("NÃºmero", "Número"),
  @("nÃºmero", "número"),
  @("Telefone nÃ£o informado", "Telefone não informado"),
  @("Cidade nÃ£o informada", "Cidade não informada"),
  @("Nenhuma bio adicionada.", "Nenhuma bio adicionada."),
  @("Nenhuma habilidade.", "Nenhuma habilidade."),
  @("Salvar alteraÃ§Ãµes", "Salvar alterações"),
  @("NÃ£o foi possÃ­vel", "Não foi possível"),
  @("possÃ­vel", "possível"),
  @("E-mail nÃ£o informado", "E-mail não informado"),
  @("Candidatar-se", "Candidatar-se"),
  @("Em anÃ¡lise", "Em análise"),
  @("anÃ¡lise", "análise"),
  @("UsuÃ¡rio", "Usuário"),
  @("usuÃ¡rio", "usuário"),
  @("UsuÃ¡rios", "Usuários"),
  @("usuÃ¡rios", "usuários"),
  @("AprovaÃ§Ã£o", "Aprovação"),
  @("aprovaÃ§Ã£o", "aprovação"),
  @("NotificaÃ§Ãµes", "Notificações"),
  @("notificaÃ§Ãµes", "notificações")
)

$extensions = @("*.dart", "*.md", "*.txt", "*.yaml", "*.yml", "*.json")

foreach ($ext in $extensions) {
  Get-ChildItem -Path $projectRoot -Recurse -Filter $ext |
    Where-Object {
      $_.FullName -notmatch "\\build\\" -and
      $_.FullName -notmatch "\\.dart_tool\\" -and
      $_.FullName -notmatch "\\.git\\" -and
      $_.FullName -notmatch "\\backup_textos_ptbr_"
    } |
    ForEach-Object {
      $file = $_
      $relative = Resolve-Path -Path $file.FullName -Relative
      $relativeClean = $relative.TrimStart(".\").TrimStart("./")
      $backupPath = Join-Path $backupRoot $relativeClean
      $backupDir = Split-Path $backupPath -Parent

      if (-not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
      }

      Copy-Item $file.FullName $backupPath -Force

      $content = Get-Content $file.FullName -Raw
      $original = $content

      foreach ($pair in $replacements) {
        $content = $content.Replace($pair[0], $pair[1])
      }

      if ($content -ne $original) {
        Set-Content -Path $file.FullName -Value $content -Encoding UTF8
        Write-Host "Corrigido: $relativeClean"
      }
    }
}

Write-Host ""
Write-Host "Rodando dart format em lib..." -ForegroundColor Cyan
dart format lib

Write-Host ""
Write-Host "Concluido." -ForegroundColor Green
Write-Host "Agora rode:"
Write-Host "flutter analyze"
Write-Host "flutter run -d chrome --web-port 5000"
Write-Host ""
Write-Host "Backup criado em: $backupRoot"
