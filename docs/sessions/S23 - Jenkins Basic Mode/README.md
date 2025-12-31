# S23: Jenkins Basic Mode - Limitaciones y Pasos para Produccion

## Objetivo
Entender las limitaciones de la configuracion basica de Jenkins y que se necesita para produccion.

---

## Configuracion Actual

| Item          | Valor                 |
|------         |-------                |
| Version       | 2.528.3               |
| Modo          | Standalone            |
| Plugins       | Suggested plugins     |
| Almacenamiento| Local (volumen Podman)|
| Auth          | Usuario local         |

---

## Limitaciones del Basic Mode

| Limitacion            | Riesgo                        | Solucion Produccion       |
|------------           |--------                       |---------------------      |
| Sin HTTPS             | Credenciales en texto plano   | Reverse proxy con TLS     |
| Auth local            | No escalable, no auditable    | LDAP/SAML/OIDC            |
| Sin backup            | Perdida de configuracion      | Backup automatizado       |
| Single node           | Sin alta disponibilidad       | Jenkins HA o agents       |
| Sin secrets management| Credenciales en Jenkins       | External secrets (Vault)  |

---

## Arquitectura Basic Mode
```
[Usuario] --> [Jenkins:8080] --> [Jobs locales]
                    |
                    v
            [/opt/jenkins_home]
```

## Arquitectura Produccion
```
[Usuario] --> [Load Balancer] --> [Jenkins Controller]
                   |                      |
                   | HTTPS                | API
                   v                      v
            [Certificate]          [Jenkins Agents]
                                          |
                                          v
                                   [Build Nodes]
```

---

## Checklist para Produccion

### Seguridad
- [ ] HTTPS habilitado (reverse proxy o plugin)
- [ ] Autenticacion externa (LDAP/SAML)
- [ ] Autorizacion basada en roles (RBAC)
- [ ] Secrets en Vault o Secret Manager
- [ ] Audit logging habilitado

### Alta Disponibilidad
- [ ] Jenkins agents para builds
- [ ] Controller solo para orquestacion
- [ ] Persistent storage (GCS, NFS)
- [ ] Backups automatizados

### Monitoreo
- [ ] Health checks
- [ ] Metricas (Prometheus)
- [ ] Alertas
- [ ] Log aggregation

### CI/CD
- [ ] Pipeline as Code (Jenkinsfile)
- [ ] Shared libraries
- [ ] Credentials binding
- [ ] Artifact management

---

## Plugins Recomendados para Produccion

| Plugin | Proposito |
|--------|-----------|
| kubernetes | Agents dinamicos en K8s |
| google-oauth-plugin | Auth con Google |
| credentials-binding | Secrets seguros |
| pipeline | Pipeline as Code |
| blueocean | UI moderna |
| prometheus | Metricas |

---

## Proxima Sesion

S24: Autenticacion segura Jenkins - Artifact Registry.