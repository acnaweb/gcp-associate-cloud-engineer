# Aula 2 — Cloud Run Services, Revisions e Scaling

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
export REGION=us-central1
gcloud services enable run.googleapis.com

gcloud run deploy ace-web \
  --image=us-docker.pkg.dev/cloudrun/container/hello \
  --region="$REGION" \
  --allow-unauthenticated
```

---

# 3. Inspecionar

Antes de provocar qualquer erro, confirme a configuração criada. O troubleshooting desta aula usará **somente elementos que você já observou aqui**.

```bash
gcloud run services describe ace-web --region="$REGION"
gcloud run revisions list --service=ace-web --region="$REGION"
```

---

# 4. Testar

```bash
URL=$(gcloud run services describe ace-web \
  --region="$REGION" --format="value(status.url)")
curl "$URL"

gcloud run services update ace-web \
  --region="$REGION" \
  --set-env-vars=VERSAO=v2 \
  --min=0 --max=3

gcloud run revisions list --service=ace-web --region="$REGION"
```

---

# 5. Quebrar propositalmente

Remova acesso público:

```bash
gcloud run services remove-iam-policy-binding ace-web \
  --region="$REGION" \
  --member="allUsers" \
  --role="roles/run.invoker"

curl -i "$URL"
```

---

# 6. Troubleshooting

Agora o erro já foi produzido e os componentes envolvidos já foram apresentados.

**Sintoma:** `HTTP 403`.

**Hipótese:** o serviço continua `Ready`, mas o principal anônimo não tem `run.invoker`.

**Evidências:**
```bash
gcloud run services describe ace-web --region="$REGION" \
  --format="value(status.conditions[0].status)"
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
gcloud run services add-iam-policy-binding ace-web \
  --region="$REGION" \
  --member="allUsers" \
  --role="roles/run.invoker"

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
gcloud run services delete ace-web --region="$REGION" --quiet
```

---


---

# Cobertura ACE ampliada — traffic splitting e versões

## Traffic splitting

Liste revisions:

```bash
gcloud run revisions list --service=ace-web --region=$REGION
```

Depois de possuir duas revisions, você pode dividir tráfego por percentuais:

```bash
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
gcloud run revisions list \
  --service=ace-web \
  --region=us-central1
```

Depois de criar duas revisions, distribua tráfego usando os nomes reais retornados:

```bash
gcloud run services update-traffic ace-web \
  --region=us-central1 \
  --to-revisions=REVISION_V1=90,REVISION_V2=10
```

Inspecione:

```bash
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
