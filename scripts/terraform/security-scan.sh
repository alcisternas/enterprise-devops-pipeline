#!/bin/bash
# =============================================================================
# Script: security-scan.sh
# Proposito: Analisis de seguridad de Terraform con tflint, tfsec, checkov
# Uso: ./security-scan.sh [directorio]
# =============================================================================

set -e

TF_DIR="${1:-terraform}"

echo "============================================"
echo "Terraform Security Scan"
echo "============================================"
echo "Directory: $TF_DIR"
echo ""

# tflint - Linter de Terraform
echo "--- TFLINT ---"
if command -v tflint &> /dev/null; then
    tflint --init
    tflint "$TF_DIR"
    echo "[DONE] tflint complete"
else
    echo "[SKIP] tflint not installed"
    echo "Install: curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash"
fi
echo ""

# tfsec - Scanner de seguridad
echo "--- TFSEC ---"
if command -v tfsec &> /dev/null; then
    tfsec "$TF_DIR" --minimum-severity MEDIUM
    echo "[DONE] tfsec complete"
else
    echo "[SKIP] tfsec not installed"
    echo "Install: curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash"
fi
echo ""

# checkov - Scanner de IaC
echo "--- CHECKOV ---"
if command -v checkov &> /dev/null; then
    checkov -d "$TF_DIR" --framework terraform --quiet
    echo "[DONE] checkov complete"
else
    echo "[SKIP] checkov not installed"
    echo "Install: pip install checkov"
fi
echo ""

echo "============================================"
echo "Security Scan Complete"
echo "============================================"