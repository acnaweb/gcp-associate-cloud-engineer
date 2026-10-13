# Aula 4 — Kubernetes e GKE: Pods, Deployments e Services

## Objetivos

Ao final, você deverá:

- compreender a arquitetura básica de Kubernetes e GKE;
- diferenciar Control Plane, Cluster, Node, Namespace, Pod, ReplicaSet, Deployment e Service;
- criar um cluster GKE Standard econômico para laboratório;
- configurar o `kubectl` para acessar o cluster;
- criar e utilizar um namespace;
- implantar e inspecionar uma aplicação;
- compreender e testar labels e selectors;
- observar a relação Deployment → ReplicaSet → Pods;
- escalar manualmente um Deployment;
- comprovar o desired state e o self-healing excluindo um Pod;
- diferenciar e testar Services `ClusterIP` e `LoadBalancer`;
- validar a aplicação com `curl`;
- compreender o modelo declarativo com manifests YAML;
- realizar rollout e acompanhar seu status;
- provocar uma falha `ImagePullBackOff`;
- diagnosticar usando `get`, `describe`, Events e `logs`;
- corrigir a falha e validar a recuperação;
- realizar o cleanup dos recursos do laboratório.

> [!IMPORTANT]
> Esta aula prioriza os fundamentos operacionais de Kubernetes. **GKE Autopilot, Standard, node pools e autoscaling** serão aprofundados na Aula 5.

## 1. Kubernetes e GKE

Kubernetes é uma plataforma de orquestração de containers. GKE é o serviço Kubernetes gerenciado do Google Cloud.

```text
GKE Cluster
   |
   +-- Control Plane
   |     +-- Kubernetes API
   |     +-- Scheduler
   |     +-- Controllers
   |
   +-- Data Plane
         +-- Node
              +-- Pod
              +-- Pod
```

No GKE, o Google gerencia o control plane. A responsabilidade operacional sobre os Nodes varia conforme o modo Standard ou Autopilot, tema aprofundado na Aula 5.

## 2. Objetos fundamentais

```text
Cluster
  |
  +-- Namespace
       |
       +-- Deployment
       |     |
       |     +-- ReplicaSet
       |           |
       |           +-- Pod
       |           +-- Pod
       |
       +-- Service
             |
             +-- selector
                    |
                    +--> labels dos Pods
```

| Objeto | Papel |
|---|---|
| Cluster | ambiente Kubernetes |
| Node | capacidade computacional que executa workloads |
| Namespace | separação lógica de recursos |
| Pod | menor unidade implantável |
| ReplicaSet | mantém a quantidade desejada de Pods |
| Deployment | gerencia ReplicaSets, replicas e rollouts |
| Service | fornece acesso estável aos Pods |
| Label | metadado usado para identificar/agrupar objetos |
| Selector | seleciona objetos por labels |

## 3. Variáveis e preflight

```bash
# Recupera o projeto ativo.
export PROJECT_ID="$(gcloud config get-value project)"
# Define a região usada na Semana 5.
export REGION="southamerica-east1"
# Define uma zona da região.
export ZONE="${REGION}-a"
# Define o cluster.
export CLUSTER="ace-gke"
# Define o namespace do laboratório.
export NAMESPACE="ace-lab"
# Define o Deployment.
export DEPLOYMENT="ace-nginx"
# Define o Service.
export SERVICE="ace-nginx"
# Habilita a API do GKE.
gcloud services enable container.googleapis.com --project="$PROJECT_ID"
# Confirma projeto e conta ativos.
gcloud config list
```

> [!WARNING]
> Um cluster GKE possui custo enquanto existir. Execute o cleanup ao final da aula, exceto se for continuar imediatamente para a Aula 5 e optar conscientemente por reaproveitá-lo.

## 4. Criar um cluster GKE Standard

Para reduzir o custo do laboratório, criaremos um cluster zonal Standard com um Node.

```bash
# Cria um cluster Standard pequeno.
gcloud container clusters create "$CLUSTER" \
  --zone="$ZONE" \
  --num-nodes=1 \
  --machine-type=e2-standard-2
# Inspeciona o cluster.
gcloud container clusters describe "$CLUSTER" \
  --zone="$ZONE"
# Lista clusters.
gcloud container clusters list
```

## 5. Configurar kubectl

