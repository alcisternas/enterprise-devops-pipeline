# S01: KMS – Crear y Rotar Claves

## Objetivo
Comprender las diferencias entre Google-managed y Customer-Managed Encryption Keys (CMEK), crear un keyring con claves de encriptación y firmado, y aprender a rotarlas.

---

## Conceptos Clave

### Google-managed vs CMEK

| Característica                | Google-managed        | CMEK                          |
|----------------               |----------------       |------                         |
| ¿Quién controla las claves?   | Google                | Tú                            |
| Rotación                      | Automática (interna)  | Configurable por ti           |
| Auditoría                     | Limitada              | Completa vía Cloud Audit Logs |
| Revocación                    | No posible            | Posible (deshabilitar clave)  |
| Costo                         | Incluido              | Costo adicional por clave     |
| Uso recomendado               | Datos no sensibles    | Datos sensibles, compliance   |

### Keyring (Llavero)
Contenedor lógico que agrupa claves criptográficas. Características:
- **No se puede eliminar** una vez creado
- Pertenece a una ubicación específica (región o global)
- Organiza claves por proyecto, ambiente o propósito

### Tipos de Claves (Llaves)

| Tipo | Propósito | Rotación | Uso en este curso |
|------|-----------|----------|-------------------|
| Simétrica (ENCRYPT_DECRYPT) | Encriptar/desencriptar datos | Automática configurable | Buckets, discos, Cloud SQL |
| Asimétrica (ASYMMETRIC_SIGN) | Firmar digitalmente | Manual | Firmar imágenes de contenedores |

### Rotación de Claves
- **Rotación**: Crear nueva versión de la clave
- **Versión primaria**: Usada para nuevas operaciones de encriptación
- **Versiones anteriores**: Siguen activas para desencriptar datos existentes
- **Beneficio**: Si una versión se compromete, solo afecta datos encriptados con esa versión

---

## APIs Utilizadas

### cloudkms.googleapis.com
**Propósito**: Servicio de gestión de claves criptográficas de Google Cloud.

**Funcionalidades**:
- Crear y gestionar keyrings y claves
- Encriptar y desencriptar datos
- Firmar y verificar firmas digitales
- Rotación automática de claves

**Por qué se necesita**: Sin esta API no podemos crear ni usar claves KMS.

### storage.googleapis.com
**Propósito**: Servicio de almacenamiento de objetos de Google Cloud.

**Funcionalidades**:
- Crear y gestionar buckets
- Almacenar y recuperar objetos (archivos)
- Configurar políticas de acceso y encriptación

**Por qué se necesita**: El backend de Terraform usa un bucket GCS para almacenar el estado.

### cloudresourcemanager.googleapis.com
**Propósito**: Gestión de recursos y proyectos de Google Cloud.

**Funcionalidades**:
- Gestionar proyectos, carpetas y organizaciones
- Consultar políticas IAM
- Obtener metadata de proyectos

**Por qué se necesita**: Terraform necesita consultar información del proyecto.

---

## Recursos Creados

### Bucket: project02-482522-tfstate
**Tipo**: Google Cloud Storage Bucket

**Propósito**: Almacenar el estado de Terraform (terraform.tfstate) de forma remota y segura.

**Beneficios del backend remoto**:
- Estado compartido entre múltiples desarrolladores
- Locking para evitar modificaciones simultáneas
- Historial de versiones del estado
- No se pierde si tu máquina local falla

**Configuración**:
- Ubicación: us-central1
- Uniform bucket-level access: Habilitado (IAM único, sin ACLs)

### Keyring: project02-keyring
**Tipo**: KMS Key Ring

**Propósito**: Contenedor que agrupa las claves criptográficas del proyecto.

**Ubicación**: us-central1

**Nota importante**: Los keyrings NO se pueden eliminar. Por eso se crean manualmente y no con Terraform.

