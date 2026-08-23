# Aula 1 — Containers e Artifact Registry

## Objetivos

Ao final desta aula, você deverá:

- Entender o que é um container;
- Diferenciar image e container;
- Entender Dockerfile em nível conceitual;
- Entender Artifact Registry;
- Publicar uma imagem;
- Preparar uma imagem para Cloud Run e GKE.

---

# 1. Container

Um container empacota aplicação e dependências.

```text
Application
    │
    ├── Runtime
    ├── Libraries
    └── Dependencies
         │
         ▼
      Container
```

---

# 2. Image x Container

```text
Image
  │
  │ instantiate
  ▼
Container
```

## Image

Artefato imutável usado como base.

## Container

Instância em execução da image.

---

# 3. Dockerfile

Exemplo:

```dockerfile
FROM nginx:alpine

COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80
```

Construir:

```bash
docker build -t ace-web:v1 .
```

Executar:

```bash
docker run -p 8080:80 ace-web:v1
```

---

# 4. Registry

Uma image precisa ser armazenada em um registry.

No Google Cloud, use:

```text
Artifact Registry
```

Modelo:

```text
Source Code
    │
    ▼
Docker Build
    │
    ▼
Container Image
    │
    ▼
Artifact Registry
    │
    ├── Cloud Run
    └── GKE
```

---

# 5. Habilitar APIs

```bash
gcloud services enable artifactregistry.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable container.googleapis.com
```

---

# 6. Criar repositório Docker

```bash
gcloud artifacts repositories create ace-containers \
  --repository-format=docker \
  --location=southamerica-east1 \
  --description="ACE container images"
```

---

# 7. Listar repositórios

```bash
gcloud artifacts repositories list
```

---

# 8. Configurar autenticação Docker

```bash
gcloud auth configure-docker \
  southamerica-east1-docker.pkg.dev
```

---

# 9. Nome da imagem

Formato:

```text
REGION-docker.pkg.dev/PROJECT_ID/REPOSITORY/IMAGE:TAG
```

Exemplo:

```text
southamerica-east1-docker.pkg.dev/meu-projeto/ace-containers/ace-web:v1
```

---

# 10. Tag

```bash
PROJECT_ID=$(gcloud config get-value project)

docker tag ace-web:v1 \
  southamerica-east1-docker.pkg.dev/$PROJECT_ID/ace-containers/ace-web:v1
```

---

# 11. Push

```bash
docker push \
  southamerica-east1-docker.pkg.dev/$PROJECT_ID/ace-containers/ace-web:v1
```

---

# 12. Listar imagens

```bash
gcloud artifacts docker images list \
  southamerica-east1-docker.pkg.dev/$PROJECT_ID/ace-containers
```

---

# 13. Tags e versionamento

Evite depender apenas de:

```text
latest
```

Prefira tags identificáveis:

```text
v1
v1.1
2026-08-23
commit-a1b2c3
```

---

# 14. Imutabilidade

Uma prática importante:

```text
Build once
   ↓
Store image
   ↓
Promote same artifact
```

Evite reconstruir imagens diferentes para cada ambiente sem necessidade.

---

# 15. Questões Estilo ACE

## Questão 1

Onde armazenar imagens Docker privadas no Google Cloud?

**Resposta:** Artifact Registry.

## Questão 2

Qual a diferença entre image e container?

**Resposta:** image é o artefato; container é uma instância em execução.

## Questão 3

Cloud Run precisa receber o código-fonte diretamente?

**Resposta:** conceitualmente, ele executa workloads empacotados em containers; o fluxo pode envolver build automático, mas o runtime executa imagens.

---

# 16. Checklist

- [ ] Entendo container
- [ ] Entendo image
- [ ] Entendo Dockerfile
- [ ] Sei o papel do Artifact Registry
- [ ] Sei criar repositório
- [ ] Sei publicar imagem
