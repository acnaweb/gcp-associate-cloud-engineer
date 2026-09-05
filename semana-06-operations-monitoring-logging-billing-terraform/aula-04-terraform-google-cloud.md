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
# Explicação: Cria o diretório usado pelos arquivos/configurações do laboratório.
mkdir -p ~/ace-tf && cd ~/ace-tf

# Explicação: Exibe conteúdo de arquivo ou cria conteúdo via redirecionamento/heredoc, conforme a sintaxe usada.
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

# Explicação: Inicializa o diretório Terraform, baixa providers/modules e prepara o backend de state.
terraform init
# Explicação: Formata os arquivos Terraform de acordo com o padrão da ferramenta.
terraform fmt
# Explicação: Valida sintaxe e consistência interna da configuração Terraform.
terraform validate
# Explicação: Calcula e exibe o plano de mudanças sem aplicá-las, permitindo revisar o impacto.
terraform plan -var="project_id=$(gcloud config get-value project)"
# Explicação: Aplica o plano/configuração Terraform e cria/altera recursos no provedor.
terraform apply -var="project_id=$(gcloud config get-value project)" -auto-approve
```

---

# 3. Inspecionar

Antes de provocar qualquer erro, confirme a configuração criada. O troubleshooting desta aula usará **somente elementos que você já observou aqui**.

```bash
# Explicação: Inspeciona ou manipula entradas do state Terraform conforme o subcomando.
terraform state list
# Explicação: Inspeciona ou manipula entradas do state Terraform conforme o subcomando.
terraform state show google_storage_bucket.lab
# Explicação: Exibe propriedades do bucket, como localização, storage class, versioning e políticas.
gcloud storage buckets describe \
 "gs://$(gcloud config get-value project)-ace-tf-2026"
```

---

# 4. Testar

```bash
# Explicação: Calcula e exibe o plano de mudanças sem aplicá-las, permitindo revisar o impacto.
terraform plan -var="project_id=$(gcloud config get-value project)"
```

O resultado deve indicar nenhuma mudança relevante imediatamente após apply.

---

# 5. Quebrar propositalmente

Altere manualmente uma label do bucket no Console ou via `gcloud`, por exemplo adicionando uma label extra. Depois:

```bash
# Explicação: Calcula e exibe o plano de mudanças sem aplicá-las, permitindo revisar o impacto.
terraform plan -var="project_id=$(gcloud config get-value project)"
```

---

# 6. Troubleshooting

Agora o erro já foi produzido e os componentes envolvidos já foram apresentados.

**Sintoma:** `terraform plan` mostra mudança inesperada.

**Hipótese:** houve drift entre configuração e recurso real.

**Evidências:**
```bash
# Explicação: Inspeciona ou manipula entradas do state Terraform conforme o subcomando.
terraform state show google_storage_bucket.lab
# Explicação: Exibe propriedades do bucket, como localização, storage class, versioning e políticas.
gcloud storage buckets describe \
 "gs://$(gcloud config get-value project)-ace-tf-2026"
# Explicação: Calcula e exibe o plano de mudanças sem aplicá-las, permitindo revisar o impacto.
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
# Explicação: Aplica o plano/configuração Terraform e cria/altera recursos no provedor.
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
# Explicação: Altera o diretório de trabalho do shell para executar os próximos comandos no local correto.
cd ~/ace-tf
# Explicação: Destrói os recursos gerenciados pela configuração Terraform para cleanup.
terraform destroy -var="project_id=$(gcloud config get-value project)" -auto-approve
```

---


---

# Conteúdo complementar + cobertura oficial de IaC

## IaC/tooling cobrado

O **guia oficial anexado** cita explicitamente:

```text
Cloud Foundation Toolkit
Config Connector
Terraform
Helm
```

`Fabric FAST` pode ser estudado como conteúdo complementar, mas **não deve substituir Cloud Foundation Toolkit na matriz oficial baseada no anexo**.

### Terraform
Declarativo, provider Google, state/plan/apply.

### Config Connector
Gerencia recursos Google Cloud usando recursos Kubernetes declarativos.

### Helm
Gerencia pacotes/charts Kubernetes; é especialmente relevante para aplicações no GKE.

### Fabric FAST
Acelerador/fundação para infraestrutura Google Cloud baseada em boas práticas e automação, útil em implantação de fundações de cloud em escala.

## AI-assisted planning/implementation

O guia atual também cita ferramentas como:

- Gemini CLI;
- Google Antigravity;
- Gemini Cloud Assist;
- Application Design Center.

Para ACE, o foco é **usar/entender como assistência**, não confiar cegamente. A saída deve ser revisada, e as permissões do operador continuam valendo.

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
