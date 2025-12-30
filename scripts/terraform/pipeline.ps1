# =============================================================================
# Script: pipeline.ps1
# Proposito: Pipeline Terraform completo local
# Uso: .\pipeline.ps1 [-Apply]
# =============================================================================

param(
    [switch]$Apply
)

$ErrorActionPreference = "Stop"
$TfDir = "C:\Users\a.cisternas.guajardo\source\repos\enterprise-devops-pipeline\terraform"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Terraform Pipeline" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Apply mode: $Apply"
Write-Host ""

Set-Location $TfDir

# Paso 1: Format
Write-Host "--- STEP 1: FORMAT ---" -ForegroundColor Yellow
$fmtResult = terraform fmt -check -recursive 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[FAIL] Format check failed" -ForegroundColor Red
    Write-Host "Run: terraform fmt -recursive" -ForegroundColor Red
    exit 1
}
Write-Host "[PASS] Format OK" -ForegroundColor Green
Write-Host ""

# Paso 2: Init
Write-Host "--- STEP 2: INIT ---" -ForegroundColor Yellow
terraform init -input=false
if ($LASTEXITCODE -ne 0) {
    Write-Host "[FAIL] Init failed" -ForegroundColor Red
    exit 1
}
Write-Host "[PASS] Init OK" -ForegroundColor Green
Write-Host ""

# Paso 3: Validate
Write-Host "--- STEP 3: VALIDATE ---" -ForegroundColor Yellow
terraform validate
if ($LASTEXITCODE -ne 0) {
    Write-Host "[FAIL] Validation failed" -ForegroundColor Red
    exit 1
}
Write-Host "[PASS] Validate OK" -ForegroundColor Green
Write-Host ""

# Paso 4: Plan
Write-Host "--- STEP 4: PLAN ---" -ForegroundColor Yellow
terraform plan -out=tfplan -input=false
if ($LASTEXITCODE -ne 0) {
    Write-Host "[FAIL] Plan failed" -ForegroundColor Red
    exit 1
}
Write-Host "[PASS] Plan OK" -ForegroundColor Green
Write-Host ""

# Paso 5: Apply (solo si -Apply flag)
if ($Apply) {
    Write-Host "--- STEP 5: APPLY ---" -ForegroundColor Yellow
    terraform apply tfplan
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[FAIL] Apply failed" -ForegroundColor Red
        exit 1
    }
    Write-Host "[PASS] Apply OK" -ForegroundColor Green
} else {
    Write-Host "--- STEP 5: APPLY (SKIPPED) ---" -ForegroundColor Gray
    Write-Host "Run with -Apply flag to execute apply" -ForegroundColor Gray
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Pipeline Complete" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan