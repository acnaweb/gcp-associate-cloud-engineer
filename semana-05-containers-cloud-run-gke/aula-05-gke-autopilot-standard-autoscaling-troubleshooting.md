# Aula 5 — GKE Autopilot, Standard, Autoscaling e Troubleshooting

## Objetivos

Ao final desta aula, você deverá:

- Diferenciar GKE Autopilot e Standard;
- Entender node pools;
- Entender autoscaling;
- Entender HPA em nível conceitual;
- Troubleshootar workloads;
- Escolher Cloud Run x GKE x Compute Engine.

---

# 1. GKE Autopilot

No Autopilot, o Google gerencia mais aspectos da infraestrutura.

```text
Application Team
      │
      ▼
Kubernetes Workloads
      │
      ▼
GKE Autopilot
      │
Google manages much of nodes/infrastructure
```

É o modo recomendado para muitos workloads novos quando você não precisa de controle detalhado dos nodes.

---

# 2. GKE Standard

No Standard, você controla mais elementos.

```text
You manage
  ├── Node Pools
  ├── Machine types
  ├── Scaling configuration
  └── More infrastructure choices
```

Use quando requisitos exigirem maior controle.

---

# 3. Autopilot x Standard

| Requisito | Opção |
|---|---|
| Menos administração | Autopilot |
| Controle detalhado de nodes | Standard |
| Configurações específicas de infraestrutura | Standard |
| Kubernetes com experiência mais gerenciada | Autopilot |

---

# 4. Node Pool

Em Standard:

```text
Cluster
   │
   ├── Node Pool A
   │     ├── Node
   │     └── Node
   └── Node Pool B
         └── Node
```

Node pools permitem máquinas diferentes no mesmo cluster.

---

# 5. Cluster Autoscaler

Ajusta quantidade de nodes de acordo com demanda de Pods.

```text
Pods pending
    │
    ▼
Need capacity
    │
    ▼
Add nodes
```

---

# 6. Horizontal Pod Autoscaler

Ajusta quantidade de Pods.

```text
CPU / Metric ↑
      │
      ▼
More Pods
```

Não confunda:

```text
HPA → Pods
Cluster Autoscaler → Nodes
```

---

# 7. Criar cluster Autopilot

```bash
gcloud container clusters create-auto ace-autopilot \
  --region=southamerica-east1
```

---

# 8. Ver workloads

```bash
kubectl get deployments
kubectl get pods
kubectl get services
```

---

# 9. Describe

```bash
kubectl describe pod POD_NAME
```

Muito útil para troubleshooting.

---

# 10. Logs

```bash
kubectl logs POD_NAME
```

---

# 11. Problemas comuns

## Pod Pending

Verifique:

- Recursos;
- Scheduling;
- Node capacity;
- Constraints.

## CrashLoopBackOff

Verifique:

- Logs;
- Command;
- Environment;
- Dependency;
- Probes.

## ImagePullBackOff

Verifique:

- Nome da image;
- Registry;
- IAM;
- Tag.

---

# 12. Troubleshooting flow

```text
kubectl get pods
      ↓
kubectl describe pod
      ↓
kubectl logs
      ↓
Events
      ↓
Image / IAM / Resource / Network
```

---

# 13. Cloud Run x GKE x Compute Engine

| Requisito | Serviço |
|---|---|
| VM / SO controlado | Compute Engine |
| Container serverless simples | Cloud Run |
| Kubernetes | GKE |
| Muitos serviços com recursos Kubernetes | GKE |
| API stateless sem cluster | Cloud Run |
| Aplicação legada em VM | Compute Engine |

---

# 14. Modelo de decisão

```text
Precisa Kubernetes?
   │
   ├── Sim → GKE
   │
   └── Não
        │
        ▼
Container stateless?
   │
   ├── Sim → Cloud Run
   │
   └── Não / precisa SO
        ↓
Compute Engine
```

---

# 15. Pegadinhas ACE

- Cloud Run não exige cluster Kubernetes.
- GKE Autopilot reduz responsabilidade de infraestrutura.
- Standard oferece mais controle.
- HPA escala Pods.
- Cluster Autoscaler escala Nodes.
- `kubectl describe` e `kubectl logs` são essenciais em troubleshooting.

---

# 16. Questões Estilo ACE

## Questão 1

Equipe quer Kubernetes, mas quer minimizar administração de nodes.

**Resposta:** GKE Autopilot.

## Questão 2

Equipe exige machine types e node pools específicos.

**Resposta:** GKE Standard.

## Questão 3

CPU sobe e a aplicação precisa aumentar número de Pods.

**Resposta:** Horizontal Pod Autoscaler.

## Questão 4

Pods não cabem nos nodes atuais.

**Resposta:** Cluster Autoscaler pode aumentar capacidade.

---

# 17. Checklist

- [ ] Sei diferenciar Autopilot e Standard
- [ ] Entendo node pools
- [ ] Entendo HPA
- [ ] Entendo Cluster Autoscaler
- [ ] Sei usar `kubectl describe`
- [ ] Sei usar `kubectl logs`
- [ ] Sei escolher Cloud Run, GKE ou Compute Engine
