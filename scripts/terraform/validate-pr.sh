#!/bin/bash
# =============================================================================
# Script: validate-pr.sh
# Proposito: Validar cambios Terraform en PR sin ejecutar apply
# Uso: ./validate-pr.sh [directorio-terraform]
# =============================================================================

set -e

TF_DIR="${1:-terraform}"

echo "============================================"
echo "Terraform PR Validation"
echo "============================================"
echo "Directory: $TF_DIR"
echo ""

cd "$TF_DIR"

# Paso 1: Format check
echo "--- FORMAT CHECK ---"
if terraform fmt -check -recursive; then
    echo "[PASS] Formato correcto"
else
    echo "[FAIL] Ejecutar: terraform fmt -recursive"
    exit 1
fi
echo ""

# Paso 2: Init
echo "--- INIT ---"
terraform init -backend=false
echo ""

# Paso 3: Validate
echo "--- VALIDATE ---"
if terraform validate; then
    echo "[PASS] Configuracion valida"
else
    echo "[FAIL] Errores de validacion"
    exit 1
fi
echo ""

# Paso 4: Plan (sin apply)
echo "--- PLAN ---"
terraform plan -lock=false -out=tfplan

echo ""
echo "============================================"
echo "PR Validation Complete"
echo "============================================"
echo "IMPORTANTE: Este script NO ejecuta apply"
echo "El plan debe ser revisado manualmente"