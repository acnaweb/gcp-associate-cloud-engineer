# Aula 1 — Containers e Artifact Registry

> **Semana 5 — Containers, Cloud Run e GKE**  
> **Foco:** construir, testar, publicar, inspecionar e recuperar uma container image. Cloud Run e GKE serão estudados nas próximas aulas.

## Objetivos

Ao final desta aula, você deverá:

- Explicar container, image, registry e a diferença entre container e máquina virtual;
- Identificar as instruções fundamentais de um Dockerfile;
- Construir uma image e executar/testar um container localmente;
- Explicar o papel do Artifact Registry e os formatos de repositório;
- Criar, listar e inspecionar um repositório Docker no Google Cloud;
- Configurar autenticação Docker para um host regional do Artifact Registry;
- Aplicar tag, publicar, listar, inspecionar e baixar uma image;
- Diferenciar tag e digest e explicar versionamento e imutabilidade;
- Identificar permissões IAM necessárias para push e pull;
- Provocar uma falha controlada de publicação, diagnosticar e corrigir;
- Explicar como Cloud Run e GKE consomem images sem implantá-los nesta aula;
- Remover os recursos criados e conferir o cleanup.

## 1. Conceito e arquitetura

**Container:** processo isolado que executa uma aplicação com suas dependências, compartilhando o kernel do host. **Image:** pacote de camadas usado para criar containers. **Registry:** serviço que armazena e distribui images. **Repository:** agrupamento de artefatos dentro do registry.

```text
Código + Dockerfile
        |
        v
    docker build
        |
        v
   Image local (tag)
        |
        +--> docker run --> container --> curl
        |
        v
     docker tag
        |
        v
   docker push (IAM + auth)
        |
        v
 Artifact Registry / repositório Docker
        |
        +--> Cloud Run (Aula 2)
        |
        +--> GKE (Aulas 4–5)
```

| Elemento | Responsabilidade | Exemplo |
|---|---|---|
| Dockerfile | Receita de build | `FROM`, `COPY`, `EXPOSE` |
| Image | Artefato versionado | `ace-web:v1` |
| Container | Instância em execução | `docker run` |
| Artifact Registry | Armazenar e distribuir | `REGION-docker.pkg.dev` |
| Cloud Run/GKE | Executar workloads | Estudados posteriormente |

Uma VM virtualiza uma máquina e normalmente contém seu próprio kernel de sistema operacional; containers isolam processos usando o kernel do host. Containers não substituem todas as necessidades de isolamento de VMs.

## 2. Pré-requisitos e custos

- Projeto GCP com faturamento habilitado e permissão para ativar API/criar repositório.
- `gcloud`, `docker`, `curl` e shell Bash.
- Docker Engine acessível (`docker info` deve funcionar).
- Conta com permissão para push no repositório; para operações administrativas de criação/exclusão, privilégios adicionais.
- Cloud Shell pode ser usado, mas seu ambiente e disponibilidade de daemon Docker devem ser verificados; não presuma que `docker run` funcionará em qualquer terminal.
- O Artifact Registry cobra armazenamento e pode cobrar tráfego. Use imagens pequenas e execute o cleanup.

**IAM — menor privilégio:** `roles/artifactregistry.reader` permite pull/listagem; `roles/artifactregistry.writer` permite push. Criar e excluir repositórios exige permissões administrativas adicionais, por exemplo `roles/artifactregistry.admin` em um projeto de laboratório. Não conceda esse papel automaticamente a desenvolvedores.

## 3. Preparar e inspecionar o ambiente

```bash
# Identifica o projeto configurado.
export PROJECT_ID="$(gcloud config get-value project)"
# Define a região de publicação do repositório.
export REGION="southamerica-east1"
# Define nomes exclusivos para este laboratório.
export REPO="ace-containers-lab"
export IMAGE="ace-web"
export TAG="v1"
# Monta o host e o nome completo da image remota.
export HOST="${REGION}-docker.pkg.dev"
export REMOTE_IMAGE="${HOST}/${PROJECT_ID}/${REPO}/${IMAGE}:${TAG}"
# Inspeciona o projeto, a conta e o Docker.
echo "PROJECT_ID=$PROJECT_ID"
gcloud auth list --filter="status:ACTIVE"
docker version
docker info --format '{{.ServerVersion}}'
```

**Esperado:** `PROJECT_ID` não vazio, uma conta ativa e um servidor Docker respondendo. Se `docker info` falhar, resolva o daemon/permissões antes do laboratório; não execute `sudo docker` indiscriminadamente, pois ele pode usar outro arquivo de credenciais.

```bash
# Confere se a região é oferecida pelo Artifact Registry.
gcloud artifacts locations list --filter="locationId:$REGION"
# Habilita somente a API necessária nesta aula.
gcloud services enable artifactregistry.googleapis.com --project="$PROJECT_ID"
# Confirma que a API foi habilitada.
gcloud services list --enabled --filter="name:artifactregistry.googleapis.com"
```

