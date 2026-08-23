# Aula 4 — Terraform no Google Cloud

## Objetivos

Ao final desta aula, você deverá:

- Entender Infrastructure as Code;
- Entender Terraform;
- Configurar provider Google;
- Criar recurso;
- Usar variables e outputs;
- Executar init, plan, apply e destroy;
- Entender state em nível conceitual.

---

# 1. Infrastructure as Code

IaC descreve infraestrutura em arquivos versionáveis.

```text
Code
  ↓
Terraform
  ↓
Google Cloud Resources
```

Benefícios:

- Reprodutibilidade;
- Versionamento;
- Automação;
- Revisão;
- Padronização.

---

# 2. Terraform

Terraform usa configuração declarativa.

Exemplo:

```hcl
resource "google_compute_instance" "vm" {
  name         = "ace-terraform-vm"
  machine_type = "e2-micro"
  zone         = "southamerica-east1-a"
}
```

---

# 3. Provider

Provider conecta Terraform ao Google Cloud.

```hcl
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
```

---

# 4. Variables

```hcl
variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "southamerica-east1"
}
```

---

# 5. Resource

Exemplo simplificado:

```hcl
resource "google_compute_network" "vpc" {
  name                    = "ace-terraform-vpc"
  auto_create_subnetworks = false
}
```

---

# 6. Output

```hcl
output "vpc_name" {
  value = google_compute_network.vpc.name
}
```

---

# 7. Fluxo Terraform

```text
terraform init
      ↓
terraform plan
      ↓
terraform apply
      ↓
Infrastructure created
```

Para remover:

```text
terraform destroy
```

---

# 8. terraform init

Inicializa diretório e baixa providers.

```bash
terraform init
```

---

# 9. terraform plan

Mostra mudanças propostas.

```bash
terraform plan
```

---

# 10. terraform apply

Aplica mudanças.

```bash
terraform apply
```

---

# 11. terraform destroy

Remove recursos gerenciados.

```bash
terraform destroy
```

---

# 12. State

Terraform mantém estado da infraestrutura.

```text
Terraform configuration
       +
State
       +
Real infrastructure
```

State ajuda Terraform a entender o que gerencia.

Não trate state como arquivo descartável.

---

# 13. Laboratório

Crie `main.tf`:

```hcl
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = "southamerica-east1"
}

variable "project_id" {
  type = string
}

resource "google_compute_network" "vpc" {
  name                    = "ace-terraform-vpc"
  auto_create_subnetworks = false
}

output "vpc_name" {
  value = google_compute_network.vpc.name
}
```

Execute:

```bash
terraform init
terraform plan -var="project_id=$(gcloud config get-value project)"
terraform apply -var="project_id=$(gcloud config get-value project)"
```

Depois:

```bash
terraform destroy -var="project_id=$(gcloud config get-value project)"
```

---

# 14. Declarativo x Imperativo

Imperativo:

```bash
gcloud compute networks create ...
```

Declarativo:

```hcl
resource "google_compute_network" "vpc" {
  ...
}
```

Para o ACE, entenda ambos.

---

# 15. Questões Estilo ACE

## Questão 1

Você quer versionar infraestrutura e reproduzir ambientes.

**Resposta:** Infrastructure as Code / Terraform.

## Questão 2

Qual comando mostra alterações antes de aplicar?

**Resposta:** `terraform plan`.

## Questão 3

Qual comando inicializa providers?

**Resposta:** `terraform init`.

---

# 16. Pegadinhas ACE

- Terraform não substitui IAM.
- `plan` não aplica alterações.
- `apply` muda infraestrutura.
- State é importante para gestão.
- Variáveis ajudam a reutilizar configuração.

---

# 17. Checklist

- [ ] Entendo IaC
- [ ] Entendo Terraform
- [ ] Entendo provider Google
- [ ] Sei criar resource
- [ ] Entendo variables
- [ ] Entendo outputs
- [ ] Sei usar init, plan, apply e destroy
- [ ] Entendo state
