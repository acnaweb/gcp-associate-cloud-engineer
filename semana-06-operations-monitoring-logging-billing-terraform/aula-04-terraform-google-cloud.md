# Aula 4 — Terraform no Google Cloud

## Objetivos

Ao final desta aula, você deverá:

- Configurar provider Google;
- Executar init/plan/apply/destroy;
- Usar variables/outputs;
- Entender state e drift;

---

# 1. Modelo mental

```text
HCL ── terraform plan/apply ──> Google Cloud
        │
        └─ state acompanha recursos
```

O objetivo desta aula não é apenas reconhecer nomes de serviços. Você deve conseguir **criar, inspecionar, testar e explicar** o comportamento dos recursos.

---

# 2. Regra de estudo da aula

Use sempre este ciclo:

```text
Conceito
   ↓
Criar
   ↓
Inspecionar
   ↓
Testar
   ↓
Quebrar propositalmente
   ↓
Diagnosticar
   ↓
Corrigir
   ↓
Remover
```

---

# 3. Laboratório principal

Crie diretório:
```bash
mkdir -p ~/ace-terraform && cd ~/ace-terraform
```

`main.tf`:
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
  region  = "us-central1"
}

variable "project_id" {
  type = string
}

resource "google_storage_bucket" "lab" {
  name                        = "${var.project_id}-ace-tf-lab"
  location                    = "US"
  uniform_bucket_level_access = true
  force_destroy               = true
}

output "bucket" {
  value = google_storage_bucket.lab.name
}
```

Execute:
```bash
terraform init
terraform fmt
terraform validate
terraform plan -var="project_id=$(gcloud config get-value project)"
terraform apply -var="project_id=$(gcloud config get-value project)"
terraform state list
```

Drift:
1. Altere label/configuração suportada manualmente no Console.
2. Execute novo `terraform plan`.
3. Observe diferença entre state/config/realidade.

---

# 4. Testes e falhas propositais

- Nunca versione credenciais ou tfstate sensível em repo público.
- `plan` não aplica.
- State é crítico para mapear recursos.
- Mudança manual pode produzir drift.

Para cada falha, não corrija imediatamente. Primeiro registre:

```text
Sintoma:
Hipótese:
Comando/evidência:
Causa:
Correção:
```

---

# 5. Troubleshooting

Use este fluxo:

```text
1. O recurso existe e está no estado esperado?
2. O escopo (project/region/zone) está correto?
3. A identidade/principal está correta?
4. IAM permite a operação?
5. Rede/rota/firewall permitem comunicação, quando aplicável?
6. A aplicação/serviço está saudável?
7. Há quota/capacidade suficiente?
8. Logs e métricas confirmam a hipótese?
```

Comandos-base:

```bash
gcloud config list
gcloud auth list
gcloud projects describe $(gcloud config get-value project)
gcloud logging read 'severity>=ERROR' --limit=10
```

---

# 6. Pegadinhas ACE

- init baixa provider/backend.
- plan prevê.
- apply converge.
- destroy remove recursos gerenciados.
- State remoto é preferível para colaboração.

---

# 7. Questões estilo ACE

- Quer saber impacto antes da mudança? → plan.
- Equipe compartilhando IaC? → backend remoto/state locking adequado.

---

# 8. Checklist

- [ ] Consigo explicar o modelo mental da aula;
- [ ] Executei o laboratório;
- [ ] Inspecionei os recursos com `describe/list`;
- [ ] Provoquei ao menos uma falha;
- [ ] Diagnostiquei antes de corrigir;
- [ ] Consigo justificar a escolha do serviço;
- [ ] Consigo explicar as pegadinhas ACE;
- [ ] Fiz o cleanup.

---

# 9. O que memorizar

Não memorize apenas comandos. Memorize a relação:

```text
Requisito
   ↓
Serviço/recurso correto
   ↓
Escopo correto
   ↓
Permissão correta
   ↓
Operação correta
   ↓
Troubleshooting com evidência
```

Essa é a forma de raciocínio mais útil para o Associate Cloud Engineer.

