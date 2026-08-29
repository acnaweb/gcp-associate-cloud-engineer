# Aula 7 — GKE Regional, Private, Node Pools, StatefulSets, HPA e VPA

## Nível de cobertura M/E/P

```text
Regional/Autopilot/node pools/StatefulSet/VPA: P/P*; GKE Enterprise/private: E/P*
```


## Cobertura no exam guide

Exam Guide 3.2 e 4.2: tipos de cluster, GKE Enterprise, node pools, StatefulSets e autoscaling horizontal/vertical.



## 1. Conceito

Esta aula organiza os recursos GKE que costumam aparecer como alternativas de cenário. Cluster regional melhora resiliência do control plane/arquitetura regional; private cluster reduz exposição; node pools agrupam nodes; StatefulSet gerencia Pods stateful; HPA e VPA atuam em dimensões diferentes.

### Arquitetura / modelo mental

```text
Cluster
 ├─ node pools → nodes
 ├─ Deployment → stateless Pods
 ├─ StatefulSet → stateful Pods
 ├─ HPA → nº Pods
 └─ VPA → requests/resources
```

## 2. Criar / Configurar

Use um cluster já existente ou apenas inspecione para reduzir custo.

```bash
gcloud container clusters list
gcloud container node-pools list --cluster=CLUSTER --location=LOCATION
kubectl get deployments,statefulsets,hpa -A
```

Se criar cluster, prefira um laboratório curto e delete ao final.

## 3. Inspecionar

```bash
gcloud container clusters describe CLUSTER --location=LOCATION
kubectl get nodes -o wide
kubectl get pods -A
```

Identifique se o cluster é Autopilot/Standard e seus endpoints/configurações de rede.

> A partir deste ponto, todos os elementos usados no troubleshooting já foram apresentados e inspecionados.

## 4. Testar

Crie um StatefulSet simples apenas se já tiver cluster:
```bash
kubectl create deployment web --image=nginx:alpine
kubectl autoscale deployment web --cpu-percent=60 --min=1 --max=3
kubectl get hpa
```

## 5. Quebrar propositalmente

Altere a imagem do Deployment para tag inexistente, algo já aprendido na aula de troubleshooting GKE.

## 6. Troubleshooting

**Sintoma:** Pods em `ImagePullBackOff`.
**Hipótese:** imagem/tag/credencial.
**Evidência:** `kubectl describe pod` + events.
**Causa:** tag inválida.
**Correção:** imagem válida.

Depois retome HPA/VPA: erro de imagem não é resolvido aumentando nodes.

Use a sequência:

```text
Sintoma → Hipótese → Evidência → Causa → Correção
```

## 7. Corrigir

```bash
kubectl set image deployment/web nginx=nginx:alpine
kubectl rollout status deployment/web
```

## 8. Questões estilo ACE

1. Escalar quantidade de Pods por CPU? **HPA**.
2. Ajustar requests/recommendations de recursos? **VPA**.
3. Controle detalhado de node pools? **GKE Standard**.
4. Identidade/ordem estável de Pods? **StatefulSet**.

## 9. Cleanup

```bash
kubectl delete deployment web --ignore-not-found
# Exclua cluster se criado somente para o lab.
```

## Checklist

- [ ] Consigo explicar os conceitos sem consultar;
- [ ] Sei localizar o recurso no Console e/ou CLI;
- [ ] Executei ou simulei o laboratório indicado;
- [ ] Inspecionei a configuração antes de provocar a falha;
- [ ] Diagnostiquei a falha com evidências;
- [ ] Sei reconhecer a alternativa correta em uma questão de cenário.


---

# Cobertura ACE ampliada — GKE operational checklist

## Inventário

```bash
kubectl get nodes
kubectl get pods -A
kubectl get services -A
gcloud container clusters list
```

## Node pools

Em Standard clusters:

```bash
gcloud container node-pools list --cluster=CLUSTER --location=LOCATION
```

Operações cobradas incluem adicionar, editar, remover e configurar autoscaling de node pool.

## StatefulSet

Use StatefulSet quando Pods precisam de identidade estável/ordenação e storage persistente associado ao padrão stateful.

```bash
kubectl get statefulsets
```

## HPA x VPA

```text
HPA → muda número de Pods
VPA → ajusta requests/limits recomendados/aplicados conforme modo
```

## Autopilot Pod resource requests

Autopilot gerencia nodes, mas requests de Pods continuam importantes para scheduling e custo/comportamento.

## GKE + Artifact Registry

