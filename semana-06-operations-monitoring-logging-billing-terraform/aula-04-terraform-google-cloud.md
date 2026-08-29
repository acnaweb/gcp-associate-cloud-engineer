# Aula 4 — Terraform no Google Cloud

## Objetivos

Ao final, você deverá:
- criar provider/config;
- executar init, fmt, validate, plan, apply;
- inspecionar state;
- provocar drift;
- corrigir por código ou importar/ajustar conforme estratégia.


---

# 1. Conceito

Terraform é IaC declarativa. Configuration descreve estado desejado; state mapeia objetos Terraform a recursos reais; plan compara configuração/state/realidade e mostra ações.

## Arquitetura mental

```text
HCL desired state
      ↓
plan
      ↓
apply
      ↓
Google Cloud
      ↕
state
```

---

# 2. Criar

```bash
mkdir -p ~/ace-tf && cd ~/ace-tf

cat > main.tf <<'EOF'
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

variable "project_id" {
  type = string
}

provider "google" {
  project = var.project_id
  region  = "us-central1"
}

resource "google_storage_bucket" "lab" {
  name                        = "${var.project_id}-ace-tf-2026"
  location                    = "US"
  uniform_bucket_level_access = true
  force_destroy               = true

  labels = {
    managed_by = "terraform"
  }
}
EOF

terraform init
terraform fmt
terraform validate
terraform plan -var="project_id=$(gcloud config get-value project)"
terraform apply -var="project_id=$(gcloud config get-value project)" -auto-approve
```

---

# 3. Inspecionar

Antes de provocar qualquer erro, confirme a configuração criada. O troubleshooting desta aula usará **somente elementos que você já observou aqui**.

```bash
terraform state list
terraform state show google_storage_bucket.lab
gcloud storage buckets describe \
 "gs://$(gcloud config get-value project)-ace-tf-2026"
```

---

# 4. Testar

```bash
terraform plan -var="project_id=$(gcloud config get-value project)"
```

O resultado deve indicar nenhuma mudança relevante imediatamente após apply.

---

# 5. Quebrar propositalmente

Altere manualmente uma label do bucket no Console ou via `gcloud`, por exemplo adicionando uma label extra. Depois:

```bash
terraform plan -var="project_id=$(gcloud config get-value project)"
```

---

# 6. Troubleshooting

Agora o erro já foi produzido e os componentes envolvidos já foram apresentados.

**Sintoma:** `terraform plan` mostra mudança inesperada.

**Hipótese:** houve drift entre configuração e recurso real.

**Evidências:**
```bash
terraform state show google_storage_bucket.lab
gcloud storage buckets describe \
 "gs://$(gcloud config get-value project)-ace-tf-2026"
terraform plan -var="project_id=$(gcloud config get-value project)"
```

**Causa:** mudança manual fora do Terraform.

Use sempre:

```text
Sintoma
   ↓
Hipótese
   ↓
Evidência
   ↓
Causa
   ↓
Correção
```

---

# 7. Corrigir

Escolha uma estratégia consciente:
- se a mudança manual não deve permanecer, `terraform apply` reconcilia;
- se deve permanecer, altere `main.tf` antes do apply.

Para o lab, remova o drift com:

```bash
terraform apply -var="project_id=$(gcloud config get-value project)" -auto-approve
```

---

# 8. Questões estilo ACE

1. Ver mudanças antes de executar? **terraform plan**.
2. State guarda credenciais? Pode conter dados sensíveis; **proteja-o**.
3. Alteração manual fora do IaC pode gerar **drift**.

---

# 9. Cleanup

```bash
cd ~/ace-tf
terraform destroy -var="project_id=$(gcloud config get-value project)" -auto-approve
```

---

# 10. Checklist

- [ ] Entendi os conceitos usados no laboratório;
- [ ] Criei o recurso;
- [ ] Inspecionei estado e configuração;
- [ ] Testei o comportamento esperado;
- [ ] Provoquei a falha descrita;
- [ ] Diagnostiquei usando evidências;
- [ ] Corrigi sem aumentar privilégios ou alterar componentes desnecessários;
- [ ] Consigo relacionar o cenário a uma questão ACE;
- [ ] Executei o cleanup.

---

# Cobertura adicional — outras opções de Infrastructure as Code citadas no exam guide

O guia cita exemplos como:

```text
Terraform
Cloud Foundation Toolkit
Config Connector
Helm
```

Você não precisa dominar todos com a mesma profundidade para ACE, mas deve reconhecer a função:

```text
Terraform
→ IaC multi-provider declarativa

Cloud Foundation Toolkit
→ templates/modules/referências para fundações e melhores práticas

Config Connector
→ gerenciar recursos Google Cloud por objetos Kubernetes

Helm
→ empacotar/configurar aplicações Kubernetes
```

A escolha depende do contexto. Se a equipe já opera Kubernetes e quer recursos GCP declarados como CRDs, Config Connector pode aparecer. Para infraestrutura geral, Terraform é uma opção comum.
