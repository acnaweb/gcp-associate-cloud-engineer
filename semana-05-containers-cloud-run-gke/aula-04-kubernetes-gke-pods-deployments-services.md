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
# Explicação: Define `REGION` com o valor da região padrão usada pelos recursos do laboratório.
export REGION=us-central1
# Explicação: Habilita a API/serviço indicado no projeto ativo para permitir o uso do recurso no laboratório.
gcloud services enable container.googleapis.com

# Explicação: Cria um cluster GKE Autopilot; o Google gerencia os nodes e grande parte da infraestrutura do cluster.
gcloud container clusters create-auto ace-gke \
  --region="$REGION"

# Explicação: Obtém as credenciais do cluster e atualiza o kubeconfig para que o `kubectl` se conecte a ele.
gcloud container clusters get-credentials ace-gke \
  --region="$REGION"

# Explicação: Cria um Deployment Kubernetes usando a imagem de container informada.
kubectl create deployment web --image=nginx:alpine
# Explicação: Altera o número desejado de réplicas do Deployment.
kubectl scale deployment web --replicas=2
# Explicação: Cria um Service para expor os Pods gerenciados pelo Deployment na porta e tipo definidos.
kubectl expose deployment web --port=80 --type=ClusterIP
```

---

# 3. Inspecionar

Antes de provocar qualquer erro, confirme a configuração criada. O troubleshooting desta aula usará **somente elementos que você já observou aqui**.

```bash
# Explicação: Lista/consulta recursos Kubernetes; filtros e flags controlam namespace, labels e formato da saída.
kubectl get deployment web
# Explicação: Lista/consulta recursos Kubernetes; filtros e flags controlam namespace, labels e formato da saída.
kubectl get pods -l app=web -o wide
# Explicação: Lista/consulta recursos Kubernetes; filtros e flags controlam namespace, labels e formato da saída.
kubectl get service web
# Explicação: Lista/consulta recursos Kubernetes; filtros e flags controlam namespace, labels e formato da saída.
kubectl get endpoints web
# Explicação: Mostra detalhes e eventos do recurso Kubernetes, útil para troubleshooting.
kubectl describe service web
```

---

# 4. Testar

```bash
# Explicação: Cria um Pod temporário para executar o container/comando informado; neste material ele é usado principalmente como cliente de teste dentro do cluster.
kubectl run curl --rm -it --restart=Never \
  --image=curlimages/curl -- \
  curl -s http://web
```

---

# 5. Quebrar propositalmente

Altere selector do Service para não corresponder aos Pods:

```bash
# Explicação: Altera parcialmente um recurso Kubernetes existente sem reaplicar todo o manifesto.
kubectl patch service web \
  -p '{"spec":{"selector":{"app":"nome-errado"}}}'

# Explicação: Lista/consulta recursos Kubernetes; filtros e flags controlam namespace, labels e formato da saída.
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
# Explicação: Lista/consulta recursos Kubernetes; filtros e flags controlam namespace, labels e formato da saída.
kubectl get service web -o yaml
# Explicação: Lista/consulta recursos Kubernetes; filtros e flags controlam namespace, labels e formato da saída.
kubectl get pods --show-labels
# Explicação: Lista/consulta recursos Kubernetes; filtros e flags controlam namespace, labels e formato da saída.
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
# Explicação: Altera parcialmente um recurso Kubernetes existente sem reaplicar todo o manifesto.
kubectl patch service web \
  -p '{"spec":{"selector":{"app":"web"}}}'

# Explicação: Lista/consulta recursos Kubernetes; filtros e flags controlam namespace, labels e formato da saída.
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
# Explicação: Exclui o cluster GKE para encerrar a cobrança dos recursos associados.
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
# Explicação: Lista/consulta recursos Kubernetes; filtros e flags controlam namespace, labels e formato da saída.
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
# Explicação: Mostra detalhes e eventos do recurso Kubernetes, útil para troubleshooting.
kubectl describe pod POD

# Explicação: Lista imagens Docker armazenadas no Artifact Registry.
gcloud artifacts docker images list \
  REGION-docker.pkg.dev/PROJECT/REPOSITORY
```

Só depois investigue a identidade/IAM usada para pull.