## 4. Criar o aplicativo e o Dockerfile

O exemplo usa **Nginx**, sem instalar runtime adicional na máquina.

```bash
# Cria uma pasta isolada para os arquivos do laboratório.
mkdir -p "$HOME/ace-containers-lab"
# Entra na pasta do laboratório.
cd "$HOME/ace-containers-lab"
# Escreve uma página HTML simples.
cat > index.html <<'EOF'
<!doctype html>
<html lang="pt-br">
<head><meta charset="utf-8"><title>ACE Containers</title></head>
<body><h1>ACE Containers v1</h1></body>
</html>
EOF
# Escreve a receita da image.
cat > Dockerfile <<'EOF'
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
EOF
# Confere os arquivos antes do build.
ls -l
cat Dockerfile
```

**Dockerfile explicado:** `FROM` escolhe a image base; `COPY` adiciona o HTML ao filesystem da image; `EXPOSE` documenta a porta do processo, mas **não publica** essa porta no host. O mapeamento ocorre em `docker run -p`.

Em produção, considere fixar a image base por digest, atualizar dependências, reduzir privilégios e examinar vulnerabilidades. Para este laboratório, `nginx:alpine` privilegia simplicidade e rapidez.

## 5. Construir, inspecionar e testar localmente

```bash
# Constrói uma image local com tag identificável.
docker build -t "${IMAGE}:${TAG}" .
# Lista a image construída.
docker image ls "$IMAGE"
# Inspeciona metadados, arquitetura e comando da image.
docker image inspect "${IMAGE}:${TAG}" --format '{{.Id}} {{.Architecture}} {{json .Config.Cmd}}'
# Executa o container em segundo plano e publica a porta 8080 apenas no loopback.
docker run --name ace-web-local -d -p 127.0.0.1:8080:80 "${IMAGE}:${TAG}"
# Inspeciona o container em execução.
docker ps --filter "name=ace-web-local"
# Testa a resposta HTTP e o conteúdo.
curl -fsS http://127.0.0.1:8080/ | grep 'ACE Containers v1'
# Consulta logs para confirmar atendimento.
docker logs ace-web-local
```

**Esperado:** HTML com `ACE Containers v1`. Se a porta 8080 já estiver ocupada, remova o container criado (se houver) e use outra porta livre, ajustando o `curl` correspondente.

## 6. Criar e inspecionar o repositório

O Artifact Registry suporta formatos como Docker e pacotes de linguagens. Aqui criamos um repositório **standard** com formato **Docker**. Não confunda *registry* (serviço), *repository* (agrupamento) e *image* (artefato).

```bash
# Cria um repositório Docker privado e regional.
gcloud artifacts repositories create "$REPO" \
  --repository-format=docker \
  --location="$REGION" \
  --description="Laboratorio ACE - containers"
# Lista os repositórios existentes na região.
gcloud artifacts repositories list --location="$REGION"
# Inspeciona formato, localização e configurações do repositório.
gcloud artifacts repositories describe "$REPO" --location="$REGION"
```

**Esperado:** `format: DOCKER` e localização `southamerica-east1`. Se o repositório já existir, use `describe` antes de reutilizá-lo; **não apague um repositório compartilhado**.

## 7. Autenticação, tag e push

O comando abaixo configura um *credential helper* no Docker. **Autenticação** comprova a identidade; **autorização IAM** determina se ela pode publicar.

```bash
# Configura o Docker para obter credenciais gcloud no host regional.
gcloud auth configure-docker "$HOST" --quiet
# Confere que o host está no arquivo de configuração Docker do usuário atual.
grep -F "$HOST" "$HOME/.docker/config.json"
# Cria um alias remoto para a image local.
docker tag "${IMAGE}:${TAG}" "$REMOTE_IMAGE"
# Confirma as duas tags locais.
docker image ls "$IMAGE"
# Publica a image no repositório privado.
docker push "$REMOTE_IMAGE"
```

**Esperado:** camadas enviadas ou reutilizadas e um digest `sha256:...`. O nome segue o padrão `LOCATION-docker.pkg.dev/PROJECT_ID/REPOSITORY/IMAGE:TAG`.

> **Segurança:** evite `sudo docker` para contornar problemas de permissão. Em Linux, Docker executado com `sudo` procura credenciais em `/root/.docker/config.json`; corrija o ambiente de modo consciente.

## 8. Inspecionar images, tags e digests

```bash
# Lista as images e seus digests no repositório.
gcloud artifacts docker images list "${HOST}/${PROJECT_ID}/${REPO}" --include-tags
# Inspeciona a image publicada e suas tags.
gcloud artifacts docker images list "${HOST}/${PROJECT_ID}/${REPO}/${IMAGE}" --include-tags
# Confere o digest local da image publicada.
docker image inspect "$REMOTE_IMAGE" --format '{{json .RepoDigests}}'
```

