# Aula 5 — Autoscaling, Autohealing, Spot VMs e Troubleshooting

## Objetivos

Ao final desta aula, você deverá:

- Configurar autoscaling;
- Entender autohealing;
- Conhecer Spot VMs;
- Investigar MIG;

---

# 1. Modelo mental

```text
MIG
 ├─ autoscaler: QUANTAS VMs?
 ├─ autohealing: VMs estão saudáveis?
 └─ template: COMO criar VMs?
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

Crie template/MIG rapidamente:
```bash
cat > startup.sh <<'EOF'
#!/bin/bash
apt-get update
apt-get install -y nginx
systemctl enable --now nginx
EOF
gcloud compute instance-templates create ace-scale-template \
  --machine-type=e2-micro \
  --metadata-from-file=startup-script=startup.sh \
  --image-family=debian-12 --image-project=debian-cloud
gcloud compute instance-groups managed create ace-scale-mig \
  --zone=us-central1-a --template=ace-scale-template --size=1
```

Autoscaling:
```bash
gcloud compute instance-groups managed set-autoscaling ace-scale-mig \
  --zone=us-central1-a \
  --min-num-replicas=1 \
  --max-num-replicas=3 \
  --target-cpu-utilization=0.60
```

Health check para autohealing:
```bash
gcloud compute health-checks create http ace-mig-hc --port=80
gcloud compute instance-groups managed update ace-scale-mig \
  --zone=us-central1-a \
  --health-check=ace-mig-hc \
  --initial-delay=120
```

Inspecione:
```bash
gcloud compute instance-groups managed describe ace-scale-mig --zone=us-central1-a
```

---

# 4. Testes e falhas propositais

- Pare nginx em uma instância para observar autohealing após os ciclos de health check.
- Autoscaling não é load balancing.
- Spot VM pode ser preemptada; use para workloads tolerantes a interrupção.

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

- Autoscaler responde à métrica/capacidade.
- Autohealing substitui instância não saudável.
- Spot reduz custo com interrupção possível.
- Health check de LB e de autohealing têm propósitos relacionados, mas efeitos diferentes.

---

# 7. Questões estilo ACE

- Batch tolerante a interrupção e custo baixo? → Spot.
- Instância existe mas app morreu; mecanismo de reparo no MIG? → autohealing.

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

