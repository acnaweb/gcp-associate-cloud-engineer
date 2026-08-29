# Aula 2 — Persistent Disks, Snapshots e Images

## Objetivos

Ao final, você deverá:
- criar um Persistent Disk e anexá-lo;
- formatar/montar o volume;
- criar snapshot;
- restaurar outro disk;
- diferenciar disk, snapshot e image;
- diagnosticar perda de acesso após unmount.


> **Custos:** Persistent Disks e snapshots geram cobrança de armazenamento.

---

# 1. Conceito

Persistent Disk é armazenamento de bloco. Snapshot representa um ponto de recuperação do disco. Image é usada principalmente como base para criar discos de boot/VMs padronizadas.

## Arquitetura mental

```text
VM ── attach ──> Persistent Disk
                    └─ snapshot
                         └─ restore disk
```

---

# 2. Criar

```bash
export ZONE=us-central1-a

gcloud compute instances create ace-disk-vm \
  --zone="$ZONE" \
  --machine-type=e2-micro \
  --image-family=debian-12 \
  --image-project=debian-cloud

gcloud compute disks create ace-data \
  --zone="$ZONE" --size=10GB --type=pd-balanced

gcloud compute instances attach-disk ace-disk-vm \
  --disk=ace-data --zone="$ZONE"

gcloud compute ssh ace-disk-vm --zone="$ZONE" --command='
sudo mkfs.ext4 -F /dev/disk/by-id/google-ace-data
sudo mkdir -p /data
sudo mount /dev/disk/by-id/google-ace-data /data
echo ACE | sudo tee /data/arquivo.txt
'
```

---

# 3. Inspecionar

Antes de provocar qualquer erro, confirme a configuração criada. O troubleshooting desta aula usará **somente elementos que você já observou aqui**.

```bash
gcloud compute disks describe ace-data --zone="$ZONE"
gcloud compute instances describe ace-disk-vm --zone="$ZONE" \
  --format="yaml(disks)"
gcloud compute ssh ace-disk-vm --zone="$ZONE" \
  --command="mount | grep /data; cat /data/arquivo.txt"
```

---

# 4. Testar

Crie snapshot e restaure:

```bash
gcloud compute snapshots create ace-data-snap \
  --source-disk=ace-data \
  --source-disk-zone="$ZONE"

gcloud compute disks create ace-data-restored \
  --zone="$ZONE" \
  --source-snapshot=ace-data-snap

gcloud compute snapshots describe ace-data-snap
```

---

# 5. Quebrar propositalmente

Desmonte o volume sem apagar dados:

```bash
gcloud compute ssh ace-disk-vm --zone="$ZONE" \
  --command="sudo umount /data; cat /data/arquivo.txt"
```

---

# 6. Troubleshooting

Agora o erro já foi produzido e os componentes envolvidos já foram apresentados.

**Sintoma:** `cat /data/arquivo.txt` falha após `umount`.

**Hipótese:** o disco continua anexado, mas não está montado.

**Evidências:**
```bash
gcloud compute instances describe ace-disk-vm --zone="$ZONE" \
  --format="yaml(disks)"
gcloud compute ssh ace-disk-vm --zone="$ZONE" \
  --command="lsblk; mount | grep /data || true"
```

