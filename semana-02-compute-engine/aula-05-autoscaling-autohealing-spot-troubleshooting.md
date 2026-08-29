# Aula 5 — Autoscaling, Autohealing, Spot VMs e Troubleshooting

## Objetivos

Ao final, você deverá:
- configurar autoscaling;
- configurar health check de autohealing;
- diferenciar autoscaling de autohealing;
- entender Spot VM;
- provocar falha do nginx e observar reparo.


> **Custos:** MIG, VM e health checks podem gerar cobrança indireta. Remova tudo.

---

# 1. Conceito

Autoscaling responde à demanda e altera quantidade de VMs. Autohealing responde à saúde e repara/substitui instâncias. Spot é modelo de provisionamento com possibilidade de interrupção.

## Arquitetura mental

```text
MIG
 ├─ autoscaler → quantas VMs?
 ├─ autohealing → estão saudáveis?
 └─ template → como criá-las?
```

---

# 2. Criar

```bash
cat > startup.sh <<'EOF'
#!/bin/bash
apt-get update
apt-get install -y nginx
systemctl enable --now nginx
EOF

gcloud compute instance-templates create ace-auto-template \
  --machine-type=e2-micro \
  --tags=ace-health \
  --metadata-from-file=startup-script=startup.sh \
  --image-family=debian-12 --image-project=debian-cloud

gcloud compute instance-groups managed create ace-auto-mig \
  --zone=us-central1-a \
  --template=ace-auto-template \
  --size=1

gcloud compute firewall-rules create ace-health-allow \
  --network=default \
  --allow=tcp:80 \
  --source-ranges=130.211.0.0/22,35.191.0.0/16 \
  --target-tags=ace-health

gcloud compute health-checks create http ace-auto-hc --port=80

gcloud compute instance-groups managed update ace-auto-mig \
  --zone=us-central1-a \
  --health-check=ace-auto-hc \
  --initial-delay=90

gcloud compute instance-groups managed set-autoscaling ace-auto-mig \
  --zone=us-central1-a \
  --min-num-replicas=1 \
  --max-num-replicas=3 \
  --target-cpu-utilization=0.60
```

---

# 3. Inspecionar

Antes de provocar qualquer erro, confirme a configuração criada. O troubleshooting desta aula usará **somente elementos que você já observou aqui**.

```bash
gcloud compute instance-groups managed describe ace-auto-mig \
  --zone=us-central1-a
gcloud compute health-checks describe ace-auto-hc
gcloud compute instance-groups managed list-instances ace-auto-mig \
  --zone=us-central1-a
```

---

# 4. Testar

Verifique que nginx está ativo na VM atual:

```bash
VM=$(gcloud compute instance-groups managed list-instances ace-auto-mig \
 --zone=us-central1-a --format="value(instance.basename())" | head -1)

gcloud compute ssh "$VM" --zone=us-central1-a \
 --command="systemctl is-active nginx"
```

---

# 5. Quebrar propositalmente

Pare nginx:

```bash
gcloud compute ssh "$VM" --zone=us-central1-a \
  --command="sudo systemctl stop nginx"
```

Aguarde os ciclos do health check/initial delay e acompanhe o MIG.

---

# 6. Troubleshooting

Agora o erro já foi produzido e os componentes envolvidos já foram apresentados.

**Sintoma:** instância pode ser marcada como não saudável e reparada/recriada.

**Hipótese:** autohealing detectou falha HTTP.

**Evidências:**
```bash
gcloud compute instance-groups managed list-instances ace-auto-mig \
  --zone=us-central1-a
gcloud compute instance-groups managed describe ace-auto-mig \
  --zone=us-central1-a \
  --format="yaml(currentActions)"
```

**Causa:** nginx foi parado propositalmente. O health check configurado é o sinal usado pelo autohealing.

Não confunda com autoscaling: CPU não foi o motivo da substituição.

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

O MIG deverá reparar/recriar automaticamente. Confirme nova instância e nginx ativo.

```bash
gcloud compute instance-groups managed list-instances ace-auto-mig \
  --zone=us-central1-a
```

---

# 8. Questões estilo ACE

1. CPU alta e necessidade de mais VMs? **Autoscaler**.
2. App parou de responder e VM deve ser reparada? **Autohealing**.
3. Batch tolerante a interrupção e sensível a custo? **Spot VM**.

---

# 9. Cleanup

```bash
gcloud compute instance-groups managed delete ace-auto-mig \
  --zone=us-central1-a --quiet
gcloud compute instance-templates delete ace-auto-template --quiet
gcloud compute health-checks delete ace-auto-hc --quiet
gcloud compute firewall-rules delete ace-health-allow --quiet
rm -f startup.sh
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

---

# Cobertura adicional — VM Manager

O exam guide inclui configuração de **VM Manager**. Ele reúne capacidades de gerenciamento do sistema operacional, como inventário e patching, dependendo da configuração/agentes e recursos habilitados.

No Console:

```text
Compute Engine → VM Manager
```

Habilite APIs conforme o laboratório/documentação atual exigir e inspecione a VM:

```bash
gcloud compute instances describe INSTANCE --zone=ZONE
```

Para prova, diferencie:

```text
MIG
→ ciclo de vida/escala de conjunto de VMs

VM Manager
→ gerenciamento do SO/inventário/patch/configuração operacional
```