Cluster/workload precisa de identidade/permissão adequada para pull da imagem quando não houver integração automática suficiente. Em troubleshooting de `ImagePullBackOff`, verifique imagem, localização e IAM do principal apropriado.

## Service Account com GKE application

Para acesso a APIs Google, prefira identidade de workload (Workload Identity Federation for GKE) em vez de key JSON dentro do Pod.


---

# Cobertura obrigatória do guia anexado — GKE Enterprise

O guia anexado cita **GKE Enterprise** entre as configurações que o candidato deve reconhecer ao implantar clusters.

Para o nível ACE, o objetivo não é administrar todas as funcionalidades avançadas da edição Enterprise, mas reconhecer o contexto:

```text
GKE Autopilot
→ maior abstração da infraestrutura de nodes

GKE Standard
→ maior controle do cluster e node pools

Regional Cluster
→ arquitetura regional / maior resiliência do control plane

Private Cluster
→ reduz exposição pública de componentes/nodes conforme configuração

GKE Enterprise
→ recursos empresariais para gestão de Kubernetes em cenários mais amplos/multicluster
```

## Questão estilo prova

Uma organização precisa de recursos empresariais de gerenciamento Kubernetes e o enunciado apresenta **GKE Enterprise** entre as opções.

Para uma questão baseada no guia anexado, o candidato deve reconhecer que **GKE Enterprise é uma configuração/oferta distinta a ser considerada**, em vez de tratar Autopilot, Standard, Regional e Private como a lista completa.


---

## Práticas obrigatórias do guia — clusters, node pools, StatefulSet e VPA

### Tipos/configurações de cluster

O guia exige **implantar um cluster com diferentes configurações**. Não crie todos simultaneamente; escolha um por sessão para controlar custo.

#### Regional Standard

```bash
gcloud container clusters create ace-regional \
  --region=us-central1 \
  --num-nodes=1
```

#### Autopilot

```bash
gcloud container clusters create-auto ace-autopilot \
  --region=us-central1
```

#### Private cluster — prática guiada

Antes de executar, revise requisitos de subnet/IPs e custo. Em projeto descartável, use o fluxo de criação de cluster privado no Console e inspecione:

```text
private nodes
control plane endpoint/configuração
master authorized networks quando aplicável
```

O objetivo é reconhecer e verificar a configuração, não manter três clusters ativos.

#### GKE Enterprise

**Nível esperado:** `E/P*`. O guia pede reconhecer/deployar configuração Enterprise, mas a habilitação pode depender da edição/frota/organização. Faça prática guiada no Console se disponível e identifique a diferença para cluster GKE isolado.

### Node pools — Standard cluster

```bash
gcloud container node-pools create ace-extra-pool \
  --cluster=ace-regional \
  --region=us-central1 \
  --num-nodes=1 \
  --machine-type=e2-small

gcloud container node-pools list \
  --cluster=ace-regional \
  --region=us-central1
```

Edite autoscaling do pool:

```bash
gcloud container clusters update ace-regional \
  --region=us-central1 \
  --enable-autoscaling \
  --node-pool=ace-extra-pool \
  --min-nodes=0 \
  --max-nodes=2
```

Remova:

```bash
gcloud container node-pools delete ace-extra-pool \
  --cluster=ace-regional \
  --region=us-central1 --quiet
```

### StatefulSet — prática real

```bash
cat > statefulset.yaml <<'EOF'
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: ace-stateful
spec:
  serviceName: ace-stateful
  replicas: 2
  selector:
    matchLabels:
      app: ace-stateful
  template:
    metadata:
      labels:
        app: ace-stateful
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
EOF

kubectl apply -f statefulset.yaml
kubectl get statefulsets,pods
```

Observe nomes estáveis:

```text
ace-stateful-0
ace-stateful-1
```

### VPA — prática guiada/executável quando API disponível

```bash
cat > vpa.yaml <<'EOF'
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: web-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web
  updatePolicy:
    updateMode: "Off"
EOF

kubectl apply -f vpa.yaml
kubectl get vpa
kubectl describe vpa web-vpa
```

Use `Off` para observar recommendations sem permitir alterações automáticas durante o laboratório.

### HPA x VPA

```text
HPA → número de Pods
VPA → recursos/request recommendation por Pod
```

### Cleanup

```bash
kubectl delete -f statefulset.yaml --ignore-not-found
kubectl delete -f vpa.yaml --ignore-not-found
rm -f statefulset.yaml vpa.yaml
# Exclua clusters criados exclusivamente para o lab.
```