# Aula 4 — Kubernetes e GKE: Pods, Deployments e Services

## Objetivos

Ao final desta aula, você deverá:

- Entender Kubernetes em nível ACE;
- Entender GKE;
- Diferenciar Cluster, Node, Pod, Deployment e Service;
- Criar cluster;
- Usar `kubectl`;
- Implantar aplicação.

---

# 1. Kubernetes

Kubernetes orquestra containers.

```text
Cluster
   │
   ├── Node
   │    ├── Pod
   │    └── Pod
   │
   └── Node
        ├── Pod
        └── Pod
```

---

# 2. GKE

GKE é o Kubernetes gerenciado do Google Cloud.

```text
Kubernetes
    +
Google-managed control plane
    =
GKE
```

---

# 3. Cluster

Conjunto de recursos Kubernetes.

---

# 4. Node

Máquina que executa workloads.

---

# 5. Pod

Menor unidade implantável no Kubernetes.

```text
Pod
 └── Container
```

Pode conter mais de um container, embora o caso simples seja um container por Pod.

---

# 6. Deployment

Gerencia Pods declarativamente.

```text
Deployment
   │
   ├── Pod
   ├── Pod
   └── Pod
```

Responsável por:

- Replicas;
- Rollout;
- Desired state.

---

# 7. Service

Fornece endpoint estável para Pods.

```text
Client
  │
  ▼
Service
  │
 ┌┴┐
 ▼ ▼
Pod Pod
```

---

# 8. Criar cluster

Exemplo Standard:

```bash
gcloud container clusters create ace-gke \
  --zone=southamerica-east1-a \
  --num-nodes=2
```

---

# 9. Credenciais

```bash
gcloud container clusters get-credentials ace-gke \
  --zone=southamerica-east1-a
```

---

# 10. Ver nodes

```bash
kubectl get nodes
```

---

# 11. Criar Deployment

```bash
kubectl create deployment ace-nginx \
  --image=nginx:alpine
```

---

# 12. Ver Pods

```bash
kubectl get pods
```

---

# 13. Escalar

```bash
kubectl scale deployment ace-nginx \
  --replicas=3
```

---

# 14. Expor

```bash
kubectl expose deployment ace-nginx \
  --type=LoadBalancer \
  --port=80
```

---

# 15. Ver Services

```bash
kubectl get services
```

---

# 16. Desired State

Kubernetes tenta manter o estado declarado.

```text
Desired = 3 Pods

Pod fails
   ↓
Kubernetes
   ↓
creates replacement
```

---

# 17. YAML

Exemplo:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ace-nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ace-nginx
  template:
    metadata:
      labels:
        app: ace-nginx
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
```

Aplicar:

```bash
kubectl apply -f deployment.yaml
```

---

# 18. Questões Estilo ACE

## Questão 1

Qual é a menor unidade de deployment Kubernetes?

**Resposta:** Pod.

## Questão 2

Qual objeto mantém quantidade desejada de Pods?

**Resposta:** Deployment.

## Questão 3

Qual objeto oferece endpoint estável para Pods?

**Resposta:** Service.

---

# 19. Checklist

- [ ] Entendo Kubernetes
- [ ] Entendo GKE
- [ ] Entendo Cluster
- [ ] Entendo Node
- [ ] Entendo Pod
- [ ] Entendo Deployment
- [ ] Entendo Service
- [ ] Sei usar comandos básicos `kubectl`
