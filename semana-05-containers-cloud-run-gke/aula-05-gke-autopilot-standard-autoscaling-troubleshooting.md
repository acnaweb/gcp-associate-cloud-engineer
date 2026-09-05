# Aula 5 — GKE Autopilot, Standard, Autoscaling e Troubleshooting

## Nível de cobertura M/E/P

```text
Autopilot x Standard: E/P
HPA: P
Cluster Autoscaler: E/P*
Troubleshooting de Pods: P
```

## Objetivos

Ao final, você deverá:
- comparar **GKE Autopilot** e **GKE Standard**;
- explicar a diferença entre **HPA**, **VPA** e **Cluster Autoscaler**;
- configurar e inspecionar um **Horizontal Pod Autoscaler (HPA)**;
- relacionar HPA com `requests.cpu` e utilização percentual;
- observar o aumento/redução de réplicas;
- reconhecer quando o problema exige mais Pods e quando exige mais Nodes;
- interpretar `Pending`, `ImagePullBackOff` e `CrashLoopBackOff`;
- provocar e corrigir `ImagePullBackOff` usando evidências.

> **Pré-requisito:** use o cluster GKE criado na Aula 4. Se ele foi removido, recrie um cluster Autopilot pequeno e exclua ao final.

> **Custos:** GKE pode gerar cobrança. Não mantenha clusters criados apenas para estudo.

---

# 1. Conceito

## 1.1 Autopilot x Standard

Os dois executam Kubernetes gerenciado pelo Google, mas dividem a responsabilidade operacional de forma diferente.

| Tema | Autopilot | Standard |
|---|---|---|
| Nodes | gerenciados pelo Google | administrados/configurados pelo usuário |
| Node pools | abstraídos | controle explícito |
| Capacidade | ajustada pelo serviço | pode usar Cluster Autoscaler |
| Controle de infraestrutura | menor | maior |
| Foco | workload | workload + infraestrutura do cluster |

Modelo mental:

```text
Autopilot
Application → Pod → Google gerencia capacidade de nodes

Standard
Application → Pod → Node Pool → Nodes
                           ↑
                  Cluster Autoscaler
```

## 1.2 As três dimensões de autoscaling

```text
                    ESCALABILIDADE NO GKE
                           │
          ┌────────────────┼────────────────┐
          │                │                │
          ▼                ▼                ▼
         HPA              VPA       Cluster Autoscaler
          │                │                │
          ▼                ▼                ▼
 quantidade de       CPU/memória       quantidade
    Pods              por Pod           de Nodes
```

### HPA — Horizontal Pod Autoscaler

O HPA responde à pergunta:

> **Quantas réplicas do workload eu preciso?**

Ele observa uma métrica — frequentemente CPU — e ajusta a quantidade de Pods entre um mínimo e um máximo.

Exemplo:

```text
Deployment web
replicas atuais = 1

CPU média > target
      ↓
HPA aumenta replicas
      ↓
Deployment passa a manter mais Pods
```

### Por que `requests.cpu` importa?

Quando o HPA usa **percentual de CPU**, ele compara o consumo observado com o **CPU request** declarado pelo container.

Exemplo:

```text
request = 100m
consumo = 80m

utilização aproximada = 80%
```

Se o target do HPA for 50%, 80% indica que o workload está acima do alvo e pode precisar de mais réplicas.

Sem compreender `requests`, o aluno pode criar HPA e não entender por que a métrica aparece como desconhecida ou por que o scaling não ocorre como esperado.

### VPA — Vertical Pod Autoscaler

O VPA responde a outra pergunta:

> **Quanto CPU/memória cada Pod deveria solicitar?**

Ele será praticado em detalhe na **Aula 7**. Aqui basta guardar a diferença:

```text
HPA → quantidade de Pods
VPA → tamanho/requisições de cada Pod
```

### Cluster Autoscaler

No GKE Standard, o Cluster Autoscaler responde:

> **O cluster possui Nodes suficientes para acomodar os Pods?**

Cadeia típica:

```text
Carga aumenta
   ↓
HPA cria mais Pods
   ↓
não existe capacidade suficiente nos Nodes
   ↓
Pods ficam Pending
   ↓
Cluster Autoscaler aumenta Nodes/node pool
```

Portanto:

```text
HPA não cria Nodes.
Cluster Autoscaler não substitui HPA.
VPA não aumenta o número de Pods.
```

---

# 2. Criar / Configurar — laboratório de HPA

## 2.1 Confirme o cluster

```bash
# Lista os clusters GKE para confirmar que existe um cluster disponível para o laboratório.
gcloud container clusters list

# Mostra os nodes vistos pelo Kubernetes. Em Autopilot eles são gerenciados pelo Google, mas continuam aparecendo para inspeção do cluster.
kubectl get nodes
```

## 2.2 Crie um workload que consome CPU

O laboratório usará um container `busybox` executando um loop contínuo. O objetivo é produzir consumo de CPU previsível para que o HPA tenha algo para observar.

