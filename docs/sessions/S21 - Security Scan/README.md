# S21: Analisis de Seguridad con tflint, tfsec, checkov

## Objetivo
Agregar herramientas de analisis estatico de seguridad al pipeline Terraform.

---

## Herramientas

| Herramienta	| Proposito			| Enfoque						|
|-------------	|-----------		|---------						|
| tflint		| Linter Terraform	| Sintaxis, best practices		|
| tfsec			| Scanner seguridad | Vulnerabilidades, misconfigs	|
| checkov		| Scanner IaC		| Compliance, policies			|

---

## Archivos Creados

| Archivo									| Proposito					|
|---------									|-----------				|
| scripts/terraform/security-scan.sh		| Scan local (Linux/CI)		|
| .github/workflows/terraform-security.yml	| Scan automatico en PR/push|

---

## Ejemplos de Detecciones

### tfsec
- Bucket sin encriptacion
- Firewall rules muy permisivas
- IAM con permisos excesivos

### checkov
- Recursos sin tags
- Logging deshabilitado
- Versiones no especificadas

---

## Integracion CI/CD

El workflow terraform-security.yml:
1. Se ejecuta en PRs y push a main
2. Corre tfsec y checkov
3. soft_fail=true (no bloquea, solo reporta)

Para bloquear PRs con vulnerabilidades, cambiar a soft_fail: false

---

## Proxima Sesion

S22: Instalar Jenkins en GCE con Podman.