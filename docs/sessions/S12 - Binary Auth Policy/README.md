# S12: Politica de Despliegue Segura Basada en Firma

## Objetivo
Configurar Binary Authorization para bloquear imagenes no firmadas.

---

## Politica Configurada

### Archivo: policies/binary-auth-policy.yaml

### Reglas aplicadas

| Regla					| Valor							| Efecto							|
|-------				|-------						|--------							|
| defaultAdmissionRule	| REQUIRE_ATTESTATION			| Solo imagenes firmadas			|
| enforcementMode		| ENFORCED_BLOCK_AND_AUDIT_LOG	| Bloquea y registra				|
| requireAttestationsBy | secure-build-attestor			| Requiere firma de nuestro attestor|

### Whitelist (imagenes permitidas sin firma)

- gcr.io/google-samples/*
- gcr.io/cloudrun/*
- gcr.io/knative-releases/*

---

## Comandos Utilizados

### Importar politica
```powershell
gcloud container binauthz policy import policies/binary-auth-policy.yaml --project PROJECT_ID
```

### Exportar/verificar politica
```powershell
gcloud container binauthz policy export --project PROJECT_ID
```

### Habilitar en Cloud Run
```powershell
gcloud run services update SERVICE --binary-authorization default --region REGION --project PROJECT_ID
```

---

## Flujo de Validacion
```
[Imagen sin firma] --> [Binary Authorization] --> BLOQUEADA
[Imagen firmada]   --> [Binary Authorization] --> PERMITIDA
```

---

## Proxima Sesion

S13: Desplegar Cloud Run con Binary Authorization habilitado y probar bloqueo de imagenes no firmadas.