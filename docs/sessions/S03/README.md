# S03: Vulnerability Scanning - Container Analysis API

## Objetivo
Habilitar y utilizar el escaneo automatico de vulnerabilidades en imagenes de contenedores almacenadas en Artifact Registry.

---

## Conceptos Clave

### Container Analysis API
Servicio de Google Cloud que analiza automaticamente las imagenes de contenedores en busca de vulnerabilidades conocidas (CVEs).

### Como funciona el escaneo
```
[Push imagen] --> [Artifact Registry] --> [Container Analysis]
                                                   |
                                                   v
                                          [Base de datos CVE]
                                                   |
                                                   v
                                          [Reporte de vulnerabilidades]
```

### Tipos de paquetes analizados
- OS (Debian, Ubuntu, Alpine, etc.)
- PYPI (Python)
- NPM (Node.js)
- MAVEN (Java)
- GO
- RUST
- RUBYGEMS
- NUGET (.NET)
- COMPOSER (PHP)

### Niveles de severidad

| Severidad | CVSS Score    | Accion recomendada        |
|-----------|------------   |-------------------        |
| CRITICAL  | 9.0 - 10.0    | Corregir inmediatamente   |
| HIGH      | 7.0 - 8.9     | Corregir en dias          |
| MEDIUM    | 4.0 - 6.9     | Corregir en semanas       |
| LOW       | 0.1 - 3.9     | Evaluar y planificar      |
| MINIMAL   | Muy bajo      | Monitorear                |

### CVSS (Common Vulnerability Scoring System)
Sistema estandar para evaluar la severidad de vulnerabilidades. Considera:
- Vector de ataque (red, local, fisico)
- Complejidad del ataque
- Privilegios requeridos
- Impacto en confidencialidad, integridad y disponibilidad

---

## APIs Utilizadas

### containeranalysis.googleapis.com
**Proposito**: Almacena y gestiona metadata de artefactos, incluyendo vulnerabilidades.

**Funcionalidades**:
- Almacenar notas de vulnerabilidades
- Crear ocurrencias (instancias de vulnerabilidades en imagenes especificas)
- Consultar vulnerabilidades por imagen

### containerscanning.googleapis.com
**Proposito**: Ejecuta el escaneo automatico de imagenes.

**Funcionalidades**:
- Escaneo automatico al hacer push
- Analisis continuo (re-escanea cuando se descubren nuevas CVEs)
- Soporte para multiples ecosistemas de paquetes

---

## Recursos Creados

### Imagen: demo-app:v1
**Ubicacion**: `us-central1-docker.pkg.dev/project02-482522/containers/demo-app:v1`

**Proposito**: Imagen de prueba para demostrar el escaneo de vulnerabilidades.

**Caracteristicas**:
- Base: python:3.9-slim (Debian)
- Usuario non-root (appuser)
- Aplicacion Python minimal

**Digest**: `sha256:a1c55dab7e9838965c79b50acd296ada7fc28290165b8c0f1163805a7234c563`

---

## Resultados del Escaneo

### Resumen de vulnerabilidades encontradas

| Severidad | Cantidad  | Paquetes principales                      |
|-----------|---------- |---------------------                      |
| MEDIUM    | 2         | pip                                       |
| LOW       | 4         | sqlite3, ncurses, shadow, util-linux      |
| MINIMAL   | 18        | glibc, systemd, apt, tar, perl, coreutils |

### Vulnerabilidades con fix disponible

| CVE           | Paquete   | Version actual| Version fix   | Severidad |
|-----          |---------  |---------------|-------------  |-----------|
| CVE-2025-8869 | pip       | 23.0.1        | 25.3          | MEDIUM    |
| CVE-2023-5752 | pip       | 23.0.1        | 23.3          | MEDIUM    |

### Vulnerabilidades sin fix disponible
La mayoria de las vulnerabilidades MINIMAL y LOW son de paquetes del sistema operativo base (Debian) que aun no tienen parches disponibles. Esto es comun y se monitorea continuamente.

### Analisis continuo
El escaneo tiene `continuousAnalysis: ACTIVE`, lo que significa que GCP re-escaneara la imagen automaticamente cuando se descubran nuevas vulnerabilidades.

---

## Comandos Ejecutados

### Habilitar APIs

#### `gcloud services enable containeranalysis.googleapis.com containerscanning.googleapis.com`
**Que hace**: Habilita las APIs de Container Analysis y Container Scanning.

