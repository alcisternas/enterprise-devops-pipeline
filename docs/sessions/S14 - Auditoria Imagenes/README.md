# S14: Auditoria Completa de Imagenes

## Objetivo
Revisar logs, trazabilidad y herramientas de auditoria para imagenes y despliegues.

---

## Herramientas de Auditoria

### 1. Logs de Binary Authorization
```powershell
gcloud logging read "protoPayload.status.message:\"denied by attestor\"" --project PROJECT --limit 5
```

Muestra intentos de despliegue bloqueados por falta de firma.

### 2. Attestations
```powershell
gcloud container binauthz attestations list --attestor ATTESTOR --attestor-project PROJECT
```

Lista todas las imagenes firmadas.

### 3. Artifact Registry
```powershell
gcloud artifacts docker images list REGISTRY --include-tags
```

Lista imagenes con tags y fechas.

---

## Script de Auditoria

### Ubicacion
scripts/audit/audit-images.ps1

### Uso
```powershell
.\audit-images.ps1 -Project "PROJECT_ID"
```

### Output
- Imagenes en registry
- Attestations (firmas)
- Servicios Cloud Run
- Estado de politica Binary Auth

---

## Trazabilidad Completa

| Pregunta				| Comando										|
|----------				|---------										|
| Que imagenes tenemos? | gcloud artifacts docker images list			|
| Cuales estan firmadas?| gcloud container binauthz attestations list	|
| Que esta desplegado?	| gcloud run services list						|
| Que fue bloqueado?	| gcloud logging read (Binary Auth)				|

---

## Proxima Sesion

S15: Terraform modules - modularizar infraestructura.