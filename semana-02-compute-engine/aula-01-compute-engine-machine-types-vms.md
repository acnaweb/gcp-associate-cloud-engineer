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