### Clave: data-encryption-key
**Tipo**: KMS Crypto Key (Simétrica)

**Propósito**: Encriptar datos en reposo (buckets, discos, bases de datos).

**Configuración**:
- Algoritmo: GOOGLE_SYMMETRIC_ENCRYPTION (AES-256-GCM)
- Rotación automática: Cada 90 días (7776000 segundos)
- Próxima rotación: 2026-03-29

**Uso futuro**: S02 (CMEK en buckets y Cloud Run)

### Clave: artifact-signing-key
**Tipo**: KMS Crypto Key (Asimétrica)

**Propósito**: Firmar digitalmente imágenes de contenedores para verificar su autenticidad.

**Configuración**:
- Algoritmo: RSA_SIGN_PKCS1_4096_SHA256
- Rotación: Manual (las claves asimétricas no soportan rotación automática)

**Uso futuro**: S11 (Firmado de imágenes y Binary Authorization)

---

## Comandos Ejecutados

### Configuración de GCP

#### `gcloud config set project project02-482522`
**Qué hace**: Establece el proyecto GCP activo para todos los comandos gcloud siguientes.

**Por qué**: Evita especificar `--project` en cada comando.

#### `gcloud auth application-default set-quota-project project02-482522`
**Qué hace**: Configura el proyecto de cuota para las credenciales de aplicación por defecto (ADC).

**Por qué**: Las bibliotecas que usan ADC (como Terraform) necesitan saber a qué proyecto facturar las operaciones.

#### `gcloud services enable cloudkms.googleapis.com storage.googleapis.com cloudresourcemanager.googleapis.com`
**Qué hace**: Habilita las APIs especificadas en el proyecto.

**Sintaxis**: `gcloud services enable [API_1] [API_2] [API_N]`

**Por qué**: Las APIs están deshabilitadas por defecto. Debe habilitarse cada servicio antes de usarlo.

### Creación de Bucket

#### `gcloud storage buckets create gs://project02-482522-tfstate --location=us-central1 --uniform-bucket-level-access`
**Qué hace**: Crea un bucket de Cloud Storage.

**Parámetros**:
- `gs://project02-482522-tfstate`: URI del bucket (debe ser globalmente único)
- `--location=us-central1`: Región donde se almacenan los datos
- `--uniform-bucket-level-access`: Usa solo IAM para control de acceso (no ACLs legacy)

**Por qué uniform-bucket-level-access**: Simplifica la gestión de permisos y es la práctica recomendada.

### Creación de KMS

#### `gcloud kms keyrings create project02-keyring --location=us-central1`
**Qué hace**: Crea un keyring en la ubicación especificada.

**Parámetros**:
- `project02-keyring`: Nombre del keyring
- `--location=us-central1`: Región (debe coincidir con los recursos que usarán las claves)

**Nota**: Los keyrings no se pueden eliminar después de creados.

#### `gcloud kms keys create data-encryption-key --location=us-central1 --keyring=project02-keyring --purpose=encryption --rotation-period=7776000s --next-rotation-time=2026-03-29T00:00:00Z`
**Qué hace**: Crea una clave de encriptación simétrica con rotación automática.

**Parámetros**:
- `data-encryption-key`: Nombre de la clave
- `--location`: Región del keyring
- `--keyring`: Keyring contenedor
- `--purpose=encryption`: Tipo de clave (simétrica para encriptar/desencriptar)
- `--rotation-period=7776000s`: Rotar cada 90 días (90 × 24 × 60 × 60 = 7,776,000 segundos)
- `--next-rotation-time`: Fecha de la primera rotación automática (debe ser futura)

#### `gcloud kms keys create artifact-signing-key --location=us-central1 --keyring=project02-keyring --purpose=asymmetric-signing --default-algorithm=rsa-sign-pkcs1-4096-sha256`
**Qué hace**: Crea una clave asimétrica para firmas digitales.

