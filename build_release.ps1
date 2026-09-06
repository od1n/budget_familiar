# build_release.ps1 - compila el release de Android FIRMADO, descifrando los
# secretos DPAPI en memoria solo durante el build.
#
# Uso:
#   powershell -ExecutionPolicy Bypass -File "D:\\Desarrollo\\Claude\\Projects\\budget_familiar\\build_release.ps1"
#   ...agrega  -Apk  al final para generar APK (sideload) en vez de .aab

param([switch]$Apk)

$ErrorActionPreference = "Stop"
$root = "D:\Desarrollo\Claude\Projects\budget_familiar"

function Get-Secret($file) {
    if (-not (Test-Path $file)) {
        throw "No existe $file. Corre primero el paso de guardar los secretos en .secrets."
    }
    $sec = Get-Content $file | ConvertTo-SecureString
    [System.Net.NetworkCredential]::new("", $sec).Password
}

try {
    $env:KEY_STORE_PASSWORD = Get-Secret "$root\.secrets\keystore.sec"
    $env:KEY_PASSWORD        = Get-Secret "$root\.secrets\key.sec"

    $envFile = "$root\env.json"
    if (-not (Test-Path $envFile)) {
        throw "Falta $envFile con SUPABASE_URL y SUPABASE_ANON_KEY. Sin eso la app arranca en pantalla blanca."
    }
    if ((Get-Content $envFile -Raw) -match "PEGA_AQUI") {
        throw "$envFile aun tiene el placeholder de la anon key. Pega la clave real (eyJ...) antes de compilar."
    }

    Set-Location $root
    if ($Apk) {
        flutter build apk --release --dart-define-from-file="$envFile"
    } else {
        flutter build appbundle --release --dart-define-from-file="$envFile"
    }
}
finally {
    # Limpiar las contrasenas de la sesion pase lo que pase
    Remove-Item Env:\KEY_STORE_PASSWORD -ErrorAction SilentlyContinue
    Remove-Item Env:\KEY_PASSWORD -ErrorAction SilentlyContinue
}
