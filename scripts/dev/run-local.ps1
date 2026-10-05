#Requires -Version 7
<#
.SYNOPSIS
    Startet den BacpacCompatFixer lokal als Container (Podman oder Docker).
#>
$ErrorActionPreference = 'Stop'

# --- Container-Engine: Podman bevorzugt (Override: $env:CONTAINER_ENGINE='docker') ---
if (-not $env:CONTAINER_ENGINE -and (Get-Command podman -ErrorAction SilentlyContinue)) {
    $env:CONTAINER_ENGINE = 'podman'
}
if (-not $env:CONTAINER_ENGINE) { $env:CONTAINER_ENGINE = 'docker' }

function container {
    if ($env:CONTAINER_ENGINE -eq 'podman') {
        if ($MyInvocation.ExpectingInput) { $input | & podman @args }
        else { & podman @args }
    } else { & docker @args }
}

$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$dockerfile = Join-Path $root 'src/BacpacCompatFixer.Blazor/Dockerfile'
$imageName = 'bacpac-compat-fixer:latest'
$containerName = 'bacpac-compat-fixer'
$localUrl = 'http://localhost:8680/'

Write-Host "Container-Engine: $env:CONTAINER_ENGINE" -ForegroundColor Cyan

Write-Host 'Stoppe bestehenden Container ...' -ForegroundColor Gray
container rm -f $containerName 2>&1 | Out-Null

Write-Host 'Baue Container-Image ...' -ForegroundColor Gray
if ($env:CONTAINER_ENGINE -eq 'podman') {
    container build --format docker -t $imageName -f $dockerfile $root
} else {
    container build -t $imageName -f $dockerfile $root
}

Write-Host 'Starte Container ...' -ForegroundColor Gray
container run -d --name $containerName --publish 8680:8080 --env ASPNETCORE_ENVIRONMENT=Development $imageName

Write-Host 'Warte auf Start ...' -ForegroundColor Gray
Start-Sleep -Seconds 8

$maxRetries = 10
$attempt = 0
$up = $false
do {
    $attempt++
    try {
        $response = Invoke-WebRequest -Uri $localUrl -TimeoutSec 3 -UseBasicParsing -ErrorAction Stop
        Write-Host "Smoke-Check OK ($attempt): $localUrl -> $($response.StatusCode)" -ForegroundColor Green
        $up = $true
        break
    } catch {
        $status = $_.Exception.Response.StatusCode.value__
        if ($status) {
            Write-Host "Smoke-Check OK ($attempt): $localUrl -> $status (Server antwortet)" -ForegroundColor Green
            $up = $true
            break
        }
        if ($attempt -ge $maxRetries) { break }
        Start-Sleep -Seconds 3
    }
} while ($true)

if (-not $up) {
    Write-Host 'Smoke-Check fehlgeschlagen.' -ForegroundColor Red
    container logs $containerName 2>&1 | Select-Object -Last 30
    exit 1
}

Write-Host ''
Write-Host 'Lokal erreichbar: http://localhost:8680' -ForegroundColor Green
Write-Host "Logs: $env:CONTAINER_ENGINE logs -f $containerName" -ForegroundColor Gray
Write-Host "Stoppen: $env:CONTAINER_ENGINE rm -f $containerName" -ForegroundColor Gray