**Tag** (`v1`, `v2`, `commit-a1b2c3`) é um nome de referência que pode mudar, conforme políticas do repositório. **Digest** (`sha256:...`) identifica o conteúdo de uma versão específica. Para implantações reproduzíveis, prefira referência por digest; não dependa apenas de `latest`.

| Referência | Vantagem | Risco/observação |
|---|---|---|
| `:latest` | Conveniente | Não identifica uma versão estável |
| `:v1` | Fácil leitura | Tag pode ser remapeada |
| `:commit-abc123` | Rastreável | Ainda é tag |
| `@sha256:...` | Identidade por conteúdo | Menos legível |

## 9. Pull e reteste: provar que a publicação funcionou

```bash
# Interrompe o container de teste local.
docker rm -f ace-web-local
# Remove a tag remota local, preservando a tag ace-web:v1.
docker image rm "$REMOTE_IMAGE"
# Baixa novamente a image do Artifact Registry.
docker pull "$REMOTE_IMAGE"
# Executa a image baixada em outra porta do loopback.
docker run --name ace-web-pulled -d -p 127.0.0.1:8081:80 "$REMOTE_IMAGE"
# Confirma o HTML servido pela image baixada.
curl -fsS http://127.0.0.1:8081/ | grep 'ACE Containers v1'
```

**Esperado:** a aplicação responde após um **pull remoto**. Esse teste distingue “funciona apenas no Docker local” de “está disponível no registry”.

## 10. Quebrar propositalmente — host de registry errado

**Uma variável por vez:** alteraremos somente o host de destino, sem mexer no IAM, no repositório ou na image válida.

```bash
# Define um host deliberadamente inválido para provocar erro de resolução DNS.
export BAD_HOST="invalid-registry.example.invalid"
# Cria uma tag de teste apontando para o host inválido.
docker tag "${IMAGE}:${TAG}" "${BAD_HOST}/${PROJECT_ID}/${REPO}/${IMAGE}:falha"
# Tenta publicar no host inválido; a falha é esperada.
docker push "${BAD_HOST}/${PROJECT_ID}/${REPO}/${IMAGE}:falha"
```

**Esperado:** falha de conexão/resolução DNS; a mensagem exata depende do ambiente. Esse erro **não comprova** problema de IAM: o cliente sequer alcança o serviço.

### Troubleshooting

| Etapa | Diagnóstico |
|---|---|
| Sintoma | `docker push` falha para o host inválido |
| Hipótese | Endereço de registry incorreto |
| Evidência | Comparar `BAD_HOST` com `HOST` e com o formato `REGION-docker.pkg.dev` |
| Causa | Host fictício, não é Artifact Registry |
| Correção | Voltar a usar `REMOTE_IMAGE` com o host regional correto |

```bash
# Inspeciona o host correto e o host inválido lado a lado.
printf 'Correto: %s\nInvalido: %s\n' "$HOST" "$BAD_HOST"
# Confirma a existência do repositório correto, sem alterar permissões.
gcloud artifacts repositories describe "$REPO" --location="$REGION"
# Retesta o push com o destino correto.
docker push "$REMOTE_IMAGE"
# Remove somente a tag local criada para a falha proposital.
docker image rm "${BAD_HOST}/${PROJECT_ID}/${REPO}/${IMAGE}:falha"
```

### Diagnósticos adicionais (não provocar falhas em produção)

| Sintoma | Verificar primeiro | Ação |
|---|---|---|
| `Unauthenticated` | `gcloud auth list`; Docker credential helper | Configurar autenticação no host correto |
| `Permission denied` / `403` | IAM da identidade ativa no repositório | Solicitar `roles/artifactregistry.writer` no escopo apropriado |
| `Repository not found` | Projeto, região, repositório e API | Corrigir o nome/ambiente, não conceder IAM às cegas |
| Docker daemon indisponível | `docker info` | Corrigir instalação/daemon |
| Porta ocupada | `docker ps` e porta do host | Usar outra porta |
| Image funciona localmente mas pull falha | Nome remoto e permissão reader | Inspecionar tag, digest, credenciais e IAM |

## 11. Cloud Run e GKE: consumidores da image

Cloud Run e GKE **não são registries**. Ambos podem consumir images armazenadas no Artifact Registry, desde que a identidade apropriada tenha acesso. Em geral, não é necessário executar `gcloud auth configure-docker` dentro desses ambientes gerenciados: essa configuração é para o **cliente Docker local**. IAM para pull ainda importa.

```text
Artifact Registry
      |
      +--> Cloud Run: executa container gerenciado
      |
      +--> GKE: executa containers em Pods Kubernetes
```

