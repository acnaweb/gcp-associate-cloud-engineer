# Aula 6 — OS Login, VM Manager e Operação de VMs

## Cobertura no exam guide

Exam Guide 3.1 e 4.1: OS Login, VM Manager, conexão remota e inventário de VMs.



## 1. Conceito

OS Login integra acesso SSH com IAM. VM Manager fornece capacidades de gerenciamento do SO. O inventário da VM inclui ID, machine type, discos, NIC, metadata, service account e status.

### Arquitetura / modelo mental

```text
User + IAM → OS Login → VM SSH
VM Manager → inventory / patch / OS management
```

## 2. Criar / Configurar

```bash
# Explicação: Cria uma VM do Compute Engine com as opções de máquina, rede, disco e identidade informadas.
gcloud compute instances create ace-opslogin \
 --zone=us-central1-a --machine-type=e2-micro \
 --image-family=debian-12 --image-project=debian-cloud

# Explicação: Adiciona metadata em nível de projeto, tornando o valor disponível às VMs conforme as regras do Compute Engine.
gcloud compute project-info add-metadata --metadata enable-oslogin=TRUE
```

## 3. Inspecionar

```bash
# Explicação: Exibe a configuração e o estado detalhado da VM para inspeção/troubleshooting.
gcloud compute instances describe ace-opslogin --zone=us-central1-a
# Explicação: Exibe metadados/configurações do Compute Engine no projeto.
gcloud compute project-info describe --format='yaml(commonInstanceMetadata)'
# Explicação: Executa `gcloud compute os-login describe-profile 2>/dev/null || true` nesta etapa para aplicar ou inspecionar a configuração indicada.
gcloud compute os-login describe-profile 2>/dev/null || true
```

No Console, abra Compute Engine → VM Manager e identifique as funcionalidades disponíveis no projeto.

> A partir deste ponto, todos os elementos usados no troubleshooting já foram apresentados e inspecionados.

## 4. Testar

```bash
# Explicação: Abre uma sessão SSH na VM indicada; flags adicionais podem executar um comando remotamente.
gcloud compute ssh ace-opslogin --zone=us-central1-a --command='id; hostname'
```

## 5. Quebrar propositalmente

Remova temporariamente a role de OS Login apenas se estiver em usuário/projeto de laboratório e souber restaurá-la; alternativa segura: crie um principal de laboratório sem `roles/compute.osLogin` e compare o resultado.

## 6. Troubleshooting

**Sintoma:** usuário autenticado no Google Cloud não consegue login no SO.
**Hipótese:** IAM de OS Login não permite login.
**Evidência:** metadata `enable-oslogin=TRUE` + bindings do principal.
**Causa:** OS Login exige autorização IAM apropriada.
**Correção:** conceder `roles/compute.osLogin` ou `roles/compute.osAdminLogin` conforme necessidade.

Use a sequência:

```text
Sintoma → Hipótese → Evidência → Causa → Correção
```

## 7. Corrigir

Restaure a role mínima e repita SSH. Não desabilite OS Login para “resolver” quando o requisito é usar identidade centralizada.

## 8. Questões estilo ACE

1. Centralizar SSH em IAM? **OS Login**.
2. Gerenciar patch/inventory do SO em VMs? **VM Manager**.
3. OS Login autorizado substitui firewall TCP 22? **Não; são camadas distintas**.

## 9. Cleanup

```bash
# Explicação: Exclui a VM indicada e libera os recursos associados que não foram preservados.
gcloud compute instances delete ace-opslogin --zone=us-central1-a --quiet
# reverta metadata enable-oslogin se foi alterada apenas para o laboratório e isso for apropriado
```

## Checklist

- [ ] Consigo explicar os conceitos sem consultar;
- [ ] Sei localizar o recurso no Console e/ou CLI;
- [ ] Executei ou simulei o laboratório indicado;
- [ ] Inspecionei a configuração antes de provocar a falha;
- [ ] Diagnostiquei a falha com evidências;
- [ ] Sei reconhecer a alternativa correta em uma questão de cenário.


---

# Cobertura ACE ampliada — conexão remota, OS Login e VM Manager

## SSH keys x OS Login

```text
SSH metadata keys → chaves gerenciadas via metadata
OS Login          → acesso SSH vinculado à identidade IAM
```

Inspecione OS Login:

```bash
# Explicação: Exibe metadados/configurações do Compute Engine no projeto.
gcloud compute project-info describe --format='yaml(commonInstanceMetadata)'
```

Habilitação em projeto de laboratório:

```bash
# Explicação: Adiciona metadata em nível de projeto, tornando o valor disponível às VMs conforme as regras do Compute Engine.
gcloud compute project-info add-metadata --metadata=enable-oslogin=TRUE
```

Roles comuns envolvidas incluem `roles/compute.osLogin` e, quando necessário, `roles/compute.osAdminLogin`.

## VM Manager

VM Manager reúne capacidades de gerenciamento de SO, como inventário, patching e políticas, dependendo da configuração/agentes.

