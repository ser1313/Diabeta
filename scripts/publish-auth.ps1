$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

$expectedBranch = 'feature/auth-login-complete'
$currentBranch = (& git branch --show-current).Trim()
if ($LASTEXITCODE -ne 0) { throw 'No se pudo consultar la rama de Git.' }
if ($currentBranch -ne $expectedBranch) {
    throw "Publicación bloqueada: cambia a la rama '$expectedBranch' (rama actual: '$currentBranch')."
}

& (Join-Path $PSScriptRoot 'validate-auth.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Las validaciones han fallado; no se hará commit ni push.' }

& git diff --check
if ($LASTEXITCODE -ne 0) { throw 'El diff contiene errores de whitespace; no se publicará.' }

$files = @(
    '.github/workflows/ci.yml',
    'apps/mobile/lib/api_client.dart',
    'apps/mobile/lib/auth_screen.dart',
    'apps/mobile/lib/main.dart',
    'apps/mobile/test/auth_screen_test.dart',
    'scripts/publish-auth.ps1',
    'scripts/validate-auth.ps1'
)
& git add -- $files
if ($LASTEXITCODE -ne 0) { throw 'No se pudieron preparar los archivos de autenticación.' }

& git diff --cached --check
if ($LASTEXITCODE -ne 0) { throw 'El diff preparado no supera git diff --check.' }

& git diff --cached --quiet
if ($LASTEXITCODE -eq 0) {
    Write-Host 'No hay cambios preparados. No se crea un commit vacío.'
    exit 0
}

& git commit -m 'feat(auth): complete mobile login and registration'
if ($LASTEXITCODE -ne 0) { throw 'El commit ha fallado; no se ejecutará push.' }

& git push -u origin $expectedBranch
if ($LASTEXITCODE -ne 0) { throw 'El push ha fallado. El commit local se conserva para diagnóstico.' }

Write-Host 'Publicación completada tras superar las validaciones.'
