# Aula 2 — Persistent Disks, Snapshots e Images

## Objetivos

Ao final desta aula, você deverá:

- Entender o papel dos discos no Compute Engine;
- Diferenciar boot disk e data disk;
- Entender Persistent Disk e Hyperdisk em nível de prova;
- Criar, anexar e montar um disco;
- Diferenciar disk, snapshot e image;
- Entender cenários de backup e clonagem.

---

# 1. Boot Disk x Data Disk

```text
VM
├── Boot Disk
│   └── Sistema operacional
└── Data Disk
    └── Dados da aplicação
```

O boot disk contém o SO. Discos adicionais podem armazenar dados separadamente.

---

# 2. Persistent Disk

O Compute Engine permite anexar armazenamento em bloco persistente às VMs.

Conceitualmente:

```text
VM
 │
 ├── Boot Persistent Disk
 └── Additional Persistent Disk
```

O disco tem ciclo de vida independente da memória da VM.

---

# 3. Escopo

Persistent Disks podem ser:

- Zonais;
- Regionais.

Um **Regional Persistent Disk** replica dados entre duas zones da mesma região e pode ser usado em cenários de maior disponibilidade.

---

# 4. Tipos de disco

Para o ACE, reconheça o objetivo geral:

```text
pd-standard   → HDD / custo
pd-balanced   → equilíbrio custo/performance
pd-ssd        → SSD / maior performance
Hyperdisk     → famílias modernas e workloads de alta performance
```

Nem todos os tipos são compatíveis com todas as séries de máquina.

---

# 5. Criar disco

```bash
gcloud compute disks create ace-data-disk \
  --zone=southamerica-east1-a \
  --size=20GB \
  --type=pd-balanced
```

Listar:

```bash
gcloud compute disks list
```

---

# 6. Anexar à VM

```bash
gcloud compute instances attach-disk ace-vm-01 \
  --disk=ace-data-disk \
  --zone=southamerica-east1-a
```

---

# 7. Verificar dentro da VM

```bash
gcloud compute ssh ace-vm-01 \
  --zone=southamerica-east1-a
```

```bash
lsblk
```

O novo dispositivo aparecerá sem filesystem se for um disco novo.

---

# 8. Criar filesystem e montar

Exemplo Linux:

```bash
sudo mkfs.ext4 -F /dev/disk/by-id/google-ace-data-disk
```

Criar diretório:

```bash
sudo mkdir -p /mnt/data
```

Montar:

```bash
sudo mount /dev/disk/by-id/google-ace-data-disk /mnt/data
```

Validar:

```bash
df -h
```

> Em produção, configure montagem persistente via `/etc/fstab` com cuidado.

---

# 9. Snapshot

Snapshot é uma cópia point-in-time de um disco.

```text
Persistent Disk
      │
      ▼
   Snapshot
      │
      ├── backup
      └── restore
```

Criar:

```bash
gcloud compute snapshots create ace-data-snapshot \
  --source-disk=ace-data-disk \
  --source-disk-zone=southamerica-east1-a
```

---

# 10. Restaurar disco a partir de snapshot

```bash
gcloud compute disks create ace-data-restored \
  --source-snapshot=ace-data-snapshot \
  --zone=southamerica-east1-a
```

---

# 11. Image

Uma image é usada principalmente como base para criar boot disks/VMs.

```text
Configured VM Boot Disk
          │
          ▼
        Image
          │
      ┌───┴───┐
      ▼       ▼
     VM1     VM2
```

Use uma image customizada quando quiser padronizar o sistema operacional e software base.

---

# 12. Disk x Snapshot x Image

| Item | Uso principal |
|---|---|
| Disk | Armazenamento ativo da VM |
| Snapshot | Backup point-in-time de disco |
| Image | Base reutilizável para criar VMs/boot disks |

Modelo mental:

```text
Disk     → uso ativo
Snapshot → backup/restore
Image    → clonagem/padronização
```

---

# 13. Caso de prova

Necessidade:

> Criar backup point-in-time de um disco.

Resposta:

**Snapshot**

Necessidade:

> Criar 20 VMs com o mesmo SO e software base.

Resposta:

**Image + Instance Template**

---

# 14. Lifecycle de discos

Ao excluir uma VM, o comportamento do disco depende da política configurada.

Não assuma que todo disco será preservado automaticamente.

Para dados importantes:

- Defina políticas de retenção adequadas;
- Use snapshots;
- Separe boot disk e data disk quando fizer sentido.

---

# 15. Laboratório completo

```bash
# Criar disco
gcloud compute disks create ace-data-disk \
  --zone=southamerica-east1-a \
  --size=20GB \
  --type=pd-balanced

# Anexar
gcloud compute instances attach-disk ace-vm-01 \
  --disk=ace-data-disk \
  --zone=southamerica-east1-a

# Criar snapshot
gcloud compute snapshots create ace-data-snapshot \
  --source-disk=ace-data-disk \
  --source-disk-zone=southamerica-east1-a

# Restaurar outro disco
gcloud compute disks create ace-data-restored \
  --source-snapshot=ace-data-snapshot \
  --zone=southamerica-east1-a
```

---

# 16. Pegadinhas ACE

- Snapshot ≠ image.
- Disk é armazenamento ativo.
- Snapshot é ótimo para backup/restore.
- Image é ideal para padronizar VMs.
- Regional Persistent Disk melhora resiliência contra falha zonal.
- Tipo de disco deve ser compatível com a série da VM.

---

# 17. Questões Estilo ACE

## Questão 1

Você precisa restaurar um disco para um estado anterior.

**Resposta:** snapshot.

## Questão 2

Você precisa criar várias VMs idênticas.

**Resposta:** image + instance template.

## Questão 3

Você quer maior resiliência a uma falha zonal para armazenamento em bloco.

**Resposta:** considerar Regional Persistent Disk.

---

# 18. Checklist

- [ ] Sei diferenciar boot disk e data disk
- [ ] Sei criar e anexar Persistent Disk
- [ ] Sei criar snapshot
- [ ] Sei restaurar disco de snapshot
- [ ] Sei diferenciar disk, snapshot e image
- [ ] Entendo o papel de Regional Persistent Disk