No Console: **Compute Engine → VM Manager**.

Para ACE, saiba distinguir:

```text
OS Login  → controle de login SSH por IAM
VM Manager → gerenciamento operacional do sistema operacional
```


---

## Prática guiada — configurar VM Manager

**Nível:** `P` quando executado em projeto de laboratório.

Habilite a API do OS Config:

```bash
# Explicação: Habilita a API/serviço indicado no projeto ativo para permitir o uso do recurso no laboratório.
gcloud services enable osconfig.googleapis.com
```

Habilite OS Config via metadata de projeto para o laboratório:

```bash
# Explicação: Adiciona metadata em nível de projeto, tornando o valor disponível às VMs conforme as regras do Compute Engine.
gcloud compute project-info add-metadata \
  --metadata=enable-osconfig=TRUE
```

Inspecione:

```bash
# Explicação: Exibe metadados/configurações do Compute Engine no projeto.
gcloud compute project-info describe \
  --format='yaml(commonInstanceMetadata)'
```

No Console, abra:

```text
Compute Engine → VM Manager
```

Observe pelo menos:

- inventário do SO;
- patch management;
- políticas/recursos disponíveis no projeto.

### Falha proposital

Se o inventário não aparecer, verifique primeiro:

```text
API osconfig habilitada?
metadata enable-osconfig=TRUE?
VM compatível e agente/configuração necessários presentes?
```

Não transforme uma falha do VM Manager em problema de firewall sem evidência.

---


## Prática verificável — VM Manager e OS Inventory

Apenas abrir o Console não é suficiente para classificar VM Manager como `P`. Use a CLI para confirmar configuração e inventário.

```bash
# Explicação: Obtém o Project ID atual para reutilizar nos comandos do VM Manager.
PROJECT_ID="$(gcloud config get-value project)"

# Explicação: Exibe o conjunto de funcionalidades do VM Manager habilitado no projeto.
gcloud compute os-config project-feature-settings describe \
  --project="$PROJECT_ID"
```

Se o projeto de laboratório permitir habilitar o conjunto completo:

```bash
# Explicação: Habilita o conjunto completo de funcionalidades de patch/configuração do VM Manager no projeto. Pode haver cobrança conforme uso; execute apenas em laboratório apropriado.
gcloud compute os-config project-feature-settings update \
  --project="$PROJECT_ID" \
  --patch-and-config-feature-set=full
```

Agora valide o inventário do sistema operacional:

```bash
# Explicação: Lista dados de inventário coletados pelo OS Config nas VMs da zona. O resultado confirma que o agente está reportando ao serviço.
gcloud compute os-config inventories list \
  --location=us-central1-a

# Explicação: Exibe detalhes de inventário da VM do laboratório, como SO, kernel e versão do agente OS Config.
gcloud compute os-config inventories describe ace-opslogin \
  --location=us-central1-a
```

> Pode levar algum tempo após habilitar o OS Config para o primeiro inventário aparecer.

### Falha proposital — inventário ausente

Se o comando de inventário não retornar a VM:

```text
Sintoma
→ ace-opslogin não aparece no inventário

Hipótese
→ OS Config não está habilitado/reportando para a VM

Evidência
→ API, metadata, feature settings e inventário CLI

Causa possível no laboratório
→ enable-osconfig ausente/incorreto ou agente ainda não reportou

Correção
→ restaurar enable-osconfig=TRUE, confirmar feature settings e aguardar nova coleta
```

Inspecione as evidências antes de alterar qualquer outra camada:

```bash
# Explicação: Confirma se a API OS Config está habilitada no projeto.
gcloud services list \
  --enabled \
  --filter='NAME:osconfig.googleapis.com'

# Explicação: Confirma o valor de enable-osconfig no metadata de projeto.
gcloud compute project-info describe \
  --format='yaml(commonInstanceMetadata.items)'

# Explicação: Verifica novamente as feature settings do VM Manager.
gcloud compute os-config project-feature-settings describe \
  --project="$PROJECT_ID"
```

Referências oficiais:
- https://cloud.google.com/compute/vm-manager/docs/setup
- https://cloud.google.com/compute/vm-manager/docs/os-inventory/view-os-details

---

<!-- MEP-ACCEPTANCE-V9 -->
# Critério de aceite M/E/P desta aula

> Esta seção não substitui o conteúdo acima; ela explicita o critério usado na auditoria da baseline v9.

Para um tópico ser classificado como `P` nesta baseline, não basta existir um comando. A aula precisa apresentar:

```text
conceito operacional
   ↓
configuração/comando
   ↓
inspeção
   ↓
teste ou comportamento observável
```

Quando a execução depender de Organization, privilégio administrativo, custo relevante ou infraestrutura especial, use `P*`.

## Tópicos do guia mapeados para esta aula

| Seção | Tópico | Esperado | Nível da matriz |
|---|---|---:|---:|
| 3.1 | OS Login | `P` | `P` |
| 3.1 | VM Manager | `P` | `P` |
