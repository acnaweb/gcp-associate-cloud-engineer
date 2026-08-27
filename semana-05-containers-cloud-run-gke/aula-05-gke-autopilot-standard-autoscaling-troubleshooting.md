# Aula 5 — GKE Autopilot, Standard, Autoscaling e Troubleshooting

## Objetivos

Ao final desta aula, você deverá:

- Comparar Autopilot e Standard;
- Entender HPA/cluster autoscaling;
- Praticar troubleshooting kubectl;
- Escolher Cloud Run x GKE;

---

# 1. Modelo mental

```text
Autopilot → Google gerencia mais infraestrutura
Standard  → maior controle de nodes/node pools

HPA → Pods
Cluster autoscaler → Nodes (Standard)
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

Use cluster existente ou crie Autopilot temporário.

Troubleshooting:
```bash
kubectl get pods -A
kubectl describe pod POD_NAME
kubectl logs POD_NAME
kubectl get events --sort-by=.lastTimestamp
kubectl get svc
kubectl get endpoints
```

Crie falha de imagem:
```bash
kubectl create deployment quebrado \
  --image=nginx:imagem-que-nao-existe
kubectl get pods
kubectl describe pod -l app=quebrado
```

Observe `ImagePullBackOff`/erros relacionados e corrija:
```bash
kubectl set image deployment/quebrado \
  nginx=nginx:alpine
```

HPA conceitual/prático quando metrics server disponível:
```bash
kubectl autoscale deployment web \
  --cpu-percent=60 --min=1 --max=5
```

---

# 4. Testes e falhas propositais

- ImagePullBackOff → imagem/credencial/tag.
- CrashLoopBackOff → app inicia e falha repetidamente.
- Pending → scheduling/recursos/policies.
- Service sem endpoints → labels/selectors/readiness.

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

- Autopilot reduz operação de nodes.
- Standard oferece maior controle.
- Cloud Run é mais simples para request-driven stateless sem necessidade de Kubernetes.
- GKE quando há requisitos Kubernetes/orquestração avançada.

---

# 7. Questões estilo ACE

- Equipe não quer gerenciar nodes e aceita constraints Autopilot? → Autopilot.
- Precisa customização profunda de node pools? → Standard.

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