**Nesta aula:** construir e publicar. **Próximas aulas:** configurar execução, rede, escalabilidade, identidade e troubleshooting em Cloud Run/GKE.

## 12. Questões estilo ACE

1. Uma equipe precisa armazenar images privadas e permitir pull por serviços Google Cloud. Qual serviço é apropriado? **Artifact Registry.** Ele armazena artefatos; não executa containers.
2. Um desenvolvedor consegue autenticar no registry, mas recebe `403` no push. O que verificar? **IAM do principal no repositório**, especialmente permissão de escrita.
3. Um deployment deve ser reproduzível mesmo se a tag `v1` for movida. Como referenciar a image? **Por digest SHA-256.**
4. Um container responde na porta 80, mas o host não responde em 8080. Qual aspecto inspecionar? **Mapeamento `docker run -p`**, além de estado do container.
5. Uma equipe deseja implantar uma image existente no Cloud Run. Precisa criar novo repositório para cada revision? **Não.** Revisions e registry têm responsabilidades diferentes.
6. O comando `docker push` falha por hostname inválido. Qual o primeiro passo? **Inspecionar o hostname e o caminho completo**, antes de alterar IAM.

## 13. Cleanup — evitar custos

**Atenção:** os comandos abaixo apagam o repositório **e todas as suas images**. Execute apenas se `ace-containers-lab` foi criado exclusivamente para esta aula.

```bash
# Para e remove o container baixado.
docker rm -f ace-web-pulled
# Exclui o repositório remoto e os artefatos de laboratório.
gcloud artifacts repositories delete "$REPO" --location="$REGION" --quiet
# Confirma que o repositório não está mais listado.
gcloud artifacts repositories list --location="$REGION" --filter="name:$REPO"
# Remove tags locais, se ainda existirem.
docker image rm "$REMOTE_IMAGE" "${IMAGE}:${TAG}" 2>/dev/null || true
# Sai da pasta para permitir sua remoção.
cd "$HOME"
# Remove apenas a pasta criada por esta aula.
rm -rf "$HOME/ace-containers-lab"
```

**Não desabilite a API** se outros projetos/workloads no mesmo projeto dependem dela. O credential helper pode permanecer configurado para laboratórios posteriores.

## 14. Checklist de aceite

- [ ] Sei explicar image, container, repository e registry;
- [ ] Sei diferenciar VM de container e `EXPOSE` de `-p`;
- [ ] Construí e inspecionei a image;
- [ ] Executei e testei HTTP localmente;
- [ ] Criei, listei e descrevi o repositório;
- [ ] Configurei autenticação e expliquei a diferença para autorização IAM;
- [ ] Fiz tag e push;
- [ ] Inspecionei tags e digests;
- [ ] Fiz pull e retestei o HTML;
- [ ] Provoquei apenas uma falha controlada e a corrigi;
- [ ] Expliquei como Cloud Run e GKE consumirão a image;
- [ ] Removi os recursos cobrados.

## 15. Matriz M/E/P — evidências da aula

`M` = mencionado; `E` = explicado; `P` = praticado com configuração, inspeção e teste; `P*` = guiado/condicional.

| Tópico | Nível | Evidência |
|---|---|---|
| Containers, images e registry | `E` | Definições e arquitetura |
| Dockerfile e build | `P` | Criar, `docker build`, `image inspect` |
| Execução local | `P` | `docker run`, `curl`, logs |
| Artifact Registry | `P` | Create/list/describe |
| Autenticação Docker | `P` | Configure helper, inspeção, push |
| Tags, digest e publicação | `P` | Tag/push/list/inspect |
| Download e reuso | `P` | Pull/run/curl |
| Falha de hostname e correção | `P` | Push inválido → evidência → push correto |
| IAM de acesso | `E` | Reader vs Writer e diagnóstico de 403 |
| Cloud Run e GKE como consumidores | `E` | Arquitetura e responsabilidades |
| Cleanup | `P` | Delete/list e remoção local |

> **Limite de escopo:** IAM `403` foi explicado, mas não provocado por alteração de permissões. Não classificar esse diagnóstico como laboratório IAM executado. A falha praticada foi exclusivamente a de hostname.

## 16. Referências oficiais

- [Artifact Registry — armazenar container images](https://cloud.google.com/artifact-registry/docs/docker/store-docker-container-images)
- [Autenticação Docker](https://cloud.google.com/artifact-registry/docs/docker/authentication)
- [Push e pull](https://cloud.google.com/artifact-registry/docs/docker/pushing-and-pulling)
- [Gerenciamento de images](https://cloud.google.com/artifact-registry/docs/docker/manage-images)

**Sugestão de commit:** `git commit -m "feat(containers): refatora aula 1 com Docker e Artifact Registry ponta a ponta"`
