# Aula 1 — Cloud Monitoring, Metrics, Dashboards e Alerts

## Objetivos

Ao final desta aula, você deverá:

- Entender Cloud Monitoring;
- Entender metrics e time series;
- Criar dashboards;
- Entender alerting policies;
- Entender incidents;
- Entender uptime checks.

---

# 1. Cloud Monitoring

Cloud Monitoring permite acompanhar saúde e performance de recursos e aplicações.

```text
Resources / Applications
        │
        ├── Metrics
        ├── Availability
        └── Performance
             │
             ▼
      Cloud Monitoring
```

---

# 2. Metrics

Metric representa uma medição.

Exemplos:

```text
CPU utilization
Memory usage
Request count
Latency
Error rate
Disk usage
```

---

# 3. Time Series

Uma metric observada ao longo do tempo forma uma série temporal.

```text
CPU %
100 |               *
 80 |          *  *
 60 |      * *
 40 |  * *
 20 |
    +-------------------
      time →
```

---

# 4. Resource + Metric

Uma metric normalmente está associada a um recurso monitorado.

Exemplo:

```text
Compute Engine VM
      +
CPU utilization
      =
Time series
```

---

# 5. Dashboards

Dashboards permitem visualizar métricas.

Exemplos de painéis:

```text
CPU
Memory
Requests
Latency
Errors
Disk
```

O Cloud Monitoring oferece dashboards predefinidos e customizados.

---

# 6. Alerting Policy

Uma alerting policy define quando gerar um incidente/notificação.

Exemplo:

```text
CPU > 80%
for 5 minutes
      │
      ▼
Alerting Policy
      │
      ▼
Incident
      │
      ▼
Notification
```

---

# 7. Notification Channels

Exemplos:

- Email;
- Aplicativos;
- Slack/PagerDuty quando integrados;
- Outros canais suportados.

---

# 8. Incident

Quando a condição de uma alerting policy é atendida, um incidente pode ser aberto.

```text
Metric threshold crossed
        ↓
Incident opened
        ↓
Notification
        ↓
Troubleshooting
```

---

# 9. Uptime Checks

Uptime checks verificam disponibilidade de endpoints.

Exemplo:

```text
Google probe
    │
    ▼
https://app.exemplo.com
    │
    ├── Success
    └── Failure
```

Pode-se criar alertas sobre falhas do uptime check.

---

# 10. Casos de uso

## VM

```text
CPU > 80%
→ alert
```

## API

```text
Latency > threshold
→ alert
```

## Site

```text
Uptime check failed
→ alert
```

---

# 11. Laboratório — explorar Monitoring

No Console:

```text
Monitoring
  ├── Metrics Explorer
  ├── Dashboards
  ├── Alerting
  └── Uptime Checks
```

Via CLI, algumas operações podem ser realizadas com comandos e APIs específicas.

---

# 12. Conceito: Monitoring x Logging

```text
Monitoring
   → métricas
   → tendências
   → alertas

Logging
   → eventos
   → detalhes
   → diagnóstico
```

Eles se complementam.

---

# 13. Questões Estilo ACE

## Questão 1

Você quer ser avisado quando CPU ultrapassar 80%.

**Resposta:** Alerting Policy.

## Questão 2

Você quer verificar se uma URL pública está respondendo.

**Resposta:** Uptime Check.

## Questão 3

Você quer acompanhar CPU, latência e erros em uma tela única.

**Resposta:** Dashboard.

---

# 14. Pegadinhas ACE

- Metric não é log.
- Alerting Policy define condição.
- Incident é o registro de um problema ativo.
- Uptime check mede disponibilidade.
- Monitoring pode trabalhar com múltiplos projetos via metrics scope.

---

# 15. Checklist

- [ ] Entendo metric
- [ ] Entendo time series
- [ ] Entendo dashboard
- [ ] Entendo alerting policy
- [ ] Entendo incident
- [ ] Entendo uptime check