```bash
# Cria um manifesto de Deployment com 1 réplica.
# requests.cpu=50m define a referência usada pelo HPA para calcular o percentual de utilização.
# limits.cpu=200m limita o máximo de CPU que cada container poderá consumir.
cat > hpa-demo.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hpa-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hpa-demo
  template:
    metadata:
      labels:
        app: hpa-demo
    spec:
      containers:
      - name: cpu
        image: busybox:1.36
        command: ["sh", "-c", "while true; do :; done"]
        resources:
          requests:
            cpu: 50m
            memory: 16Mi
          limits:
            cpu: 200m
            memory: 32Mi
EOF

# Aplica o manifesto declarativamente, criando o Deployment e o Pod inicial.
kubectl apply -f hpa-demo.yaml
```

## 2.3 Inspecione os requests antes de criar o HPA

```bash
# Mostra o Deployment e confirma número desejado/disponível de réplicas.
kubectl get deployment hpa-demo

# Exibe a configuração completa do Deployment para localizar resources.requests e resources.limits.
kubectl describe deployment hpa-demo

# Lista o Pod e permite confirmar que ele entrou em Running.
kubectl get pods -l app=hpa-demo -o wide
```

O ponto didático é confirmar **antes** do autoscaling:

```text
Deployment existe
Pod está Running
CPU request existe
```

---

# 3. Criar o HPA

```bash
# Cria um Horizontal Pod Autoscaler para o Deployment hpa-demo.
# --cpu-percent=50 define target médio de 50% do CPU request.
# --min=1 impede reduzir abaixo de 1 réplica.
# --max=4 impede ultrapassar 4 réplicas durante o laboratório.
kubectl autoscale deployment hpa-demo \
  --cpu-percent=50 \
  --min=1 \
  --max=4
```

## O que foi criado?

```text
HPA
├── targetRef → Deployment/hpa-demo
├── minReplicas → 1
├── maxReplicas → 4
└── CPU target → 50%
```

---

# 4. Inspecionar o HPA

```bash
# Lista o HPA em formato resumido.
# TARGETS mostra utilização observada versus target.
# MINPODS/MAXPODS delimitam o scaling.
# REPLICAS mostra a quantidade atual controlada pelo HPA.
kubectl get hpa

# Exibe detalhes do HPA, incluindo métricas, desired replicas, condições e eventos.
kubectl describe hpa hpa-demo

# Acompanha mudanças continuamente. Use Ctrl+C para sair.
kubectl get hpa hpa-demo -w
```

Campos que você precisa saber interpretar:

```text
TARGETS      → métrica atual / target
MINPODS      → mínimo permitido
MAXPODS      → máximo permitido
REPLICAS     → réplicas atuais
Conditions   → consegue ou não calcular/escalar
Events       → evidências de decisões ou falhas
```

> A coleta de métricas não é instantânea. Aguarde alguns ciclos antes de concluir que o HPA não funciona.

---

# 5. Testar o comportamento de scaling

Em outro terminal:

```bash
# Acompanha a quantidade de Pods do workload.
kubectl get pods -l app=hpa-demo -w
```

No primeiro terminal:

```bash
# Consulta novamente o HPA após alguns ciclos de métricas.
kubectl get hpa hpa-demo

# Mostra detalhes para verificar current/desired replicas e eventos de scaling.
kubectl describe hpa hpa-demo
```

Como o container mantém CPU ocupada, a tendência é o HPA observar utilização acima do target e aumentar as réplicas até que a política/limites estabilizem o workload.

O objetivo não é decorar um número de réplicas, mas observar o fluxo:

```text
métrica alta
   ↓
HPA calcula desired replicas
   ↓
Deployment recebe novo número desejado
   ↓
novos Pods são criados
```

---

# 6. Quebrar propositalmente — HPA sem CPU request

Agora provoque **uma única falha**: remova o `requests.cpu` do Deployment.

```bash
# Remove apenas o campo requests.cpu do primeiro container.
# O objetivo é demonstrar por que um HPA percentual depende de resource requests.
kubectl patch deployment hpa-demo \
  --type=json \
  -p='[{"op":"remove","path":"/spec/template/spec/containers/0/resources/requests/cpu"}]'

# Aguarda o rollout criado pela alteração no Pod template.
kubectl rollout status deployment/hpa-demo
```

---

# 7. Troubleshooting do HPA

## Sintoma

O HPA deixa de apresentar a utilização percentual esperada ou não consegue calcular corretamente o número desejado de réplicas.

## Hipótese

O container alvo não possui `requests.cpu`, então a utilização percentual de CPU não possui a referência necessária.

## Evidência

```bash
# Mostra o HPA e suas condições/eventos.
kubectl describe hpa hpa-demo

# Confirma a configuração de resources do Deployment.
kubectl get deployment hpa-demo -o yaml

# Mostra requests/limits efetivamente presentes no Pod atual.
kubectl describe pod -l app=hpa-demo
```

Procure evidência de que o CPU request não está definido para o container.

## Causa

Removemos deliberadamente:

```text
resources.requests.cpu
```

## Correção

