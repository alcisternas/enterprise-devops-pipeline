# S02: Aplicar CMEK a Buckets y Cloud Run

## Objetivo
Aplicar Customer-Managed Encryption Keys (CMEK) a recursos de almacenamiento y preparar Cloud Run para encriptacion con claves propias.

---

## Conceptos Clave

### CMEK en Recursos GCP

| Recurso           | Encriptacion por Defecto  | Con CMEK      |
|---------          |-------------------------- |----------     |
| Cloud Storage     | Google-managed            | Tu clave KMS  |
| Artifact Registry | Google-managed            | Tu clave KMS  |
| Cloud Run         | Google-managed            | Tu clave KMS  |

### Beneficios de CMEK

1. **Control total**: Tu decides cuando rotar o deshabilitar claves
2. **Auditoria**: Cloud Audit Logs registra cada uso de la clave
3. **Revocacion**: Deshabilitar la clave hace los datos inaccesibles
4. **Compliance**: Cumple requisitos regulatorios (HIPAA, PCI-DSS, etc.)

### Service Agents vs Service Accounts

| Tipo              | Quien lo crea             | Proposito                         |
|------             |---------------            |-----------                        |
| Service Agent     | GCP automaticamente       | Operaciones internas del servicio |
| Service Account   | Tu (manual o Terraform)   | Tu aplicacion                     |

Los Service Agents necesitan permisos KMS para encriptar/desencriptar datos del servicio.

---

## APIs Utilizadas

### artifactregistry.googleapis.com
**Proposito**: Almacenar imagenes de contenedores, paquetes de lenguajes y otros artefactos.

**Funcionalidades**:
- Repositorios Docker, Maven, npm, Python, etc.
- Escaneo de vulnerabilidades integrado
- Encriptacion con CMEK
- Control de acceso granular con IAM

**Por que se necesita**: Almacenaremos imagenes Docker para Cloud Run.

### run.googleapis.com
**Proposito**: Ejecutar contenedores serverless.

**Funcionalidades**:
- Escalado automatico (incluyendo a cero)
- HTTPS automatico
- Encriptacion con CMEK
- Integracion con Artifact Registry

**Por que se necesita**: Desplegaremos aplicaciones en sesiones posteriores.

### iam.googleapis.com
**Proposito**: Gestion de identidad y acceso.

**Funcionalidades**:
- Service Accounts
- Roles y permisos
- Politicas IAM

**Por que se necesita**: Crear Service Account para Cloud Run.

---

## Recursos Creados

### Bucket: project02-482522-encrypted-data
**Tipo**: Google Cloud Storage Bucket

**Proposito**: Almacenamiento de datos encriptados con CMEK.

**Configuracion**:
- Ubicacion: us-central1
- Encriptacion: CMEK con `data-encryption-key`
- Versionado: Habilitado
- Uniform bucket-level access: Habilitado

**Uso futuro**: Almacenar artefactos, backups, datos de aplicacion.

### Artifact Registry: containers
**Tipo**: Docker Repository

**Proposito**: Almacenar imagenes de contenedores encriptadas con CMEK.

**Configuracion**:
- Ubicacion: us-central1
- Formato: DOCKER
- Encriptacion: CMEK con `data-encryption-key`

**URL para push/pull**: `us-central1-docker.pkg.dev/project02-482522/containers`

**Uso futuro**: S08+ (imagenes Docker), S11+ (imagenes firmadas).

### Service Account: cloud-run-sa
**Tipo**: IAM Service Account

**Proposito**: Identidad para aplicaciones que corren en Cloud Run.

**Email**: `cloud-run-sa@project02-482522.iam.gserviceaccount.com`

**Permisos asignados**:
- `roles/cloudkms.cryptoKeyEncrypterDecrypter` en `data-encryption-key`

**Uso futuro**: S13+ cuando despleguemos aplicaciones.

---

## Permisos KMS Configurados

### Por que cada Service Account necesita acceso a KMS

| Service Account                       | Servicio           | Necesita KMS para                        |
|-----------------                      |----------          |-------------------                       |
| `service-*@gs-project-accounts`       | Cloud Storage      | Encriptar/desencriptar objetos en bucket |
| `service-*@gcp-sa-artifactregistry`   | Artifact Registry  | Encriptar/desencriptar imagenes          |
| `cloud-run-sa@*`                      | Cloud Run (app)    | Acceder a datos encriptados              |
| `service-*@serverless-robot-prod`     | Cloud Run (agente) | Desencriptar imagen al desplegar         |

### Flujo de Encriptacion
```
[Tu App] --> [Cloud Run] --> [Artifact Registry] --> [KMS]
                |                    |                  |
                v                    v                  v
         Usa cloud-run-sa    Usa service agent    Desencripta imagen
```

---

## Comandos Ejecutados

### Habilitar APIs

#### `gcloud services enable artifactregistry.googleapis.com run.googleapis.com iam.googleapis.com`
**Que hace**: Habilita las APIs de Artifact Registry, Cloud Run e IAM.

**Por que**: Estos servicios estaban deshabilitados por defecto.

### Obtener Service Agents

