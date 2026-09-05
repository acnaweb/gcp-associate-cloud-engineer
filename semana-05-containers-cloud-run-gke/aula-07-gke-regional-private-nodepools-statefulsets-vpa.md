# Aula 7 — GKE Regional, Private, Node Pools, StatefulSets, HPA e VPA

## Nível de cobertura M/E/P

```text
Regional cluster: P
Private cluster: P*
GKE Enterprise: E/P*
Node pools: P
StatefulSet: P
HPA: retomada P (Aula 5)
VPA: P/P*
```

## Objetivos

Ao final, você deverá:
- diferenciar cluster regional, private, Autopilot, Standard e GKE Enterprise no nível exigido pelo ACE;
- explicar o papel de **node pools** em clusters Standard;
- adicionar, inspecionar, configurar autoscaling e remover node pool;
- explicar por que **StatefulSet** não é apenas “Deployment para banco de dados”;
- criar e inspecionar StatefulSet;
- explicar detalhadamente **VPA**;
- distinguir `recommendation`, `requests`, `updateMode` e efeito do VPA;
- diferenciar HPA, VPA e Cluster Autoscaler sem confundir suas responsabilidades.

> **Custos:** clusters Standard e regionais podem gerar cobrança significativa. Crie apenas o necessário e execute cleanup.

---

# 1. Conceito — configurações de cluster

## 1.1 Autopilot

```text
Você gerencia principalmente workloads.
Google abstrai a administração dos Nodes.
```

Use quando quer reduzir operação de infraestrutura Kubernetes.

## 1.2 Standard

```text
Você controla:
- node pools
- machine type dos Nodes
- autoscaling de node pools
- várias configurações de infraestrutura
```

Use quando precisa desse controle adicional.

## 1.3 Regional cluster

Um cluster regional distribui componentes do control plane regionalmente e é escolhido quando a arquitetura requer maior resiliência regional do cluster.

Não confunda:

```text
regional cluster
≠
Pod automaticamente replicado em qualquer região do mundo
```

## 1.4 Private cluster

Private cluster reduz exposição de componentes/nodes conforme configuração de rede.

Para o laboratório ACE, o importante é reconhecer:

```text
private nodes
control plane endpoint/configuração
subnet/IP ranges
acesso administrativo
```

A criação completa pode depender de uma rede preparada; por isso será `P*` quando o ambiente do aluno não possuir os pré-requisitos.

## 1.5 GKE Enterprise

O guia anexado cita GKE Enterprise. No nível ACE, reconheça-o como oferta/configuração voltada a gestão Kubernetes empresarial e cenários mais amplos/multicluster.

Não é necessário transformar esta aula em administração avançada de fleet.

---

# 2. Arquitetura mental

```text
GKE Standard regional
│
├── Node Pool A
│    ├── Node
│    └── Node
│
├── Deployment
│    └── Pods stateless
│
├── StatefulSet
│    ├── pod-0
│    └── pod-1
│
├── HPA
│    └── altera nº de Pods
│
└── VPA
     └── recomenda/ajusta requests por Pod
```

---

# 3. Criar um cluster regional Standard

> Pule a criação se você já possui um cluster Standard adequado. Não mantenha clusters duplicados.

```bash
# Define a região usada nos comandos do laboratório.
export REGION=us-central1

# Habilita a API do GKE no projeto ativo, caso ainda não esteja habilitada.
gcloud services enable container.googleapis.com

# Cria um cluster GKE Standard regional com um Node por zona gerenciada pela configuração regional.
# O objetivo é praticar a opção regional e ter acesso explícito a node pools.
gcloud container clusters create ace-regional \
  --region="$REGION" \
  --num-nodes=1 \
  --machine-type=e2-small

# Obtém credenciais e atualiza kubeconfig para que kubectl use o cluster ace-regional.
gcloud container clusters get-credentials ace-regional \
  --region="$REGION"
```

## Inspecione antes de continuar

