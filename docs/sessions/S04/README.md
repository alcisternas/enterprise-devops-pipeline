# S04: Filtrado de Vulnerabilidades Criticas con CVSS

## Objetivo
Aprender a consultar y filtrar vulnerabilidades por severidad CVSS para tomar decisiones automatizadas en pipelines CI/CD.

---

## Conceptos Clave

### CVSS (Common Vulnerability Scoring System)

Sistema estandar para evaluar la severidad de vulnerabilidades de seguridad.

| Version | Rango   | Descripcion                               |
|---------|-------  |-------------                              |
| CVSS v2 | 0-10    | Version legacy, aun usada en CVEs antiguas|
| CVSS v3 | 0-10    | Version actual, mas precisa               |

### Mapeo de severidad GCP

| Severidad GCP         | CVSS Score | Significado                              |
|---------------        |------------|-------------                             |
| CRITICAL              | 9.0 - 10.0 | Explotable remotamente, impacto total    |
| HIGH                  | 7.0 - 8.9  | Explotable con facilidad, alto impacto   |
| MEDIUM                | 4.0 - 6.9  | Requiere condiciones especificas         |
| LOW                   | 0.1 - 3.9  | Dificil de explotar, bajo impacto        |
| MINIMAL               | ~0         | Riesgo teorico, impacto negligible       |

### Effective Severity vs CVSS Score

- **CVSS Score**: Puntuacion numerica cruda
- **Effective Severity**: Clasificacion ajustada por GCP considerando contexto

Ejemplo: Una CVE puede tener CVSS 9.8 pero Effective Severity MINIMAL si:
- No aplica al contexto del contenedor
- Requiere configuracion especifica no presente
- Ya esta mitigada por otras capas

---

## Estrategias de Filtrado en CI/CD

### Estrategia 1: Bloquear solo CRITICAL
```
BlockOn: CRITICAL
```

- Mas permisiva
- Solo detiene builds con vulnerabilidades criticas
- Adecuada para: desarrollo, ambientes de prueba

### Estrategia 2: Bloquear HIGH y superiores
```
BlockOn: HIGH
```

- Balance entre seguridad y velocidad
- Bloquea vulnerabilidades explotables
- Adecuada para: staging, pre-produccion

### Estrategia 3: Bloquear MEDIUM y superiores
```
BlockOn: MEDIUM
```

- Mas estricta
- Requiere corregir la mayoria de vulnerabilidades
- Adecuada para: produccion, sistemas criticos

### Estrategia 4: Bloquear solo con fix disponible
```
BlockOn: HIGH + FixableOnly
```

- Solo bloquea si hay solucion disponible
- Evita bloqueos por CVEs sin parche
- Adecuada para: equipos pragmaticos

---

## Resultados del Escaneo de demo-app:v1

### Resumen por severidad

| Severidad | Cantidad  | Paquetes                                  |
|-----------|---------- |----------                                 |
| CRITICAL  | 0         | -                                         |
| HIGH      | 0         | -                                         |
| MEDIUM    | 2         | pip                                       |
| LOW       | 4         | shadow, sqlite3, util-linux, ncurses      |
| MINIMAL   | 19        | glibc, systemd, apt, tar, perl, coreutils |

### Vulnerabilidades MEDIUM (bloqueantes con -BlockOn MEDIUM)

| CVE           | Paquete   | CVSS  | Fix disponible    |
|-----          |---------  |------ |----------------   |
| CVE-2025-8869 | pip       | -     | Si (25.3)         |
| CVE-2023-5752 | pip       | 3.3   | Si (23.3)         |

### Observacion importante

Algunas CVEs tienen CVSS alto (ej: CVE-2005-2541 con 10.0) pero Effective Severity MINIMAL. Esto se debe a que GCP evalua el contexto real de explotabilidad en contenedores.

---

## Script de Validacion

### Ubicacion
`scripts/security/check-vulnerabilities.ps1`

### Parametros

| Parametro     | Tipo      | Requerido | Descripcion                                   |
|-----------    |------     |-----------|-------------                                  |
| -Image        | string    | Si        | URI completa de la imagen                     |
| -BlockOn      | string    | No        | Severidad minima para bloquear (default: HIGH)|
| -FixableOnly  | switch    | No        | Solo considerar vulnerabilidades con fix      |

