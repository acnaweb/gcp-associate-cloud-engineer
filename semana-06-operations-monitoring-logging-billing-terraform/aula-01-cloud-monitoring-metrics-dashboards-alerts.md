# Aula 1 — Cloud Monitoring, Metrics, Dashboards e Alerts

## Objetivos

Ao final desta aula, você deverá:

- Explorar métricas;
- Criar VM monitorável;
- Criar uptime check/alert conceitualmente;
- Ler dashboards;

---

# 1. Modelo mental

```text
Resource ── metrics ──> Cloud Monitoring
                         ├─ dashboard
                         ├─ alert policy
                         └─ notification channel
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

Crie uma VM web:
```bash
cat > startup.sh <<'EOF'
#!/bin/bash
apt-get update
apt-get install -y nginx
systemctl enable --now nginx
EOF

gcloud compute instances create ace-monitor-vm \
  --zone=us-central1-a \
  --machine-type=e2-micro \
  --tags=http-server \
  --metadata-from-file=startup-script=startup.sh \
  --image-family=debian-12 --image-project=debian-cloud
```

No Console:
1. Monitoring → Metrics Explorer.
2. Resource: VM Instance.
3. Métrica: CPU utilization.
4. Salve em um dashboard.
5. Crie alert policy (ex.: CPU > limite por janela).
6. Observe incident state.

Liste policies:
```bash
gcloud alpha monitoring policies list 2>/dev/null || true
```

> Algumas operações de Monitoring são mais didáticas no Console e APIs; o foco é entender resource + metric + condition + notification.

---

# 4. Testes e falhas propositais

- Pare a VM e veja mudança nas séries/availability.
- Alerta não 'conserta' recurso; ele detecta condição e abre incidente/notifica.
- Métrica não é log.

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

- Metrics são time series.
- Alert policy combina condição e canais.
- Dashboard é visualização, não mecanismo de retenção/automação.

---

# 7. Questões estilo ACE

- Quer ser notificado quando CPU alta? → alerting policy.
- Quer visualizar tendência? → dashboard/metrics explorer.

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