```bash
# Exibe configuração detalhada do cluster, incluindo localização e modo.
gcloud container clusters describe ace-regional \
  --region="$REGION"

# Lista nodes registrados no cluster.
kubectl get nodes -o wide

# Lista node pools existentes no cluster.
gcloud container node-pools list \
  --cluster=ace-regional \
  --region="$REGION"
```


## 3.1 Testar o cluster regional

Criar o cluster e descrevê-lo não é suficiente para `P`; valide que o control plane aceita uma workload e que os Nodes estão prontos.

```bash
# Explicação: Cria um Deployment mínimo no cluster regional para validar scheduling e execução de Pods.
kubectl create deployment regional-web \
  --image=nginx:alpine

# Explicação: Aguarda o Deployment ficar disponível; sucesso confirma que a workload foi agendada e os Pods ficaram Ready.
kubectl wait deployment/regional-web \
  --for=condition=Available \
  --timeout=180s

# Explicação: Mostra em quais Nodes os Pods foram agendados e ajuda a observar a topologia do cluster.
kubectl get pods -o wide

# Explicação: Exibe labels de topologia dos Nodes, incluindo informações de zona/região quando presentes.
kubectl get nodes \
  -L topology.kubernetes.io/region,topology.kubernetes.io/zone
```

Comportamento esperado:

```text
Deployment Available
Pods Ready
Nodes associados à região configurada
```

Cleanup dessa workload de validação:

```bash
# Explicação: Remove somente o Deployment usado para testar o cluster regional.
kubectl delete deployment regional-web
```

---

# 4. Node pools — conceito e prática

Node pool é um conjunto de Nodes com configuração comum.

Exemplos de características associadas a um pool:

```text
machine type
quantidade de nodes
autoscaling
labels/taints em cenários específicos
versão/configuração operacional
```

Por que isso importa?

```text
Cluster Standard
├── pool-general → e2-small
└── pool-batch   → outra configuração
```

O scheduler posiciona Pods nos Nodes disponíveis de acordo com requisitos/restrições.

## 4.1 Adicionar node pool

```bash
# Cria um node pool adicional chamado ace-extra-pool.
# --num-nodes=1 inicia pequeno para laboratório.
# --machine-type=e2-small define o tipo das VMs do pool.
gcloud container node-pools create ace-extra-pool \
  --cluster=ace-regional \
  --region="$REGION" \
  --num-nodes=1 \
  --machine-type=e2-small
```

## 4.2 Inspecionar

```bash
# Lista todos os node pools e confirma que ace-extra-pool foi criado.
gcloud container node-pools list \
  --cluster=ace-regional \
  --region="$REGION"

# Exibe detalhes específicos do novo node pool.
gcloud container node-pools describe ace-extra-pool \
  --cluster=ace-regional \
  --region="$REGION"

# Lista os Nodes Kubernetes depois da inclusão do pool.
kubectl get nodes -o wide
```

## 4.3 Configurar autoscaling do node pool

O autoscaling do node pool pertence à camada de **capacidade de Nodes**, não à camada de réplicas do Deployment.

```bash
# Habilita autoscaling do node pool ace-extra-pool.
# O pool poderá variar entre 0 e 2 Nodes conforme necessidade de scheduling/capacidade.
gcloud container clusters update ace-regional \
  --region="$REGION" \
  --enable-autoscaling \
  --node-pool=ace-extra-pool \
  --min-nodes=0 \
  --max-nodes=2
```

Inspecione novamente o pool e localize a configuração de autoscaling.

---

# 5. StatefulSet — conceito antes do comando

Deployment é ótimo quando as réplicas podem ser tratadas como intercambiáveis.

```text
Deployment
web-abc
web-def
web-ghi
```

StatefulSet é usado quando o workload necessita características stateful como **identidade estável e ordenação previsível dos Pods**.

```text
StatefulSet ace-stateful
├── ace-stateful-0
└── ace-stateful-1
```

Isso não significa:

> “Se a aplicação usa banco, então o banco deve estar em StatefulSet.”

Muitas arquiteturas usam banco gerenciado fora do cluster.

## 5.1 Criar

```bash
# Cria manifesto StatefulSet com duas réplicas nginx.
# serviceName participa da identidade de rede estável normalmente associada ao StatefulSet.
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

# Aplica o manifesto e cria o StatefulSet.
kubectl apply -f statefulset.yaml
```

## 5.2 Inspecionar e testar

```bash
# Lista StatefulSets e número de réplicas prontas.
kubectl get statefulsets

# Lista os Pods para observar nomes estáveis terminados em -0 e -1.
kubectl get pods -l app=ace-stateful

# Mostra detalhes, eventos e estado desejado do StatefulSet.
kubectl describe statefulset ace-stateful
```

Observe:

```text
ace-stateful-0
ace-stateful-1
```

---

# 6. VPA — Vertical Pod Autoscaler

## 6.1 O problema que o VPA resolve

Imagine um Deployment declarado assim:

```text
CPU request = 50m
Memory request = 32Mi
```

Mas, na prática, os Pods historicamente precisam de muito mais recursos.

Duas consequências possíveis:

```text
request muito baixo
→ scheduling/capacidade não refletem bem a necessidade real

request muito alto
→ reserva/custo podem ser maiores do que o necessário
```

O VPA analisa utilização e produz recomendações de sizing para os containers.

Pergunta respondida pelo VPA:

> **Quanto CPU/memória cada Pod deveria solicitar?**

## 6.2 Recommendation

Uma recomendação do VPA pode conter valores como:

```text
target       → sizing recomendado
lowerBound   → limite inferior recomendado
upperBound   → limite superior recomendado
uncappedTarget → recomendação sem considerar determinados limites/policies
```

No ACE, o mais importante é reconhecer que VPA atua sobre **resource requests**, não sobre a quantidade de réplicas.

## 6.3 Update modes

### `Off`

```text
VPA observa
   ↓
gera recommendation
   ↓
não altera automaticamente os Pods
```

É o modo mais seguro para laboratório didático.

### Modos que aplicam recomendações

Dependendo do modo/configuração suportado pelo ambiente, o VPA pode aplicar sizing aos Pods. Isso pode envolver recriação/atualização de Pods; portanto, não trate VPA como uma alteração “sem impacto”.

Para esta aula, usaremos `Off` para separar **observar** de **aplicar**.

---

# 7. Criar workload para VPA

```bash
# Cria manifesto de Deployment com requests baixos e um processo que consome CPU continuamente.
cat > vpa-workload.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vpa-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: vpa-demo
  template:
    metadata:
      labels:
        app: vpa-demo
    spec:
      containers:
      - name: cpu
        image: busybox:1.36
        command: ["sh", "-c", "while true; do :; done"]
        resources:
          requests:
            cpu: 25m
            memory: 16Mi
          limits:
            cpu: 200m
            memory: 32Mi
EOF

# Cria o Deployment do laboratório VPA.
kubectl apply -f vpa-workload.yaml

# Confirma que o Pod está Running e registra os requests originais.
kubectl describe deployment vpa-demo
kubectl get pods -l app=vpa-demo
```

---

# 8. Criar VPA em modo `Off`

> Em ambientes onde o recurso/API de VPA não estiver disponível, esta parte deve ser tratada como `P*`. Não finja sucesso: confirme primeiro se o tipo de recurso existe.

```bash
# Verifica se o cluster reconhece o recurso VerticalPodAutoscaler.
kubectl api-resources | grep -i verticalpodautoscaler || true
```

Se o recurso estiver disponível:

```bash
# Cria um VPA apontando para Deployment/vpa-demo.
# updateMode=Off instrui o VPA a produzir recomendações sem alterar automaticamente os Pods.
cat > vpa.yaml <<'EOF'
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: vpa-demo
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: vpa-demo
  updatePolicy:
    updateMode: "Off"
EOF

# Aplica o recurso VPA.
kubectl apply -f vpa.yaml
```

---

# 9. Inspecionar VPA

