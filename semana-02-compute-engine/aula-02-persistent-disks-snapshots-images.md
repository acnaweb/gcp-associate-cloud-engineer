# Aula 2 — Persistent Disks, Snapshots e Images

## Objetivos

Ao final desta aula, você deverá:

- Criar e anexar Persistent Disk;
- Criar snapshot;
- Diferenciar disk, snapshot e image;
- Restaurar dados;

---

# 1. Modelo mental

```text
VM ── attach ──> Persistent Disk
                   │
                   ├─ snapshot (backup point-in-time)
                   └─ image (template bootable/generalized)
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
export REGION=us-central1

gcloud compute instances create ace-disk-vm \
  --zone=$ZONE --machine-type=e2-micro \
  --image-family=debian-12 --image-project=debian-cloud

gcloud compute disks create ace-data-disk \
  --zone=$ZONE --size=10GB --type=pd-balanced

gcloud compute instances attach-disk ace-disk-vm \
  --disk=ace-data-disk --zone=$ZONE

gcloud compute ssh ace-disk-vm --zone=$ZONE --command='
sudo mkfs.ext4 -F /dev/disk/by-id/google-ace-data-disk &&
sudo mkdir -p /data &&
sudo mount /dev/disk/by-id/google-ace-data-disk /data &&
echo "ACE" | sudo tee /data/arquivo.txt
'
```

Snapshot:
```bash
gcloud compute snapshots create ace-data-snap \
  --source-disk=ace-data-disk \
  --source-disk-zone=$ZONE
gcloud compute snapshots list
```

Restaure em outro disco:
```bash
gcloud compute disks create ace-data-restore \
  --zone=$ZONE \
  --source-snapshot=ace-data-snap
```

---

# 4. Testes e falhas propositais

- Desanexe o disco e verifique que a VM continua existindo mas os dados do volume ficam indisponíveis.
- Snapshot não é disco montável: restaure um disk a partir dele.
- Boot image é diferente de snapshot de dados.

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

- Persistent Disk tem ciclo de vida separado da VM dependendo da configuração.
- Snapshot é incremental gerenciado; image é comum para criação de VMs.
- Zona/região do disco deve ser compatível com o uso.

---

# 7. Questões estilo ACE

- Precisa recuperar um volume após corrupção? → snapshot.
- Precisa padronizar boot de novas VMs? → image/custom image ou instance template.

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

