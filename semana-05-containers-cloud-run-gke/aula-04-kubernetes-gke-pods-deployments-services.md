# Aula 4 — Kubernetes e GKE: Pods, Deployments e Services

## Objetivos

Ao final, você deverá:
- criar cluster Autopilot;
- criar Deployment;
- escalar Pods;
- expor Service;
- deletar Pod e observar reconciliação;
- diagnosticar selector/endpoint.


> **Custos:** GKE pode gerar cobrança. Cluster deve ser excluído no final.

---

# 1. Conceito

Pod é unidade de execução. Deployment mantém estado desejado de Pods. Service fornece endpoint estável e seleciona Pods por labels.

## Arquitetura mental

```text
GKE
 └─ Deployment
     └─ Pods
Service ── selector ──> Pods
```

---

# 2. Criar

```bash
export REGION=us-central1
gcloud services enable container.googleapis.com

gcloud container clusters create-auto ace-gke \
  --region="$REGION"

gcloud container clusters get-credentials ace-gke \
  --region="$REGION"

kubectl create deployment web --image=nginx:alpine
kubectl scale deployment web --replicas=2
kubectl expose deployment web --port=80 --type=ClusterIP
```

---

# 3. Inspecionar

Antes de provocar qualquer erro, confirme a configuração criada. O troubleshooting desta aula usará **somente elementos que você já observou aqui**.

```bash
kubectl get deployment web
kubectl get pods -l app=web -o wide
kubectl get service web
kubectl get endpoints web
kubectl describe service web
```

---

# 4. Testar

```bash
kubectl run curl --rm -it --restart=Never \
  --image=curlimages/curl -- \
  curl -s http://web
```

---

# 5. Quebrar propositalmente

Altere selector do Service para não corresponder aos Pods:

```bash
kubectl patch service web \
  -p '{"spec":{"selector":{"app":"nome-errado"}}}'

kubectl get endpoints web
```

Agora teste novamente de um pod curl.

---

# 6. Troubleshooting

Agora o erro já foi produzido e os componentes envolvidos já foram apresentados.

**Sintoma:** nome `web` resolve, mas Service não encaminha para Pods/tem endpoints vazios.

**Hipótese:** selector não corresponde às labels dos Pods.

**Evidências:**
```bash
kubectl get service web -o yaml
kubectl get pods --show-labels
kubectl get endpoints web
```

**Causa:** alteramos `spec.selector.app` para `nome-errado`.

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
kubectl patch service web \
  -p '{"spec":{"selector":{"app":"web"}}}'

kubectl get endpoints web
```

---

# 8. Questões estilo ACE

1. Quem mantém réplicas? **Deployment**.
2. Quem fornece endpoint estável? **Service**.
3. Service sem endpoints: primeiro comparar **selector e labels**.

---

# 9. Cleanup

```bash
gcloud container clusters delete ace-gke \
  --region="$REGION" --quiet
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

# Cobertura adicional — StatefulSets e Artifact Registry no GKE

## StatefulSet

Deployment é adequado para réplicas intercambiáveis/stateless. StatefulSet oferece identidade estável e ordenação apropriada para workloads stateful.

```bash
kubectl get statefulsets
```

Não use StatefulSet só porque a aplicação “usa banco”; normalmente o banco pode estar fora do cluster.

## GKE acessando Artifact Registry

Fluxo:

```text
Artifact Registry
      ↓ pull da imagem
GKE node/workload identity + IAM
      ↓
Pod
```

Se ocorrer `ImagePullBackOff` com imagem privada, confirme em ordem:

```bash
kubectl describe pod POD

gcloud artifacts docker images list \
  REGION-docker.pkg.dev/PROJECT/REPOSITORY
```

Só depois investigue a identidade/IAM usada para pull.
