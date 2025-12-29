# S10: Autenticacion Docker/Podman con Artifact Registry

## Objetivo
Configurar y entender los metodos de autenticacion para push/pull de imagenes con Artifact Registry.

---

## Metodos de Autenticacion

### Resumen

| Metodo                    | Uso                       | Seguridad | Configuracion |
|--------                   |-----                      |-----------|---------------|
| gcloud credential helper  | Desarrollo local          | Alta      | Automatica    |
| Token de acceso           | CI/CD                     | Media     | Manual        |
| Service Account Key       | CI/CD legacy              | Media     | JSON file     |
| Workload Identity         | GKE/Cloud Run/Cloud Build | Alta      | Sin secretos  |

---

## Metodo 1: gcloud Credential Helper (Recomendado para desarrollo)

### Configuracion
```powershell
gcloud auth configure-docker us-central1-docker.pkg.dev
```

### Resultado en ~/.docker/config.json
```json
{
  "credHelpers": {
    "us-central1-docker.pkg.dev": "gcloud"
  }
}
```

### Como funciona

1. Docker/Podman intenta push/pull
2. Detecta credential helper "gcloud"
3. Ejecuta `gcloud auth print-access-token`
4. Usa el token para autenticar

### Ventajas

- No requiere gestionar secretos
- Usa la sesion activa de gcloud
- Se renueva automaticamente

### Desventajas

- Requiere gcloud instalado
- No funciona en todos los CI/CD

---

## Metodo 2: Token de Acceso (CI/CD)

### Obtener token
```bash
gcloud auth print-access-token
```

### Autenticar Docker
```bash
# Linux/bash
echo $(gcloud auth print-access-token) | docker login -u oauth2accesstoken --password-stdin us-central1-docker.pkg.dev

# En CI/CD con variable
echo $ACCESS_TOKEN | docker login -u oauth2accesstoken --password-stdin us-central1-docker.pkg.dev
```

### Caracteristicas

- Token expira en 1 hora
- Usuario siempre es `oauth2accesstoken`
- Util para scripts de CI/CD

---

## Metodo 3: Service Account Key (Legacy)

### Crear Service Account
```powershell
gcloud iam service-accounts create docker-pusher --display-name="Docker Pusher"
```

### Asignar permisos
```powershell
gcloud projects add-iam-policy-binding PROJECT_ID \
    --member="serviceAccount:docker-pusher@PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/artifactregistry.writer"
```

### Crear key JSON
```powershell
gcloud iam service-accounts keys create key.json \
    --iam-account=docker-pusher@PROJECT_ID.iam.gserviceaccount.com
```

### Autenticar
```bash
cat key.json | docker login -u _json_key --password-stdin us-central1-docker.pkg.dev
```

### Advertencias

- NO RECOMENDADO para nuevos proyectos
- Keys JSON son dificiles de rotar
- Si se filtra, compromete el proyecto
- Preferir Workload Identity

---

## Metodo 4: Workload Identity (Recomendado para GCP)

### Que es?

Permite que cargas de trabajo en GCP se autentiquen sin secretos, usando la identidad del recurso.

### Donde funciona

| Servicio          | Soporte                       |
|----------         |---------                      |
| GKE               | Si (configuracion requerida)  |
| Cloud Run         | Si (automatico)               |
| Cloud Build       | Si (automatico)               |
| Compute Engine    | Si (Service Account adjunta)  |

### En Cloud Build (automatico)
```yaml
steps:
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'us-central1-docker.pkg.dev/$PROJECT_ID/containers/app:latest']
```

No requiere autenticacion explicita - Cloud Build tiene permisos automaticos.

### En Cloud Run (automatico)

Cloud Run puede hacer pull de Artifact Registry automaticamente si el Service Account tiene permisos.

### En GKE
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    iam.gke.io/gcp-service-account: GSA@PROJECT.iam.gserviceaccount.com
```

---

## Permisos Requeridos

### Roles de Artifact Registry

| Rol                       | Permisos                  |
|-----                      |----------                 |
| artifactregistry.reader   | Pull imagenes             |
| artifactregistry.writer   | Push + Pull imagenes      |
| artifactregistry.admin    | Administrar repositorios  |

### Asignar permisos
```powershell
# A usuario
gcloud projects add-iam-policy-binding PROJECT_ID \
    --member="user:email@domain.com" \
    --role="roles/artifactregistry.writer"

# A Service Account
gcloud projects add-iam-policy-binding PROJECT_ID \
    --member="serviceAccount:SA@PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/artifactregistry.writer"
```

---

## Script de Autenticacion

### Ubicacion
`scripts/auth/docker-auth.sh`

### Logica
```
1. Si gcloud disponible -> usar credential helper
2. Si GOOGLE_APPLICATION_CREDENTIALS -> usar SA key
3. Si metadata server disponible -> usar Workload Identity
4. Si nada disponible -> error
```

### Uso
```bash
chmod +x scripts/auth/docker-auth.sh
./scripts/auth/docker-auth.sh
```

---

## Verificar Autenticacion

### Probar pull
```powershell
docker pull us-central1-docker.pkg.dev/PROJECT/REPO/IMAGE:TAG
```

### Ver configuracion actual
```powershell
cat ~/.docker/config.json
```

### Ver identidad activa
```powershell
gcloud auth list
```

---

## Troubleshooting

### Error: "unauthorized"
```
Error: unauthorized: Access denied
```

**Solucion**: Verificar permisos del usuario/SA
```powershell
gcloud projects get-iam-policy PROJECT_ID --filter="bindings.members:IDENTITY"
```

### Error: "gcloud not found"

**Solucion**: Instalar gcloud CLI o usar token de acceso

### Error: "token expired"

**Solucion**: Los tokens duran 1 hora, regenerar con:
```bash
gcloud auth print-access-token
```

---

## Mejores Practicas

1. **Desarrollo local**: Usar gcloud credential helper
2. **CI/CD en GCP**: Usar Workload Identity (sin secretos)
3. **CI/CD externo**: Usar token de acceso con SA dedicado
4. **Evitar**: JSON keys en repositorios o variables de entorno
5. **Rotar**: Si usas keys, rotar cada 90 dias maximo

---

## Proxima Sesion

**S11**: Firmado de imagenes con Artifact Registry. Aprenderemos a firmar imagenes para garantizar su integridad y procedencia.