`kubectl` conversa com a Kubernetes API. Primeiro obtenha as credenciais.

```bash
# Configura o contexto local do kubectl.
gcloud container clusters get-credentials "$CLUSTER" \
  --zone="$ZONE" \
  --project="$PROJECT_ID"
# Mostra o contexto atual.
kubectl config current-context
# Lista Nodes.
kubectl get nodes -o wide
```

```text
kubectl
   |
   v
Kubernetes API
   |
   v
objetos do cluster
```

## 6. Namespace

```bash
# Cria o namespace do laboratório.
kubectl create namespace "$NAMESPACE"
# Lista namespaces.
kubectl get namespaces
# Define o namespace padrão no contexto atual.
kubectl config set-context --current --namespace="$NAMESPACE"
# Confirma o namespace.
kubectl config view --minify -o 'jsonpath={..namespace}'; echo
```

### Troubleshooting: namespace errado

Se `kubectl get` retornar `No resources found`, confirme o namespace antes de recriar recursos.

```bash
# Procura Pods em todos os namespaces.
kubectl get pods --all-namespaces
# Confirma o namespace atual.
kubectl config view --minify -o 'jsonpath={..namespace}'; echo
```

## 7. Deployment → ReplicaSet → Pod

```bash
# Cria o Deployment.
kubectl create deployment "$DEPLOYMENT" \
  --image=nginx:alpine
# Aguarda o rollout inicial.
kubectl rollout status deployment/"$DEPLOYMENT"
# Lista Deployment.
kubectl get deployment "$DEPLOYMENT"
# Lista ReplicaSets.
kubectl get replicasets
# Lista Pods.
kubectl get pods -o wide
```

Observe:

```text
Deployment
    |
    v
ReplicaSet
    |
    v
Pod
```

## 8. Padrão operacional: get → describe → logs

```bash
# Captura o Pod da aplicação.
export POD="$(kubectl get pods -l app="$DEPLOYMENT" -o jsonpath='{.items[0].metadata.name}')"
# Inspeciona configuração, condições e Events.
kubectl describe pod "$POD"
# Lê logs da aplicação.
kubectl logs "$POD"
# Inspeciona o Deployment.
kubectl describe deployment "$DEPLOYMENT"
```

Memorize:

```text
get
 |
 v
estado resumido
 |
 v
describe
 |
 +--> configuração
 +--> condições
 +--> Events
 |
 v
logs
```

## 9. Labels e selectors

Services encontram seus backends por labels/selectors, não por um IP permanente de Pod.

```bash
# Mostra labels.
kubectl get pods --show-labels
# Seleciona Pods pela label.
kubectl get pods -l app="$DEPLOYMENT"
# Inspeciona labels e selectors do Deployment.
kubectl get deployment "$DEPLOYMENT" -o yaml
```

```text
Service
 selector: app=ace-nginx
          |
          v
Pods
 label: app=ace-nginx
```

## 10. Escalar

```bash
# Define três replicas.
kubectl scale deployment "$DEPLOYMENT" \
  --replicas=3
# Aguarda o estado desejado.
kubectl rollout status deployment/"$DEPLOYMENT"
# Observa a cadeia de objetos.
kubectl get deployment,replicaset,pods -o wide
```

Esperado: três Pods disponíveis.

## 11. Desired state e self-healing

Exclua deliberadamente um Pod gerenciado.

```bash
# Captura um Pod.
export POD_TO_DELETE="$(kubectl get pods -l app="$DEPLOYMENT" -o jsonpath='{.items[0].metadata.name}')"
# Exclui o Pod.
kubectl delete pod "$POD_TO_DELETE"
# Observa o estado imediatamente.
kubectl get pods -l app="$DEPLOYMENT" -o wide
# Aguarda reconciliação.
kubectl rollout status deployment/"$DEPLOYMENT"
# Confirma três Pods novamente.
kubectl get pods -l app="$DEPLOYMENT" -o wide
```

```text
Desired = 3
Actual  = 2
    |
    v
ReplicaSet cria substituto
    |
    v
Actual = 3
```

## 12. Service ClusterIP

```bash
# Expõe o Deployment internamente.
kubectl expose deployment "$DEPLOYMENT" \
  --name="$SERVICE" \
  --type=ClusterIP \
  --port=80 \
  --target-port=80
# Inspeciona o Service.
kubectl get service "$SERVICE" -o wide
# Mostra selector e endpoints.
kubectl describe service "$SERVICE"
# Lista EndpointSlices.
kubectl get endpointslices
```

