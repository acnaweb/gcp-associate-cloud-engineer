# Aula 1 — Containers e Artifact Registry

## Objetivos

Ao final desta aula, você deverá:

- Construir imagem Docker;
- Criar Artifact Registry;
- Autenticar Docker;
- Push/pull de imagem;

---

# 1. Modelo mental

```text
Source ── docker build ──> Image
                         └─ push ──> Artifact Registry
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

```bash
export PROJECT_ID=$(gcloud config get-value project)
export REGION=us-central1
export REPO=ace-containers

gcloud services enable artifactregistry.googleapis.com

gcloud artifacts repositories create $REPO \
  --repository-format=docker \
  --location=$REGION

cat > Dockerfile <<'EOF'
FROM nginx:alpine
RUN echo 'ACE Container Lab' > /usr/share/nginx/html/index.html
EOF

gcloud auth configure-docker $REGION-docker.pkg.dev --quiet

docker build -t $REGION-docker.pkg.dev/$PROJECT_ID/$REPO/web:v1 .
docker push $REGION-docker.pkg.dev/$PROJECT_ID/$REPO/web:v1

gcloud artifacts docker images list \
  $REGION-docker.pkg.dev/$PROJECT_ID/$REPO
```

---

# 4. Testes e falhas propositais

- Tente push antes de `gcloud auth configure-docker`.
- Tag não é digest; digest identifica conteúdo imutável.
- Artifact Registry armazena artefatos; não executa containers.

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

- Image é template imutável; container é instância em execução.
- Artifact Registry substitui Container Registry em novos fluxos.
- IAM controla push/pull.

---

# 7. Questões estilo ACE

- Onde armazenar imagens privadas no GCP? → Artifact Registry.
- Precisa executar imagem serverless? → Cloud Run, não Artifact Registry.

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

