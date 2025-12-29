# S05: Gestion Correcta de Tags (Tags vs Digest)

## Objetivo
Comprender la diferencia entre tags mutables y digests inmutables, y por que los digests son esenciales para reproducibilidad en produccion.

---

## Conceptos Clave

### Tag
- **Que es**: Etiqueta legible asignada a una imagen (ej: `v1`, `latest`, `prod`)
- **Caracteristica**: MUTABLE - puede apuntar a diferentes imagenes en el tiempo
- **Uso**: Conveniente para humanos, peligroso para automatizacion

### Digest
- **Que es**: Hash SHA256 del contenido de la imagen
- **Caracteristica**: INMUTABLE - siempre identifica exactamente la misma imagen
- **Formato**: `sha256:a1c55dab7e9838965c79b50acd296ada7fc28290165b8c0f1163805a7234c563`
- **Uso**: Garantiza reproducibilidad, esencial para produccion

### Comparacion

| Aspecto			| Tag					| Digest |
|---------			|-----					|--------|
| Legibilidad		| Alta (`v1`, `latest`) | Baja (hash de 64 chars) |
| Mutabilidad		| Mutable				| Inmutable |
| Reproducibilidad	| No garantizada		| Garantizada |
| Uso recomendado	| Desarrollo, CI		| Produccion, CD |

---

## Demostracion Practica

### Estado inicial

| Digest				| Tag	|
|--------				|-----	|
| `sha256:a1c55d...`	| v1	|

### Despues de crear v2

| Digest				| Tags	|
|--------				|------	|
| `sha256:a1c55d...`	| v1	|
| `sha256:0f2fd5...`	| v2	|

### Despues de mover tag v1 (PELIGRO)
```powershell
docker tag demo-app:v2 demo-app:v1
docker push demo-app:v1
```

| Digest				| Tags		|
|--------				|------		|
| `sha256:a1c55d...`	| (sin tag) |
| `sha256:0f2fd5...`	| v1, v2	|

**Problema**: Cualquier sistema que use `demo-app:v1` ahora obtiene una imagen diferente sin saberlo.

### Recuperacion con digest
```powershell
docker pull demo-app@sha256:a1c55dab7e9838965c79b50acd296ada7fc28290165b8c0f1163805a7234c563
```

**El digest siempre obtiene la imagen original**, sin importar que paso con los tags.

---

## Riesgos de Usar Solo Tags

### 1. Sobrescritura accidental
Un desarrollador puede hacer push de una imagen con el mismo tag, reemplazando la anterior.

### 2. Tag `latest` es peligroso
- Cambia constantemente
- Nunca se sabe que version tiene
- Imposible reproducir problemas

### 3. Rollback incierto
Si necesitas volver a una version anterior y el tag fue sobrescrito, perdiste esa version.

### 4. Auditorias imposibles
No puedes saber que imagen se desplego realmente si solo tienes el tag.

---

## Mejores Practicas

### 1. Usar digests en produccion
```yaml
# MAL - Tag mutable
image: demo-app:v1

# BIEN - Digest inmutable
image: demo-app@sha256:a1c55dab7e9838965c79b50acd296ada7fc28290165b8c0f1163805a7234c563
```

### 2. Tags semanticos + digest

Usar ambos: tag para legibilidad, digest para despliegue.
```yaml
# En documentacion/PR
image: demo-app:v1.2.3

# En deployment real
image: demo-app@sha256:abc123...
```

### 3. Nunca usar `latest` en produccion
```yaml
# NUNCA en produccion
image: demo-app:latest

# SIEMPRE version especifica
image: demo-app:v1.2.3
```

### 4. Registrar digest en logs de despliegue
```
Deployed: demo-app:v1.2.3 (sha256:abc123...)
```

### 5. Politica de tags inmutables

Artifact Registry permite habilitar inmutabilidad de tags:
```powershell
gcloud artifacts repositories update REPO --location=LOCATION --immutable-tags
```

---

## Comandos Utilizados

### Listar imagenes con tags

#### `gcloud artifacts docker images list IMAGE --include-tags`
**Que hace**: Lista todas las versiones de una imagen con sus tags y digests.

**Output**:
- IMAGE: Ruta completa
- DIGEST: Hash SHA256
- TAGS: Lista de tags (puede ser multiple)
- CREATE_TIME, UPDATE_TIME, SIZE

### Operaciones con tags

#### `docker tag SOURCE TARGET`
**Que hace**: Crea un nuevo tag apuntando al mismo digest.

**Ejemplo**:
```powershell
docker tag demo-app:v2 demo-app:v1
```
Esto hace que `v1` apunte a la misma imagen que `v2`.

### Pull por digest

#### `docker pull IMAGE@DIGEST`
**Que hace**: Descarga una imagen especifica usando su digest inmutable.

**Ejemplo**:
```powershell
docker pull demo-app@sha256:a1c55dab7e9838965c79b50acd296ada7fc28290165b8c0f1163805a7234c563
```

---

## Flujo Recomendado para CI/CD
```
[Build]
   |
   v
[Tag con version semantica]
   demo-app:v1.2.3
   |
   v
[Push a Registry]
   |
   v
[Obtener digest]
   sha256:abc123...
   |
   v
[Guardar en manifiesto de despliegue]
   image: demo-app@sha256:abc123...
   |
   v
[Deploy a produccion usando digest]
   |
   v
[Log: v1.2.3 = sha256:abc123...]
```

---

## Imagenes en el Repositorio

### Estado actual

| Digest				| Tag	| Version	| Descripcion		|
|--------				|-----	|---------	|-------------		|
| `sha256:a1c55dab...`	| v1	| 1.0		| Demo app original |
| `sha256:0f2fd59e...`	| v2	| 2.0		| Demo app v2		|

### Como referenciar
```
# Por tag (desarrollo)
us-central1-docker.pkg.dev/project02-482522/containers/demo-app:v1

# Por digest (produccion)
us-central1-docker.pkg.dev/project02-482522/containers/demo-app@sha256:a1c55dab7e9838965c79b50acd296ada7fc28290165b8c0f1163805a7234c563
```

---

## Practica Empresarial Aplicada

1. **Tags para desarrollo**: Convenientes para iterar rapidamente
2. **Digests para produccion**: Garantizan que se despliega exactamente lo esperado
3. **Registro de correspondencia**: Tag <-> Digest en logs y sistemas de tracking
4. **Inmutabilidad opcional**: Artifact Registry puede bloquear sobrescritura de tags
5. **Auditorias**: Siempre se puede verificar que imagen se desplego usando el digest

---

## Proxima Sesion

**S06**: Limpieza de tags antiguos sin eliminar imagenes. Aprenderemos a mantener el repositorio limpio sin perder imagenes importantes.