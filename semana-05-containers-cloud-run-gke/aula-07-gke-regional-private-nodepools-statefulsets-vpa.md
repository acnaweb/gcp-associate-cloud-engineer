# Aula 7 — GKE Regional, Private, Node Pools, StatefulSets, HPA e VPA

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