### Valores validos para -BlockOn
- CRITICAL
- HIGH
- MEDIUM
- LOW

### Codigos de salida

| Codigo | Significado                              |
|--------|-------------                             |
| 0      | PASSED - Sin vulnerabilidades bloqueantes|
| 1      | BLOCKED - Vulnerabilidades encontradas   |

### Ejemplos de uso
```powershell
# Bloquear solo en CRITICAL (permisivo)
.\check-vulnerabilities.ps1 -Image "us-central1-docker.pkg.dev/PROJECT/REPO/IMAGE:TAG" -BlockOn "CRITICAL"

# Bloquear en HIGH o superior (recomendado)
.\check-vulnerabilities.ps1 -Image "us-central1-docker.pkg.dev/PROJECT/REPO/IMAGE:TAG" -BlockOn "HIGH"

# Bloquear en MEDIUM o superior (estricto)
.\check-vulnerabilities.ps1 -Image "us-central1-docker.pkg.dev/PROJECT/REPO/IMAGE:TAG" -BlockOn "MEDIUM"

# Bloquear solo si hay fix disponible
.\check-vulnerabilities.ps1 -Image "us-central1-docker.pkg.dev/PROJECT/REPO/IMAGE:TAG" -BlockOn "HIGH" -FixableOnly
```

### Integracion en CI/CD
```yaml
# Ejemplo en Jenkins/GitHub Actions
- name: Security Scan
  run: |
    .\scripts\security\check-vulnerabilities.ps1 -Image "$IMAGE" -BlockOn "HIGH"
    if ($LASTEXITCODE -ne 0) { exit 1 }
```

---

## Comandos Utilizados

### Listar vulnerabilidades

#### `gcloud artifacts vulnerabilities list IMAGE`
**Que hace**: Lista todas las vulnerabilidades detectadas en una imagen.

**Output incluye**:
- CVE ID
- Effective Severity
- CVSS Score
- Fix Available
- Package afectado
- Tipo de paquete (OS, PYPI, NPM, etc.)

### Filtrar con PowerShell

#### `| Select-String -Pattern "MEDIUM|HIGH|CRITICAL"`
**Que hace**: Filtra lineas que contengan las severidades especificadas.

**Por que PowerShell**: El filtro nativo de gcloud no funciona bien con este comando especifico.

---

## Flujo de Decision en CI/CD
```
[Build imagen]
      |
      v
[Push a Artifact Registry]
      |
      v
[Escaneo automatico]
      |
      v
[check-vulnerabilities.ps1]
      |
      +---> PASSED --> [Continuar deploy]
      |
      +---> BLOCKED --> [Detener pipeline]
                              |
                              v
                        [Notificar equipo]
                              |
                              v
                        [Corregir vulnerabilidades]
                              |
                              v
                        [Rebuild imagen]
```

---

## Practica Empresarial Aplicada

1. **Politicas por ambiente**: Diferentes niveles de bloqueo segun criticidad
2. **Automatizacion**: Script integrable en cualquier pipeline
3. **Codigos de salida**: Permiten decision automatica (0=ok, 1=error)
4. **Visibilidad**: Resumen claro de vulnerabilidades por severidad
5. **Flexibilidad**: Parametros configurables segun necesidad

---

## Recomendaciones por Ambiente

| Ambiente          | BlockOn               | Justificacion                 |
|----------         |---------              |---------------                |
| Desarrollo        | CRITICAL              | Velocidad de iteracion        |
| Staging           | HIGH                  | Balance seguridad/velocidad   |
| Produccion        | HIGH                  | Minimo recomendado            |
| PCI/HIPAA         | MEDIUM                | Compliance estricto           |
| Sistemas criticos | MEDIUM + FixableOnly  | Maxima seguridad practica     |

---

## Proxima Sesion

**S05**: Gestion correcta de tags (tags vs digest). Aprenderemos la diferencia entre tags mutables y digests inmutables para garantizar reproducibilidad.