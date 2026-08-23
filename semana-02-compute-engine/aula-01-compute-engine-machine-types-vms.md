# Aula 1 — Compute Engine, Machine Types e VMs

## Objetivos

Ao final desta aula, você deverá:

- Entender o papel do Compute Engine;
- Saber quando escolher VMs;
- Diferenciar machine family, series e machine type;
- Criar e operar VMs pelo `gcloud`;
- Entender IP interno e externo;
- Reconhecer o escopo zonal das VMs.

---

# 1. O que é Compute Engine?

O **Compute Engine** é o serviço IaaS do Google Cloud para execução de máquinas virtuais.

```text
Application
    │
    ▼
Virtual Machine
    │
    ├── vCPU
    ├── RAM
    ├── Disk
    ├── Network
    └── Operating System
```

Você controla o sistema operacional, pacotes, runtime, aplicação, discos e boa parte da configuração da VM.

---

# 2. Quando usar?

Use Compute Engine quando precisar de:

- Controle do sistema operacional;
- Aplicações legadas;
- Instalação de agentes, drivers ou pacotes específicos;
- Lift-and-shift;
- Configuração específica de CPU/RAM;
- Workloads não containerizados.

Exemplo:

```text
Sistema legado
     │
     ▼
Linux VM
     │
     ▼
Compute Engine
```

---

# 3. Compute Engine x Cloud Run x GKE

| Necessidade | Serviço |
|---|---|
| Controle da VM/SO | Compute Engine |
| Container serverless | Cloud Run |
| Kubernetes | GKE |
| PaaS tradicional | App Engine |

---

# 4. Anatomia de uma VM

```text
Compute Engine VM
        │
        ├── Machine Type
        │     ├── vCPU
        │     └── RAM
        ├── Boot Disk
        ├── Network Interface
        ├── Internal IP
        ├── External IP (opcional)
        ├── Service Account
        └── Metadata
```

---

# 5. Machine Family, Series e Machine Type

```text
Machine Family
      ↓
Machine Series
      ↓
Machine Type
```

Exemplo:

```text
General Purpose
      ↓
      N2
      ↓
n2-standard-4
```

---

# 6. Tipos de workload

## General Purpose

Uso geral:

- Web;
- APIs;
- Aplicações corporativas;
- Desenvolvimento.

## Compute Optimized

- HPC;
- Simulações;
- Processamento CPU-intensive.

## Memory Optimized

- Grandes bancos;
- SAP HANA;
- Workloads in-memory.

## Accelerator Optimized

- GPU;
- ML/AI;
- HPC.

Para o ACE, General Purpose é o mais importante.

---

# 7. Standard, Highmem e Highcpu

```text
standard → equilíbrio
highmem  → mais RAM proporcionalmente
highcpu  → mais CPU proporcionalmente
```

---

# 8. Tipos predefinidos x customizados

Predefinido:

```text
n2-standard-4
```

Customizado:

```text
vCPU = X
RAM  = Y
```

Considere custom machine type quando os tipos predefinidos desperdiçarem recursos.

---

# 9. Laboratório — preparar ambiente

```bash
gcloud config list
gcloud config get-value project

gcloud config set compute/region southamerica-east1
gcloud config set compute/zone southamerica-east1-a

gcloud services enable compute.googleapis.com
```

---

# 10. Listar Machine Types

```bash
gcloud compute machine-types list
```

Filtrar região/zone:

```bash
gcloud compute machine-types list \
  --zones=southamerica-east1-a
```

---

# 11. Criar VM

```bash
gcloud compute instances create ace-vm-01 \
  --zone=southamerica-east1-a \
  --machine-type=e2-medium
```

---

# 12. Listar e descrever

```bash
gcloud compute instances list
```

```bash
gcloud compute instances describe ace-vm-01 \
  --zone=southamerica-east1-a
```

---

# 13. SSH

```bash
gcloud compute ssh ace-vm-01 \
  --zone=southamerica-east1-a
```

Dentro da VM:

```bash
hostname
uname -a
free -h
nproc
lsblk
ip addr
```

---

# 14. Operar a VM

Parar:

```bash
gcloud compute instances stop ace-vm-01 \
  --zone=southamerica-east1-a
```

Iniciar:

```bash
gcloud compute instances start ace-vm-01 \
  --zone=southamerica-east1-a
```

Reset:

```bash
gcloud compute instances reset ace-vm-01 \
  --zone=southamerica-east1-a
```

---

# 15. Alterar Machine Type

Fluxo:

```text
RUNNING
   ↓
STOP
   ↓
CHANGE MACHINE TYPE
   ↓
START
```

```bash
gcloud compute instances stop ace-vm-01 \
  --zone=southamerica-east1-a

gcloud compute instances set-machine-type ace-vm-01 \
  --zone=southamerica-east1-a \
  --machine-type=e2-standard-2

gcloud compute instances start ace-vm-01 \
  --zone=southamerica-east1-a
```

---

# 16. IP interno x externo

```text
Internet
   │
External IP
   ▼
  VM
   │
Internal IP
   ▼
  VPC
```

Em arquiteturas mais seguras, VMs privadas podem acessar a internet usando Cloud NAT.

---

# 17. Escopo zonal

Uma VM pertence a uma zone:

```text
Region: southamerica-east1
        │
        ├── southamerica-east1-a
        │       └── ace-vm-01
        ├── southamerica-east1-b
        └── southamerica-east1-c
```

---

# 18. Pegadinhas ACE

- Compute Engine é indicado quando você precisa controlar o SO.
- VM é normalmente um recurso zonal.
- Alta disponibilidade exige distribuição entre zones.
- Machine type define CPU/RAM.
- Alterações relevantes de machine type normalmente exigem a VM parada.

---

# 19. Questões Estilo ACE

## Questão 1

Um software exige drivers específicos no SO.

**Resposta:** Compute Engine.

## Questão 2

Uma VM está em `southamerica-east1-a`.

**Resposta:** recurso zonal.

## Questão 3

Nenhum machine type predefinido atende bem à relação CPU/RAM.

**Resposta:** considerar custom machine type.

---

# 20. Checklist

- [ ] Sei quando usar Compute Engine
- [ ] Sei criar VMs
- [ ] Sei listar e descrever VMs
- [ ] Sei usar SSH
- [ ] Sei parar e iniciar VMs
- [ ] Entendo machine types
- [ ] Entendo IP interno e externo
- [ ] Sei que VM é zonal
