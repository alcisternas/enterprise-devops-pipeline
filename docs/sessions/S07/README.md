# S07: Repaso y Evaluacion del Bloque 1

## Objetivo
Consolidar los conceptos aprendidos sobre seguridad, KMS, vulnerabilidades y gestion de imagenes en Artifact Registry.

---

## Resumen del Bloque 1

### Sesiones Completadas

| Sesion | Tema | Entregable |
|--------|------|------------|
| S01 | KMS - Crear y rotar claves | Keyring + 2 claves (encriptacion, firmado) |
| S02 | CMEK en buckets y Cloud Run | Bucket y Artifact Registry encriptados |
| S03 | Vulnerability Scanning | Imagen demo-app escaneada |
| S04 | Filtrado CVSS | Script check-vulnerabilities.ps1 |
| S05 | Tags vs digest | Comprension de mutabilidad |
| S06 | Limpieza de tags | Script cleanup-tags.ps1 |
| S07 | Repaso Bloque 1 | Este documento |

---

## Infraestructura Creada

### Recursos GCP

| Recurso | Nombre | Proposito |
|---------|--------|-----------|
| KMS Keyring | project02-keyring | Contenedor de claves |
| KMS Key | data-encryption-key | Encriptar datos (CMEK) |
| KMS Key | artifact-signing-key | Firmar imagenes (futuro) |
| Storage Bucket | project02-482522-encrypted-data | Almacenamiento con CMEK |
| Artifact Registry | containers | Repositorio de imagenes con CMEK |
| Service Account | cloud-run-sa | Identidad para Cloud Run |

### Imagenes en Artifact Registry

| Imagen | Tags | Digest |
|--------|------|--------|
| demo-app | v1 | sha256:a1c55d... |
| demo-app | v2, latest, build-102 | sha256:0f2fd5... |

---

## Scripts Creados

### scripts/security/check-vulnerabilities.ps1

**Proposito**: Validar imagenes antes de despliegue basado en severidad CVSS.

**Uso**:
```powershell
.\check-vulnerabilities.ps1 -Image "REGISTRY/IMAGE:TAG" -BlockOn "HIGH"
```

**Parametros**:
- `-Image`: URI de la imagen
- `-BlockOn`: CRITICAL, HIGH, MEDIUM, LOW
- `-FixableOnly`: Solo considerar CVEs con fix

### scripts/cleanup/cleanup-tags.ps1

**Proposito**: Limpiar tags antiguos preservando imagenes.

**Uso**:
```powershell
.\cleanup-tags.ps1 -Repository "REGISTRY/IMAGE" -KeepTags @("v1","latest") -TagPattern "build-*" -KeepRecent 5 -DryRun
```

---

## Conceptos Clave Aprendidos

### 1. KMS y Encriptacion

| Concepto | Descripcion |
|----------|-------------|
| Google-managed | Google controla las claves automaticamente |
| CMEK | Tu controlas las claves, rotacion y acceso |
| Keyring | Contenedor logico de claves (no eliminable) |
| Rotacion | Crear nueva version, mantener anteriores para descifrar |

### 2. CMEK en Recursos

| Recurso | Configuracion |
|---------|---------------|
| Cloud Storage | `encryption.default_kms_key_name` |
| Artifact Registry | `kms_key_name` |
| Cloud Run | `encryption_key` en template |

### 3. Vulnerability Scanning

| Aspecto | Detalle |
|---------|---------|
| Activacion | Automatica al habilitar API |
| Trigger | Push de imagen a Artifact Registry |
| Re-escaneo | Automatico cuando aparecen nuevas CVEs |
| Costo | $0.26 USD por imagen unica |

### 4. Severidades CVSS

| Severidad | CVSS | Accion |
|-----------|------|--------|
| CRITICAL | 9.0-10.0 | Bloquear inmediatamente |
| HIGH | 7.0-8.9 | Bloquear en produccion |
| MEDIUM | 4.0-6.9 | Evaluar y planificar |
| LOW/MINIMAL | 0-3.9 | Monitorear |

### 5. Tags vs Digests

| Caracteristica | Tag | Digest |
|----------------|-----|--------|
| Mutable | Si | No |
| Legible | Si | No |
| Reproducible | No | Si |
| Uso en produccion | Evitar | Recomendado |

---

## Estructura del Repositorio
```
enterprise-devops-pipeline/
├── .gitignore
├── README.md
├── docker/
│   └── demo-app/
│       └── Dockerfile
├── docs/
│   └── sessions/
│       ├── S01/README.md
│       ├── S02/README.md
│       ├── S03/README.md
│       ├── S04/README.md
│       ├── S05/README.md
│       ├── S06/README.md
│       └── S07/README.md
├── jenkins/
├── policies/
├── scripts/
│   ├── cleanup/
│   │   └── cleanup-tags.ps1
│   └── security/
│       └── check-vulnerabilities.ps1
└── terraform/
    ├── main.tf
    ├── variables.tf
    ├── terraform.tfvars
    ├── outputs.tf
    ├── kms.tf
    ├── storage.tf
    ├── registry.tf
    ├── iam.tf
    └── cloudrun.tf
```

---

## Verificacion Final

### Comandos de validacion ejecutados
```powershell
# Terraform outputs
terraform output

# KMS keys
gcloud kms keys list --location=us-central1 --keyring=project02-keyring

# Bucket CMEK
gcloud storage buckets describe gs://project02-482522-encrypted-data --format="yaml(default_kms_key)"

# Artifact Registry CMEK
gcloud artifacts repositories describe containers --location=us-central1 --format="yaml(kmsKeyName)"

# Imagenes
gcloud artifacts docker images list us-central1-docker.pkg.dev/project02-482522/containers --include-tags

# Script de vulnerabilidades
.\scripts\security\check-vulnerabilities.ps1 -Image "...:v1" -BlockOn "HIGH"
```

### Resultados

| Verificacion | Estado |
|--------------|--------|
| Terraform outputs | OK |
| KMS Keyring + 2 claves | OK |
| Bucket con CMEK | OK |
| Artifact Registry con CMEK | OK |
| 2 imagenes (v1, v2) | OK |
| Script vulnerabilidades | OK (PASSED) |
| Script limpieza tags | OK |

---

## Mejores Practicas Aplicadas

1. **KMS manual, Terraform referencia**: Recursos permanentes no gestionados por IaC
2. **CMEK en todo**: Bucket y Registry encriptados con clave propia
3. **Escaneo automatico**: Vulnerabilidades detectadas al push
4. **Politicas de bloqueo**: Script para CI/CD basado en severidad
5. **Digests para produccion**: Tags para desarrollo, digests para deploy
6. **Limpieza automatizada**: Script para mantener repositorio limpio
7. **Documentacion completa**: README por sesion

---

## Proximo Bloque

**Bloque 2: Docker/Podman, Imagenes Seguras y Supply Chain**

| Sesion | Tema |
|--------|------|
| S08 | Multi-stage builds - reduccion de tamano |
| S09 | Imagenes non-root y best practices |
| S10 | Autenticacion Docker/Podman con Artifact Registry |
| S11 | Firmado de imagenes y Binary Authorization |
| S12 | Politica de despliegue segura basada en firma |
| S13 | Build + push + firma + verificacion |
| S14 | Auditoria completa de imagenes |

---

## Felicitaciones!

Has completado el Bloque 1 del curso de seguridad y CI/CD avanzado en GCP. Ahora tienes:

- Infraestructura segura con CMEK
- Escaneo automatico de vulnerabilidades
- Scripts para validacion y limpieza
- Comprension de tags vs digests
- Documentacion completa de cada sesion