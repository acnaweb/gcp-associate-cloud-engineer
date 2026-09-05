# Aula 2 — Cloud Run Services, Revisions e Scaling

## Nível de cobertura M/E/P

```text
Cloud Run deploy/revisions/traffic split/autoscaling: P
```


## Objetivos

Ao final, você deverá:
- deployar serviço;
- identificar URL;
- criar nova revision;
- configurar min/max instances;
- testar autenticação pública/privada;
- diagnosticar 403 por invoker.


---

# 1. Conceito

Cloud Run executa containers serverless. Cada alteração de imagem/configuração cria uma revision imutável. IAM controla quem invoca o serviço. Scaling define quantidade de instâncias, inclusive zero quando permitido.

## Arquitetura mental

```text
Client
  ↓ IAM invoker
Cloud Run Service
 ├─ revision 1
 └─ revision 2
      └─ autoscaling
```

---

# 2. Criar

```bash
# Explicação: Define `REGION` com o valor da região padrão usada pelos recursos do laboratório.
export REGION=us-central1
# Explicação: Habilita a API/serviço indicado no projeto ativo para permitir o uso do recurso no laboratório.
gcloud services enable run.googleapis.com

# Explicação: Implanta uma nova revisão do serviço Cloud Run a partir da imagem/configuração informada.
gcloud run deploy ace-web \
  --image=us-docker.pkg.dev/cloudrun/container/hello \
  --region="$REGION" \
  --allow-unauthenticated
```

---

# 3. Inspecionar

Antes de provocar qualquer erro, confirme a configuração criada. O troubleshooting desta aula usará **somente elementos que você já observou aqui**.

```bash
# Explicação: Exibe configuração e status do serviço Cloud Run, incluindo URL, revisão e parâmetros de scaling.
gcloud run services describe ace-web --region="$REGION"
# Explicação: Lista revisões de um serviço Cloud Run para acompanhar versões implantadas.
gcloud run revisions list --service=ace-web --region="$REGION"
```

---

# 4. Testar

```bash
# Explicação: Define a variável `URL` usada nas próximas etapas do laboratório.
URL=$(gcloud run services describe ace-web \
  --region="$REGION" --format="value(status.url)")
# Explicação: Envia uma requisição HTTP ao endpoint informado para testar conectividade, resposta ou comportamento da aplicação.
curl "$URL"

# Explicação: Atualiza a configuração do serviço Cloud Run, como variáveis, min/max instances ou concurrency.
gcloud run services update ace-web \
  --region="$REGION" \
  --set-env-vars=VERSAO=v2 \
  --min=0 --max=3

# Explicação: Lista revisões de um serviço Cloud Run para acompanhar versões implantadas.
gcloud run revisions list --service=ace-web --region="$REGION"
```

---

# 5. Quebrar propositalmente

Remova acesso público:

```bash
# Explicação: Executa `gcloud run services remove-iam-policy-binding ace-web --region="$REGION" --member="a…` nesta etapa para aplicar ou inspecionar a configuração indicada.
gcloud run services remove-iam-policy-binding ace-web \
  --region="$REGION" \
  --member="allUsers" \
  --role="roles/run.invoker"

# Explicação: Envia uma requisição HTTP ao endpoint informado para testar conectividade, resposta ou comportamento da aplicação.
curl -i "$URL"
```

---

# 6. Troubleshooting

Agora o erro já foi produzido e os componentes envolvidos já foram apresentados.

**Sintoma:** `HTTP 403`.

**Hipótese:** o serviço continua `Ready`, mas o principal anônimo não tem `run.invoker`.

**Evidências:**
```bash
# Explicação: Exibe configuração e status do serviço Cloud Run, incluindo URL, revisão e parâmetros de scaling.
gcloud run services describe ace-web --region="$REGION" \
  --format="value(status.conditions[0].status)"
# Explicação: Executa `gcloud run services get-iam-policy ace-web --region="$REGION"` nesta etapa para aplicar ou inspecionar a configuração indicada.
gcloud run services get-iam-policy ace-web --region="$REGION"
```

**Causa:** removemos deliberadamente o binding `allUsers → roles/run.invoker`.

Não é falha de revision nem scaling.

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

Restaure acesso público:

```bash
# Explicação: Executa `gcloud run services add-iam-policy-binding ace-web --region="$REGION" --member="allU…` nesta etapa para aplicar ou inspecionar a configuração indicada.
gcloud run services add-iam-policy-binding ace-web \
  --region="$REGION" \
  --member="allUsers" \
  --role="roles/run.invoker"

# Explicação: Envia uma requisição HTTP ao endpoint informado para testar conectividade, resposta ou comportamento da aplicação.
curl "$URL"
```

---

# 8. Questões estilo ACE

1. Container HTTP stateless sem cluster? **Cloud Run**.
2. Mudou env var. Surge nova revision? **Sim**.
3. Serviço Ready, mas anônimo recebe 403: verificar **IAM Invoker**.

---

# 9. Cleanup

```bash
# Explicação: Exclui o serviço Cloud Run e suas revisões do laboratório.
gcloud run services delete ace-web --region="$REGION" --quiet
```

---


---

# Cobertura ACE ampliada — traffic splitting e versões

## Traffic splitting

Liste revisions:

```bash
# Explicação: Lista revisões de um serviço Cloud Run para acompanhar versões implantadas.
gcloud run revisions list --service=ace-web --region=$REGION
```

Depois de possuir duas revisions, você pode dividir tráfego por percentuais:

```bash
# Explicação: Redistribui o tráfego do Cloud Run entre revisões conforme percentuais/tags informados.
gcloud run services update-traffic ace-web \
  --region=$REGION \
  --to-revisions=REVISION_V1=90,REVISION_V2=10
