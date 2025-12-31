# S22: Instalar Jenkins en GCE con Podman

## Objetivo
Crear una VM en Google Compute Engine con Jenkins instalado usando Podman.

---

## Recursos Creados

| Recurso	| Valor |
|---------	|-------|
| VM		| jenkins-server |
| Zona		| us-central1-a |
| Tipo		| e2-medium |
| IP		| 34.170.249.103 |
| URL		| http://34.170.249.103:8080 |

## Configuracion

| Item		| Valor					|
|------		|-------				|
| Usuario	| jenkins				|
| Password	| jenkadmin				|
| Contenedor| jenkins/jenkins:lts	|
| Puerto	| 8080					|
| Volumen	| /opt/jenkins_home		|

---

## Modulo Terraform compute

Creado en `terraform/modules/compute/` para VMs reutilizables.

## Archivo jenkins.tf

Despliega Jenkins con:
- Podman instalado via startup script
- Contenedor con restart=always
- Volumen persistente en /opt/jenkins_home
- Firewall rule para puerto 8080

---

## Troubleshooting Documentado

### Problema 1: CRLF en startup script
- **Error**: `/bin/bash^M: bad interpreter`
- **Solucion**: Guardar archivos con LF (no CRLF) en VS Code

### Problema 2: Permisos en volumen
- **Error**: `Permission denied on /var/jenkins_home`
- **Solucion**: `chown -R 1000:1000` antes de iniciar contenedor

### Problema 3: Rootless Podman en startup
- **Error**: `no systemd user session available`
- **Solucion**: Ejecutar Podman como root, contenedor internamente usa UID 1000

---

## Comandos Utiles

### Ver logs de Jenkins
```bash
sudo podman logs jenkins
```

### Reiniciar Jenkins
```bash
sudo podman restart jenkins
```

### Password inicial
```bash
sudo podman exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

---

## Proxima Sesion

S23: Jenkins Basic Mode - limitaciones y pasos para produccion.