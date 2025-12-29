# =============================================================================
# Script: check-vulnerabilities.ps1
# Proposito: Verificar vulnerabilidades en imagenes de contenedores
# Uso: .\check-vulnerabilities.ps1 -Image "us-central1-docker.pkg.dev/PROJECT/REPO/IMAGE:TAG"
# =============================================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$Image,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("CRITICAL", "HIGH", "MEDIUM", "LOW")]
    [string]$BlockOn = "HIGH",
    
    [Parameter(Mandatory=$false)]
    [switch]$FixableOnly
)

# Mapeo de severidades a numeros para comparacion
$severityLevel = @{
    "CRITICAL" = 4
    "HIGH" = 3
    "MEDIUM" = 2
    "LOW" = 1
    "MINIMAL" = 0
}

$blockLevel = $severityLevel[$BlockOn]

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Vulnerability Scanner" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Image: $Image"
Write-Host "Block on: $BlockOn or higher"
Write-Host ""

# Obtener vulnerabilidades
Write-Host "Scanning for vulnerabilities..." -ForegroundColor Yellow
$output = gcloud artifacts vulnerabilities list $Image 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to scan image" -ForegroundColor Red
    Write-Host $output
    exit 1
}

# Parsear resultados
$criticalCount = ($output | Select-String -Pattern "\| CRITICAL\s+" | Measure-Object).Count
$highCount = ($output | Select-String -Pattern "\| HIGH\s+" | Measure-Object).Count
$mediumCount = ($output | Select-String -Pattern "\| MEDIUM\s+" | Measure-Object).Count
$lowCount = ($output | Select-String -Pattern "\| LOW\s+" | Measure-Object).Count
$minimalCount = ($output | Select-String -Pattern "\| MINIMAL\s+" | Measure-Object).Count

# Mostrar resumen
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Vulnerability Summary" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "CRITICAL: $criticalCount" -ForegroundColor $(if ($criticalCount -gt 0) { "Red" } else { "Green" })
Write-Host "HIGH:     $highCount" -ForegroundColor $(if ($highCount -gt 0) { "Red" } else { "Green" })
Write-Host "MEDIUM:   $mediumCount" -ForegroundColor $(if ($mediumCount -gt 0) { "Yellow" } else { "Green" })
Write-Host "LOW:      $lowCount" -ForegroundColor White
Write-Host "MINIMAL:  $minimalCount" -ForegroundColor Gray
Write-Host ""

# Verificar vulnerabilidades con fix disponible
if ($FixableOnly) {
    $fixableLines = $output | Select-String -Pattern "\| True\s+"
    $fixableCount = ($fixableLines | Measure-Object).Count
    Write-Host "Fixable vulnerabilities: $fixableCount" -ForegroundColor Yellow
    Write-Host ""
}

# Determinar si bloquear
$shouldBlock = $false
$blockReason = ""

if ($criticalCount -gt 0 -and $severityLevel["CRITICAL"] -ge $blockLevel) {
    $shouldBlock = $true
    $blockReason = "CRITICAL vulnerabilities found"
}
elseif ($highCount -gt 0 -and $severityLevel["HIGH"] -ge $blockLevel) {
    $shouldBlock = $true
    $blockReason = "HIGH vulnerabilities found"
}
elseif ($mediumCount -gt 0 -and $severityLevel["MEDIUM"] -ge $blockLevel) {
    $shouldBlock = $true
    $blockReason = "MEDIUM vulnerabilities found"
}
elseif ($lowCount -gt 0 -and $severityLevel["LOW"] -ge $blockLevel) {
    $shouldBlock = $true
    $blockReason = "LOW vulnerabilities found"
}

# Resultado final
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Result" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

if ($shouldBlock) {
    Write-Host "BLOCKED: $blockReason" -ForegroundColor Red
    Write-Host "Deployment should be stopped." -ForegroundColor Red
    exit 1
}
else {
    Write-Host "PASSED: No blocking vulnerabilities found" -ForegroundColor Green
    Write-Host "Deployment can proceed." -ForegroundColor Green
    exit 0
}