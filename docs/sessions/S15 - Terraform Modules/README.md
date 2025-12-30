# S15: Terraform Modules - Modularizar Infraestructura

## Objetivo
Refactorizar la infraestructura Terraform en modulos reutilizables.

---

## Modulos Creados

### 1. artifact-registry

Crea repositorios de Artifact Registry con CMEK opcional.

| Variable      | Tipo      | Requerido | Descripcion           |
|----------     |------     |-----------|-------------          |
| project_id    | string    | Si        | ID del proyecto       |
| region        | string    | Si        | Region GCP            |
| repository_id | string    | Si        | Nombre del repositorio|
| kms_key_name  | string    | No        | Clave KMS para CMEK   |

### 2. cloud-run

Despliega servicios en Cloud Run.

| Variable              | Tipo   | Requerido| Default   | Descripcion           |
|----------             |------  |----------|---------  |-------------          |
| project_id            | string | Si       | -         | ID del proyecto       |
| region                | string | Si       | -         | Region GCP            |
| service_name          | string | Si       | -         | Nombre del servicio   |
| image                 | string | Si       | -         | URL de la imagen      |
| port                  | number | No       | 8080      | Puerto del contenedor |
| allow_unauthenticated | bool   | No       | false     | Acceso publico        |

### 3. iam

Crea Service Accounts con roles asignados.

| Variable      | Tipo          | Requerido | Descripcion       |
|----------     |------         |-----------|-------------      |
| project_id    | string        | Si        | ID del proyecto   |
| account_id    | string        | Si        | ID de la cuenta   |
| display_name  | string        | Si        | Nombre visible    |
| roles         | list(string)  | No        | Roles IAM         |

---

## Estructura
```
terraform/modules/
├── artifact-registry/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── cloud-run/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
└── iam/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

---

## Uso de Modulos
```hcl
module "registry" {
  source        = "./modules/artifact-registry"
  project_id    = var.project_id
  region        = var.region
  repository_id = "my-repo"
  kms_key_name  = data.google_kms_crypto_key.key.id
}

module "api_service" {
  source        = "./modules/cloud-run"
  project_id    = var.project_id
  region        = var.region
  service_name  = "api"
  image         = "gcr.io/project/image:tag"
  allow_unauthenticated = true
}
```

---

## Proxima Sesion

S16: Networking - VPC, subnets y firewall rules.