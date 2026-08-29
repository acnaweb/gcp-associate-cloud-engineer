# Aula 1 — Compute Engine, Machine Types e VMs

## Objetivos

Ao final, você deverá:
- criar e inspecionar uma VM;
- entender machine type, zone, boot disk e network interface;
- praticar `stop`, `start` e `reset`;
- diagnosticar tentativa de conexão em VM parada.


> **Custos:** VMs podem gerar cobrança por compute e disco. Use `e2-micro` e remova ao final.

---

# 1. Conceito

Compute Engine oferece VMs com controle do sistema operacional. A VM é tipicamente zonal e combina CPU/memória, disco de boot, NIC e uma identidade de runtime.

## Arquitetura mental

```text
Project
 └─ Zone
    └─ VM
       ├─ machine type
       ├─ boot disk
       └─ NIC
```

---

# 2. Criar

```bash
export ZONE=us-central1-a

gcloud compute instances create ace-vm \
  --zone="$ZONE" \
  --machine-type=e2-micro \
  --image-family=debian-12 \
  --image-project=debian-cloud
```

---

# 3. Inspecionar

Antes de provocar qualquer erro, confirme a configuração criada. O troubleshooting desta aula usará **somente elementos que você já observou aqui**.

```bash
gcloud compute instances describe ace-vm --zone="$ZONE"
gcloud compute instances list
gcloud compute machine-types describe e2-micro --zone="$ZONE"
```

---

# 4. Testar

```bash
gcloud compute ssh ace-vm --zone="$ZONE" --command="hostname && uptime"
gcloud compute instances stop ace-vm --zone="$ZONE"
gcloud compute instances start ace-vm --zone="$ZONE"
gcloud compute instances reset ace-vm --zone="$ZONE"
```

---

# 5. Quebrar propositalmente

Pare a VM:

```bash
gcloud compute instances stop ace-vm --zone="$ZONE"
gcloud compute ssh ace-vm --zone="$ZONE"
```

---

# 6. Troubleshooting

Agora o erro já foi produzido e os componentes envolvidos já foram apresentados.

**Sintoma:** SSH falha.

**Hipótese:** a instância está `TERMINATED`.

**Evidência:**
```bash
gcloud compute instances describe ace-vm \
  --zone="$ZONE" \
  --format="value(status)"
```

**Causa:** a VM foi parada deliberadamente. Não altere firewall antes de confirmar o estado do recurso.

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

```bash
gcloud compute instances start ace-vm --zone="$ZONE"
gcloud compute ssh ace-vm --zone="$ZONE" --command="hostname"
```

---

# 8. Questões estilo ACE

1. Precisa de controle do SO para software legado? **Compute Engine**.
2. `reset` é equivalente a shutdown gracioso? **Não**.
3. Uma VM é normalmente global, regional ou zonal? **Zonal**.

---

# 9. Cleanup

```bash
gcloud compute instances delete ace-vm --zone="$ZONE" --quiet
```

---


---

# Cobertura ACE ampliada — compute choices, custom types, GPUs e TPUs

## Escolha de compute

| Requisito | Escolha típica |
|---|---|
| Controle do SO/VM | Compute Engine |
| Kubernetes | GKE |
| Container HTTP/serverless | Cloud Run |
| Função/evento | Cloud Run functions |
| Agente gerenciado | Agent Runtime no Gemini Enterprise Agent Platform |

## Custom machine types

Quando predefined machine types não atendem à combinação desejada de vCPU/memória, avalie custom machine type.

```bash
gcloud compute machine-types list --zones=us-central1-a --filter='name:n2'
```

Exemplo de criação (não é necessário executar se gerar custo):

```bash
gcloud compute instances create ace-custom-vm \
  --zone=us-central1-a \
  --custom-cpu=2 \
  --custom-memory=4GB \
  --image-family=debian-12 \
  --image-project=debian-cloud
```

## Availability policy

Em `describe`, observe scheduling/provisioning model. Decisões como automatic restart, host maintenance e Spot fazem parte da política de disponibilidade da VM.

## GPUs x TPUs

Regra de decisão de nível ACE:

```text
GPU → aceleração genérica/ML/HPC, ampla compatibilidade
TPU → workloads de ML compatíveis com aceleradores Google
```

Não é necessário dominar tuning de aceleradores para ACE, mas reconhecer o requisito.

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

# Cobertura adicional — escolha de compute, Custom Machine Types, Spot e availability policies

A prova exige comparar, no mínimo:

```text
Compute Engine → VM / controle do SO
GKE            → Kubernetes
Cloud Run      → container serverless
Cloud Functions → função orientada a eventos/HTTP
```

## Custom Machine Type

Quando tipos predefinidos não atendem bem à relação vCPU/memória, um custom machine type pode reduzir desperdício.

Exemplo:

```bash
gcloud compute instances create ace-custom-vm \
  --zone=us-central1-a \
  --custom-cpu=2 \
  --custom-memory=4GB \
  --image-family=debian-12 \
  --image-project=debian-cloud
```

Inspecione:

```bash
gcloud compute instances describe ace-custom-vm \
  --zone=us-central1-a \
  --format='value(machineType)'
```

## Spot VMs

Spot VMs têm preço reduzido, mas podem ser interrompidas pelo Google Cloud. São apropriadas para workloads tolerantes a interrupção, como batch e processamento distribuído resiliente.

## Availability policy

Inspecione:

```bash
gcloud compute instances describe ace-vm \
  --zone=us-central1-a \
  --format='yaml(scheduling)'
```

A seção `scheduling` ajuda a entender manutenção, reinício automático e comportamento de provisionamento.


---

## Prática obrigatória — custom machine type, Spot e availability policy

O guia exige usar **Spot VMs** e **custom machine types**, não apenas reconhecê-los.

### Custom Machine Type

```bash
gcloud compute instances create ace-custom-vm \
  --zone=us-central1-a \
  --custom-cpu=2 \
  --custom-memory=4GB \
  --image-family=debian-12 \
  --image-project=debian-cloud

gcloud compute instances describe ace-custom-vm \
  --zone=us-central1-a \
  --format='yaml(machineType,status)'
```

### Spot VM

```bash
gcloud compute instances create ace-spot-vm \
  --zone=us-central1-a \
  --machine-type=e2-micro \
  --provisioning-model=SPOT \
  --instance-termination-action=STOP \
  --image-family=debian-12 \
  --image-project=debian-cloud

gcloud compute instances describe ace-spot-vm \
  --zone=us-central1-a \
  --format='yaml(scheduling.provisioningModel,scheduling.instanceTerminationAction,status)'
```

### Availability policy / scheduling

Inspecione:

```bash
gcloud compute instances describe ace-custom-vm \
  --zone=us-central1-a \
  --format='yaml(scheduling)'
```

Saiba interpretar opções de manutenção/restart compatíveis com a VM.

### Cleanup adicional

```bash
gcloud compute instances delete ace-custom-vm ace-spot-vm \
  --zone=us-central1-a --quiet
```
