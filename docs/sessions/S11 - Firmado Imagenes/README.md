# S11: Firmado de Imagenes y Binary Authorization

## Objetivo
Aprender a firmar imagenes para garantizar integridad y procedencia, y configurar Binary Authorization para controlar que imagenes pueden desplegarse.

---

## Conceptos Clave

### Por que firmar imagenes?

| Beneficio     | Descripcion                               |
|-----------    |-------------                              |
| Integridad    | Garantiza que la imagen no fue modificada |
| Procedencia   | Demuestra quien construyo la imagen       |
| Compliance    | Requerido por PCI-DSS, HIPAA, SOC2        |
| Supply Chain  | Previene ataques de cadena de suministro  |

### Componentes de Binary Authorization

| Componente    | Funcion                                                   |
|------------   |---------                                                  |
| Attestor      | Entidad que verifica y firma imagenes                     |
| Note          | Registro en Container Analysis que almacena attestations  |
| Attestation   | Firma criptografica de una imagen especifica              |
| Policy        | Reglas que definen que imagenes pueden desplegarse        |

### Flujo de firmado
```
[Build imagen]
      |
      v
[Push a Artifact Registry]
      |
      v
[Crear Attestation con KMS]
      |
      v
[Imagen firmada y verificable]
      |
      v
[Deploy - Binary Authorization verifica firma]
```

---

## Recursos Creados

### Attestor: secure-build-attestor

| Propiedad | Valor                     |
|-----------|-------                    |
| Nombre    | secure-build-attestor     |
| Proyecto  | project02-482522          |
| Nota      | secure-build-note         |
| Clave     | artifact-signing-key (KMS)|

### Note: secure-build-note

| Propiedad     | Valor                 |
|-----------    |-------                |
| Nombre        | secure-build-note     |
| Tipo          | ATTESTATION           |
| Descripcion   | Secure Build Attestor |

### Attestation creada

| Propiedad     | Valor                         |
|-----------    |-------                        |
| Imagen        | secure-app@sha256:5361a34ac...|
| Firmada con   | artifact-signing-key v1       |
| Algoritmo     | RSA_SIGN_PKCS1_4096_SHA256    |

---

## Comandos Utilizados

### Habilitar APIs
```powershell
gcloud services enable binaryauthorization.googleapis.com
gcloud services enable containeranalysis.googleapis.com
```

### Crear nota de Container Analysis (via API REST)
```powershell
$accessToken = gcloud auth print-access-token
$noteBody = '{"attestation":{"hint":{"humanReadableName":"Secure Build Attestor"}}}'

Invoke-RestMethod -Uri "https://containeranalysis.googleapis.com/v1/projects/PROJECT_ID/notes?noteId=NOTE_ID" `
  -Method POST `
  -Headers @{"Authorization"="Bearer $accessToken"; "Content-Type"="application/json"} `
  -Body $noteBody
```

### Crear Attestor
```powershell
gcloud container binauthz attestors create ATTESTOR_NAME \
  --attestation-authority-note=NOTE_NAME \
  --attestation-authority-note-project=PROJECT_ID
```

### Asociar clave KMS al Attestor
```powershell
gcloud container binauthz attestors public-keys add \
  --attestor=ATTESTOR_NAME \
  --keyversion-project=PROJECT_ID \
  --keyversion-location=LOCATION \
  --keyversion-keyring=KEYRING \
  --keyversion-key=KEY_NAME \
  --keyversion=VERSION
```

### Firmar imagen (crear attestation)
```powershell
gcloud beta container binauthz attestations sign-and-create \
  --artifact-url="REGISTRY/IMAGE@sha256:DIGEST" \
  --attestor=ATTESTOR_NAME \
  --attestor-project=PROJECT_ID \
  --keyversion-project=PROJECT_ID \
  --keyversion-location=LOCATION \
  --keyversion-keyring=KEYRING \
  --keyversion-key=KEY_NAME \
  --keyversion=VERSION
```

### Listar attestations
```powershell
gcloud container binauthz attestations list \
  --attestor=ATTESTOR_NAME \
  --attestor-project=PROJECT_ID
