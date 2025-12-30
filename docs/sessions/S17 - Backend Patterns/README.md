# S17: Backend Patterns - Remote State

## Objetivo
Entender patrones de backend remoto y workspaces. Los modulos creados en S15-S16 son plantillas reutilizables.

---

## Patron Aplicado en Este Curso

Este curso usa un **proyecto evolutivo** con un unico `terraform/` que crece por sesion:
```
terraform/
├── main.tf          # Provider, backend GCS
├── variables.tf     
├── outputs.tf       
├── kms.tf           # S01
├── storage.tf       # S02
├── registry.tf      # S02
├── iam.tf           # S02
└── modules/         # Plantillas reutilizables (S15-S16)
```

---

## Patron Alternativo: Multiples Ambientes

En empresas grandes se usa separacion por ambiente:
```
terraform/
├── modules/              # Plantillas compartidas
└── environments/
    ├── dev/
    │   └── main.tf       # Llama a modules con valores dev
    └── prod/
        └── main.tf       # Llama a modules con valores prod
```

**Cuando usar**:
- Equipos grandes con permisos separados
- Compliance que requiere aislamiento
- Diferentes cuentas GCP por ambiente

**Este curso no lo implementa** para mantener simplicidad del proyecto evolutivo.

---

## Backend Remoto GCS

Ya configurado en `terraform/main.tf`:
```hcl
terraform {
  backend "gcs" {
    bucket = "project02-482522-tfstate"
    prefix = "terraform/state"
  }
}
```

### Beneficios
- Estado compartido entre equipos
- Locking automatico (previene conflictos)
- Versionado del estado
- Encriptacion en reposo

---

## Proxima Sesion

S18: Continuacion de patrones Terraform avanzados.