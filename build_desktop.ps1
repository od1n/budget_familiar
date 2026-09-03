# Compila la app de escritorio (Windows) en release con los secretos de env.json
# y opcionalmente genera un ZIP portable listo para subir a GitHub Releases.
#
#   .\build_desktop.ps1          # solo compila
#   .\build_desktop.ps1 -Zip     # compila y empaqueta en dist\
param([switch]$Zip)
$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
Set-Location $root

# ── Validar env.json (mismos secretos que Android; sin esto la app va en blanco)
$envPath = Join-Path $root "env.json"
if (-not (Test-Path $envPath)) { Write-Error "Falta $envPath"; exit 1 }
$cfg = Get-Content $envPath -Raw | ConvertFrom-Json
if (-not $cfg.SUPABASE_URL -or -not $cfg.SUPABASE_ANON_KEY -or ($cfg.SUPABASE_URL -like "*TU_*")) {
  Write-Error "env.json incompleto o con placeholders."; exit 1
}

# Cerrar la app si esta corriendo (evita LNK1104: el linker no puede sobrescribir el .exe en uso)
$proc = Get-Process budget_familiar -ErrorAction SilentlyContinue
if ($proc) {
  Write-Host "Cerrando budget_familiar.exe en ejecucion..." -ForegroundColor Yellow
  $proc | Stop-Process -Force -ErrorAction SilentlyContinue
  Start-Sleep -Milliseconds 800
}

Write-Host "Compilando Windows release..." -ForegroundColor Cyan
flutter build windows --release --dart-define-from-file="$envPath"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$rel = Join-Path $root "build\windows\x64\runner\Release"
if (-not (Test-Path $rel)) { Write-Error "No se encontro la carpeta Release: $rel"; exit 1 }
Write-Host "Build OK: $rel" -ForegroundColor Green

if ($Zip) {
  $verLine = (Select-String -Path (Join-Path $root "pubspec.yaml") -Pattern '^version:\s*(.+)$').Matches[0].Groups[1].Value
  $ver = ($verLine -split '\+')[0].Trim()
  $out = Join-Path $root "dist"
  New-Item -ItemType Directory -Force -Path $out | Out-Null
  $zipPath = Join-Path $out "BudgetFamiliar-Windows.zip"
  if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
  Compress-Archive -Path (Join-Path $rel '*') -DestinationPath $zipPath
  Write-Host "ZIP listo para subir a GitHub Releases:" -ForegroundColor Green
  Write-Host "  $zipPath" -ForegroundColor Yellow
}