Teste o Service com port-forward:

```bash
# Encaminha localhost:8080 para o Service.
kubectl port-forward service/"$SERVICE" 8080:80 >/tmp/ace-port-forward.log 2>&1 &
# Guarda o PID.
export PORT_FORWARD_PID=$!
# Aguarda o túnel.
sleep 3
# Testa HTTP.
curl -I http://127.0.0.1:8080
# Encerra o port-forward.
kill "$PORT_FORWARD_PID"
```

## 13. Tipos de Service

| Tipo | Uso |
|---|---|
| `ClusterIP` | acesso interno; tipo padrão |
| `NodePort` | expõe uma porta nos Nodes |
| `LoadBalancer` | solicita integração com balanceador externo |
| `ExternalName` | mapeia para um nome DNS externo |

Agora altere o Service para `LoadBalancer`.

```bash
# Altera o Service.
kubectl patch service "$SERVICE" \
  -p '{"spec":{"type":"LoadBalancer"}}'
# Acompanha o provisionamento.
kubectl get service "$SERVICE" -w
```

Quando o endereço externo aparecer, encerre o `-w` com `Ctrl+C`.

```bash
# Captura o endereço externo.
export EXTERNAL_IP="$(kubectl get service "$SERVICE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
# Mostra o IP.
echo "$EXTERNAL_IP"
# Testa externamente.
curl -I "http://${EXTERNAL_IP}"
```

> [!NOTE]
> O provisionamento do LoadBalancer pode levar alguns minutos.

## 14. Imperativo x declarativo

```text
Imperativo                     Declarativo
kubectl create ...             kubectl apply -f ...
kubectl scale ...              spec.replicas: ...
ação direta                    desired state em YAML
```

Exemplo de `deployment.yaml`:

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
        ports:
        - containerPort: 80
```

Aplicação:

```bash
# Aplica o desired state declarado.
kubectl apply -f deployment.yaml
```

Para estudar a configuração existente:

```bash
# Exporta a representação do Deployment atual.
kubectl get deployment "$DEPLOYMENT" -o yaml > deployment-observado.yaml
# Exibe o conteúdo.
cat deployment-observado.yaml
```

## 15. Rollout

```bash
# Mostra histórico.
kubectl rollout history deployment/"$DEPLOYMENT"
# Atualiza para outra image válida.
kubectl set image deployment/"$DEPLOYMENT" \
  nginx=nginx:stable-alpine
# Acompanha o rollout.
kubectl rollout status deployment/"$DEPLOYMENT"
# Observa ReplicaSets e Pods.
kubectl get replicasets,pods
# Mostra o histórico atualizado.
kubectl rollout history deployment/"$DEPLOYMENT"
```

```text
Deployment
   |
   +-- ReplicaSet antigo
   |
   +-- ReplicaSet novo
          |
          +-- novos Pods
```

## 16. Quebrar propositalmente — ImagePullBackOff

Altere uma única variável: a image.

```bash
# Define deliberadamente uma tag inexistente.
kubectl set image deployment/"$DEPLOYMENT" \
  nginx=nginx:tag-ace-inexistente
# Aguarda o erro aparecer.
sleep 10
# Observa os Pods.
kubectl get pods
```

O novo Pod deverá evoluir para `ErrImagePull`/`ImagePullBackOff`.

### Diagnóstico

```bash
# Lista Pods e identifica o Pod problemático.
kubectl get pods
# Inspecione o Pod problemático substituindo <POD_COM_ERRO>.
kubectl describe pod <POD_COM_ERRO>
# Mostra Events recentes.
kubectl get events --sort-by='.lastTimestamp'
# Inspeciona o Deployment.
kubectl describe deployment "$DEPLOYMENT"
# Mostra histórico.
kubectl rollout history deployment/"$DEPLOYMENT"
```

**Sintoma:** novo Pod não entra em `Running`.

**Hipótese:** Kubernetes não consegue baixar a image.

**Evidência:** `describe pod` e Events mostram falha no pull.

**Causa:** tag deliberadamente inexistente.

**Correção:** restaurar uma image válida.

## 17. Corrigir e validar

```bash
# Corrige somente a image.
kubectl set image deployment/"$DEPLOYMENT" \
  nginx=nginx:alpine
