# Aula 4 — Load Balancing no Google Cloud

## Objetivos

Ao final desta aula, você deverá:

- Entender o papel de um Load Balancer;
- Diferenciar balanceamento externo e interno;
- Entender Application Load Balancer x Network Load Balancer;
- Entender frontend, backend e health check;
- Relacionar Load Balancer com MIG.

---

# 1. Por que Load Balancing?

```text
Clients
   │
   ▼
Load Balancer
   │
 ┌─┼─┐
 ▼ ▼ ▼
VM VM VM
```

Benefícios:

- Distribuição de tráfego;
- Alta disponibilidade;
- Health checks;
- Escalabilidade;
- Abstração dos backends.

---

# 2. Componentes básicos

```text
Frontend
   │
   ▼
Forwarding / Proxy
   │
   ▼
Backend Service
   │
   ▼
Backends
```

E:

```text
Health Check
   │
   ▼
Backend Health
```

---

# 3. Application Load Balancer

Indicado para tráfego de camada 7, como HTTP/HTTPS.

```text
HTTP / HTTPS
     │
     ▼
Application Load Balancer
```

Permite decisões com base em elementos da aplicação, dependendo do tipo/configuração.

---

# 4. Network Load Balancer

Voltado a tráfego de camada 4.

```text
TCP / UDP
   │
   ▼
Network Load Balancer
```

---

# 5. External x Internal

## External

Frontend acessível externamente.

```text
Internet
   │
   ▼
External Load Balancer
```

## Internal

Frontend acessível internamente.

```text
Internal Clients
      │
      ▼
Internal Load Balancer
```

---

# 6. Global x Regional

O Google Cloud possui opções globais e regionais de balanceamento dependendo do produto.

Para o ACE, foque em identificar o requisito:

- Tráfego global;
- Tráfego regional;
- HTTP/HTTPS;
- TCP/UDP;
- Interno;
- Externo.

---

# 7. Load Balancer + MIG

Arquitetura típica:

```text
Internet
   │
   ▼
External Application LB
   │
   ▼
Backend Service
   │
   ▼
Regional MIG
   │
 ┌─┼─┐
 ▼ ▼ ▼
VM VM VM
```

---

# 8. Health Checks

Load Balancers usam health checks para direcionar tráfego apenas a backends saudáveis.

```text
Backend 1 ✓
Backend 2 ✗
Backend 3 ✓
```

Tráfego é enviado aos saudáveis conforme a política do serviço.

---

# 9. Backend Service

Backend service associa:

- Backends;
- Health checks;
- Configurações de tráfego;
- Outras políticas.

---

# 10. Conceito de alta disponibilidade

Uma combinação comum:

```text
Load Balancer
      +
Regional MIG
      +
Autoscaling
      +
Health Checks
      =
Highly Available Web Tier
```

---

# 11. Fluxo de escolha

Pergunte:

```text
1. Interno ou externo?
2. HTTP/HTTPS ou TCP/UDP?
3. Global ou regional?
4. Que tipo de backend?
5. Precisa health check?
```

---

# 12. Laboratório de observação

Liste forwarding rules:

```bash
gcloud compute forwarding-rules list
```

Liste backend services:

```bash
gcloud compute backend-services list
```

Liste health checks:

```bash
gcloud compute health-checks list
```

---

# 13. Pegadinhas ACE

- Load Balancer não substitui autoscaling.
- Health check é essencial para detectar backend saudável.
- Application LB é orientado a HTTP/HTTPS.
- Network LB atua em camada de transporte.
- Internal e External atendem requisitos distintos.
- O escopo global/regional depende do tipo específico.

---

# 14. Questões Estilo ACE

## Questão 1

Aplicação HTTP pública precisa atender usuários e distribuir tráfego entre múltiplas VMs.

**Resposta:** External Application Load Balancer com backends apropriados.

## Questão 2

Aplicação interna precisa balancear tráfego entre backends privados.

**Resposta:** Internal Load Balancer apropriado ao protocolo.

## Questão 3

Backend não saudável continua recebendo tráfego.

O que verificar?

**Resposta:** health check e configuração do backend.

---

# 15. Checklist

- [ ] Entendo Load Balancer
- [ ] Sei diferenciar Application e Network LB
- [ ] Sei diferenciar External e Internal
- [ ] Entendo frontend e backend
- [ ] Entendo health checks
- [ ] Entendo integração com MIG
