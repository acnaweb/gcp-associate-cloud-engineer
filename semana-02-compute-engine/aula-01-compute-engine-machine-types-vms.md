# Aula 1 — Compute Engine, Machine Types e VMs

## Objetivos

Ao final desta aula, você deverá:

- Criar e operar VMs;
- Comparar machine types;
- Praticar stop/start/reset;
- Inspecionar metadados e rede;

---

# 1. Modelo mental

```text
Compute Engine
  └─ VM (zonal)
      ├─ vCPU/RAM
      ├─ boot disk
      ├─ NIC
      └─ service account
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

```bash
export ZONE=us-central1-a
gcloud services enable compute.googleapis.com

gcloud compute machine-types list \
  --zones=$ZONE \
  --filter="name:e2-"

gcloud compute instances create ace-vm \
  --zone=$ZONE \
  --machine-type=e2-micro \
  --image-family=debian-12 \
  --image-project=debian-cloud

gcloud compute instances describe ace-vm --zone=$ZONE
gcloud compute instances stop ace-vm --zone=$ZONE
gcloud compute instances start ace-vm --zone=$ZONE
gcloud compute instances reset ace-vm --zone=$ZONE
```

Observe status:
```bash
gcloud compute instances list
```

> `stop/start` altera o estado da VM. `reset` equivale a um hard reset e não é um shutdown gracioso do SO.

---

# 4. Testes e falhas propositais

- Pare a VM e tente SSH.
- Compare IP externo antes/depois de stop/start quando ele é efêmero.
- Use `describe` para conferir zone, machine type e disks antes de troubleshooting.

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

- VM é normalmente zonal.
- Machine family/series/type não são sinônimos.
- Reset não é stop+start gracioso.
- Pare VMs de laboratório para reduzir custo, mas discos persistentes continuam existindo.

---

# 7. Questões estilo ACE

- Você precisa de controle do SO e software legado. Serviço? → Compute Engine.
- Qual operação é semelhante a power-cycle sem shutdown gracioso? → reset.

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

