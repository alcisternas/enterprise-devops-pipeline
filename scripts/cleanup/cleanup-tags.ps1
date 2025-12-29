# =============================================================================
# Script: cleanup-tags.ps1
# Proposito: Limpiar tags antiguos de Artifact Registry preservando imagenes
# Uso: .\cleanup-tags.ps1 -Repository "us-central1-docker.pkg.dev/PROJECT/REPO/IMAGE" -KeepTags @("v1","v2","latest") -DryRun
# =============================================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$Repository,
    
    [Parameter(Mandatory=$false)]
    [string[]]$KeepTags = @("latest"),
    
    [Parameter(Mandatory=$false)]
    [string]$TagPattern = "build-*",
    
    [Parameter(Mandatory=$false)]
    [int]$KeepRecent = 5,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Artifact Registry Tag Cleanup" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Repository: $Repository"
Write-Host "Keep tags: $($KeepTags -join ', ')"
Write-Host "Tag pattern to clean: $TagPattern"
Write-Host "Keep recent: $KeepRecent"
Write-Host "Dry run: $DryRun"
Write-Host ""

# Obtener lista de tags usando formato value
Write-Host "Fetching tags..." -ForegroundColor Yellow
$rawOutput = gcloud artifacts docker tags list $Repository --format="value(tag)" 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to list tags" -ForegroundColor Red
    Write-Host $rawOutput
    exit 1
}

# Parsear tags - filtrar linea de encabezado y lineas vacias
$allTags = @()
foreach ($line in $rawOutput) {
    $line = $line.ToString().Trim()
    if ($line -ne "" -and $line -notmatch "^Listing items" -and $line -notmatch "^ERROR") {
        $allTags += $line
    }
}

$allTags = $allTags | Select-Object -Unique | Sort-Object

Write-Host "Found tags: $($allTags -join ', ')" -ForegroundColor Gray
Write-Host ""

# Filtrar tags que coinciden con el patron
$matchingTags = @($allTags | Where-Object { $_ -like $TagPattern })

Write-Host "Tags matching pattern '$TagPattern': $($matchingTags -join ', ')" -ForegroundColor Gray

# Excluir tags protegidos
$tagsToConsider = @($matchingTags | Where-Object { $_ -notin $KeepTags })

Write-Host "Tags after excluding protected: $($tagsToConsider -join ', ')" -ForegroundColor Gray

# Ordenar y mantener los mas recientes
$tagsToDelete = @()
if ($tagsToConsider.Count -gt $KeepRecent) {
    $tagsToDelete = $tagsToConsider | Sort-Object | Select-Object -First ($tagsToConsider.Count - $KeepRecent)
} else {
    Write-Host ""
    Write-Host "Not enough tags to clean (have $($tagsToConsider.Count), keeping $KeepRecent)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Cleanup Plan" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Tags to delete: $($tagsToDelete.Count)" -ForegroundColor $(if ($tagsToDelete.Count -gt 0) { "Yellow" } else { "Green" })

if ($tagsToDelete.Count -eq 0) {
    Write-Host "No tags to delete." -ForegroundColor Green
    exit 0
}

foreach ($tag in $tagsToDelete) {
    Write-Host "  - $tag" -ForegroundColor Red
}

Write-Host ""

# Ejecutar limpieza
if ($DryRun) {
    Write-Host "DRY RUN - No changes made" -ForegroundColor Yellow
    exit 0
}

Write-Host "Deleting tags..." -ForegroundColor Yellow
$deleted = 0
$failed = 0

foreach ($tag in $tagsToDelete) {
    $fullTag = "${Repository}:${tag}"
    Write-Host "  Deleting $tag... " -NoNewline
    
    $result = gcloud artifacts docker tags delete $fullTag --quiet 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "OK" -ForegroundColor Green
        $deleted++
    } else {
        Write-Host "FAILED" -ForegroundColor Red
        $failed++
    }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Deleted: $deleted" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Gray" })