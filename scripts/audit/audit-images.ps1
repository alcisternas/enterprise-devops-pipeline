# =============================================================================
# Script: audit-images.ps1
# Proposito: Auditar imagenes, firmas y despliegues
# Uso: .\audit-images.ps1 -Project "PROJECT_ID"
# =============================================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$Project,
    
    [Parameter(Mandatory=$false)]
    [string]$Attestor = "secure-build-attestor",
    
    [Parameter(Mandatory=$false)]
    [string]$Region = "us-central1"
)

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Image Security Audit Report" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Project: $Project"
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host ""

# 1. Listar imagenes
Write-Host "--- IMAGENES EN ARTIFACT REGISTRY ---" -ForegroundColor Yellow
gcloud artifacts docker images list "$Region-docker.pkg.dev/$Project/containers" --include-tags --format "table(package,tags,createTime)"
Write-Host ""

# 2. Listar attestations
Write-Host "--- ATTESTATIONS (IMAGENES FIRMADAS) ---" -ForegroundColor Yellow
$attestations = gcloud container binauthz attestations list --attestor $Attestor --attestor-project $Project --format "value(resourceUri)" 2>$null
if ($attestations) {
    $attestations | ForEach-Object { Write-Host "  [SIGNED] $_" -ForegroundColor Green }
} else {
    Write-Host "  No attestations found" -ForegroundColor Gray
}
Write-Host ""

# 3. Servicios Cloud Run
Write-Host "--- SERVICIOS CLOUD RUN ---" -ForegroundColor Yellow
gcloud run services list --project $Project --region $Region --format "table(name,status.url,status.conditions[0].status)"
Write-Host ""

# 4. Politica Binary Authorization
Write-Host "--- POLITICA BINARY AUTHORIZATION ---" -ForegroundColor Yellow
$policy = gcloud container binauthz policy export --project $Project 2>$null
$enforcement = ($policy | Select-String "enforcementMode").ToString().Split(":")[1].Trim()
Write-Host "  Enforcement: $enforcement"
Write-Host ""

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Audit Complete" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan