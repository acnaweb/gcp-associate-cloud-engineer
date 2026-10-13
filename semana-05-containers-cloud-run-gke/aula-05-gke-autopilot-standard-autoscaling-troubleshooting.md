# Aula 5 — GKE Autopilot, Standard, Autoscaling e Troubleshooting

## Objetivos

Ao final, você deverá:

- comparar GKE Standard e Autopilot com base em responsabilidade operacional e requisitos;
- reaproveitar e inspecionar o cluster Standard criado na Aula 4;
- inspecionar node pools de um cluster Standard;
- explicar e configurar Cluster Autoscaler;
- compreender como `resources.requests` influenciam scheduling e capacidade;
- provocar e diagnosticar um Pod `Pending` por insuficiência de recursos;
- configurar e inspecionar um Horizontal Pod Autoscaler (HPA);
- diferenciar claramente HPA de Cluster Autoscaler;
- observar métricas com `kubectl top`;
- explicar como HPA e Cluster Autoscaler podem atuar em conjunto;
- criar, inspecionar e comparar um cluster GKE Autopilot;
- provocar e diagnosticar `CrashLoopBackOff`;
- utilizar `kubectl logs --previous`;
- diferenciar readiness e liveness probes;
- aplicar o fluxo `get → describe → Events → logs → causa → correção`;
- escolher entre Cloud Run, Cloud Run Jobs, GKE Autopilot, GKE Standard e Compute Engine;
- executar o cleanup completo dos recursos do laboratório.

> [!IMPORTANT]
> ## Pré-requisito — Aula 4
>
> Esta aula foi desenhada para **reaproveitar o cluster Standard `ace-gke` criado na Aula 4**. Se você executou o cleanup completo da Aula 4, recrie o cluster Standard usando as mesmas variáveis antes de continuar.

## 1. Visão geral: Standard x Autopilot

GKE oferece dois modos principais de operação.

```text
GKE Standard                         GKE Autopilot
     |                                    |
     +-- Control Plane: Google            +-- Control Plane: Google
     +-- Node pools: você controla        +-- Nodes: mais abstraídos
     +-- Machine types: você escolhe      +-- Menos gestão de infraestrutura
     +-- Autoscaling: configurável        +-- Foco maior no workload
```

| Tema | Standard | Autopilot |
|---|---|---|
| Control plane | Google gerencia | Google gerencia |
| Nodes | usuário controla mais detalhes | mais abstraídos pelo GKE |
| Node pools | explícitos | não administrados da mesma forma |
| Machine types | escolha explícita | menor controle direto |
| Infraestrutura | mais responsabilidade | menos responsabilidade |
| Casos típicos | requisitos específicos de infraestrutura | Kubernetes com menor overhead operacional |

A escolha é um **trade-off entre controle e operação**, não uma hierarquia de “melhor” e “pior”.

## 2. Variáveis e preflight

```bash
# Recupera o projeto ativo.
export PROJECT_ID="$(gcloud config get-value project)"
# Define a região usada na Semana 5.
export REGION="southamerica-east1"
# Define a zona do cluster Standard.
export ZONE="${REGION}-a"
# Reutiliza o cluster Standard da Aula 4.
export CLUSTER="ace-gke"
# Define o node pool padrão.
export NODE_POOL="default-pool"
# Define o namespace desta aula.
export NAMESPACE="ace-scale"
# Define o Deployment usado nos testes.
export DEPLOYMENT="ace-scale-web"
# Define o cluster Autopilot temporário.
export AUTOPILOT_CLUSTER="ace-autopilot"
# Habilita a API do GKE.
gcloud services enable container.googleapis.com --project="$PROJECT_ID"
# Confirma que o cluster Standard existe.
gcloud container clusters describe "$CLUSTER" --zone="$ZONE" --project="$PROJECT_ID"
```

Se o último comando retornar `NOT_FOUND`, recrie o cluster conforme a Aula 4.

## 3. Recuperar credenciais e preparar namespace

```bash
# Atualiza as credenciais do kubectl para o cluster Standard.
gcloud container clusters get-credentials "$CLUSTER" --zone="$ZONE" --project="$PROJECT_ID"
# Cria o namespace desta aula.
kubectl create namespace "$NAMESPACE"
# Define o namespace padrão do contexto atual.
kubectl config set-context --current --namespace="$NAMESPACE"
# Confirma Nodes disponíveis.
kubectl get nodes -o wide
```

## 4. Node pools no GKE Standard

No Standard, node pools representam grupos de Nodes com configurações semelhantes.

```text
Cluster
   |
   +-- Node Pool A
   |     +-- Node
   |     +-- Node
   |
   +-- Node Pool B
         +-- Node
```

```bash
# Lista node pools do cluster Standard.
gcloud container node-pools list \
  --cluster="$CLUSTER" \
  --zone="$ZONE"
# Inspeciona o node pool padrão.
gcloud container node-pools describe "$NODE_POOL" \
  --cluster="$CLUSTER" \
  --zone="$ZONE"
```

Observe machine type, tamanho atual e configurações de autoscaling.

## 5. Cluster Autoscaler

O Cluster Autoscaler ajusta **Nodes**, não Pods.

```text
Pods Pending por falta de capacidade
              |
              v
      Cluster Autoscaler
              |
              v
        aumenta Nodes
```

Habilite autoscaling no node pool:

```bash
# Habilita autoscaling entre 1 e 3 Nodes.
gcloud container clusters update "$CLUSTER" \
  --zone="$ZONE" \
  --enable-autoscaling \
  --node-pool="$NODE_POOL" \
  --min-nodes=1 \
  --max-nodes=3
# Confirma a configuração.
gcloud container node-pools describe "$NODE_POOL" \
  --cluster="$CLUSTER" \
  --zone="$ZONE"
```

> [!NOTE]
> O Cluster Autoscaler reage à necessidade de capacidade para scheduling. Ele não deve ser interpretado como “CPU alta → adiciona Node” de forma direta.

## 6. Requests, scheduling e Pod Pending

O Scheduler usa `resources.requests` para decidir se um Pod cabe em um Node.

```text
Pod requests
    |
    v
Scheduler
    |
    +--> cabe em algum Node? --> sim --> Running
    |
    +--> não --> Pending
                   |
                   v
          Cluster Autoscaler pode reagir
```

Crie um Deployment simples:

```bash
# Cria o Deployment base.
kubectl create deployment "$DEPLOYMENT" --image=nginx:alpine
# Aguarda o rollout.
kubectl rollout status deployment/"$DEPLOYMENT"
# Define um request modesto de CPU.
kubectl set resources deployment "$DEPLOYMENT" \
  --requests=cpu=100m,memory=64Mi \
  --limits=cpu=500m,memory=128Mi
# Confirma a configuração.
kubectl get deployment "$DEPLOYMENT" -o yaml
```

Agora provoque uma condição de scheduling mais exigente aumentando replicas e requests de CPU.

```bash
# Escala para quatro replicas.
kubectl scale deployment "$DEPLOYMENT" --replicas=4
# Aumenta o request de CPU por Pod.
kubectl set resources deployment "$DEPLOYMENT" \
  --requests=cpu=900m,memory=64Mi \
  --limits=cpu=1,memory=128Mi
# Observa Pods e scheduling.
kubectl get pods -o wide
# Exibe Events recentes.
kubectl get events --sort-by='.lastTimestamp'
```

Dependendo da capacidade efetiva do Node e do tempo de reação do autoscaler, você poderá observar Pods `Pending` e posteriormente novos Nodes sendo adicionados.

```bash
# Observa Nodes.
kubectl get nodes
# Inspeciona um Pod Pending, se houver.
kubectl get pods
```

Se houver um Pod `Pending`, execute:

```bash
# Substitua <POD_PENDING> pelo Pod observado.
kubectl describe pod <POD_PENDING>
```

Procure por Events como `FailedScheduling` e mensagens de capacidade insuficiente.

## 7. HPA — Horizontal Pod Autoscaler

HPA ajusta **replicas de Pods**.

```text
métrica
  |
  v
 HPA
  |
  v
Deployment replicas
  |
  v
 Pods
```

Não confunda:

```text
HPA                -> Pods
Cluster Autoscaler -> Nodes
```

Antes do HPA, reduza o Deployment para um estado simples:

```bash
# Retorna a uma replica.
kubectl scale deployment "$DEPLOYMENT" --replicas=1
# Ajusta requests para uma base adequada ao HPA.
kubectl set resources deployment "$DEPLOYMENT" \
  --requests=cpu=100m,memory=64Mi \
  --limits=cpu=500m,memory=128Mi
# Aguarda estabilização.
kubectl rollout status deployment/"$DEPLOYMENT"
```

Crie o HPA:

```bash
# Configura HPA de 1 a 5 replicas com alvo de CPU de 50%.
kubectl autoscale deployment "$DEPLOYMENT" \
  --cpu-percent=50 \
  --min=1 \
  --max=5
# Inspeciona o HPA.
kubectl get hpa
# Exibe detalhes.
kubectl describe hpa "$DEPLOYMENT"
```

## 8. Métricas com kubectl top

```bash
# Exibe uso atual dos Nodes.
kubectl top nodes
# Exibe uso atual dos Pods.
kubectl top pods
```

Se `kubectl top` ainda não retornar métricas, aguarde alguns minutos e tente novamente. Em um HPA, o campo `TARGETS` pode aparecer temporariamente como `<unknown>` enquanto métricas não estão disponíveis.

```text
kubectl top
    |
    v
uso observado
resources.requests
    |
    v
base para scheduling e referência de utilização
HPA
    |
    v
ajuste de replicas
```

## 9. HPA + Cluster Autoscaler

Os dois mecanismos podem atuar em sequência:

```text
Load aumenta
    |
    v
HPA pede mais Pods
    |
    v
Deployment aumenta replicas
    |
    v
Pods não cabem nos Nodes
    |
    v
Pods Pending
    |
    v
Cluster Autoscaler aumenta Nodes
    |
    v
Scheduler posiciona os Pods
```

A ideia central para o exame é:

```text
HPA escala workload
Cluster Autoscaler escala capacidade de Nodes
```

## 10. Troubleshooting: Pod Pending

Use o fluxo:

```bash
# Estado resumido.
kubectl get pods
# Events recentes.
kubectl get events --sort-by='.lastTimestamp'
# Detalhes do Pod problemático.
kubectl describe pod <POD_PENDING>
```

Analise:

| Sintoma | Evidência comum | Hipótese |
|---|---|---|
| `Pending` | `FailedScheduling` | falta de capacidade |
| `Pending` | `Insufficient cpu` | requests não cabem |
| `Pending` | constraints/taints | regra impede scheduling |
| `Pending` com autoscaler | limites atingidos | `max-nodes` pode impedir crescimento |

## 11. CrashLoopBackOff — falha deliberada

Na Aula 4 provocamos `ImagePullBackOff`. Agora criaremos uma falha diferente: o container inicia e termina com erro.

```bash
# Cria um Deployment que termina deliberadamente com exit 1.
kubectl create deployment ace-crash \
  --image=alpine:3 \
  -- sh -c 'echo "falha deliberada"; exit 1'
# Aguarda reinicializações.
sleep 15
# Observa o estado.
kubectl get pods
```

O estado esperado tende a evoluir para `CrashLoopBackOff`.

### Diagnóstico

```bash
# Localiza o Pod do Deployment ace-crash.
export CRASH_POD="$(kubectl get pods -l app=ace-crash -o jsonpath='{.items[0].metadata.name}')"
# Inspeciona condições e Events.
kubectl describe pod "$CRASH_POD"
# Lê logs da tentativa atual.
kubectl logs "$CRASH_POD"
# Lê logs da execução anterior do container.
kubectl logs "$CRASH_POD" --previous
# Mostra Events recentes.
kubectl get events --sort-by='.lastTimestamp'
```

**Sintoma:** reinicializações repetidas / `CrashLoopBackOff`.

**Hipótese:** processo principal encerra com erro.

**Evidência:** logs mostram `falha deliberada` e exit code diferente de zero.

**Causa:** comando configurado para `exit 1`.

**Correção:** substituir o workload por um processo que permaneça saudável.

```bash
# Corrige a image/comando do Deployment.
kubectl set image deployment/ace-crash alpine=nginx:alpine
# Remove os argumentos incompatíveis recriando o Deployment de forma simples.
kubectl delete deployment ace-crash
# Recria com um container saudável.
kubectl create deployment ace-crash --image=nginx:alpine
# Aguarda o rollout.
kubectl rollout status deployment/ace-crash
# Confirma estado saudável.
kubectl get pods -l app=ace-crash
```

## 12. Readiness x Liveness

As probes têm responsabilidades diferentes.

```text
readinessProbe
      |
      +--> pode receber tráfego?
livenessProbe
      |
      +--> precisa ser reiniciado?
```

| Probe | Pergunta | Efeito típico da falha |
|---|---|---|
| Readiness | está pronto para receber tráfego? | sai dos endpoints do Service |
| Liveness | o processo está saudável? | container pode ser reiniciado |

Exemplo conceitual:

```yaml
readinessProbe:
  httpGet:
    path: /
    port: 80
  initialDelaySeconds: 5
  periodSeconds: 5
livenessProbe:
  httpGet:
    path: /
    port: 80
  initialDelaySeconds: 10
  periodSeconds: 10
```

Nesta aula, probes são **E/P***: você deve saber interpretar configuração e sintomas, mas não precisamos construir um segundo laboratório completo somente para probes.

## 13. Criar GKE Autopilot

Agora criaremos um cluster Autopilot temporário para comparação.

```bash
# Cria um cluster Autopilot regional.
gcloud container clusters create-auto "$AUTOPILOT_CLUSTER" \
  --region="$REGION" \
  --project="$PROJECT_ID"
# Inspeciona o cluster.
gcloud container clusters describe "$AUTOPILOT_CLUSTER" \
  --region="$REGION" \
  --project="$PROJECT_ID"
# Configura o kubectl para o Autopilot.
gcloud container clusters get-credentials "$AUTOPILOT_CLUSTER" \
  --region="$REGION" \
  --project="$PROJECT_ID"
# Observa Nodes fornecidos pelo ambiente.
kubectl get nodes -o wide
```

A diferença importante não é “Autopilot não tem Nodes”, e sim que **o usuário administra menos diretamente a infraestrutura de Nodes**.

Crie um workload simples:

```bash
# Cria namespace de comparação.
kubectl create namespace ace-autopilot-lab
# Cria um Deployment no Autopilot.
kubectl create deployment ace-autopilot-web \
  --image=nginx:alpine \
  --namespace=ace-autopilot-lab
# Aguarda o rollout.
kubectl rollout status deployment/ace-autopilot-web \
  --namespace=ace-autopilot-lab
# Inspeciona Pods.
kubectl get pods \
  --namespace=ace-autopilot-lab \
  -o wide
```

## 14. Comparação operacional observada

```text
Standard
  |
  +-- você inspecionou node pool
  +-- configurou min/max Nodes
  +-- configurou Cluster Autoscaler
  +-- gerenciou capacidade explicitamente
Autopilot
  |
  +-- você criou o cluster
  +-- publicou workload
  +-- trabalhou principalmente com objetos Kubernetes
  +-- infraestrutura de Nodes ficou mais abstraída
```

## 15. Cleanup imediato do Autopilot

Para evitar manter dois clusters simultaneamente:

```bash
# Remove o namespace de teste do Autopilot.
kubectl delete namespace ace-autopilot-lab
# Exclui o cluster Autopilot.
gcloud container clusters delete "$AUTOPILOT_CLUSTER" \
  --region="$REGION" \
  --project="$PROJECT_ID" \
  --quiet
```

## 16. Voltar ao cluster Standard

```bash
# Restaura credenciais do cluster Standard.
gcloud container clusters get-credentials "$CLUSTER" \
  --zone="$ZONE" \
  --project="$PROJECT_ID"
# Restaura namespace da aula.
kubectl config set-context --current --namespace="$NAMESPACE"
# Confirma contexto.
kubectl config current-context
```

## 17. Troubleshooting por sintoma

| Sintoma | Onde olhar | Causa provável |
|---|---|---|
| `Pending` | `describe`, Events | requests, capacity, taints, constraints |
| `ImagePullBackOff` | `describe`, Events | image/tag/IAM |
| `CrashLoopBackOff` | logs + `--previous` | processo encerrando repetidamente |
| `Running` sem tráfego | readiness, Service, selectors | endpoint não ready/selector incorreto |
| HPA `<unknown>` | HPA + métricas | métricas ainda indisponíveis |
| Pods Pending e Nodes não crescem | autoscaling config + limits | max nodes/configuração |

Roteiro geral:

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
    +--> --previous quando houver restart
    |
    v
causa
    |
    v
correção
```

## 18. Cloud Run x Cloud Run Jobs x GKE x Compute Engine

| Requisito | Melhor candidato |
|---|---|
| API/container HTTP stateless com mínimo operacional | Cloud Run |
| processamento batch containerizado serverless | Cloud Run Jobs |
| Kubernetes obrigatório | GKE |
| Kubernetes com menor operação de Nodes | GKE Autopilot |
| node pools/machine types específicos | GKE Standard |
| operadores, CRDs e recursos Kubernetes | GKE |
| controle de SO/kernel | Compute Engine |
| aplicação legada em VM | Compute Engine |

Regra importante:

```text
"Tenho um container"
       !=
