# Aula 5 — GKE Autopilot, Standard, Autoscaling e Troubleshooting

## Objetivos

Ao final, você deverá:
- comparar Autopilot e Standard;
- reconhecer HPA x cluster autoscaling;
- interpretar `Pending`, `ImagePullBackOff` e `CrashLoopBackOff`;
- provocar e corrigir `ImagePullBackOff`.


---

# 1. Conceito

Autopilot delega mais gestão de infraestrutura ao Google. Standard dá mais controle sobre nodes/node pools. HPA escala workloads/Pods; cluster autoscaling ajusta capacidade de nodes em Standard quando configurado.

## Arquitetura mental

```text
Deployment
  └─ Pod status
      ├─ Running
      ├─ ImagePullBackOff
      ├─ CrashLoopBackOff
      └─ Pending
```

---

# 2. Criar

Use o cluster da aula anterior se ainda existir ou crie um pequeno Autopilot de laboratório.

Crie Deployment quebrado:

```bash
kubectl create deployment quebrado \
  --image=nginx:tag-que-nao-existe-ace
```

---

# 3. Inspecionar

Antes de provocar qualquer erro, confirme a configuração criada. O troubleshooting desta aula usará **somente elementos que você já observou aqui**.

```bash
kubectl get deployment quebrado
kubectl get pods -l app=quebrado
kubectl describe pod -l app=quebrado
kubectl get events --sort-by=.lastTimestamp | tail -30
```

---

# 4. Testar

Observe o pod por alguns minutos:

```bash
kubectl get pods -l app=quebrado -w
```

O estado deverá apontar problema ao obter a imagem.

---

# 5. Quebrar propositalmente

A própria imagem inexistente é a falha proposital. Não adicione uma segunda falha antes de diagnosticar a primeira.

---

# 6. Troubleshooting

Agora o erro já foi produzido e os componentes envolvidos já foram apresentados.

**Sintoma:** `ImagePullBackOff`/`ErrImagePull`.

**Hipótese:** image/tag não existe ou registry não pode ser acessado.

**Evidências:**
```bash
kubectl describe pod -l app=quebrado
kubectl get events --sort-by=.lastTimestamp | tail -30
```

**Causa:** `nginx:tag-que-nao-existe-ace` foi definido deliberadamente.

Como o evento indica `not found`, não é necessário começar por CPU, HPA ou Service.

Use sempre:

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

# 7. Corrigir

```bash
kubectl set image deployment/quebrado \
  nginx=nginx:alpine

kubectl rollout status deployment/quebrado
kubectl get pods -l app=quebrado
```

---

# 8. Questões estilo ACE

1. Quer maior abstração de nodes? **Autopilot**.
2. Precisa controle profundo de node pools? **Standard**.
3. `ImagePullBackOff`: olhar **image/tag/registry/credential**, começando pelos eventos.

---

# 9. Cleanup

```bash
kubectl delete deployment quebrado --ignore-not-found
# Exclua o cluster se foi criado exclusivamente para esta aula.
```

---

# 10. Checklist

- [ ] Entendi os conceitos usados no laboratório;
- [ ] Criei o recurso;
- [ ] Inspecionei estado e configuração;
- [ ] Testei o comportamento esperado;
- [ ] Provoquei a falha descrita;
- [ ] Diagnostiquei usando evidências;
- [ ] Corrigi sem aumentar privilégios ou alterar componentes desnecessários;
- [ ] Consigo relacionar o cenário a uma questão ACE;
- [ ] Executei o cleanup.

---

# Cobertura adicional — regional/private clusters, node pools, HPA e VPA

## Tipos/decisões de cluster

```text
Autopilot
→ maior gerenciamento pelo Google

Standard
→ controle de nodes/node pools

Regional cluster
→ control plane/recursos distribuídos regionalmente conforme arquitetura do GKE

Private cluster
→ restringe exposição de nodes/endpoints conforme configuração

GKE Enterprise
→ recursos de gerenciamento de frotas/multicluster/enterprise
```

## Node pools

No Standard:

```bash
gcloud container node-pools list \
  --cluster=CLUSTER \
  --location=LOCATION
```

Node pool é agrupamento de nodes com configuração comum.

## HPA x VPA

```text
HPA
→ altera quantidade de Pods

VPA
→ recomenda/ajusta requests de CPU/memória, conforme modo/configuração

Cluster autoscaler
→ altera quantidade de nodes em node pools suportados
```

Não confunda as três camadas de escala.
