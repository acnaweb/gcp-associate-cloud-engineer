# Aula 2 — Cloud Logging e Troubleshooting

## Objetivos

Ao final desta aula, você deverá:

- Entender Cloud Logging;
- Consultar logs;
- Entender structured logs;
- Entender log-based metrics;
- Correlacionar logs com Monitoring;
- Seguir um fluxo de troubleshooting.

---

# 1. Cloud Logging

Cloud Logging centraliza logs de serviços e aplicações.

```text
Applications
Compute Engine
Cloud Run
GKE
Cloud SQL
...
   │
   ▼
Cloud Logging
```

---

# 2. Logs Explorer

Ferramenta principal para consulta de logs.

Você pode filtrar por:

- Resource type;
- Severity;
- Service;
- Project;
- Text;
- Labels;
- Timestamp.

---

# 3. Exemplo de filtro

Conceitualmente:

```text
resource.type="gce_instance"
severity>=ERROR
```

Objetivo:

> encontrar erros em VMs.

---

# 4. Severity

Níveis comuns:

```text
DEBUG
INFO
NOTICE
WARNING
ERROR
CRITICAL
ALERT
EMERGENCY
```

---

# 5. Structured Logging

Logs estruturados usam campos.

Exemplo:

```json
{
  "severity": "ERROR",
  "message": "Database connection failed",
  "service": "orders-api",
  "request_id": "abc123"
}
```

Isso facilita filtros e correlação.

---

# 6. Log-based Metrics

Você pode transformar padrões de logs em métricas.

Exemplo:

```text
Log contains "ERROR"
       │
       ▼
Log-based Metric
       │
       ▼
Alerting Policy
```

---

# 7. Monitoring + Logging

Fluxo operacional:

```text
Monitoring detects anomaly
        ↓
Alert opens incident
        ↓
Engineer checks logs
        ↓
Root cause
        ↓
Correction
```

---

# 8. Troubleshooting de Cloud Run

```text
Service failed
   ↓
Cloud Run logs
   ↓
Check:
- container start
- port
- IAM
- env vars
- dependency
```

---

# 9. Troubleshooting de Compute Engine

```text
VM issue
  ↓
Instance status
  ↓
Serial output
  ↓
System logs
  ↓
Network/firewall
```

---

# 10. Troubleshooting de GKE

```text
kubectl get pods
      ↓
kubectl describe pod
      ↓
kubectl logs
      ↓
Cloud Logging
```

---

# 11. Comandos úteis

Cloud Run:

```bash
gcloud run services logs read SERVICE_NAME \
  --region=REGION
```

Compute Engine serial output:

```bash
gcloud compute instances get-serial-port-output VM_NAME \
  --zone=ZONE
```

---

# 12. Fluxo geral de troubleshooting

```text
1. What changed?
2. Is resource healthy?
3. Check metrics
4. Check logs
5. Check IAM
6. Check network
7. Check quota
8. Check dependencies
```

---

# 13. Questões Estilo ACE

## Questão 1

CPU está normal, mas aplicação retorna HTTP 500.

**Resposta:** consultar logs da aplicação.

## Questão 2

Você quer gerar alerta sempre que logs contiverem padrão específico.

**Resposta:** log-based metric + alerting policy.

## Questão 3

VM não completa boot.

**Resposta:** verificar serial output/logs de inicialização.

---

# 14. Pegadinhas ACE

- Logs detalham eventos; métricas mostram comportamento agregado.
- Um erro de aplicação nem sempre aparece como problema de infraestrutura.
- IAM, rede e quota são causas comuns.
- Sempre correlacione mudança recente com o início do incidente.

---

# 15. Checklist

- [ ] Entendo Cloud Logging
- [ ] Sei usar Logs Explorer
- [ ] Entendo severity
- [ ] Entendo structured logging
- [ ] Entendo log-based metrics
- [ ] Sei correlacionar logs e metrics
- [ ] Sei seguir troubleshooting