#### `gcloud storage service-agent --project=project02-482522`
**Que hace**: Muestra el Service Agent de Cloud Storage.

**Resultado**: `service-429672679330@gs-project-accounts.iam.gserviceaccount.com`

**Por que**: Necesitamos su email para otorgar permisos KMS.

#### `gcloud beta services identity create --service=artifactregistry.googleapis.com --project=project02-482522`
**Que hace**: Crea (si no existe) y muestra el Service Agent de Artifact Registry.

**Resultado**: `service-429672679330@gcp-sa-artifactregistry.iam.gserviceaccount.com`

**Por que**: El Service Agent se crea bajo demanda; este comando fuerza su creacion.

### Otorgar Permisos KMS

#### `gcloud kms keys add-iam-policy-binding data-encryption-key --location=us-central1 --keyring=project02-keyring --member="serviceAccount:SERVICE_ACCOUNT" --role="roles/cloudkms.cryptoKeyEncrypterDecrypter"`
**Que hace**: Otorga permiso para usar la clave KMS al Service Account especificado.

**Parametros**:
- `data-encryption-key`: Nombre de la clave
- `--location`, `--keyring`: Ubicacion de la clave
- `--member`: Service Account que recibe el permiso
- `--role`: Rol que permite encriptar y desencriptar

### Verificacion

#### `gcloud storage buckets describe gs://BUCKET --format="yaml(default_kms_key)"`
**Que hace**: Muestra la clave KMS configurada para encriptacion por defecto del bucket.

#### `gcloud artifacts repositories describe REPO --location=LOCATION --format="yaml(kmsKeyName)"`
**Que hace**: Muestra la clave KMS configurada para el repositorio de Artifact Registry.

#### `gcloud kms keys get-iam-policy KEY --location=LOCATION --keyring=KEYRING`
**Que hace**: Lista todos los permisos IAM asignados a una clave KMS.

---

## Archivos Terraform Creados/Modificados

### main.tf (Modificado)
**Cambio**: Agregado provider `google-beta`.

**Por que**: El recurso `google_project_service_identity` requiere el provider beta.

### storage.tf (Nuevo)
**Proposito**: Define el bucket encriptado con CMEK.

**Recursos**:
- `google_storage_bucket.encrypted_data`

**Configuracion clave**:
```hcl
encryption {
  default_kms_key_name = data.google_kms_crypto_key.data_encryption.id
}
```

### registry.tf (Nuevo)
**Proposito**: Define el repositorio de Artifact Registry con CMEK.

**Recursos**:
- `google_artifact_registry_repository.containers`

**Configuracion clave**:
```hcl
kms_key_name = data.google_kms_crypto_key.data_encryption.id
```

### iam.tf (Nuevo)
**Proposito**: Define Service Accounts y permisos.

**Recursos**:
- `google_service_account.cloud_run_sa`: Service Account para aplicaciones
- `google_kms_crypto_key_iam_member.cloud_run_kms`: Permiso KMS para la app

### cloudrun.tf (Nuevo)
**Proposito**: Prepara permisos para Cloud Run con CMEK.

**Recursos**:
- `google_project_service_identity.cloud_run`: Obtiene el Service Agent de Cloud Run
- `google_kms_crypto_key_iam_member.cloud_run_agent_kms`: Permiso KMS para el agente

**Nota**: El servicio Cloud Run se desplegara en sesiones posteriores.

### outputs.tf (Modificado)
**Cambio**: Agregados outputs para bucket, registry y service account.

---

## Diagrama de Recursos
```
project02-482522
|
+-- Cloud KMS
|   +-- project02-keyring
|       +-- data-encryption-key
|           +-- IAM Policy:
|               +-- cloud-run-sa (app)
|               +-- service-*@gs-project-accounts (Storage)
|               +-- service-*@gcp-sa-artifactregistry (Registry)
|               +-- service-*@serverless-robot-prod (Cloud Run agent)
|
+-- Cloud Storage
|   +-- project02-482522-encrypted-data
|       +-- Encryption: CMEK (data-encryption-key)
|       +-- Versioning: Enabled
|
+-- Artifact Registry
|   +-- containers (DOCKER)
|       +-- Encryption: CMEK (data-encryption-key)
|       +-- URL: us-central1-docker.pkg.dev/project02-482522/containers
|
+-- IAM
    +-- cloud-run-sa@project02-482522.iam.gserviceaccount.com
        +-- Para: Aplicaciones en Cloud Run
```

---

## Practica Empresarial Aplicada

1. **CMEK en todos los recursos de datos**: Bucket y Registry encriptados con clave propia
2. **Principio de minimo privilegio**: Cada Service Account solo tiene el permiso necesario
3. **Separacion de responsabilidades**: Service Account de app vs Service Agents de GCP
4. **Preparacion anticipada**: Permisos de Cloud Run listos antes de desplegar
5. **IaC completo**: Todo definido en Terraform, reproducible

---

## Proxima Sesion

**S03**: Vulnerability Scanning - Container Analysis API. Escanearemos imagenes en Artifact Registry para detectar vulnerabilidades.