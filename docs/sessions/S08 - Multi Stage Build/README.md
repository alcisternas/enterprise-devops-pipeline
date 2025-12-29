# S08: Multi-stage Builds - Reduccion de Tamano y Capas

## Objetivo
Aprender a usar multi-stage builds para crear imagenes mas pequenas, seguras y eficientes.

---

## Conceptos Clave

### Single-stage Build (Tradicional)
```dockerfile
FROM python:3.11-slim
RUN apt-get install -y gcc    # Queda en imagen final
RUN pip install dependencies
COPY app .
CMD ["python", "app.py"]
```

**Problema**: Herramientas de compilacion (gcc, build-essential) quedan en la imagen final aunque no se usan en runtime.

### Multi-stage Build (Optimizado)
```dockerfile
# Stage 1: Builder
FROM python:3.11-slim AS builder
RUN apt-get install -y gcc
RUN pip install dependencies

# Stage 2: Runtime
FROM python:3.11-slim AS runtime
COPY --from=builder /dependencies /dependencies
COPY app .
CMD ["python", "app.py"]
```

**Solucion**: Las herramientas de compilacion solo existen en el stage builder y no se copian a la imagen final.

---

## Resultados Obtenidos

### Comparacion de Tamanos

| Dockerfile | Tamano | Diferencia |
|------------|--------|------------|
| Single-stage | 354 MB | - |
| Multi-stage | 170 MB | -52% |

### Ahorro: 184 MB (52% menos)

---

## Beneficios de Multi-stage Builds

### 1. Imagen mas pequena
- Menos tiempo de descarga
- Menor costo de almacenamiento
- Despliegues mas rapidos

### 2. Menor superficie de ataque
- Sin herramientas de compilacion (gcc, make)
- Sin gestores de paquetes innecesarios
- Menos vulnerabilidades potenciales

### 3. Separacion de responsabilidades
- Stage builder: compilar y preparar
- Stage runtime: ejecutar

### 4. Cache de capas mas eficiente
- Cambios en codigo no invalidan cache de dependencias
- Builds incrementales mas rapidos

---

## Anatomia del Dockerfile Multi-stage
```dockerfile
# =============================================================================
# Stage 1: Builder
# =============================================================================
FROM python:3.11-slim AS builder

# Herramientas de compilacion (NO van a imagen final)
RUN apt-get update && apt-get install -y gcc

# Virtualenv para aislar dependencias
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Instalar dependencias
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# =============================================================================
# Stage 2: Runtime (imagen final)
# =============================================================================
FROM python:3.11-slim AS runtime

# Copiar SOLO el virtualenv (sin gcc)
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copiar codigo
COPY main.py .

# Usuario non-root
RUN useradd --create-home appuser
USER appuser

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Elementos clave

| Elemento | Proposito |
|----------|-----------|
| `AS builder` | Nombra el stage para referencia |
| `COPY --from=builder` | Copia archivos de otro stage |
| `/opt/venv` | Virtualenv con dependencias instaladas |
| `--no-cache-dir` | No guardar cache de pip (reduce tamano) |

---

## Patrones Comunes de Multi-stage

### Python con Virtualenv
```dockerfile
FROM python:3.11-slim AS builder
RUN python -m venv /opt/venv
COPY requirements.txt .
RUN /opt/venv/bin/pip install -r requirements.txt

FROM python:3.11-slim
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
```

### Go (compilado)
```dockerfile
FROM golang:1.21 AS builder
COPY . .
RUN go build -o /app

FROM gcr.io/distroless/static
COPY --from=builder /app /app
CMD ["/app"]
```

### Node.js
```dockerfile
FROM node:20 AS builder
COPY package*.json .
RUN npm ci --only=production

FROM node:20-slim
COPY --from=builder /node_modules /node_modules
COPY . .
CMD ["node", "app.js"]
```

---

## Optimizaciones Adicionales

### 1. Ordenar instrucciones por frecuencia de cambio
```dockerfile
# Menos frecuente (primero - mejor cache)
COPY requirements.txt .
RUN pip install -r requirements.txt

# Mas frecuente (ultimo)
COPY . .
```

### 2. Usar .dockerignore
```
.git
__pycache__
*.pyc
.env
tests/
docs/
```

### 3. Combinar comandos RUN
```dockerfile
# MAL - Multiples capas
RUN apt-get update
RUN apt-get install -y gcc
RUN rm -rf /var/lib/apt/lists/*

# BIEN - Una sola capa
RUN apt-get update && apt-get install -y gcc && rm -rf /var/lib/apt/lists/*
```

### 4. Usar imagenes base pequenas

| Imagen | Tamano |
|--------|--------|
| python:3.11 | ~1 GB |
| python:3.11-slim | ~150 MB |
| python:3.11-alpine | ~50 MB |
| distroless/python3 | ~50 MB |

---

## Imagenes Creadas

### fastapi-app:v1

| Caracteristica | Valor |
|----------------|-------|
| Base | python:3.11-slim |
| Stages | 2 (builder + runtime) |
| Tamano local | 170 MB |
| Tamano registry | ~58 MB (comprimido) |
| Usuario | non-root (appuser) |
| Puerto | 8000 |

---

## Archivos Creados
```
docker/fastapi-app/
├── requirements.txt      # Dependencias Python
├── main.py              # Aplicacion FastAPI
├── Dockerfile.single    # Build tradicional (354 MB)
└── Dockerfile.multi     # Build optimizado (170 MB)
```

---

## Comandos Utilizados

### Construir con Dockerfile especifico
```powershell
docker build -f Dockerfile.multi -t image:tag .
```

### Ver tamano de imagenes
```powershell
docker images | Select-String "pattern"
```

### Copiar entre stages
```dockerfile
COPY --from=builder /source /destination
```

---

## Mejores Practicas Aplicadas

1. **Multi-stage**: Separar build y runtime
2. **Virtualenv**: Aislar dependencias Python
3. **No cache pip**: `--no-cache-dir` reduce tamano
4. **Limpiar apt**: `rm -rf /var/lib/apt/lists/*`
5. **Usuario non-root**: Seguridad en runtime
6. **Slim base**: python:3.11-slim en lugar de python:3.11

---

## Proxima Sesion

**S09**: Imagenes non-root y best practices. Profundizaremos en seguridad de contenedores y usuario no privilegiado.