**Parámetros**:
- `--purpose=asymmetric-signing`: Para firmar (no encriptar)
- `--default-algorithm=rsa-sign-pkcs1-4096-sha256`: RSA 4096 bits con SHA-256

**Por qué RSA 4096**: Mayor seguridad para firmas de larga duración (imágenes de contenedores).

### Rotación Manual

#### `gcloud kms keys versions create --location=us-central1 --keyring=project02-keyring --key=data-encryption-key`
**Qué hace**: Crea una nueva versión de la clave.

**Por qué**: Demuestra rotación manual. En producción, la rotación automática hace esto periódicamente.

#### `gcloud kms keys update data-encryption-key --location=us-central1 --keyring=project02-keyring --primary-version=2`
**Qué hace**: Establece la versión 2 como primaria.

**Efecto**: Las nuevas operaciones de encriptación usarán la versión 2. La versión 1 sigue activa para desencriptar datos existentes.

### Verificación

#### `gcloud kms keys list --location=us-central1 --keyring=project02-keyring`
**Qué hace**: Lista todas las claves en un keyring.

**Muestra**: Nombre, propósito, algoritmo, nivel de protección, versión primaria.

#### `gcloud kms keys versions list --location=us-central1 --keyring=project02-keyring --key=data-encryption-key`
**Qué hace**: Lista todas las versiones de una clave específica.

**Muestra**: Nombre completo de cada versión y su estado (ENABLED, DISABLED, DESTROYED).

---

## Archivos Terraform

### main.tf
**Propósito**: Configuración principal de Terraform.

**Contenido**:
- `terraform {}`: Versión requerida y providers
- `backend "gcs"`: Almacena estado en bucket remoto
- `provider "google"`: Configura acceso a GCP

### variables.tf
**Propósito**: Declaración de variables de entrada.

**Variables definidas**:
- `project_id`: ID del proyecto GCP
- `region`: Región por defecto

### terraform.tfvars
**Propósito**: Valores de las variables.

**Nota**: En producción, este archivo puede contener datos sensibles y no debe commitearse. En este curso lo incluimos para facilitar el aprendizaje.

### outputs.tf
**Propósito**: Valores de salida que Terraform muestra después de apply.

**Outputs definidos**:
- IDs del proyecto y región
- IDs completos de keyring y claves KMS

### kms.tf
**Propósito**: Referencias a recursos KMS existentes (no gestionados por Terraform).

**Data sources**:
- `google_kms_key_ring`: Lee información del keyring
- `google_kms_crypto_key`: Lee información de cada clave

**Por qué data sources y no resources**: Los recursos KMS se crearon manualmente porque son permanentes. Terraform solo los referencia para usarlos en otros recursos.

---

## Práctica Empresarial Aplicada

1. **KMS manual, no Terraform**: Los keyrings no se eliminan, evitamos accidentes con `terraform destroy`
2. **Backend remoto**: Estado compartido y protegido
3. **Uniform bucket-level access**: IAM consistente, sin ACLs legacy
4. **Rotación automática**: Seguridad continua sin intervención manual
5. **Separación de claves por propósito**: Una para datos, otra para firmas

---

## Diagrama de Recursos
```
project02-482522
│
├── APIs Habilitadas
│   ├── cloudkms.googleapis.com
│   ├── storage.googleapis.com
│   └── cloudresourcemanager.googleapis.com
│
├── Cloud Storage
│   └── project02-482522-tfstate (Backend Terraform)
│
└── Cloud KMS
    └── project02-keyring (us-central1)
        ├── data-encryption-key (Simétrica, rotación 90d)
        │   ├── version/1 (ENABLED)
        │   └── version/2 (ENABLED, PRIMARY)
        └── artifact-signing-key (Asimétrica RSA-4096)
```

---

## Próxima Sesión

**S02**: Aplicar CMEK a buckets y Cloud Run. Usaremos `data-encryption-key` para encriptar recursos.