# S19: Como Evitar que un PR Ejecute Apply

## Objetivo
Configurar protecciones para que cambios en Terraform requieran revision antes de aplicarse.

---

## Principio de Seguridad

**NUNCA ejecutar terraform apply automaticamente en un PR.**

| Accion	| En PR | Post-Merge|
|--------	|-------|-----------|
| fmt		| Si	| Si		|
| init		| Si	| Si		|
| validate	| Si	| Si		|
| plan		| Si	| Si		|
| apply		| NO	| Manual	|

---

## Archivos Creados

### Script local: scripts/terraform/validate-pr.sh

Valida cambios antes de crear PR.

### GitHub Actions: .github/workflows/terraform-pr.yml

Se ejecuta automaticamente en PRs que modifican terraform/.

---

## Validacion Local Realizada
```powershell
terraform fmt -check -recursive  # Sin cambios
terraform init                    # Inicializado
terraform validate                # Configuracion valida
terraform plan                    # Sin cambios pendientes
```

---

## Proxima Sesion

S20: Pipeline Terraform seguro (validate -> plan).