$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $ScriptDir

Write-Host '==> [1/2] Construyendo imagen Docker para Lambda Layer...' -ForegroundColor Cyan
docker build -t lambda-layer-builder .

Write-Host '==> [2/2] Extrayendo layer.zip compatible con Lambda...' -ForegroundColor Cyan
docker run --rm -v "${ScriptDir}:/output" lambda-layer-builder

Write-Host "==> Layer empaquetada exitosamente en $ScriptDir\layer.zip" -ForegroundColor Green