**Causa:** removemos o mount, não o disk nem o snapshot.

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
gcloud compute ssh ace-disk-vm --zone="$ZONE" --command='
sudo mount /dev/disk/by-id/google-ace-data /data
cat /data/arquivo.txt
'
```

---

# 8. Questões estilo ACE

1. Precisa restaurar um volume para um ponto anterior? **Snapshot**.
2. Precisa padronizar boot de VMs? **Image/Instance Template**, conforme caso.
3. Disk anexado significa necessariamente montado no SO? **Não**.

---

# 9. Cleanup

```bash
gcloud compute instances delete ace-disk-vm --zone="$ZONE" --quiet
gcloud compute disks delete ace-data ace-data-restored --zone="$ZONE" --quiet
gcloud compute snapshots delete ace-data-snap --quiet
```

---


---

# Cobertura ACE ampliada — tipos de storage de Compute Engine

## Zonal Persistent Disk

Volume associado a uma zona. Bom para workloads que não exigem replicação síncrona entre zonas pelo próprio disco.

## Regional Persistent Disk

Replica dados entre duas zonas da mesma região para maior disponibilidade.

## Hyperdisk

Família de block storage do Google Cloud voltada a requisitos modernos de performance/capacidade configuráveis. Para ACE, reconheça que pode ser alternativa a Persistent Disk conforme workload e disponibilidade regional.

## Snapshot schedules

O guia cobra agendamento de snapshots. Use resource policies:

```bash
gcloud compute resource-policies create snapshot-schedule ace-daily-snapshot \
  --region=us-central1 \
  --daily-schedule \
  --start-time=03:00
```

Associe a um disco compatível:

```bash
gcloud compute disks add-resource-policies DISK_NAME \
  --zone=us-central1-a \
  --resource-policies=ace-daily-snapshot
```

Inspecione:

```bash
gcloud compute resource-policies describe ace-daily-snapshot --region=us-central1
```

## Matriz

```text
Zonal PD      → bloco em uma zona
Regional PD   → bloco replicado entre zonas
Hyperdisk     → bloco com opções modernas de performance
Snapshot      → ponto de recuperação
Image         → base para criação de discos/VMs
```

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

# Cobertura adicional — Zonal x Regional Persistent Disk, Images e Snapshot Schedules

## Zonal x Regional Persistent Disk

```text
Zonal PD
→ réplica dentro da zona/infraestrutura do serviço
→ usado por VM na zona compatível

Regional PD
→ replicação síncrona entre duas zonas da mesma região
→ maior disponibilidade de armazenamento
```

## Images

Snapshots são voltados a recuperação de disco. Images são usadas como origem padronizada para boot disks/VMs.

```bash
gcloud compute images list --no-standard-images --limit=10
```

Exemplo a partir de um disk:

```bash
gcloud compute images create ace-custom-image \
  --source-disk=DISK_NAME \
  --source-disk-zone=us-central1-a
```

## Snapshot schedules

A prova inclui trabalhar com snapshots, inclusive agendamento. Modelo mental:

```text
Resource Policy (snapshot schedule)
        ↓ associada ao
Persistent Disk
        ↓
snapshots automáticos
```

Liste policies:

```bash
gcloud compute resource-policies list
```

Diferencie:

```text
Snapshot manual   → ação pontual
Snapshot schedule → política automática recorrente
Image             → base para criar boot disks/VMs
```


---

## Prática completa — Images e Snapshot Schedule

### Criar, visualizar e excluir custom image

Depois de ter um disco disponível:

```bash
gcloud compute images create ace-custom-image \
  --source-disk=ace-data \
  --source-disk-zone="$ZONE"

gcloud compute images describe ace-custom-image
gcloud compute images list --no-standard-images
```

Teste de uso:

```bash
gcloud compute instances create ace-from-image \
  --zone="$ZONE" \
  --machine-type=e2-micro \
  --image=ace-custom-image
```

### Snapshot schedule completo

```bash
gcloud compute resource-policies create snapshot-schedule ace-daily-snapshot \
  --region=us-central1 \
  --daily-schedule \
  --start-time=03:00

gcloud compute disks add-resource-policies ace-data \
  --zone="$ZONE" \
  --resource-policies=ace-daily-snapshot

gcloud compute resource-policies describe ace-daily-snapshot \
  --region=us-central1
```

### Cleanup adicional

```bash
gcloud compute instances delete ace-from-image --zone="$ZONE" --quiet
gcloud compute images delete ace-custom-image --quiet
gcloud compute disks remove-resource-policies ace-data \
  --zone="$ZONE" \
  --resource-policies=ace-daily-snapshot 2>/dev/null || true
gcloud compute resource-policies delete ace-daily-snapshot \
  --region=us-central1 --quiet 2>/dev/null || true
```