**Por que dos APIs**:
- `containeranalysis`: Almacena los resultados
- `containerscanning`: Ejecuta el escaneo

### Construir y subir imagen

#### `docker build -t us-central1-docker.pkg.dev/project02-482522/containers/demo-app:v1 .`
**Que hace**: Construye una imagen Docker con el tag especificado.

**Parametros**:
- `-t`: Tag de la imagen (registry/proyecto/repo/nombre:version)
- `.`: Contexto de build (directorio actual)

**Nota**: En este proyecto `docker` es un alias de `podman`.

#### `docker push us-central1-docker.pkg.dev/project02-482522/containers/demo-app:v1`
**Que hace**: Sube la imagen al Artifact Registry.

**Autenticacion**: Usa las credenciales configuradas con `gcloud auth configure-docker`.

### Verificar escaneo

#### `gcloud artifacts docker images list us-central1-docker.pkg.dev/project02-482522/containers`
**Que hace**: Lista las imagenes en el repositorio.

**Muestra**: Nombre, digest, fecha de creacion, tamano.

#### `gcloud artifacts docker images describe IMAGE:TAG --show-package-vulnerability`
**Que hace**: Muestra informacion detallada de la imagen incluyendo vulnerabilidades.

**Secciones del output**:
- `discovery_summary`: Estado del escaneo
- `image_summary`: Metadata de la imagen
- `package_vulnerability_summary`: Lista de CVEs agrupadas por severidad

---

## Archivos Creados

### docker/demo-app/Dockerfile
**Proposito**: Definir como construir la imagen de prueba.

**Contenido**:
```dockerfile
FROM python:3.9-slim

LABEL maintainer="devops-course"
LABEL version="1.0"
LABEL description="Demo app for vulnerability scanning"

WORKDIR /app

RUN echo 'print("Hello from demo-app")' > app.py

RUN useradd --create-home appuser
USER appuser

CMD ["python", "app.py"]
```

**Best practices aplicadas**:
- Usuario non-root (se profundiza en S09)
- Labels para metadata
- Imagen slim (menor superficie de ataque)

---

## Interpretacion de Resultados

### Por que hay tantas vulnerabilidades MINIMAL?
Las imagenes base de Debian/Ubuntu incluyen muchos paquetes del sistema operativo. Muchas CVEs antiguas (2010, 2011, etc.) se clasifican como MINIMAL porque:
- Son dificiles de explotar
- Requieren condiciones muy especificas
- El impacto es limitado
- No hay fix disponible o el fix romperia compatibilidad

### Que hacer con las vulnerabilidades?

| Severidad     | Accion                                                |
|-----------    |--------                                               |
| CRITICAL/HIGH | Bloquear despliegue, corregir inmediatamente          |
| MEDIUM        | Planificar correccion, considerar para proxima release|
| LOW/MINIMAL   | Documentar, monitorear, aceptar riesgo si es necesario|

### Como reducir vulnerabilidades (se vera en S08-S09)
1. Usar imagenes base mas pequenas (alpine, distroless)
2. Multi-stage builds
3. Actualizar paquetes en el Dockerfile
4. Eliminar paquetes innecesarios

---

## Diagrama del flujo de escaneo
```
[Developer]
     |
     | docker build + push
     v
[Artifact Registry]
     |
     | Trigger automatico
     v
[Container Scanning API]
     |
     | Analiza capas de imagen
     v
[Base de datos CVE]
     |
     | Compara paquetes vs CVEs conocidas
     v
[Container Analysis API]
     |
     | Almacena resultados
     v
[Reporte de vulnerabilidades]
     |
     | gcloud describe --show-package-vulnerability
     v
[Developer/CI Pipeline]
```

---

## Practica Empresarial Aplicada

1. **Escaneo automatico**: Cada imagen es escaneada al hacer push
2. **Analisis continuo**: Re-escaneo cuando aparecen nuevas CVEs
3. **Visibilidad**: Reportes detallados por severidad
4. **Trazabilidad**: Cada vulnerabilidad tiene CVE, paquete afectado y fix sugerido
5. **Integracion con CI/CD**: Se puede bloquear despliegues basado en severidad (S04)

---

## Proxima Sesion

**S04**: Filtrado de vulnerabilidades criticas con CVSS. Aprenderemos a crear politicas que bloqueen imagenes con vulnerabilidades de alta severidad.