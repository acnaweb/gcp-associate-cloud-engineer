# Aula 1 — Containers e Artifact Registry

## Objetivos

Ao final, você deverá:
- criar imagem Docker;
- executar localmente;
- criar repositório Artifact Registry;
- autenticar Docker;
- push e pull;
- diagnosticar push sem autenticação/configuração.


---

# 1. Conceito

Imagem é artefato imutável por conteúdo; container é uma execução. Artifact Registry armazena imagens e outros artefatos, mas não os executa.

## Arquitetura mental

```text
Dockerfile → image → Artifact Registry
                    ↓
              Cloud Run/GKE
```

---

# 2. Criar

```bash
export PROJECT_ID=$(gcloud config get-value project)
export REGION=us-central1
export REPO=ace-containers

gcloud services enable artifactregistry.googleapis.com

gcloud artifacts repositories create "$REPO" \
  --repository-format=docker \
  --location="$REGION"

cat > Dockerfile <<'EOF'
FROM nginx:alpine
RUN echo "ACE Container Lab" > /usr/share/nginx/html/index.html
EOF

docker build -t ace-web:v1 .
docker run -d --rm -p 8080:80 --name ace-local ace-web:v1
curl http://localhost:8080
docker stop ace-local
```

---

# 3. Inspecionar

Antes de provocar qualquer erro, confirme a configuração criada. O troubleshooting desta aula usará **somente elementos que você já observou aqui**.

```bash
gcloud artifacts repositories describe "$REPO" --location="$REGION"
docker images | head
```

---

# 4. Testar

Configure autenticação e push:

```bash
gcloud auth configure-docker "$REGION-docker.pkg.dev" --quiet

docker tag ace-web:v1 \
 "$REGION-docker.pkg.dev/$PROJECT_ID/$REPO/web:v1"

docker push \
 "$REGION-docker.pkg.dev/$PROJECT_ID/$REPO/web:v1"

gcloud artifacts docker images list \
 "$REGION-docker.pkg.dev/$PROJECT_ID/$REPO"
```

---

# 5. Quebrar propositalmente

Remova temporariamente/edite a configuração de autenticação somente se souber restaurá-la, ou use um hostname de região ainda não configurado para observar que Docker não possui credencial helper correspondente.

Alternativa segura: explique o erro usando `docker config` e não danifique credenciais compartilhadas.

---

# 6. Troubleshooting

Agora o erro já foi produzido e os componentes envolvidos já foram apresentados.

**Sintoma esperado:** push pode retornar `unauthorized`/`denied`.

**Hipótese:** Docker não está autenticado para o host do Artifact Registry.

**Evidências já ensinadas:**
```bash
cat ~/.docker/config.json | grep "$REGION-docker.pkg.dev" || true
gcloud auth list
```

**Causa:** ausência de credential helper/credencial para o registry.

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
gcloud auth configure-docker "$REGION-docker.pkg.dev" --quiet
docker push "$REGION-docker.pkg.dev/$PROJECT_ID/$REPO/web:v1"
```

---

# 8. Questões estilo ACE

1. Onde armazenar imagens privadas? **Artifact Registry**.
2. Artifact Registry executa containers? **Não**.
3. Tag e digest são equivalentes? **Não**.

---

# 9. Cleanup

```bash
gcloud artifacts repositories delete "$REPO" \
  --location="$REGION" --quiet
rm -f Dockerfile
docker image rm ace-web:v1 2>/dev/null || true
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
