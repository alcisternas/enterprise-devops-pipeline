# S20: Pipeline Terraform Seguro (validate -> plan)

## Objetivo
Crear pipeline completo de CI/CD para Terraform con validacion y plan automatizado.

---

## Archivos Creados

| Archivo								| Proposito					|
|---------								|-----------				|
| .github/workflows/terraform-main.yml	| Pipeline CI en push a main|
| scripts/terraform/pipeline.ps1		| Pipeline local PowerShell |

---

## Pipeline Steps

| Step			| Comando				| Falla si					|
|------			|---------				|----------					|
| 1. Format		| terraform fmt -check	| Archivos sin formatear	|
| 2. Init		| terraform init		| Error de backend/providers|
| 3. Validate	| terraform validate	| Sintaxis invalida			|
| 4. Plan		| terraform plan		| Errores de configuracion	|
| 5. Apply		| terraform apply		| Solo manual con flag		|

---

## Uso Local
```powershell
# Solo validar (sin apply)
.\scripts\terraform\pipeline.ps1

# Validar y aplicar
.\scripts\terraform\pipeline.ps1 -Apply
```

---

## Resultado de Validacion
```
[PASS] Format OK
[PASS] Init OK
[PASS] Validate OK
[PASS] Plan OK - No changes needed
```

---

## Proxima Sesion

S21: Analisis de seguridad con tflint, tfsec, checkov.