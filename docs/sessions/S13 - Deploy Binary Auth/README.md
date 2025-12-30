# S13: Build + Push + Firma + Verificacion

## Objetivo
Desplegar Cloud Run con Binary Authorization y verificar que imagenes no firmadas son bloqueadas.

---

## Resultados

### Imagen firmada (secure-app)

| Aspecto		| Valor													|
|---------		|-------												|
| Imagen		| secure-app@sha256:5361a34ac...						|
| Attestation	| secure-build-attestor									|
| Despliegue	| EXITOSO												|
| URL			| https://secure-app-429672679330.us-central1.run.app	|

### Imagen no firmada (fastapi-app)

| Aspecto		| Valor						|
|---------		|-------					|
| Imagen		| fastapi-app:v1			|
| Attestation	| Ninguna					|
| Despliegue	| BLOQUEADO					|
| Error			| "No attestations found"	|

---

## Flujo Demostrado
```
[secure-app firmada]     --> [Binary Auth] --> PERMITIDO --> Cloud Run activo
[fastapi-app no firmada] --> [Binary Auth] --> BLOQUEADO --> Error despliegue
```

---

## Comandos Utilizados

### Desplegar con Binary Authorization
```powershell
gcloud run deploy SERVICE --image IMAGE@DIGEST --binary-authorization default --region REGION --project PROJECT --allow-unauthenticated --port PORT
```

### Verificar URL del servicio
```powershell
gcloud run services describe SERVICE --region REGION --project PROJECT --format "value(status.url)"
```

---

## Endpoints del Servicio

| Endpoint	| Respuesta								|
|----------	|-----------							|
| /			| {"message": "Hello from Secure API"}	|
| /whoami	| {"user": "appuser", "uid": 1000, ...} |
| /health	| {"status": "healthy"}					|

---

## Proxima Sesion

S14: Auditoria completa de imagenes - revisar logs y trazabilidad.