param(
  [string]$Root = "."
)

Write-Host "Limpando warnings simples em: $Root"

Get-ChildItem -Path $Root -Recurse -Filter "*.dart" | ForEach-Object {
  $path = $_.FullName
  $content = Get-Content $path -Raw

  # Troca simples: .withOpacity(0.5) -> .withValues(alpha: 0.5)
  $content = [regex]::Replace($content, "\.withOpacity\(([^)]+)\)", ".withValues(alpha: `$1)")

  # Remove imports duplicados mantendo a primeira ocorrência
  $lines = $content -split "`r?`n"
  $seen = @{}
  $newLines = New-Object System.Collections.Generic.List[string]

  foreach ($line in $lines) {
    if ($line.Trim().StartsWith("import ")) {
      if ($seen.ContainsKey($line)) {
        continue
      }
      $seen[$line] = $true
    }

    $newLines.Add($line)
  }

  Set-Content -Path $path -Value ($newLines -join "`r`n") -Encoding UTF8
}

Write-Host "Concluído. Rode flutter analyze para conferir."
