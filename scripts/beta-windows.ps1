[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('Start', 'Build', 'Stop')]
    [string]$Action = 'Start',

    [string]$ApiUrl
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Project = 'diabeta-beta-local'
$EnvFile = Join-Path $RepoRoot '.env.beta.local'
$LocalHealthUrl = 'http://127.0.0.1:3000/health'
$CorsOrigin = 'https://example.invalid'

if ($ApiUrl) {
    $ParsedUrl = $null
    if (-not [uri]::TryCreate($ApiUrl, [UriKind]::Absolute, [ref]$ParsedUrl) -or
        $ParsedUrl.Scheme -ne 'https' -or
        -not $ParsedUrl.Host -or
        $ParsedUrl.UserInfo -or $ParsedUrl.Query -or $ParsedUrl.Fragment) {
        throw 'ApiUrl debe ser una URL HTTPS absoluta sin credenciales, consulta ni fragmento.'
    }
    $ApiUrl = $ParsedUrl.AbsoluteUri.TrimEnd('/')
    $CorsOrigin = $ParsedUrl.GetLeftPart([UriPartial]::Authority)
}

if ($Action -eq 'Build') {
    if (-not $ApiUrl) {
        throw 'Indica la URL HTTPS privada de pruebas con -ApiUrl.'
    }
    if (-not $PSCmdlet.ShouldProcess('APK local de Diabeta', 'Compilar Android release')) {
        return
    }
    $Flutter = Get-Command flutter -CommandType Application
    Push-Location (Join-Path $RepoRoot 'apps/mobile')
    try {
        & $Flutter.Source build apk --release "--dart-define=API_URL=$ApiUrl" '--dart-define=DIABETA_BETA=true'
        if ($LASTEXITCODE -ne 0) {
            throw 'Flutter no ha compilado el APK. Revisa el error y ejecuta flutter doctor si falta el SDK.'
        }
        $Apk = Get-Item -LiteralPath 'build/app/outputs/flutter-apk/app-release.apk'
        Write-Host "APK: $($Apk.FullName)"
        Write-Host "SHA-256: $((Get-FileHash -LiteralPath $Apk.FullName).Hash)"
    }
    finally {
        Pop-Location
    }
    return
}

if ($Action -eq 'Stop' -and -not (Test-Path -LiteralPath $EnvFile)) {
    return
}
if (-not $PSCmdlet.ShouldProcess($Project, "$Action de la API local de pruebas")) {
    return
}

$Docker = Get-Command docker -CommandType Application
$Context = & $Docker.Source context show
if ($LASTEXITCODE -ne 0 -or -not $Context) {
    throw 'No se pudo identificar el contexto Docker.'
}
$DockerHost = & $Docker.Source context inspect $Context --format '{{.Endpoints.docker.Host}}'
if ($LASTEXITCODE -ne 0 -or $DockerHost -notmatch '^(npipe:/{2,4}\./pipe/|unix:///)') {
    throw 'Selecciona un contexto local de Docker Desktop. El script no admite Docker remoto.'
}
$DockerOs = & $Docker.Source --context $Context info --format '{{.OSType}}'
if ($LASTEXITCODE -ne 0 -or $DockerOs -ne 'linux') {
    throw 'Arranca Docker Desktop en modo contenedores Linux.'
}

function New-LocalSecret {
    $Bytes = New-Object byte[] 32
    $Generator = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $Generator.GetBytes($Bytes)
        return [BitConverter]::ToString($Bytes).Replace('-', '').ToLowerInvariant()
    }
    finally {
        $Generator.Dispose()
    }
}

if (-not (Test-Path -LiteralPath $EnvFile)) {
    $File = [IO.File]::Open($EnvFile, [IO.FileMode]::CreateNew)
    $Writer = New-Object IO.StreamWriter($File)
    try {
        $Writer.WriteLine('JWT_SECRET=' + (New-LocalSecret))
        $Writer.WriteLine('POSTGRES_PASSWORD=' + (New-LocalSecret))
    }
    finally {
        $Writer.Dispose()
    }
}

$Settings = @{
    API_BIND_HOST = '127.0.0.1'
    PORT = '3000'
    POSTGRES_BIND_HOST = '127.0.0.1'
    POSTGRES_PORT = '55432'
    POSTGRES_DB = 'diabeta'
    POSTGRES_USER = 'diabeta'
    NODE_ENV = 'production'
    CORS_ORIGIN = $CorsOrigin
    JWT_SECRET = $null
    POSTGRES_PASSWORD = $null
}
$Previous = @{}
try {
    foreach ($Name in $Settings.Keys) {
        $Previous[$Name] = [Environment]::GetEnvironmentVariable($Name)
        if ($null -eq $Settings[$Name]) {
            Remove-Item -LiteralPath "Env:$Name" -ErrorAction SilentlyContinue
        }
        else {
            [Environment]::SetEnvironmentVariable($Name, $Settings[$Name])
        }
    }
    $Compose = @('--context', $Context, 'compose', '--project-name', $Project,
        '--file', (Join-Path $RepoRoot 'docker-compose.yml'), '--env-file', $EnvFile)
    if ($Action -eq 'Stop') {
        & $Docker.Source @Compose down
        if ($LASTEXITCODE -ne 0) {
            throw 'No se pudieron detener los contenedores de la beta.'
        }
        return
    }

    & $Docker.Source @Compose up -d --build
    if ($LASTEXITCODE -ne 0) {
        throw 'No se pudo arrancar la API. Comprueba que los puertos 3000 y 55432 estan libres.'
    }
}
finally {
    foreach ($Name in $Previous.Keys) {
        if ($null -eq $Previous[$Name]) {
            Remove-Item -LiteralPath "Env:$Name" -ErrorAction SilentlyContinue
        }
        else {
            [Environment]::SetEnvironmentVariable($Name, $Previous[$Name])
        }
    }
}

for ($Attempt = 0; $Attempt -lt 30; $Attempt++) {
    try {
        $Health = Invoke-RestMethod -Uri $LocalHealthUrl -TimeoutSec 2
        if ($Health.status -eq 'ok' -and $Health.service -eq 'diabeta-api') {
            Write-Host "API local lista: $LocalHealthUrl"
            return
        }
    }
    catch {
        # El contenedor puede seguir ejecutando las migraciones.
    }
    Start-Sleep -Seconds 1
}
throw "La API no respondio en $LocalHealthUrl. Revisa los logs del proyecto $Project en Docker Desktop."