```bash
# Lista os VPAs do namespace e confirma associação ao target.
kubectl get vpa

# Mostra detalhes do VPA, incluindo recommendation quando dados suficientes estiverem disponíveis.
kubectl describe vpa vpa-demo

# Exibe o objeto completo para localizar status.recommendation.
kubectl get vpa vpa-demo -o yaml
```

A recomendação pode levar algum tempo para aparecer porque o VPA precisa observar uso do workload.

Não considere “sem recommendation imediatamente” como falha sem antes aguardar coleta suficiente.

---

# 10. Testar a diferença entre HPA e VPA

Retome a Aula 5:

```text
HPA
input → métrica
output → desired replicas

VPA
input → histórico/uso de recursos
output → recommendation/request sizing
```

Com `updateMode=Off`:

```text
VPA recommendation muda
      ↓
Deployment original NÃO é automaticamente redimensionado
```

Isso é justamente o comportamento esperado do laboratório.

---

# 11. Quebrar propositalmente — targetRef incorreto

Vamos alterar **uma única variável**: o nome do Deployment alvo.

```bash
# Troca apenas targetRef.name para um Deployment inexistente.
kubectl patch vpa vpa-demo \
  --type=merge \
  -p '{"spec":{"targetRef":{"apiVersion":"apps/v1","kind":"Deployment","name":"nao-existe"}}}'
```

---

# 12. Troubleshooting do VPA

## Sintoma

O VPA não consegue produzir comportamento/recomendação coerente para o workload esperado.

## Hipótese

O `targetRef` aponta para um Deployment inexistente.

## Evidência

```bash
# Mostra o targetRef configurado e condições/eventos do VPA.
kubectl describe vpa vpa-demo

# Confirma que nao-existe não aparece entre Deployments.
kubectl get deployments

# Mostra o YAML do VPA para comparar targetRef.name com os recursos reais.
kubectl get vpa vpa-demo -o yaml
```

## Causa

```text
targetRef.name = nao-existe
```

## Correção

```bash
# Corrige apenas targetRef.name para o Deployment vpa-demo criado anteriormente.
kubectl patch vpa vpa-demo \
  --type=merge \
  -p '{"spec":{"targetRef":{"apiVersion":"apps/v1","kind":"Deployment","name":"vpa-demo"}}}'

# Confirma a associação após a correção.
kubectl describe vpa vpa-demo
```

Fluxo:

```text
Sintoma
   ↓
Hipótese
   ↓
Evidência
   ↓
Causa
   ↓
Correção
```

---

# 13. HPA x VPA x Cluster Autoscaler

| Recurso | Escala o quê? | Pergunta principal |
|---|---|---|
| HPA | quantidade de Pods | quantas réplicas preciso? |
| VPA | requests de CPU/memória por Pod | qual tamanho cada Pod precisa? |
| Cluster Autoscaler | Nodes/node pool | há capacidade de cluster suficiente? |

Modelo integrado:

```text
Aplicação recebe mais carga
        ↓
HPA pede mais Pods
        ↓
Pods precisam ser agendados
        ↓
se não houver capacidade (Standard)
        ↓
Cluster Autoscaler pode aumentar Nodes
```

Separadamente:

```text
uso histórico mostra sizing inadequado
        ↓
VPA gera recommendation
        ↓
requests podem ser ajustados conforme update mode/policy
```

### Pegadinha de prova

`Pending` por falta de capacidade de Nodes não é resolvido aumentando apenas `maxReplicas` do HPA.

`CPU request` inadequado não significa automaticamente que a solução é aumentar a quantidade de Nodes.

---

# 14. Private cluster — prática guiada

Antes de criar um private cluster, prepare rede/subnet e valide custo. No Console ou CLI, identifique:

```text
private nodes
authorization/control-plane access
subnet e secondary ranges quando aplicável
endpoint/configuração de acesso
```

A prática é `P*` porque o ambiente do aluno pode não ter rede preparada e não é razoável criar múltiplos clusters caros apenas para marcar checklist.

---

# 15. GKE + Artifact Registry

Fluxo mental:

```text
Artifact Registry
      ↓ pull
identidade/permissão adequada
      ↓
GKE Pod
```

