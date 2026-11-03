$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$MobilePath = Join-Path $RepoRoot 'apps/mobile'
$LogPath = Join-Path ([System.IO.Path]::GetTempPath()) 'diabeta-auth-validation.log'
$MaximumAttempts = 3

Set-Content -Path $LogPath -Value "Diabeta auth validation started: $(Get-Date -Format o)"

function Invoke-MobileCommand {
    param(
        [Parameter(Mandatory = $true)][string]$Label,
        [Parameter(Mandatory = $true)][scriptblock]$Action
    )

    Push-Location $MobilePath
    try {
        Add-Content -Path $LogPath -Value "--- $Label ---"
        $output = & $Action 2>&1
        $exitCode = $LASTEXITCODE
        $output | ForEach-Object {
            $line = "$_"
            Add-Content -Path $LogPath -Value $line
            Write-Host $line
        }
        if ($exitCode -ne 0) {
            throw "$Label terminó con código $exitCode."
        }
    }
    finally {
        Pop-Location
    }
}

for ($attempt = 1; $attempt -le $MaximumAttempts; $attempt++) {
    try {
        Write-Host "Validación de DIABETA: intento $attempt/$MaximumAttempts"
        Invoke-MobileCommand 'Dependencias Flutter' { flutter pub get }
        Invoke-MobileCommand 'Formato determinista de archivos de autenticación' {
            dart format lib/auth_screen.dart test/auth_screen_test.dart
        }
        Invoke-MobileCommand 'Análisis estático' { flutter analyze }
        Invoke-MobileCommand 'Pruebas automáticas' { flutter test }
        Invoke-MobileCommand 'Compilación Android debug' { flutter build apk --debug }

        Add-Content -Path $LogPath -Value "PASS: $(Get-Date -Format o)"
        Write-Host 'PASS: análisis, pruebas y compilación completados.'
        Write-Host "Registro: $LogPath"
        return
    }
    catch {
        $failure = $_.Exception.Message
        Add-Content -Path $LogPath -Value "ATTEMPT $attempt FAILED: $failure"
        Add-Content -Path $LogPath -Value $_.ScriptStackTrace
        Write-Warning "$failure"

        if ($attempt -lt $MaximumAttempts) {
            Write-Host 'Reintentando tras normalizar el formato de los archivos de autenticación...'
            try {
                Invoke-MobileCommand 'Recuperación de formato' {
                    dart format lib/auth_screen.dart test/auth_screen_test.dart
                }
            }
            catch {
                Add-Content -Path $LogPath -Value "FORMAT RECOVERY FAILED: $($_.Exception.Message)"
            }
        }
        else {
            throw "Validación bloqueada tras $MaximumAttempts intentos. Consulta el registro: $LogPath"
        }
    }
}
