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
# Explicação: Define `PROJECT_ID` com o ID do projeto Google Cloud usado pelos comandos seguintes.
export PROJECT_ID=$(gcloud config get-value project)
# Explicação: Define `REGION` com o valor da região padrão usada pelos recursos do laboratório.
export REGION=us-central1
# Explicação: Define a variável `REPO` usada nas próximas etapas do laboratório.
export REPO=ace-containers

# Explicação: Habilita a API/serviço indicado no projeto ativo para permitir o uso do recurso no laboratório.
gcloud services enable artifactregistry.googleapis.com

# Explicação: Cria um repositório no Artifact Registry para armazenar imagens/artefatos.
gcloud artifacts repositories create "$REPO" \
  --repository-format=docker \
  --location="$REGION"

# Explicação: Exibe conteúdo de arquivo ou cria conteúdo via redirecionamento/heredoc, conforme a sintaxe usada.
cat > Dockerfile <<'EOF'
FROM nginx:alpine
RUN echo "ACE Container Lab" > /usr/share/nginx/html/index.html
EOF

# Explicação: Constrói uma imagem Docker a partir do Dockerfile e atribui a tag informada.
docker build -t ace-web:v1 .
# Explicação: Cria e executa um container a partir da imagem indicada com as opções fornecidas.
docker run -d --rm -p 8080:80 --name ace-local ace-web:v1
# Explicação: Envia uma requisição HTTP ao endpoint informado para testar conectividade, resposta ou comportamento da aplicação.
curl http://localhost:8080
# Explicação: Executa `docker stop ace-local` nesta etapa para aplicar ou inspecionar a configuração indicada.
docker stop ace-local
```

---

# 3. Inspecionar

Antes de provocar qualquer erro, confirme a configuração criada. O troubleshooting desta aula usará **somente elementos que você já observou aqui**.

```bash
# Explicação: Exibe detalhes do repositório Artifact Registry.
gcloud artifacts repositories describe "$REPO" --location="$REGION"
# Explicação: Lista imagens Docker disponíveis localmente.
docker images | head
```

---

# 4. Testar

Configure autenticação e push:

```bash
# Explicação: Configura o Docker para autenticar no Artifact Registry da região indicada.
gcloud auth configure-docker "$REGION-docker.pkg.dev" --quiet

# Explicação: Cria uma nova tag apontando para a mesma imagem local, normalmente com o endereço do registry.
docker tag ace-web:v1 \
 "$REGION-docker.pkg.dev/$PROJECT_ID/$REPO/web:v1"

# Explicação: Envia a imagem/tag local para o registry configurado.
docker push \
 "$REGION-docker.pkg.dev/$PROJECT_ID/$REPO/web:v1"

# Explicação: Lista imagens Docker armazenadas no Artifact Registry.
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
# Explicação: Exibe conteúdo de arquivo ou cria conteúdo via redirecionamento/heredoc, conforme a sintaxe usada.
cat ~/.docker/config.json | grep "$REGION-docker.pkg.dev" || true
# Explicação: Lista as identidades autenticadas e mostra qual conta está ativa no `gcloud`.
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
# Explicação: Configura o Docker para autenticar no Artifact Registry da região indicada.
gcloud auth configure-docker "$REGION-docker.pkg.dev" --quiet
# Explicação: Envia a imagem/tag local para o registry configurado.
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
# Explicação: Exclui o repositório Artifact Registry e seus artefatos.
gcloud artifacts repositories delete "$REPO" \
  --location="$REGION" --quiet
# Explicação: Remove o arquivo/diretório temporário indicado durante correção ou cleanup.
rm -f Dockerfile
# Explicação: Executa `docker image rm ace-web:v1 2>/dev/null || true` nesta etapa para aplicar ou inspecionar a configuração indicada.
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
| 4.2 | GKE acesso Artifact Registry | `P` | `E/P*` |