```bash
# Reaplica o manifesto original, restaurando requests.cpu=50m e limits.cpu=200m.
kubectl apply -f hpa-demo.yaml

# Aguarda o Deployment estabilizar novamente.
kubectl rollout status deployment/hpa-demo

# Confirma se o HPA voltou a receber métricas após alguns ciclos.
kubectl get hpa hpa-demo
kubectl describe hpa hpa-demo
```

Fluxo obrigatório:

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

# 8. Troubleshooting de Pods — ImagePullBackOff

O exam guide também exige operação do GKE. Vamos manter a falha de imagem da versão anterior do laboratório.

```bash
# Cria um Deployment deliberadamente quebrado com uma tag inexistente.
kubectl create deployment quebrado \
  --image=nginx:tag-que-nao-existe-ace

# Lista os Pods para observar ErrImagePull/ImagePullBackOff.
kubectl get pods -l app=quebrado

# Mostra eventos e a mensagem retornada pelo runtime ao tentar obter a imagem.
kubectl describe pod -l app=quebrado
```

### Sintoma

`ErrImagePull` / `ImagePullBackOff`.

### Hipótese

Imagem ou tag não existe — ou o registry não pode ser acessado.

### Evidência

No nosso caso, os eventos mostram que a tag deliberadamente escolhida não existe.

### Correção

```bash
# Substitui a imagem inválida por nginx:alpine e inicia novo rollout.
kubectl set image deployment/quebrado \
  nginx=nginx:alpine

# Aguarda o rollout concluir.
kubectl rollout status deployment/quebrado

# Confirma que o Pod agora entra em Running.
kubectl get pods -l app=quebrado
```

Não tente resolver `ImagePullBackOff` aumentando HPA, VPA ou Nodes. O erro está na obtenção da imagem.

---

# 9. HPA x VPA x Cluster Autoscaler — decisão de prova

| Situação | Recurso principal |
|---|---|
| Mais requisições e cada Pod está saudável | HPA |
| Pod está sub/superdimensionado em CPU/memória | VPA |
| Pods extras não cabem nos Nodes de cluster Standard | Cluster Autoscaler |
| Quer menos gestão de Nodes | Autopilot |
| Precisa controlar node pools/máquinas | Standard |

Exemplo integrado:

```text
Tráfego ↑
  ↓
HPA aumenta Pods
  ↓
Pods Pending por falta de capacidade (Standard)
  ↓
Cluster Autoscaler aumenta Nodes
```

Outro cenário:

```text
Pod usa muito mais memória do que request declarado
  ↓
VPA observa histórico
  ↓
recomenda/ajusta sizing conforme update mode
```

---

# 10. Questões estilo ACE

**1.** Uma aplicação recebe picos de requisições. Os Pods atuais funcionam normalmente, mas a empresa precisa aumentar automaticamente a quantidade de réplicas com base em CPU. Qual recurso usar?

**Resposta:** HPA.

**2.** Um Pod possui CPU request de `100m` e consome aproximadamente `80m`. O HPA possui target de 50%. O que representa esse cenário?

**Resposta:** utilização aproximada de 80% do request, acima do target; o HPA pode calcular necessidade de mais réplicas.

**3.** Em um cluster Standard, o HPA criou Pods adicionais, mas eles permanecem `Pending` por falta de capacidade nos Nodes. Qual camada deve ser investigada?

**Resposta:** capacidade dos Nodes/node pools e Cluster Autoscaler.

**4.** A organização quer que o Google gerencie a infraestrutura de Nodes e prefere operar principalmente workloads Kubernetes. Qual modo tende a ser mais apropriado?

**Resposta:** Autopilot.

**5.** O HPA mostra problema para calcular utilização percentual de CPU. Qual configuração deve ser verificada antes de alterar o target?

**Resposta:** `resources.requests.cpu` do workload e disponibilidade da métrica.

---

# 11. Cleanup

```bash
# Remove o HPA para que ele deixe de controlar o número de réplicas.
kubectl delete hpa hpa-demo --ignore-not-found

# Remove o Deployment usado no laboratório de HPA.
kubectl delete deployment hpa-demo --ignore-not-found

# Remove o Deployment usado no troubleshooting de imagem.
kubectl delete deployment quebrado --ignore-not-found

# Remove o arquivo temporário do manifesto.
rm -f hpa-demo.yaml
```

Se o cluster foi criado apenas para esta sessão, exclua-o conforme a Aula 4.

---

# 12. Checklist M/E/P

- [ ] Consigo explicar Autopilot x Standard;
- [ ] Consigo explicar HPA x VPA x Cluster Autoscaler;
- [ ] Entendo por que CPU request é relevante para HPA percentual;
- [ ] Criei HPA com min/max/target;
- [ ] Inspecionei `TARGETS`, réplicas, conditions e events;
- [ ] Observei comportamento de scaling;
- [ ] Removi propositalmente `requests.cpu`;
- [ ] Diagnostiquei o HPA usando evidências;
- [ ] Corrigi sem alterar componentes não relacionados;
- [ ] Diagnostiquei e corrigi `ImagePullBackOff`;
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
| 4.2 | HPA | `P` | `P` |
