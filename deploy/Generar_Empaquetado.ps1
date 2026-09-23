# ============================================================================
# KOREX_CONTABILIDAD - Script PowerShell de Empaquetado Standalone
# ============================================================================

Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host "   KOREX_CONTABILIDAD - EMPAQUETADO Y PREPARACION DE BUILDS" -ForegroundColor Cyan
Write-Host "================================================================`n" -ForegroundColor Cyan

$rootDir = Split-Path -Parent $PSScriptRoot
Set-Location $rootDir

Write-Host "[1/3] Generando esquemas consolidados y metadata..." -ForegroundColor Yellow
node deploy/gen_schema_json.js

Write-Host "[2/3] Validando integridad de la suite completa..." -ForegroundColor Yellow
node scripts/validate_full_suite.js

Write-Host "[3/3] Directorio dist preparado." -ForegroundColor Green
$distDir = Join-Path $rootDir "dist"
if (-not (Test-Path $distDir)) {
    New-Item -ItemType Directory -Path $distDir | Out-Null
}

Write-Host "`n✅ Empaquetado completado exitosamente.`n" -ForegroundColor Green
