# Aula 4 — Kubernetes e GKE: Pods, Deployments e Services

## Objetivos

Ao final desta aula, você deverá:

- Criar GKE Autopilot;
- Usar kubectl;
- Criar Deployment e Service;
- Simular falha de Pod;

---

# 1. Modelo mental

```text
GKE Cluster
 └─ Namespace
    └─ Deployment
       └─ ReplicaSet
          ├─ Pod
          └─ Pod
    └─ Service
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

> GKE pode gerar custo. Exclua o cluster no final.

```bash
export REGION=us-central1
gcloud services enable container.googleapis.com

gcloud container clusters create-auto ace-gke \
  --region=$REGION

gcloud container clusters get-credentials ace-gke \
  --region=$REGION

kubectl create deployment web --image=nginx:alpine
kubectl scale deployment web --replicas=2
kubectl expose deployment web --port=80 --type=ClusterIP

kubectl get pods -o wide
kubectl get deployments
kubectl get services
```

Self-healing:
```bash
POD=$(kubectl get pods -l app=web -o jsonpath='{.items[0].metadata.name}')
kubectl delete pod $POD
kubectl get pods -w
```

---

# 4. Testes e falhas propositais

- Delete um Pod e observe Deployment restaurar réplica.
- Service seleciona Pods por labels; selector errado = endpoint vazio.
- Pod não é Deployment.

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

- Deployment gerencia estado desejado de Pods.
- Service oferece endpoint estável.
- kubectl opera recursos Kubernetes, gcloud gerencia cluster GKE.

---

# 7. Questões estilo ACE

- Pod morreu e voltou automaticamente por Deployment. Qual conceito? → reconciliation.
- Precisa endpoint estável para Pods efêmeros? → Service.

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

