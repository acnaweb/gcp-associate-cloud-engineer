# Aula 1 — Cloud Monitoring, Metrics, Dashboards e Alerts

## Objetivos

Ao final, você deverá:
- entender metric, resource, time series e alert policy;
- observar CPU de uma VM;
- criar dashboard/alert no Console;
- provocar condição de indisponibilidade simples;
- distinguir métrica de log.


---

# 1. Conceito

Monitoring trabalha com séries temporais. Uma métrica associada a um recurso gera pontos ao longo do tempo. Alert policy avalia condição; notification channel envia notificação.

## Arquitetura mental

```text
Resource → metric → time series
                    ├─ dashboard
                    └─ alert policy → incident
```

---

# 2. Criar

```bash
gcloud compute instances create ace-monitor-vm \
  --zone=us-central1-a \
  --machine-type=e2-micro \
  --image-family=debian-12 \
  --image-project=debian-cloud
```

No Console:
1. Monitoring → Metrics Explorer.
2. Resource: VM Instance.
3. Metric: CPU utilization.
4. Salve o gráfico em um dashboard.
5. Crie uma alert policy simples com limiar baixo o suficiente para laboratório, ou apenas configure sem esperar o disparo se não quiser gerar carga artificial.

---

# 3. Inspecionar

Antes de provocar qualquer erro, confirme a configuração criada. O troubleshooting desta aula usará **somente elementos que você já observou aqui**.

```bash
gcloud compute instances describe ace-monitor-vm \
  --zone=us-central1-a \
  --format="value(status)"
```

No Metrics Explorer, identifique explicitamente:
- monitored resource;
- metric;
- aggregation;
- time range.

---

# 4. Testar

Gere CPU por curto período:

```bash
gcloud compute ssh ace-monitor-vm \
  --zone=us-central1-a \
  --command="timeout 30s yes > /dev/null || true"
```

Observe a série após alguns minutos.

---

# 5. Quebrar propositalmente

Pare a VM:

```bash
gcloud compute instances stop ace-monitor-vm \
  --zone=us-central1-a
```

Agora você já conhece o estado da VM e a série temporal; observe a diferença de dados/availability.

---

# 6. Troubleshooting

Agora o erro já foi produzido e os componentes envolvidos já foram apresentados.

**Sintoma:** a VM está parada e novas métricas de CPU deixam de representar workload em execução.

**Hipótese:** mudança no estado do recurso, não falha do dashboard.

**Evidência:**
```bash
gcloud compute instances describe ace-monitor-vm \
  --zone=us-central1-a \
  --format="value(status)"
```

**Causa:** `stop` deliberado.

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
gcloud compute instances start ace-monitor-vm \
  --zone=us-central1-a
```

Confirme status `RUNNING` e aguarde novas métricas.

---

# 8. Questões estilo ACE

1. CPU ao longo do tempo é **métrica/time series**.
2. Alert policy corrige automaticamente a VM? **Não**.
3. Dashboard é visualização, não mecanismo de autorização.

---

# 9. Cleanup

```bash
gcloud compute instances delete ace-monitor-vm \
  --zone=us-central1-a --quiet
# Remova dashboard/alert policy criados no Console.
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