# Aguarda a recuperação.
kubectl rollout status deployment/"$DEPLOYMENT"
# Confirma Pods.
kubectl get pods -o wide
# Atualiza o IP do Service.
export EXTERNAL_IP="$(kubectl get service "$SERVICE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
# Testa novamente.
curl -I "http://${EXTERNAL_IP}"
```

## 18. Troubleshooting — roteiro

| Sintoma | Hipótese | Evidência | Correção |
|---|---|---|---|
| `No resources found` | namespace incorreto | contexto + `--all-namespaces` | selecionar namespace correto |
| `ImagePullBackOff` | image/tag inválida ou registry inacessível | `describe pod` + Events | corrigir image/IAM |
| Pods `Running`, Service sem backends | selector não corresponde às labels | labels + selector + EndpointSlice | corrigir labels/selector |
| aplicação inicia e falha | erro da aplicação | `kubectl logs` | corrigir aplicação/configuração |
| rollout não termina | novos Pods não ficam disponíveis | rollout, Pods e Events | diagnosticar o Pod |

```text
kubectl get
    |
    v
kubectl describe
    |
    +--> Events
    |
    v
kubectl logs
    |
    v
causa -> correção
```

## 19. Questões estilo ACE

1. Um Pod gerenciado por Deployment foi excluído. O que ocorre? **O ReplicaSet cria outro Pod para reconciliar o desired state.**
2. Três Pods podem mudar de IP durante rollouts. Qual objeto fornece endpoint estável? **Service.**
3. Pods estão `Running`, mas um Service não encontra backends. O que verificar? **Labels, selector e EndpointSlices.**
4. Um Pod mostra `ImagePullBackOff`. Qual comando ajuda a encontrar a causa? **`kubectl describe pod`, especialmente Events.**
5. Qual objeto normalmente gerencia ReplicaSets e rollouts? **Deployment.**
6. Você precisa de comunicação somente interna. Qual tipo de Service? **ClusterIP.**
7. Você precisa expor externamente com integração de balanceamento. Qual tipo? **LoadBalancer.**
8. `kubectl get pods` não mostra a aplicação. O que verificar antes de recriar recursos? **Namespace/contexto.**

## 20. Cleanup

```bash
# Exclui o namespace e seus recursos.
kubectl delete namespace "$NAMESPACE"
# Confirma.
kubectl get namespaces
# Exclui o cluster para interromper custos.
gcloud container clusters delete "$CLUSTER" \
  --zone="$ZONE" \
  --quiet
# Confirma.
gcloud container clusters list
```

> [!IMPORTANT]
> Se você continuar imediatamente para a Aula 5 e quiser reaproveitar o cluster Standard, execute o cleanup dos recursos do namespace, mas adie a exclusão do cluster até concluir a próxima aula.

## 21. M/E/P

| Conteúdo | Nível | Evidência |
|---|---|---|
| Kubernetes / GKE | E | arquitetura e responsabilidades |
| Control Plane / Node | E | modelo arquitetural |
| Cluster Standard | P | create, describe e list |
| `kubectl` | P | contexto e operações |
| Namespace | P | create, contexto e troubleshooting |
| Pod | P | get, describe, logs e exclusão |
| Deployment | P | create, scale, set image e rollout |
| ReplicaSet | P | inspeção antes/depois do rollout |
| Labels / selectors | P | inspeção e seleção |
| ClusterIP | P | expose, EndpointSlice e teste |
| LoadBalancer | P | patch, IP externo e curl |
| Desired state / self-healing | P | exclusão e reconciliação |
| YAML | E/P* | manifesto e aplicação orientada |
| Rollout | P | status, history e atualização |
| Events | P | diagnóstico |
| `ImagePullBackOff` | P | falha, evidência e correção |
| Troubleshooting | P | get → describe/Events → logs |
| Cleanup | P | namespace + cluster |

## 22. Mapa mental para a prova

```text
GKE
 |
 +-- Control Plane
 |
 +-- Node(s)
      |
      +-- Pods
Deployment
   |
   v
ReplicaSet
   |
   v
Pods <--- labels/selectors ---> Service
                               |
                               +-- ClusterIP
                               +-- LoadBalancer
Operação:
get -> describe -> Events/logs -> causa -> correção
```
