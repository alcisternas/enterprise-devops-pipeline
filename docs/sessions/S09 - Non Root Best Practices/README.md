# S09: Imagenes Non-root y Best Practices

## Objetivo
Profundizar en seguridad de contenedores: usuario no privilegiado, permisos minimos y otras mejores practicas.

---

## Conceptos Clave

### Por que NO ejecutar como root?

| Riesgo                    | Descripcion                                               |
|--------                   |-------------                                              |
| Escalada de privilegios   | Un atacante que compromete el contenedor tiene acceso root|
| Modificacion del sistema  | Root puede modificar /etc/passwd, /etc/shadow, etc.       |
| Escape del contenedor     | Vulnerabilidades de kernel son mas explotables como root  |
| Compliance                | Muchos estandares (PCI-DSS, HIPAA) prohiben root          |

### Demostracion del riesgo
```powershell
# Root PUEDE modificar archivos del sistema
docker run --rm secure-app:root sh -c "echo 'hacked' >> /etc/passwd"
# Resultado: Exitoso (PELIGROSO)

# Non-root NO puede modificar archivos del sistema
docker run --rm secure-app:nonroot sh -c "echo 'hacked' >> /etc/passwd"
# Resultado: Permission denied (SEGURO)
```

---

## Tres Niveles de Seguridad

### 1. Root (INSEGURO)
```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY . .
CMD ["python", "app.py"]
# Usuario: root (UID 0)
```

**Problemas**:
- Ejecuta como UID 0
- Puede modificar cualquier archivo
- Maximo riesgo de seguridad

### 2. Non-root Basico (SEGURO)
```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY . .

# Crear usuario
RUN useradd --create-home --uid 1000 appuser
RUN chown -R appuser:appuser /app
USER appuser

CMD ["python", "app.py"]
```

**Mejoras**:
- Usuario non-root (UID 1000)
- No puede modificar archivos del sistema
- Suficiente para muchos casos

### 3. Hardened (MAXIMA SEGURIDAD)
```dockerfile
FROM python:3.11-slim AS builder
# ... build stage ...

FROM python:3.11-slim AS runtime
# Actualizar paquetes de seguridad
RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*

# Usuario sin shell
RUN useradd --create-home --uid 1000 --shell /usr/sbin/nologin appuser

# Variables de seguridad
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1

# Ownership correcto
COPY --chown=appuser:appuser . .

USER appuser
HEALTHCHECK ...
CMD ["python", "app.py"]
```

**Mejoras adicionales**:
- Multi-stage build
- Paquetes actualizados
- Usuario sin shell de login
- Variables de entorno seguras
- Healthcheck integrado

---

## Best Practices Aplicadas

### 1. Usuario non-root
```dockerfile
RUN useradd --create-home --uid 1000 --shell /usr/sbin/nologin appuser
USER appuser
```

| Opcion                    | Proposito                         |
|--------                   |-----------                        |
| --create-home             | Crear directorio home             |
| --uid 1000                | UID predecible y no privilegiado  |
| --shell /usr/sbin/nologin | Prevenir login interactivo        |

### 2. Ownership correcto
```dockerfile
# Opcion A: En COPY
COPY --chown=appuser:appuser main.py .

# Opcion B: Despues de COPY
COPY main.py .
RUN chown -R appuser:appuser /app
```

### 3. Actualizar paquetes de seguridad
```dockerfile
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
```

### 4. Variables de entorno seguras
```dockerfile
ENV PYTHONDONTWRITEBYTECODE=1 \  # No crear .pyc
    PYTHONUNBUFFERED=1 \         # Output sin buffer
    PYTHONFAULTHANDLER=1 \       # Stack traces en errores
    PIP_NO_CACHE_DIR=1 \         # No cache de pip
    PIP_DISABLE_PIP_VERSION_CHECK=1  # No verificar version
```

### 5. Healthcheck
```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1
```

| Parametro     | Valor | Descripcion                   |
|-----------    |-------|-------------                  |
| interval      | 30s   | Frecuencia de verificacion    |
| timeout       | 10s   | Tiempo maximo de espera       |
| start-period  | 5s    | Gracia inicial para arranque  |
| retries       | 3     | Intentos antes de unhealthy   |

### 6. Sin shell en imagen hardened
```dockerfile
--shell /usr/sbin/nologin
```

**Beneficio**: Si un atacante compromete el contenedor, no puede obtener shell interactivo.

---

## Comparacion de Imagenes

| Caracteristica        | root          | nonroot               | hardened              |
|----------------       |------         |---------              |----------             |
| Usuario               | root (UID 0)  | appuser (UID 1000)    | appuser (UID 1000)    |
| Shell                 | /bin/bash     | /bin/bash             | /usr/sbin/nologin     |
| Multi-stage           | No            | No                    | Si                    |
| Paquetes actualizados | No            | No                    | Si                    |                   
| Healthcheck           | No            | No                    | Si                    |
| Variables seguras     | No            | No                    | Si                    |
| Tamano                | 156 MB        | 156 MB                | 170 MB                |

---

## Verificacion de Usuario

### Endpoint /whoami
```python
@app.get("/whoami")
def whoami():
    return {
        "user": os.getenv("USER", "unknown"),
        "uid": os.getuid(),
        "gid": os.getgid(),
        "home": os.getenv("HOME", "unknown")
    }
```

### Resultados
```json
// Imagen root
{"user": "root", "uid": 0, "gid": 0, "home": "/root"}

// Imagen nonroot/hardened
{"user": "appuser", "uid": 1000, "gid": 1000, "home": "/home/appuser"}
```

---

## Archivos Creados
```
docker/secure-app/
├── requirements.txt       # Dependencias
├── main.py               # App con endpoint /whoami
├── Dockerfile.root       # INSEGURO - root
├── Dockerfile.nonroot    # SEGURO - non-root basico
└── Dockerfile.hardened   # MAXIMA SEGURIDAD
```

---

## Comandos Utiles

### Verificar usuario en contenedor
```powershell
docker run --rm IMAGE whoami
docker run --rm IMAGE id
```

### Verificar que no puede escribir en sistema
```powershell
docker run --rm IMAGE sh -c "echo test >> /etc/passwd"
# Debe fallar con "Permission denied"
```

### Inspeccionar usuario de imagen
```powershell
docker inspect IMAGE --format '{{.Config.User}}'
```

---

## Recomendaciones por Ambiente

| Ambiente          | Dockerfile recomendado        |
|----------         |------------------------       |
| Desarrollo        | nonroot                       |
| Staging           | hardened                      |
| Produccion        | hardened                      |
| PCI/HIPAA/SOC2    | hardened + scan obligatorio   |

---

## Proxima Sesion

**S10**: Autenticacion Docker/Podman con Artifact Registry. Configuraremos autenticacion segura para push/pull de imagenes.