"Preciso de Kubernetes"
```

## 19. Modelo de decisão

```text
Precisa Kubernetes?
   |
   +-- Sim
   |    |
   |    +-- precisa controle detalhado de Nodes?
   |           |
   |           +-- Sim -> GKE Standard
   |           +-- Não -> GKE Autopilot
   |
   +-- Não
        |
        +-- batch containerizado? -> Cloud Run Jobs
        |
        +-- HTTP stateless? -> Cloud Run
        |
        +-- precisa SO/VM? -> Compute Engine
```

## 20. Questões estilo ACE

1. Um HPA aumenta replicas, mas novos Pods ficam `Pending` por falta de CPU nos Nodes. Qual mecanismo pode adicionar capacidade? **Cluster Autoscaler.**
2. Uma equipe precisa de machine type específico e node pool dedicado. Qual modo GKE é mais apropriado? **Standard.**
3. Uma equipe quer Kubernetes, mas deseja reduzir a administração de Nodes. Qual modo considerar? **Autopilot.**
4. Um Pod está `Pending` e `describe` mostra `Insufficient cpu`. O que isso indica? **Os requests não cabem na capacidade disponível.**
5. Um container reinicia repetidamente. Qual comando ajuda a recuperar a saída da tentativa anterior? **`kubectl logs POD --previous`.**
6. O Pod está `Running`, mas não deve receber tráfego enquanto inicializa. Qual mecanismo representa melhor esse estado? **Readiness probe.**
7. CPU do workload sobe e você precisa aumentar replicas de Pods. Qual recurso? **HPA.**
8. Você possui uma API stateless simples e não precisa Kubernetes. Qual serviço tende a reduzir operação? **Cloud Run.**
9. Você precisa executar processamento batch e terminar ao concluir. Qual opção serverless estudada? **Cloud Run Jobs.**
10. Pods não podem ser agendados e o node pool já atingiu `max-nodes`. O que verificar? **Limites/configuração do Cluster Autoscaler e capacidade requerida.**

## 21. Cleanup do cluster Standard

Remova os workloads e HPA da aula:

```bash
# Exclui o namespace e seus recursos.
kubectl delete namespace "$NAMESPACE"
# Confirma a remoção.
kubectl get namespaces
```

Depois exclua o cluster Standard para interromper os custos:

```bash
# Exclui o cluster Standard reaproveitado das Aulas 4 e 5.
gcloud container clusters delete "$CLUSTER" \
  --zone="$ZONE" \
  --project="$PROJECT_ID" \
  --quiet
# Confirma que os clusters do laboratório foram removidos.
gcloud container clusters list --project="$PROJECT_ID"
```

> [!WARNING]
> Esta é a última aula de GKE da Semana 5. Salvo se você tiver outro laboratório planejado, **não deixe `ace-gke` ou `ace-autopilot` executando**.

## 22. M/E/P

| Conteúdo | Nível | Evidência |
|---|---|---|
| Standard x Autopilot | E/P | comparação + clusters observados |
| Node pools | P | list + describe |
| Cluster Autoscaler | P | enable + min/max + describe |
| Requests / scheduling | P | requests + observação de Pending |
| Pod Pending | P | Events + describe |
| HPA | P | autoscale + get + describe |
| Métricas | P | `kubectl top nodes/pods` |
| HPA + Cluster Autoscaler | E/P* | fluxo combinado e ambiente configurado |
| CrashLoopBackOff | P | falha deliberada + logs + `--previous` |
| Readiness / Liveness | E/P* | interpretação de comportamento e YAML |
| Events | P | consulta ordenada |
| Troubleshooting | P | get → describe → Events → logs |
| Cloud Run x Jobs x GKE x CE | E | matriz e cenários |
| Cleanup | P | Autopilot + Standard |

## 23. Mapa mental final da Semana 5

```text
Container
   |
   +-- Registry -> Artifact Registry
   |
   +-- HTTP stateless -> Cloud Run Service
   |
   +-- Batch -> Cloud Run Job
   |
   +-- Kubernetes -> GKE
                     |
                     +-- Autopilot -> menos operação de Nodes
                     |
                     +-- Standard -> mais controle de Nodes
                                       |
                                       +-- HPA -> Pods
                                       +-- Cluster Autoscaler -> Nodes
Troubleshooting Kubernetes:
get -> describe -> Events -> logs -> causa -> correção
```
