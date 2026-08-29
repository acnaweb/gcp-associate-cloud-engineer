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
gcloud compute instances create ace-opslogin \
 --zone=us-central1-a --machine-type=e2-micro \
 --image-family=debian-12 --image-project=debian-cloud

gcloud compute project-info add-metadata --metadata enable-oslogin=TRUE
```

## 3. Inspecionar

```bash
gcloud compute instances describe ace-opslogin --zone=us-central1-a
gcloud compute project-info describe --format='yaml(commonInstanceMetadata)'
gcloud compute os-login describe-profile 2>/dev/null || true
```

No Console, abra Compute Engine → VM Manager e identifique as funcionalidades disponíveis no projeto.

> A partir deste ponto, todos os elementos usados no troubleshooting já foram apresentados e inspecionados.

## 4. Testar

```bash
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
gcloud compute project-info describe --format='yaml(commonInstanceMetadata)'
```

Habilitação em projeto de laboratório:

```bash
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
