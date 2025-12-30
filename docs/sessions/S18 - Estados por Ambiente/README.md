# S18: Patron de Estados por Ambiente

## Objetivo
Entender el patron de estados separados por ambiente y cuando aplicarlo.

---

## Patron NO Aplicado en Este Curso

Este curso usa **proyecto evolutivo unico** donde todo el estado vive en:
```
gs://project02-482522-tfstate/terraform/state
```

---

## Patron Alternativo: Estado por Ambiente

En empresas grandes, cada ambiente tiene su propio estado:
```
gs://bucket-tfstate/dev/terraform.tfstate
gs://bucket-tfstate/staging/terraform.tfstate
gs://bucket-tfstate/prod/terraform.tfstate
```

### Implementacion con prefix
```hcl
# dev/main.tf
terraform {
  backend "gcs" {
    bucket = "company-tfstate"
    prefix = "dev"
  }
}

# prod/main.tf
terraform {
  backend "gcs" {
    bucket = "company-tfstate"
    prefix = "prod"
  }
}
```

### Implementacion con workspaces
```hcl
terraform {
  backend "gcs" {
    bucket = "company-tfstate"
    prefix = "environments"
  }
}

# Uso:
# terraform workspace new dev
# terraform workspace new prod
# terraform workspace select dev
```

---

## Cuando Usar Estados Separados

| Situacion                         | Recomendacion     |
|-----------                        |---------------    |
| Proyecto pequeno / aprendizaje    | Estado unico      |
| Equipo pequeno (1-5 personas)     | Estado unico      |
| Equipos separados por ambiente    | Estados separados |
| Compliance / auditoria estricta   | Estados separados |
| Diferentes permisos por ambiente  | Estados separados |

---

## Ventajas de Estados Separados

1. **Aislamiento**: Error en dev no afecta prod
2. **Permisos**: Equipo dev sin acceso a estado prod
3. **Auditoria**: Cambios trackeables por ambiente
4. **Rollback**: Mas facil revertir un ambiente

## Desventajas

1. **Complejidad**: Multiples `terraform apply`
2. **Sincronizacion**: Mantener modulos consistentes
3. **Overhead**: Mas archivos, mas configuracion

---

## Proxima Sesion

S19: Como evitar que un PR ejecute apply.