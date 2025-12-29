#!/bin/bash
# =============================================================================
# Script: docker-auth.sh
# Proposito: Autenticar Docker/Podman con Artifact Registry en CI/CD
# Uso: ./docker-auth.sh
# =============================================================================

set -e

REGION="us-central1"
REGISTRY="${REGION}-docker.pkg.dev"

echo "============================================"
echo "Artifact Registry Authentication"
echo "============================================"
echo "Registry: ${REGISTRY}"
echo ""

# Metodo 1: gcloud credential helper (recomendado si gcloud esta disponible)
if command -v gcloud &> /dev/null; then
    echo "Using gcloud credential helper..."
    gcloud auth configure-docker ${REGISTRY} --quiet
    echo "Authentication configured successfully"
    exit 0
fi

# Metodo 2: Token de acceso (para CI/CD con Service Account)
if [ -n "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
    echo "Using Service Account credentials..."
    gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS
    TOKEN=$(gcloud auth print-access-token)
    echo "$TOKEN" | docker login -u oauth2accesstoken --password-stdin ${REGISTRY}
    echo "Authentication successful"
    exit 0
fi

# Metodo 3: Workload Identity (GKE, Cloud Run, Cloud Build)
if curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/ &> /dev/null; then
    echo "Using Workload Identity..."
    TOKEN=$(curl -s -H "Metadata-Flavor: Google" \
        http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token \
        | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")
    echo "$TOKEN" | docker login -u oauth2accesstoken --password-stdin ${REGISTRY}
    echo "Authentication successful"
    exit 0
fi

echo "ERROR: No authentication method available"
echo "Options:"
echo "  1. Install gcloud CLI"
echo "  2. Set GOOGLE_APPLICATION_CREDENTIALS"
echo "  3. Run on GCP with Workload Identity"
exit 1