```

Casos:

```text
100% nova revision → rollout direto
90/10             → canary
50/50             → comparação controlada
rollback          → redirecionar tráfego à revision anterior
```

## Autoscaling de Cloud Run

Além de min/max instances, entenda concurrency e CPU como fatores do comportamento de scaling conforme configuração/plataforma.

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

# Cobertura adicional — Traffic Splitting e novas versões

A prova inclui gerenciar novas versões/revisions e divisão de tráfego.

Liste revisions:

```bash
# Explicação: Lista revisões de um serviço Cloud Run para acompanhar versões implantadas.
gcloud run revisions list \
  --service=ace-web \
  --region=us-central1
```

Depois de criar duas revisions, distribua tráfego usando os nomes reais retornados:

```bash
# Explicação: Redistribui o tráfego do Cloud Run entre revisões conforme percentuais/tags informados.
gcloud run services update-traffic ace-web \
  --region=us-central1 \
  --to-revisions=REVISION_V1=90,REVISION_V2=10
```

Inspecione:

```bash
# Explicação: Exibe configuração e status do serviço Cloud Run, incluindo URL, revisão e parâmetros de scaling.
gcloud run services describe ace-web \
  --region=us-central1 \
  --format='yaml(status.traffic)'
```

Modelo mental:

```text
Revision
→ versão imutável de código/configuração

Traffic split
→ percentual de requisições por revision

Autoscaling
→ quantidade de instâncias
```


---

## Laboratório completo — Autoscaling do Cloud Run

Esta seção eleva o tópico de **mencionado/explicado** para **praticado**.

### 1. Conceitos que influenciam scaling

```text
Requests
   ↓
Concurrency por instância
   ↓
necessidade de novas instâncias
```

Parâmetros essenciais:

```text
min instances
→ capacidade mínima mantida pronta
→ pode reduzir cold start
→ pode gerar custo mesmo sem tráfego

max instances
→ limite de instâncias
→ protege custo e dependências downstream

concurrency
→ quantas requisições simultâneas uma instância pode atender
```

### 2. Configurar

```bash
# Explicação: Define `REGION` com o valor da região padrão usada pelos recursos do laboratório.
export REGION=us-central1

# Explicação: Atualiza a configuração do serviço Cloud Run, como variáveis, min/max instances ou concurrency.
gcloud run services update ace-web \
  --region="$REGION" \
  --min=1 \
  --max=3 \
  --concurrency=10
```

### 3. Inspecionar

```bash
# Explicação: Exibe configuração e status do serviço Cloud Run, incluindo URL, revisão e parâmetros de scaling.
gcloud run services describe ace-web \
  --region="$REGION" \
  --format='yaml(spec.template.metadata.annotations,spec.template.spec.containerConcurrency)'
```

No Console, abra:

```text
Cloud Run → ace-web → Edit & deploy new revision → Scaling
```

Confirme `min`, `max` e concurrency.

### 4. Testar

Faça várias requisições em paralelo:

```bash
# Explicação: Define a variável `URL` usada nas próximas etapas do laboratório.
URL=$(gcloud run services describe ace-web \
  --region="$REGION" \
  --format='value(status.url)')

# Explicação: Executa `seq 1 30 | xargs -n1 -P10 -I{} curl -s -o /dev/null "$URL"` nesta etapa para aplicar ou inspecionar a configuração indicada.
seq 1 30 | xargs -n1 -P10 -I{} curl -s -o /dev/null "$URL"
```

Depois inspecione métricas de request/instance no Cloud Monitoring/Cloud Run Metrics.

> O número de instâncias observado depende de carga, duração da requisição e política de autoscaling; não espere exatamente 3 apenas porque `max=3`.

### 5. Quebrar propositalmente

Reduza `max` para 1:

```bash
# Explicação: Atualiza a configuração do serviço Cloud Run, como variáveis, min/max instances ou concurrency.
gcloud run services update ace-web \
  --region="$REGION" \
  --max=1
```

Repita o teste paralelo.

### 6. Troubleshooting

```text
Sintoma
→ latência/espera aumenta sob concorrência

Hipótese
→ capacidade máxima do serviço foi limitada

Evidência
→ configuração max instances = 1
→ métricas de requests/instances

Causa
→ limite imposto deliberadamente

Correção
→ ajustar max/concurrency de acordo com requisito e capacidade downstream
```

### 7. Corrigir

```bash
# Explicação: Atualiza a configuração do serviço Cloud Run, como variáveis, min/max instances ou concurrency.
gcloud run services update ace-web \
  --region="$REGION" \
  --min=0 \
  --max=3 \
  --concurrency=10
```

### Pegadinha ACE

```text
max instances
≠ quantidade fixa de instâncias

min instances
≠ requests mínimos

traffic splitting
≠ autoscaling
```

---

<!-- MEP-ACCEPTANCE-V8 -->
# Critério de aceite M/E/P desta aula

> Esta seção não substitui o conteúdo acima; ela explicita o critério usado na auditoria da baseline v8.

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
| 3.3 | Deploy Cloud Run | `P` | `P` |
| 4.3 | Novas revisions do Cloud Run | `P` | `P` |
| 4.3 | Traffic splitting | `P` | `P` |
| 4.3 | Cloud Run autoscaling parameters | `P` | `P` |
