# S16: Networking - VPC, Subnets y Firewall Rules

## Objetivo
Crear modulo de networking reutilizable con VPC, subnets y firewall rules.

---

## Modulo networking

### Variables

| Variable      | Tipo          | Requerido | Descripcion       |
|----------     |------         |-----------|-------------      |
| project_id    | string        | Si        | ID del proyecto   |
| vpc_name      | string        | Si        | Nombre de la VPC  |
| routing_mode  | string        | No        | REGIONAL o GLOBAL |
| subnets       | list(object)  | No        | Lista de subnets  |
| firewall_rules| list(object)  | No        | Lista de reglas   |

### Outputs

| Output    | Descripcion       |
|--------   |-------------      |
| vpc_id    | ID de la VPC      |
| vpc_name  | Nombre de la VPC  |
| subnet_ids| Mapa de subnet IDs|

### Ejemplo de uso
```hcl
module "network" {
  source     = "./modules/networking"
  project_id = var.project_id
  vpc_name   = "main-vpc"

  subnets = [
    {
      name                  = "subnet-apps"
      region                = "us-central1"
      cidr                  = "10.0.1.0/24"
      private_google_access = true
    }
  ]

  firewall_rules = [
    {
      name      = "allow-http"
      direction = "INGRESS"
      priority  = 1000
      ranges    = ["0.0.0.0/0"]
      allow = [
        { protocol = "tcp", ports = ["80", "443"] }
      ]
    }
  ]
}
```