Se houver `ImagePullBackOff` com imagem privada:

```bash
# Mostra eventos do Pod e identifica se o erro é not found, auth ou permission.
kubectl describe pod POD

# Lista imagens disponíveis no repositório Artifact Registry esperado.
gcloud artifacts docker images list \
  REGION-docker.pkg.dev/PROJECT/REPOSITORY
```

Não comece alterando HPA/VPA para resolver falha de pull de imagem.

---

# 16. Questões estilo ACE

**1.** A aplicação precisa aumentar número de Pods quando CPU sobe. **HPA**.

**2.** O objetivo é recomendar CPU/memória apropriadas para cada Pod. **VPA**.

**3.** Pods criados pelo HPA ficam `Pending` porque cluster Standard está sem capacidade. **Node pool/Cluster Autoscaler**.

**4.** Workload precisa de identidade estável `pod-0`, `pod-1` e semântica stateful. **StatefulSet**.

**5.** Equipe quer controle explícito de node pools e machine types. **GKE Standard**.

**6.** Equipe quer reduzir exposição de Nodes à Internet. **Private cluster**, considerando desenho de rede/acesso.

**7.** VPA em `updateMode: Off` possui recommendation, mas o Deployment não muda automaticamente. Isso é erro? **Não. É o comportamento esperado do modo Off.**

---

# 17. Cleanup

```bash
# Remove o VPA, se ele foi criado com sucesso.
kubectl delete -f vpa.yaml --ignore-not-found

# Remove o workload usado para produzir dados para o VPA.
kubectl delete -f vpa-workload.yaml --ignore-not-found

# Remove o StatefulSet criado no laboratório.
kubectl delete -f statefulset.yaml --ignore-not-found

# Remove arquivos locais temporários.
rm -f vpa.yaml vpa-workload.yaml statefulset.yaml

# Remove o node pool extra se ele ainda existir.
gcloud container node-pools delete ace-extra-pool \
  --cluster=ace-regional \
  --region="$REGION" \
  --quiet

# Exclui o cluster regional se ele foi criado apenas para esta aula.
gcloud container clusters delete ace-regional \
  --region="$REGION" \
  --quiet
```

---

# 18. Checklist M/E/P

- [ ] Diferencio Autopilot e Standard;
- [ ] Explico cluster regional e private;
- [ ] Reconheço GKE Enterprise no nível ACE;
- [ ] Criei/inspecionei/removi node pool;
- [ ] Entendo autoscaling de node pool;
- [ ] Criei StatefulSet e observei nomes estáveis;
- [ ] Explico `target`, `requests` e `updateMode` do VPA;
- [ ] Criei/inspecionei VPA ou classifiquei corretamente como P* por indisponibilidade do recurso;
- [ ] Diferencio HPA, VPA e Cluster Autoscaler;
- [ ] Provoquei targetRef incorreto sem adicionar outra falha;
- [ ] Diagnostiquei e corrigi usando evidências;
- [ ] Executei cleanup.

---

<!-- MEP-ACCEPTANCE-V9 -->
# Critério de aceite M/E/P desta aula

> Esta seção não substitui o conteúdo acima; ela explicita o critério usado na auditoria da baseline v9.

Para um tópico ser classificado como `P` nesta baseline, não basta existir um comando. A aula precisa apresentar:

```text
conceito operacional
   ↓
configuração/comando
   ↓
inspeção
   ↓
teste ou comportamento observável
```

Quando a execução depender de Organization, privilégio administrativo, custo relevante ou infraestrutura especial, use `P*`.

## Tópicos do guia mapeados para esta aula

| Seção | Tópico | Esperado | Nível da matriz |
|---|---|---:|---:|
| 3.2 | Regional cluster | `P` | `P` |
| 3.2 | Private cluster | `P` | `P*` |
| 3.2 | GKE Enterprise | `P` | `P*` |
| 4.2 | Node pools add/edit/remove | `P` | `P` |
| 4.2 | VPA | `P` | `P/P*` |
