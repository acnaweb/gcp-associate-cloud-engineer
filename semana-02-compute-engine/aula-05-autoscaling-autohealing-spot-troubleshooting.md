# Aula 5 — Autoscaling, Autohealing, Spot VMs e Troubleshooting

## Objetivos

Ao final desta aula, você deverá:

- Entender autoscaling;
- Entender autohealing;
- Diferenciar scaling de healing;
- Entender Spot VMs;
- Reconhecer cenários adequados para Spot;
- Diagnosticar problemas comuns de Compute Engine.

---

# 1. Autoscaling

Autoscaling altera automaticamente a quantidade de VMs do MIG.

```text
Load ↑
  │
  ▼
Autoscaler
  │
  ▼
More VMs
```

Quando a carga diminui:

```text
Load ↓
  │
  ▼
Autoscaler
  │
  ▼
Fewer VMs
```

---

# 2. Sinais de autoscaling

O MIG pode escalar com base em sinais como:

- CPU;
- Capacidade do Load Balancer;
- Métricas do Cloud Monitoring;
- Schedule;
- Outros sinais suportados pelo tipo de grupo/workload.

---

# 3. Configurar Autoscaling por CPU

```bash
gcloud compute instance-groups managed set-autoscaling ace-web-mig \
  --zone=southamerica-east1-a \
  --min-num-replicas=2 \
  --max-num-replicas=5 \
  --target-cpu-utilization=0.60
```

Modelo:

```text
CPU > target
    ↓
Scale out

CPU < target
    ↓
Scale in
```

---

# 4. Autohealing

Autohealing não é autoscaling.

```text
VM unhealthy
    │
    ▼
Health Check
    │
    ▼
MIG recreates VM
```

Objetivo:

> Manter a quantidade de instâncias saudáveis.

Autoscaling:

> Ajusta capacidade.

Autohealing:

> Substitui instâncias não saudáveis.

---

# 5. Health Check

O health check determina se uma VM está saudável.

Arquitetura:

```text
Health Check
    │
    ├── VM1 ✓
    ├── VM2 ✗
    └── VM3 ✓
          │
          ▼
     recreate VM2
```

---

# 6. Criar Health Check

Exemplo HTTP:

```bash
gcloud compute health-checks create http ace-http-health-check \
  --port=80
```

Associar ao MIG:

```bash
gcloud compute instance-groups managed update ace-web-mig \
  --zone=southamerica-east1-a \
  --health-check=ace-http-health-check \
  --initial-delay=60
```

---

# 7. Spot VMs

Spot VMs oferecem menor custo, porém podem ser interrompidas pelo Google quando a capacidade for necessária.

Use para workloads tolerantes a interrupção.

Exemplos:

- Batch;
- CI;
- Renderização;
- Workers;
- Processamento paralelo;
- Algumas cargas de ML.

Evite para:

- Workloads que não toleram interrupção;
- Sistemas stateful sem estratégia de recuperação;
- Componentes únicos críticos.

---

# 8. Modelo mental de Spot

```text
Lower cost
    +
Can be interrupted
    =
Spot VM
```

---

# 9. Spot em MIG

Arquitetura:

```text
Instance Template
  configured for Spot
          │
          ▼
         MIG
     ┌────┼────┐
     ▼    ▼    ▼
   Spot Spot Spot
```

---

# 10. Criar template Spot

Exemplo:

```bash
gcloud compute instance-templates create ace-spot-template \
  --machine-type=e2-medium \
  --provisioning-model=SPOT \
  --instance-termination-action=STOP
```

> Escolha a termination action conforme o comportamento desejado e compatibilidade do cenário.

---

# 11. Troubleshooting — VM não inicia

Verifique:

```bash
gcloud compute instances describe VM_NAME \
  --zone=ZONE
```

Procure:

- Status;
- Erros de quota;
- Tipo de máquina indisponível;
- Disco;
- IAM;
- Startup script.

---

# 12. Serial Console

```bash
gcloud compute instances get-serial-port-output VM_NAME \
  --zone=ZONE
```

Útil para:

- Falha de boot;
- Startup script;
- Problemas de sistema operacional.

---

# 13. Troubleshooting — SSH

Se SSH falhar, verifique:

```text
VM running?
↓
Network route?
↓
Firewall?
↓
IAM?
↓
OS Login?
↓
External IP / IAP?
```

Não trate SSH apenas como problema de senha.

---

# 14. Troubleshooting — aplicação inacessível

Fluxo:

```text
Client
  ↓
External IP / Load Balancer
  ↓
Firewall
  ↓
VM Network Interface
  ↓
Application Port
  ↓
Application Process
```

Verifique:

- Porta;
- Firewall;
- Processo;
- Health check;
- Tags;
- Route;
- IP.

---

# 15. Troubleshooting — quota

Muitos erros de criação são relacionados a quota/capacidade.

Verifique:

```bash
gcloud compute regions describe southamerica-east1
```

e quotas pelo Console/Cloud Quotas quando necessário.

---

# 16. Alto nível de disponibilidade

Arquitetura típica:

```text
            Load Balancer
                 │
                 ▼
          Regional MIG
        ┌────────┼────────┐
        ▼        ▼        ▼
      Zone A   Zone B   Zone C
        │        │        │
       VM       VM       VM
```

Combine:

- Regional MIG;
- Health checks;
- Autohealing;
- Autoscaling;
- Load Balancer.

---

# 17. Autoscaling x Autohealing

| Conceito | Objetivo |
|---|---|
| Autoscaling | Ajustar quantidade de VMs |
| Autohealing | Substituir VMs não saudáveis |
| Health Check | Detectar saúde |
| MIG | Gerenciar grupo de VMs |

---

# 18. Questões Estilo ACE

## Questão 1

CPU média do grupo cresce acima do esperado.

**Resposta:** autoscaling.

## Questão 2

Uma VM parou de responder, mas o tamanho desejado do grupo deve continuar igual.

**Resposta:** autohealing.

## Questão 3

Workload batch tolera interrupção e o objetivo é reduzir custo.

**Resposta:** Spot VMs.

## Questão 4

A aplicação precisa sobreviver à falha de uma zone.

**Resposta:** Regional MIG.

---

# 19. Laboratório

```bash
# Autoscaling
gcloud compute instance-groups managed set-autoscaling ace-web-mig \
  --zone=southamerica-east1-a \
  --min-num-replicas=2 \
  --max-num-replicas=5 \
  --target-cpu-utilization=0.60

# Health check
gcloud compute health-checks create http ace-http-health-check \
  --port=80

# Autohealing
gcloud compute instance-groups managed update ace-web-mig \
  --zone=southamerica-east1-a \
  --health-check=ace-http-health-check \
  --initial-delay=60

# Listar estado
gcloud compute instance-groups managed list
```

---

# 20. Checklist

- [ ] Entendo autoscaling
- [ ] Entendo autohealing
- [ ] Sei diferenciar os dois
- [ ] Entendo health checks
- [ ] Entendo Spot VMs
- [ ] Sei quando Spot faz sentido
- [ ] Sei usar describe e serial output
- [ ] Sei investigar SSH e conectividade
- [ ] Entendo arquitetura HA com Regional MIG
