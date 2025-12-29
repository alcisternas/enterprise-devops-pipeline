# S06: Limpieza de Tags Antiguos sin Eliminar Imagenes

## Objetivo
Aprender a mantener el repositorio limpio eliminando tags obsoletos mientras se preservan las imagenes importantes referenciadas por digest.

---

## Conceptos Clave

### Diferencia entre eliminar Tag vs Imagen

| Accion            | Comando                                   | Efecto                                            |
|--------           |---------                                  |--------                                           |
| Eliminar tag      | `gcloud artifacts docker tags delete`     | Solo remueve la etiqueta, imagen sigue existiendo |
| Eliminar imagen   | `gcloud artifacts docker images delete`   | Elimina la imagen y todos sus tags                |

### Por que limpiar tags?

1. **Reducir ruido**: Muchos tags de CI/CD (build-123, build-124, etc.)
2. **Claridad**: Facilita encontrar versiones importantes
3. **Costos**: Artifact Registry cobra por almacenamiento (aunque tags no agregan tamano)
4. **Seguridad**: Tags obsoletos pueden tener vulnerabilidades conocidas

### Tags que NUNCA se deben eliminar

- Tags de versiones en produccion (v1, v2, v1.0.0)
- `latest` si se usa activamente
- Tags referenciados en deployments actuales

---

## Demostracion Practica

### Estado inicial

| Digest                | Tags                      |
|--------               |------                     |
| `sha256:a1c55d...`    | v1, build-100, build-101  |
| `sha256:0f2fd5...`    | v2, build-102, latest     |

### Despues de limpieza

| Digest                | Tags                  |
|--------               |------                 |
| `sha256:a1c55d...`    | v1                    |
| `sha256:0f2fd5...`    | v2, build-102, latest |

**Resultado**: Tags `build-100` y `build-101` eliminados, imagenes intactas.

---

## Script de Limpieza

### Ubicacion
`scripts/cleanup/cleanup-tags.ps1`

### Parametros

| Parametro     | Tipo      | Requerido | Default       | Descripcion                               |
|-----------    |------     |-----------|---------      |-------------                              |
| -Repository   | string    | Si        | -             | URI del repositorio                       |
| -KeepTags     | string[]  | No        | @("latest")   | Tags protegidos (nunca eliminar)          |
| -TagPattern   | string    | No        | "build-*"     | Patron de tags a considerar para limpieza |
| -KeepRecent   | int       | No        | 5             | Cantidad de tags recientes a mantener     |
| -DryRun       | switch    | No        | False         | Simular sin ejecutar                      |

### Ejemplos de uso
```powershell
# Ver que se eliminaria (sin ejecutar)
.\cleanup-tags.ps1 -Repository "REGISTRY/PROJECT/REPO/IMAGE" -DryRun

# Limpiar builds antiguos, mantener ultimos 5
.\cleanup-tags.ps1 -Repository "REGISTRY/PROJECT/REPO/IMAGE" -TagPattern "build-*" -KeepRecent 5

# Proteger tags especificos
.\cleanup-tags.ps1 -Repository "REGISTRY/PROJECT/REPO/IMAGE" -KeepTags @("v1","v2","latest","prod")

# Limpiar tags de fecha (ej: 20231201, 20231202)
.\cleanup-tags.ps1 -Repository "REGISTRY/PROJECT/REPO/IMAGE" -TagPattern "202312*" -KeepRecent 3
```

### Logica del script
```
1. Obtener todos los tags del repositorio
2. Filtrar tags que coinciden con el patron (ej: build-*)
3. Excluir tags protegidos (ej: v1, v2, latest)
4. Ordenar alfabeticamente
5. Mantener los N mas recientes (KeepRecent)
6. Eliminar el resto
```

### Codigos de salida

| Codigo    | Significado                                   |
|--------   |-------------                                  |
| 0         | Exito (limpieza completada o nada que limpiar)|
| 1         | Error (fallo al listar o eliminar)            |

---

## Comandos Utilizados

### Listar tags

#### `gcloud artifacts docker tags list REPOSITORY`
**Que hace**: Lista todos los tags de una imagen.

**Formato util**:
```powershell
gcloud artifacts docker tags list REPO --format="value(tag)"
```

### Eliminar tag

#### `gcloud artifacts docker tags delete REPOSITORY:TAG --quiet`
**Que hace**: Elimina un tag especifico sin pedir confirmacion.

**Importante**: Solo elimina el tag, NO la imagen.

**Ejemplo**:
```powershell
gcloud artifacts docker tags delete us-central1-docker.pkg.dev/project/repo/image:build-100 --quiet
```

### Listar imagenes con tags

#### `gcloud artifacts docker images list REPOSITORY --include-tags`
**Que hace**: Lista imagenes mostrando todos sus tags asociados.

---

## Estrategias de Limpieza por Ambiente

### Desarrollo
- Patron: `dev-*`, `feature-*`
- Mantener: 3 ultimos
- Frecuencia: Diaria

### Staging
- Patron: `staging-*`, `rc-*`
- Mantener: 5 ultimos
- Frecuencia: Semanal

### Produccion
- Patron: `build-*` (solo CI builds)
- Mantener: 10 ultimos
- Frecuencia: Mensual
- Proteger: Todos los tags `v*`

---

## Integracion con CI/CD

### Limpieza automatica post-deploy
```yaml
# Ejemplo en pipeline
- name: Cleanup old tags
  run: |
    .\scripts\cleanup\cleanup-tags.ps1 `
      -Repository "$REGISTRY/$PROJECT/containers/$IMAGE" `
      -KeepTags @("latest","prod","$NEW_VERSION") `
      -TagPattern "build-*" `
      -KeepRecent 10
```

### Limpieza programada (cron)
```yaml
# GitHub Actions - Semanal
on:
  schedule:
    - cron: '0 0 * * 0'  # Domingos a medianoche

jobs:
  cleanup:
    runs-on: ubuntu-latest
    steps:
      - name: Cleanup old tags
        run: |
          # Script de limpieza
```

---

## Politicas de Retencion en Artifact Registry

Artifact Registry soporta politicas automaticas de limpieza:
```powershell
# Crear politica de retencion (elimina imagenes sin tags despues de 30 dias)
gcloud artifacts repositories set-cleanup-policies REPO \
  --location=LOCATION \
  --policy=policy.json
```

Ejemplo `policy.json`:
```json
{
  "name": "delete-untagged",
  "action": {"type": "Delete"},
  "condition": {
    "tagState": "untagged",
    "olderThan": "30d"
  }
}
```

---

## Mejores Practicas

1. **Siempre usar DryRun primero**: Verificar que se eliminara antes de ejecutar
2. **Proteger tags de produccion**: Nunca eliminar tags en uso
3. **Mantener historial razonable**: 5-10 builds recientes es suficiente
4. **Automatizar**: Incluir limpieza en pipelines CI/CD
5. **Documentar politica**: Equipo debe conocer que tags se mantienen

---

## Diagrama del Flujo de Limpieza
```
[Repositorio con muchos tags]
          |
          v
[Script cleanup-tags.ps1]
          |
          +---> Obtener todos los tags
          |
          +---> Filtrar por patron (build-*)
          |
          +---> Excluir protegidos (v1, v2, latest)
          |
          +---> Ordenar y mantener recientes
          |
          +---> Eliminar antiguos
          |
          v
[Repositorio limpio]
   - Imagenes intactas
   - Solo tags relevantes
```

---

## Proxima Sesion

**S07**: Repaso y evaluacion del Bloque 1. Consolidaremos los conceptos aprendidos sobre seguridad, KMS, vulnerabilidades y gestion de imagenes.