```

### Verificar attestor
```powershell
gcloud container binauthz attestors describe ATTESTOR_NAME
```

---

## Permisos Requeridos

### Para crear notas y attestations

| Rol                                   | Proposito             |
|-----                                  |-----------            |
| containeranalysis.notes.editor        | Crear/editar notas    |
| containeranalysis.occurrences.editor  | Crear attestations    |
| cloudkms.cryptoKeyVersions.useToSign  | Firmar con KMS        |
| binaryauthorization.attestors.create  | Crear attestors       |

### Asignar permisos
```powershell
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="user:EMAIL" \
  --role="roles/containeranalysis.notes.editor"
```

---

## Integracion con CI/CD

### Script de firmado automatico
```bash
#!/bin/bash
IMAGE_DIGEST=$(gcloud artifacts docker images describe $IMAGE:$TAG \
  --format="value(image_summary.fully_qualified_digest)")

gcloud beta container binauthz attestations sign-and-create \
  --artifact-url="$IMAGE_DIGEST" \
  --attestor=secure-build-attestor \
  --attestor-project=$PROJECT_ID \
  --keyversion-project=$PROJECT_ID \
  --keyversion-location=us-central1 \
  --keyversion-keyring=project02-keyring \
  --keyversion-key=artifact-signing-key \
  --keyversion=1
```

### En Cloud Build
```yaml
steps:
  # Build y push
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', '$_IMAGE', '.']
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', '$_IMAGE']
  
  # Firmar imagen
  - name: 'gcr.io/cloud-builders/gcloud'
    entrypoint: 'bash'
    args:
      - '-c'
      - |
        DIGEST=$(gcloud artifacts docker images describe $_IMAGE --format="value(image_summary.fully_qualified_digest)")
        gcloud beta container binauthz attestations sign-and-create \
          --artifact-url="$DIGEST" \
          --attestor=secure-build-attestor \
          --keyversion=1 ...
```

---

## Diagrama de Arquitectura
```
                    +-------------------+
                    |   Cloud KMS       |
                    | artifact-signing  |
                    |      -key         |
                    +--------+----------+
                             |
                             | firma
                             v
+------------+     +-------------------+     +------------------+
|   Build    | --> | Artifact Registry | --> |   Attestation    |
|  Pipeline  |     |   secure-app:v1   |     | (Container       |
+------------+     +-------------------+     |  Analysis)       |
                             |               +------------------+
                             |                        |
                             v                        v
                    +-------------------+     +------------------+
                    |    GKE/Cloud Run  | <-- | Binary           |
                    |    (Deploy)       |     | Authorization    |
                    +-------------------+     | Policy           |
                                              +------------------+
```

---

## Verificacion de Firma

### Estructura de una Attestation
```json
{
  "critical": {
    "identity": {
      "docker-reference": "us-central1-docker.pkg.dev/project02-482522/containers/secure-app"
    },
    "image": {
      "docker-manifest-digest": "sha256:5361a34ac414494c629ad3c0c46aa5c65bb1cb19804be4e4bcf2eaf51b04c276"
    },
    "type": "Google cloud binauthz container signature"
  }
}
```

### Que garantiza

| Campo                     | Garantia                      |
|-------                    |----------                     |
| docker-reference          | Repositorio de origen         |
| docker-manifest-digest    | Contenido exacto de la imagen |
| signature                 | Firma criptografica con KMS   |

---

## Mejores Practicas

1. **Usar KMS para firmas**: Claves gestionadas, auditables, rotables
2. **Un attestor por ambiente**: dev-attestor, staging-attestor, prod-attestor
3. **Firmar solo imagenes escaneadas**: Integrar con vulnerability scanning
4. **Automatizar en CI/CD**: Firmar automaticamente despues de build exitoso
5. **Auditar attestations**: Revisar periodicamente que imagenes fueron firmadas

---

## Proxima Sesion

**S12**: Politica de despliegue segura basada en firma. Configuraremos Binary Authorization para bloquear imagenes no firmadas.