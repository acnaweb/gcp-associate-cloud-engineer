# Laboratório — Regional Internal Application Load Balancer com Cloud Functions e Cloud Run

## Objetivos

Ao final deste laboratório, você deverá conseguir:

- Entender como um **Regional Internal Application Load Balancer** trabalha com backends serverless;
- Entender o papel de um **Serverless Network Endpoint Group (NEG)**;
- Criar duas **Cloud Functions Gen2**:
  - `cf-default`, usada como backend padrão do Load Balancer;
  - `cf-backend`, acessada pelo path `/cf-backend`;
- Criar um serviço **Cloud Run** chamado `cr-backend`, acessado pelo path `/cr-backend`;
- Criar um Serverless NEG para cada backend;
- Criar um Backend Service regional para cada aplicação;
- Configurar o **URL Map de forma declarativa em YAML**;
- Aplicar o URL Map com `gcloud compute url-maps import`;
- Entender quando `routeAction.urlRewrite` é necessário e quando não é;
- Criar um frontend HTTP interno;
- Testar o Load Balancer a partir de uma VM dentro da VPC;
- Quebrar propositalmente uma regra de roteamento;
- Executar troubleshooting;
- Corrigir a configuração;
- Remover todos os recursos utilizados.

---

# 1. Cenário

Neste laboratório criaremos uma arquitetura totalmente **serverless**.

Teremos três aplicações:

```text
cf-default
→ Cloud Function Gen2 usada como backend default
```

```text
cf-backend
→ Cloud Function Gen2 acessada pelo path /cf-backend
```

```text
cr-backend
→ Cloud Run acessado pelo path /cr-backend
```

O comportamento esperado será:

```text
GET /
→ cf-default
```

```text
GET /qualquer-coisa
→ cf-default
```

```text
GET /cf-backend
→ cf-backend
```

```text
GET /cr-backend
→ cr-backend
```

Arquitetura:

```text
                         VPC
                          |
                          |
                   +-------------+
                   | VM cliente  |
                   +-------------+
                          |
                          | HTTP :80
                          v
                 +------------------+
                 | Internal IP      |
                 | Regional         |
                 +------------------+
                          |
                          v
                 +------------------+
                 | Forwarding Rule  |
                 | INTERNAL_MANAGED |
                 +------------------+
                          |
                          v
                 +------------------+
                 | Target HTTP      |
                 | Proxy Regional   |
                 +------------------+
                          |
                          v
                 +------------------+
                 | URL Map          |
                 +------------------+
                   /        |       \
                  /         |        \
        /cf-backend   /cr-backend   default
              |             |          |
              v             v          v
       +------------+ +------------+ +------------+
       | Backend CF | | Backend CR | | Backend    |
       | backend    | | backend    | | default    |
       +------------+ +------------+ +------------+
              |             |          |
              v             v          v
       +------------+ +------------+ +------------+
       | Serverless | | Serverless | | Serverless |
       | NEG        | | NEG        | | NEG        |
       +------------+ +------------+ +------------+
              |             |          |
              v             v          v
       +------------+ +------------+ +------------+
       | cf-backend | | cr-backend | | cf-default |
       | Function   | | Cloud Run  | | Function   |
       +------------+ +------------+ +------------+
```

Transversalmente:

```text
Proxy-only subnet
       |
       v
Google-managed Envoy proxies
```

> Para um Regional Internal Application Load Balancer com backends exclusivamente serverless, não é necessário criar health check tradicional para os Serverless NEGs, nem firewall permitindo tráfego da proxy-only subnet para esses backends.

---

# 2. Estrutura do laboratório

```text
Conceito
   ↓
Criar cf-default
   ↓
Criar cf-backend
   ↓
Criar cr-backend
   ↓
Inspecionar
   ↓
Criar Serverless NEGs
   ↓
Criar Backend Services
   ↓
Criar URL Map
   ↓
Criar YAML de roteamento
   ↓
Importar YAML
   ↓
Criar Target HTTP Proxy
   ↓
Criar Forwarding Rule
   ↓
Testar
   ↓
Quebrar propositalmente
   ↓
Troubleshooting
   ↓
Corrigir
   ↓
Questões estilo ACE
   ↓
Cleanup
```

---

# 3. Modelo mental

Para uma requisição HTTP:

```text
Cliente
   ↓
Forwarding Rule
   ↓
Target HTTP Proxy
   ↓
URL Map
   ↓
Backend Service
   ↓
Serverless NEG
   ↓
Aplicação serverless
```

O URL Map decide:

```text
/cf-backend
→ cf-backend
```

```text
/cr-backend
→ cr-backend
```

```text
qualquer outro path
→ cf-default
```

---

# 4. Pré-requisitos

Você precisa de:

- Projeto Google Cloud;
- Billing habilitado;
- Cloud Shell ou `gcloud` instalado;
- Permissões para criar recursos de Compute Engine, Cloud Run e Cloud Functions;
- VPC `default` disponível;
- Região `us-central1`.

Verifique o projeto:

```bash
gcloud config get-value project
```

Configure região e zona:

```bash
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a
```

---

# 5. Habilitando APIs

```bash
gcloud services enable \
  compute.googleapis.com \
  run.googleapis.com \
  cloudfunctions.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com
```

Verifique:

```bash
gcloud services list --enabled \
  --filter="NAME:(compute.googleapis.com OR run.googleapis.com OR cloudfunctions.googleapis.com)"
```

---

# 6. Variáveis

```bash
export PROJECT_ID="$(gcloud config get-value project)"

export REGION=us-central1
export ZONE=us-central1-a

export NETWORK=default
export SUBNET=default

export CF_DEFAULT=cf-default
export CF_BACKEND=cf-backend
export CR_BACKEND=cr-backend

export CF_DEFAULT_NEG=cf-default-neg
export CF_BACKEND_NEG=cf-backend-neg
export CR_BACKEND_NEG=cr-backend-neg

export CF_DEFAULT_BS=cf-default-backend-service
export CF_BACKEND_BS=cf-backend-backend-service
export CR_BACKEND_BS=cr-backend-backend-service

export PROXY_SUBNET=serverless-ialb-proxy-only
export PROXY_CIDR=172.20.0.0/23

export URL_MAP=serverless-ialb-url-map
export PATH_MATCHER=serverless-path-matcher

export HTTP_PROXY=serverless-ialb-http-proxy

export IP_NAME=serverless-ialb-ip
export FORWARDING_RULE=serverless-ialb-forwarding-rule

export CLIENT=serverless-ialb-client
```

Confira:

```bash
echo "$PROJECT_ID"
echo "$REGION"
echo "$CF_DEFAULT"
echo "$CF_BACKEND"
echo "$CR_BACKEND"
```

---

# 7. Criando `cf-default`

Crie o diretório:

```bash
mkdir -p cf-default
cd cf-default
```

Crie `main.py`:

```bash
cat > main.py <<'PYTHON'
import functions_framework
import json

@functions_framework.http
def cf_default(request):
    response = {
        "backend": "cf-default",
        "service": "Cloud Functions Gen2",
        "role": "default-backend",
        "path": request.path,
        "method": request.method
    }

    return (
        json.dumps(response),
        200,
        {"Content-Type": "application/json"}
    )
PYTHON
```

Crie `requirements.txt`:

```bash
cat > requirements.txt <<'EOF'
functions-framework>=3.0,<4.0
EOF
```

Inspecione:

```bash
cat main.py
cat requirements.txt
```

---

# 8. Deploy de `cf-default`

```bash
gcloud functions deploy "$CF_DEFAULT" \
  --gen2 \
  --runtime=python312 \
  --region="$REGION" \
  --source=. \
  --entry-point=cf_default \
  --trigger-http \
  --allow-unauthenticated \
  --ingress-settings=internal-only
```

Volte:

```bash
cd ..
```

Inspecione:

```bash
gcloud functions describe "$CF_DEFAULT" \
  --gen2 \
  --region="$REGION"
```

---

# 9. Criando `cf-backend`

```bash
mkdir -p cf-backend
cd cf-backend
```

Crie `main.py`:

```bash
cat > main.py <<'PYTHON'
import functions_framework
import json

@functions_framework.http
def cf_backend(request):
    response = {
        "backend": "cf-backend",
        "service": "Cloud Functions Gen2",
        "path": request.path,
        "method": request.method
    }

    return (
        json.dumps(response),
        200,
        {"Content-Type": "application/json"}
    )
PYTHON
```

Crie `requirements.txt`:

```bash
cat > requirements.txt <<'EOF'
functions-framework>=3.0,<4.0
EOF
```

Inspecione:

```bash
cat main.py
cat requirements.txt
```

---

# 10. Deploy de `cf-backend`

```bash
gcloud functions deploy "$CF_BACKEND" \
  --gen2 \
  --runtime=python312 \
  --region="$REGION" \
  --source=. \
  --entry-point=cf_backend \
  --trigger-http \
  --allow-unauthenticated \
  --ingress-settings=internal-only
```

Volte:

```bash
cd ..
```

Inspecione:

```bash
gcloud functions describe "$CF_BACKEND" \
  --gen2 \
  --region="$REGION"
```

---

# 11. Criando `cr-backend`

```bash
mkdir -p cr-backend
cd cr-backend
```

Crie `app.py`:

```bash
cat > app.py <<'PYTHON'
from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.get("/")
def index():
    return jsonify({
        "backend": "cr-backend",
        "service": "Cloud Run"
    })

@app.get("/cr-backend")
def backend():
    return jsonify({
        "backend": "cr-backend",
        "service": "Cloud Run",
        "path": "/cr-backend",
        "revision": os.environ.get("K_REVISION", "unknown")
    })

@app.get("/info")
def info():
    return jsonify({
        "backend": "cr-backend",
        "service": "Cloud Run",
        "endpoint": "/info",
        "revision": os.environ.get("K_REVISION", "unknown")
    })

if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8080"))
    app.run(host="0.0.0.0", port=port)
PYTHON
```

Crie `requirements.txt`:

```bash
cat > requirements.txt <<'EOF'
Flask>=3.0,<4.0
gunicorn>=22,<24
EOF
```

Crie `Dockerfile`:

```bash
cat > Dockerfile <<'EOF'
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

CMD exec gunicorn \
    --bind :${PORT} \
    --workers 1 \
    --threads 8 \
    app:app
EOF
```

Inspecione:

```bash
cat app.py
cat requirements.txt
cat Dockerfile
```

---

# 12. Deploy de `cr-backend`

```bash
gcloud run deploy "$CR_BACKEND" \
  --source=. \
  --region="$REGION" \
  --allow-unauthenticated \
  --ingress=internal
```

Volte:

```bash
cd ..
```

Inspecione:

```bash
gcloud run services describe "$CR_BACKEND" \
  --region="$REGION"
```

---

# 13. Aplicações criadas

Temos:

```text
cf-default
→ Cloud Functions Gen2
→ backend default
```

```text
cf-backend
→ Cloud Functions Gen2
→ path /cf-backend
```

```text
cr-backend
→ Cloud Run
→ path /cr-backend
```

---

# 14. Criando a proxy-only subnet

Regional Internal Application Load Balancers usam proxies gerenciados pelo Google.

Crie:

```bash
gcloud compute networks subnets create "$PROXY_SUBNET" \
  --network="$NETWORK" \
  --region="$REGION" \
  --range="$PROXY_CIDR" \
  --purpose=REGIONAL_MANAGED_PROXY \
  --role=ACTIVE
```

Inspecione:

```bash
gcloud compute networks subnets describe "$PROXY_SUBNET" \
  --region="$REGION"
```

Confirme:

```text
purpose
→ REGIONAL_MANAGED_PROXY

role
→ ACTIVE
```

Modelo mental:

```text
Proxy-only subnet
→ utilizada pelos proxies gerenciados
```

```text
Frontend IP
→ utiliza uma subnet normal
```

---

# 15. Criando o Serverless NEG de `cf-default`

Cloud Functions Gen2 executa sobre a infraestrutura do Cloud Run e pode ser utilizada como backend por meio de Serverless NEG.

```bash
gcloud compute network-endpoint-groups create "$CF_DEFAULT_NEG" \
  --region="$REGION" \
  --network-endpoint-type=serverless \
  --cloud-run-service="$CF_DEFAULT"
```

Inspecione:

```bash
gcloud compute network-endpoint-groups describe "$CF_DEFAULT_NEG" \
  --region="$REGION"
```

---

# 16. Criando o Serverless NEG de `cf-backend`

```bash
gcloud compute network-endpoint-groups create "$CF_BACKEND_NEG" \
  --region="$REGION" \
  --network-endpoint-type=serverless \
  --cloud-run-service="$CF_BACKEND"
```

Inspecione:

```bash
gcloud compute network-endpoint-groups describe "$CF_BACKEND_NEG" \
  --region="$REGION"
```

---

# 17. Criando o Serverless NEG de `cr-backend`

```bash
gcloud compute network-endpoint-groups create "$CR_BACKEND_NEG" \
  --region="$REGION" \
  --network-endpoint-type=serverless \
  --cloud-run-service="$CR_BACKEND"
```

Inspecione:

```bash
gcloud compute network-endpoint-groups describe "$CR_BACKEND_NEG" \
  --region="$REGION"
```

---

# 18. Listando os Serverless NEGs

```bash
gcloud compute network-endpoint-groups list \
  --filter="region:($REGION)"
```

Modelo:

```text
cf-default-neg
       |
       v
cf-default
```

```text
cf-backend-neg
       |
       v
cf-backend
```

```text
cr-backend-neg
       |
       v
cr-backend
```

---

# 19. Criando Backend Service de `cf-default`

```bash
gcloud compute backend-services create "$CF_DEFAULT_BS" \
  --load-balancing-scheme=INTERNAL_MANAGED \
  --protocol=HTTP \
  --region="$REGION"
```

Adicione o NEG:

```bash
gcloud compute backend-services add-backend "$CF_DEFAULT_BS" \
  --region="$REGION" \
  --network-endpoint-group="$CF_DEFAULT_NEG" \
  --network-endpoint-group-region="$REGION"
```

Inspecione:

```bash
gcloud compute backend-services describe "$CF_DEFAULT_BS" \
  --region="$REGION"
```

---

# 20. Criando Backend Service de `cf-backend`

```bash
gcloud compute backend-services create "$CF_BACKEND_BS" \
  --load-balancing-scheme=INTERNAL_MANAGED \
  --protocol=HTTP \
  --region="$REGION"
```

Adicione:

```bash
gcloud compute backend-services add-backend "$CF_BACKEND_BS" \
  --region="$REGION" \
  --network-endpoint-group="$CF_BACKEND_NEG" \
  --network-endpoint-group-region="$REGION"
```

Inspecione:

```bash
gcloud compute backend-services describe "$CF_BACKEND_BS" \
  --region="$REGION"
```

---

# 21. Criando Backend Service de `cr-backend`

```bash
gcloud compute backend-services create "$CR_BACKEND_BS" \
  --load-balancing-scheme=INTERNAL_MANAGED \
  --protocol=HTTP \
  --region="$REGION"
```

Adicione:

```bash
gcloud compute backend-services add-backend "$CR_BACKEND_BS" \
  --region="$REGION" \
  --network-endpoint-group="$CR_BACKEND_NEG" \
  --network-endpoint-group-region="$REGION"
```

Inspecione:

```bash
gcloud compute backend-services describe "$CR_BACKEND_BS" \
  --region="$REGION"
```

---

# 22. Health Check e firewall

Observe que não criamos:

```text
Health Check HTTP tradicional
```

nem:

```text
Firewall da proxy-only subnet para os backends serverless
```

Isso ocorre porque os backends são Serverless NEGs.

Compare:

```text
MIG
 |
 +---- Health Check
 |
 v
VMs
```

com:

```text
Backend Service
      |
      v
Serverless NEG
      |
      v
Cloud Run / Cloud Functions Gen2
```

---

# 23. Criando o URL Map base

O backend padrão será:

```text
cf-default
```

Crie:

```bash
gcloud compute url-maps create "$URL_MAP" \
  --default-service="$CF_DEFAULT_BS" \
  --region="$REGION"
```

Neste momento:

```text
qualquer requisição
       |
       v
cf-default
```

Inspecione:

```bash
gcloud compute url-maps describe "$URL_MAP" \
  --region="$REGION"
```

---

# 24. Configurando o roteamento com YAML

Em vez de adicionar as regras de path de forma imperativa, vamos declarar o estado completo do URL Map em YAML.

O objetivo será:

```text
/cf-backend
→ cf-backend
```

```text
/cr-backend
→ cr-backend
```

```text
qualquer outro path
→ cf-default
```

---

# 25. Criando `url-map.yaml`

```bash
cat > url-map.yaml <<EOF
name: ${URL_MAP}

defaultService: projects/${PROJECT_ID}/regions/${REGION}/backendServices/${CF_DEFAULT_BS}

hostRules:
- hosts:
  - "*"
  pathMatcher: ${PATH_MATCHER}

pathMatchers:
- name: ${PATH_MATCHER}

  defaultService: projects/${PROJECT_ID}/regions/${REGION}/backendServices/${CF_DEFAULT_BS}

  pathRules:

  - paths:
    - /cf-backend
    - /cf-backend/*
    service: projects/${PROJECT_ID}/regions/${REGION}/backendServices/${CF_BACKEND_BS}

  - paths:
    - /cr-backend
    - /cr-backend/*
    service: projects/${PROJECT_ID}/regions/${REGION}/backendServices/${CR_BACKEND_BS}
EOF
```

Inspecione:

```bash
cat url-map.yaml
```

---

# 26. Entendendo o YAML

## `defaultService`

```yaml
defaultService: projects/PROJECT_ID/regions/REGION/backendServices/cf-default-backend-service
```

Esse é o backend usado quando nenhuma regra específica é encontrada.

Modelo:

```text
Path conhecido?
   |
   +---- SIM → Backend específico
   |
   +---- NÃO → cf-default
```

---

## `hostRules`

```yaml
hostRules:
- hosts:
  - "*"
  pathMatcher: serverless-path-matcher
```

O `*` significa que qualquer host recebido será avaliado pelo Path Matcher.

---

## `pathMatchers`

```yaml
pathMatchers:
- name: serverless-path-matcher
```

O Path Matcher contém as regras de roteamento por caminho.

---

## `/cf-backend`

```yaml
- paths:
  - /cf-backend
  - /cf-backend/*
  service: projects/PROJECT_ID/regions/REGION/backendServices/cf-backend-backend-service
```

Resultado:

```text
/cf-backend
→ cf-backend
```

---

## `/cr-backend`

```yaml
- paths:
  - /cr-backend
  - /cr-backend/*
  service: projects/PROJECT_ID/regions/REGION/backendServices/cr-backend-backend-service
```

Resultado:

```text
/cr-backend
→ cr-backend
```

---

# 27. `urlRewrite` é necessário aqui?

Não.

Neste laboratório queremos:

```text
Cliente chama:
GET /cr-backend
```

e o Cloud Run possui:

```text
GET /cr-backend
```

Portanto o backend deve receber o mesmo path:

```text
/cr-backend
```

Da mesma forma:

```text
Cliente chama:
GET /cf-backend
```

e `cf-backend` recebe:

```text
/cf-backend
```

Logo, não há necessidade de reescrever a URL.

Modelo:

```text
Routing
→ escolhe o backend
```

```text
URL Rewrite
→ altera host e/ou path antes de enviar ao backend
```

---

# 28. Quando usar `routeAction.urlRewrite`?

Imagine que o cliente deva acessar:

```text
/cr-backend
```

mas o Cloud Run só implemente:

```text
GET /
```

Sem rewrite:

```text
Cliente:
GET /cr-backend
       |
       v
Cloud Run recebe:
GET /cr-backend
```

Se o serviço não possuir essa rota:

```text
HTTP 404
```

Com URL Rewrite:

```text
Cliente:
GET /cr-backend
       |
       v
URL Map
       |
       v
Rewrite:
 /cr-backend → /
       |
       v
Cloud Run recebe:
GET /
```

Nesse cenário podemos usar `routeRules` e `routeAction.urlRewrite`.

Exemplo conceitual:

```yaml
pathMatchers:
- name: serverless-path-matcher

  defaultService: projects/PROJECT_ID/regions/REGION/backendServices/cf-default-backend-service

  routeRules:

  - priority: 10

    matchRules:
    - prefixMatch: /cr-backend

    routeAction:
      weightedBackendServices:
      - backendService: projects/PROJECT_ID/regions/REGION/backendServices/cr-backend-backend-service
        weight: 100

      urlRewrite:
        pathPrefixRewrite: /
```

Fluxo:

```text
/cr-backend
      |
      v
prefixMatch
      |
      v
urlRewrite
      |
      v
/
      |
      v
cr-backend
```

> `pathRules` e `routeRules` são alternativas dentro do mesmo `pathMatcher`. Para recursos avançados como rewrite, traffic splitting, retries, mirroring e fault injection, `routeRules` são mais apropriadas.

Neste laboratório principal continuaremos com:

```text
pathRules
```

porque queremos apenas roteamento simples.

---

# 29. Aplicando o URL Map com `gcloud import`

Aplique:

```bash
gcloud compute url-maps import "$URL_MAP" \
  --region="$REGION" \
  --source=url-map.yaml \
  --quiet
```

Modelo:

```text
url-map.yaml
     |
     v
gcloud compute url-maps import
     |
     v
Regional URL Map
```

---

# 30. Inspecionando a configuração aplicada

```bash
gcloud compute url-maps describe "$URL_MAP" \
  --region="$REGION"
```

Confirme:

```text
defaultService
→ cf-default-backend-service
```

```text
/cf-backend
→ cf-backend-backend-service
```

```text
/cr-backend
→ cr-backend-backend-service
```

---

# 31. Exportando o URL Map

Exporte:

```bash
gcloud compute url-maps export "$URL_MAP" \
  --region="$REGION" \
  --destination=url-map-exported.yaml
```

Inspecione:

```bash
cat url-map-exported.yaml
```

Modelo:

```text
YAML
 ↓ import
Google Cloud
 ↓ export
YAML
```

Esse fluxo ajuda em:

```text
versionamento
auditoria
backup
troubleshooting
comparação entre ambientes
```

---

# 32. Criando o Target HTTP Proxy regional

```bash
gcloud compute target-http-proxies create "$HTTP_PROXY" \
  --url-map="$URL_MAP" \
  --region="$REGION"
```

Inspecione:

```bash
gcloud compute target-http-proxies describe "$HTTP_PROXY" \
  --region="$REGION"
```

---

# 33. Reservando o IP interno

O IP do frontend deve vir de uma subnet normal.

Crie:

```bash
gcloud compute addresses create "$IP_NAME" \
  --region="$REGION" \
  --subnet="$SUBNET"
```

Obtenha:

```bash
export IALB_IP="$(gcloud compute addresses describe "$IP_NAME" \
  --region="$REGION" \
  --format='value(address)')"
```

Confira:

```bash
echo "$IALB_IP"
```

Não confunda:

```text
Subnet normal
→ IP do frontend
```

com:

```text
Proxy-only subnet
→ proxies gerenciados
```

---

# 34. Criando a Forwarding Rule

```bash
gcloud compute forwarding-rules create "$FORWARDING_RULE" \
  --load-balancing-scheme=INTERNAL_MANAGED \
  --network="$NETWORK" \
  --subnet="$SUBNET" \
  --address="$IP_NAME" \
  --ports=80 \
  --region="$REGION" \
  --target-http-proxy="$HTTP_PROXY" \
  --target-http-proxy-region="$REGION"
```

Inspecione:

```bash
gcloud compute forwarding-rules describe "$FORWARDING_RULE" \
  --region="$REGION"
```

Confirme:

```text
loadBalancingScheme
→ INTERNAL_MANAGED
```

---

# 35. Arquitetura construída

```text
                           VM CLIENTE
                               |
                               | HTTP
                               v
                       +---------------+
                       | Internal IP   |
                       |     :80       |
                       +---------------+
                               |
                               v
                       +---------------+
                       | Forwarding    |
                       | Rule          |
                       +---------------+
                               |
                               v
                       +---------------+
                       | Target HTTP   |
                       | Proxy         |
                       +---------------+
                               |
                               v
                       +---------------+
                       | URL Map       |
                       +---------------+
                         /      |      \
                        /       |       \
                       /        |        \
             /cf-backend /cr-backend   default
                    |         |           |
                    v         v           v
                 BS CF       BS CR    BS Default
                    |         |           |
                    v         v           v
                 NEG CF      NEG CR    NEG Default
                    |         |           |
                    v         v           v
             cf-backend  cr-backend   cf-default
```

---

# 36. Criando uma VM cliente

Como o frontend é interno, teste a partir de dentro da VPC.

```bash
gcloud compute instances create "$CLIENT" \
  --zone="$ZONE" \
  --machine-type=e2-micro \
  --image-family=debian-12 \
  --image-project=debian-cloud \
  --network="$NETWORK" \
  --subnet="$SUBNET" \
  --no-address \
  --tags=allow-iap-ssh
```

Inspecione:

```bash
gcloud compute instances describe "$CLIENT" \
  --zone="$ZONE" \
  --format="table(name,networkInterfaces[0].networkIP,status)"
```

---

# 37. Permitindo SSH somente via IAP

Evite:

```text
tcp:22
0.0.0.0/0
```

Crie:

```bash
gcloud compute firewall-rules create allow-iap-ssh-serverless-ialb \
  --network="$NETWORK" \
  --direction=INGRESS \
  --action=ALLOW \
  --rules=tcp:22 \
  --source-ranges=35.235.240.0/20 \
  --target-tags=allow-iap-ssh
```

Inspecione:

```bash
gcloud compute firewall-rules describe \
  allow-iap-ssh-serverless-ialb
```

---

# 38. Testando o backend default

```bash
gcloud compute ssh "$CLIENT" \
  --zone="$ZONE" \
  --tunnel-through-iap \
  --command="curl -s http://$IALB_IP/"
```

Resultado esperado:

```json
{
  "backend": "cf-default",
  "service": "Cloud Functions Gen2",
  "role": "default-backend",
  "path": "/",
  "method": "GET"
}
```

Fluxo:

```text
GET /
   |
   v
nenhuma Path Rule encontrada
   |
   v
defaultService
   |
   v
cf-default
```

---

# 39. Testando outro path sem regra

```bash
gcloud compute ssh "$CLIENT" \
  --zone="$ZONE" \
  --tunnel-through-iap \
  --command="curl -s http://$IALB_IP/teste"
```

Resultado esperado:

```text
cf-default
```

Isso comprova o funcionamento do backend default.

---

# 40. Testando `/cf-backend`

```bash
gcloud compute ssh "$CLIENT" \
  --zone="$ZONE" \
  --tunnel-through-iap \
  --command="curl -s http://$IALB_IP/cf-backend"
```

Resultado esperado:

```json
{
  "backend": "cf-backend",
  "service": "Cloud Functions Gen2",
  "path": "/cf-backend",
  "method": "GET"
}
```

Fluxo:

```text
/cf-backend
      |
      v
URL Map
      |
      v
cf-backend-backend-service
      |
      v
cf-backend-neg
      |
      v
cf-backend
```

---

# 41. Testando `/cr-backend`

```bash
gcloud compute ssh "$CLIENT" \
  --zone="$ZONE" \
  --tunnel-through-iap \
  --command="curl -s http://$IALB_IP/cr-backend"
```

Resultado esperado:

```json
{
  "backend": "cr-backend",
  "service": "Cloud Run",
  "path": "/cr-backend"
}
```

---

# 42. Teste completo

```bash
for PATH in / /teste /cf-backend /cr-backend; do

  echo
  echo "===== GET $PATH ====="

  gcloud compute ssh "$CLIENT" \
    --zone="$ZONE" \
    --tunnel-through-iap \
    --command="curl -s http://$IALB_IP$PATH"

  echo

done
```

Resultado conceitual:

```text
/
→ cf-default
```

```text
/teste
→ cf-default
```

```text
/cf-backend
→ cf-backend
```

```text
/cr-backend
→ cr-backend
```

---

# 43. Tabela de roteamento

| Request | Regra encontrada? | Backend |
|---|---|---|
| `/` | Não | `cf-default` |
| `/teste` | Não | `cf-default` |
| `/qualquer-coisa` | Não | `cf-default` |
| `/cf-backend` | Sim | `cf-backend` |
| `/cf-backend/teste` | Sim | `cf-backend` |
| `/cr-backend` | Sim | `cr-backend` |
| `/cr-backend/teste` | Sim | `cr-backend` |

---

# 44. Investigando a arquitetura

Forwarding Rule:

```bash
gcloud compute forwarding-rules describe "$FORWARDING_RULE" \
  --region="$REGION"
```

Target HTTP Proxy:

```bash
gcloud compute target-http-proxies describe "$HTTP_PROXY" \
  --region="$REGION"
```

URL Map:

```bash
gcloud compute url-maps describe "$URL_MAP" \
  --region="$REGION"
```

Backend Services:

```bash
gcloud compute backend-services list \
  --filter="region:($REGION)"
```

Serverless NEGs:

```bash
gcloud compute network-endpoint-groups list \
  --filter="region:($REGION)"
```

Functions:

```bash
gcloud functions list \
  --gen2
```

Cloud Run:

```bash
gcloud run services list \
  --region="$REGION"
```

---

# 45. Quebrar propositalmente usando YAML

O estado correto é:

```text
/cr-backend
→ cr-backend
```

Vamos alterar propositalmente para:

```text
/cr-backend
→ cf-default
```

Crie uma cópia:

```bash
cp url-map.yaml url-map-broken.yaml
```

Agora gere uma versão incorreta:

```bash
cat > url-map-broken.yaml <<EOF
name: ${URL_MAP}

defaultService: projects/${PROJECT_ID}/regions/${REGION}/backendServices/${CF_DEFAULT_BS}

hostRules:
- hosts:
  - "*"
  pathMatcher: ${PATH_MATCHER}

pathMatchers:
- name: ${PATH_MATCHER}

  defaultService: projects/${PROJECT_ID}/regions/${REGION}/backendServices/${CF_DEFAULT_BS}

  pathRules:

  - paths:
    - /cf-backend
    - /cf-backend/*
    service: projects/${PROJECT_ID}/regions/${REGION}/backendServices/${CF_BACKEND_BS}

  - paths:
    - /cr-backend
    - /cr-backend/*
    service: projects/${PROJECT_ID}/regions/${REGION}/backendServices/${CF_DEFAULT_BS}
EOF
```

Observe:

```text
/cr-backend
→ CF_DEFAULT_BS
```

quando deveria ser:

```text
/cr-backend
→ CR_BACKEND_BS
```

---

# 46. Importando a configuração incorreta

```bash
gcloud compute url-maps import "$URL_MAP" \
  --region="$REGION" \
  --source=url-map-broken.yaml \
  --quiet
```

Inspecione:

```bash
gcloud compute url-maps describe "$URL_MAP" \
  --region="$REGION"
```

---

# 47. Testando a falha

```bash
gcloud compute ssh "$CLIENT" \
  --zone="$ZONE" \
  --tunnel-through-iap \
  --command="curl -s http://$IALB_IP/cr-backend"
```

Agora a resposta deverá indicar:

```text
backend
→ cf-default
```

em vez de:

```text
backend
→ cr-backend
```

O Load Balancer continua disponível.

A falha é de:

```text
roteamento L7
```

---

# 48. Troubleshooting

Temos:

```text
GET /
→ cf-default
→ OK
```

```text
GET /cf-backend
→ cf-backend
→ OK
```

```text
GET /cr-backend
→ cf-default
→ INCORRETO
```

Logo:

```text
Frontend
→ OK
```

```text
Forwarding Rule
→ OK
```

```text
Target HTTP Proxy
→ OK
```

```text
cf-default
→ OK
```

```text
cf-backend
→ OK
```

Como apenas uma rota apresenta comportamento incorreto, a primeira configuração a investigar é:

```text
URL Map / Path Rule
```

---

# 49. Exportando o estado atual

```bash
gcloud compute url-maps export "$URL_MAP" \
  --region="$REGION" \
  --destination=url-map-current.yaml
```

Inspecione:

```bash
cat url-map-current.yaml
```

Procure:

```bash
grep -A5 -B2 "/cr-backend" url-map-current.yaml
```

Você deverá identificar:

```text
/cr-backend
→ cf-default-backend-service
```

---

# 50. Comparando arquivos

Temos:

```text
url-map.yaml
→ configuração correta
```

```text
url-map-current.yaml
→ estado aplicado atualmente
```

Compare:

```bash
diff -u url-map.yaml url-map-current.yaml || true
```

O arquivo exportado pelo Google pode conter campos adicionais, mas a comparação continua útil para investigar as regras relevantes.

---

# 51. Diagnóstico

```text
Sintoma
→ /cr-backend retorna cf-default

Frontend
→ OK

/cf-backend
→ OK

Backend Services
→ existem

Serverless NEGs
→ existem

cr-backend
→ existe

URL Map exportado
→ /cr-backend aponta para cf-default
```

Conclusão:

```text
Path Rule incorreta
```

---

# 52. Corrigindo

O arquivo original:

```text
url-map.yaml
```

continua contendo a configuração correta.

Reimporte:

```bash
gcloud compute url-maps import "$URL_MAP" \
  --region="$REGION" \
  --source=url-map.yaml \
  --quiet
```

---

# 53. Inspecionando após a correção

```bash
gcloud compute url-maps export "$URL_MAP" \
  --region="$REGION" \
  --destination=url-map-fixed.yaml
```

Inspecione:

```bash
grep -A5 -B2 "/cr-backend" url-map-fixed.yaml
```

Agora deverá apontar para:

```text
cr-backend-backend-service
```

---

# 54. Reteste

```bash
gcloud compute ssh "$CLIENT" \
  --zone="$ZONE" \
  --tunnel-through-iap \
  --command="curl -s http://$IALB_IP/cr-backend"
```

Resultado esperado:

```text
backend
→ cr-backend
```

Teste tudo novamente:

```bash
for PATH in / /teste /cf-backend /cr-backend; do

  echo
  echo "===== GET $PATH ====="

  gcloud compute ssh "$CLIENT" \
    --zone="$ZONE" \
    --tunnel-through-iap \
    --command="curl -s http://$IALB_IP$PATH"

  echo

done
```

---

# 55. Fluxo declarativo aprendido

```text
Criar recursos
      ↓
Criar URL Map base
      ↓
Escrever url-map.yaml
      ↓
Inspecionar YAML
      ↓
Importar
      ↓
Testar
      ↓
Exportar
      ↓
Investigar
      ↓
Corrigir YAML
      ↓
Importar novamente
```

Modelo:

```text
YAML
 ↓
gcloud import
 ↓
Google Cloud
```

e:

```text
Google Cloud
 ↓
gcloud export
 ↓
YAML
```

---

# 56. Backend Service x Serverless NEG

Não confunda:

```text
URL Map
   |
   v
Backend Service
   |
   v
Serverless NEG
   |
   v
Aplicação serverless
```

Exemplo:

```text
/cr-backend
      |
      v
cr-backend-backend-service
      |
      v
cr-backend-neg
      |
      v
cr-backend
```

---

# 57. Comparando os três backends

| Item | `cf-default` | `cf-backend` | `cr-backend` |
|---|---|---|---|
| Tecnologia | Cloud Functions Gen2 | Cloud Functions Gen2 | Cloud Run |
| Função no LB | Default backend | Backend por path | Backend por path |
| Path específico | Não | `/cf-backend` | `/cr-backend` |
| Serverless NEG | Sim | Sim | Sim |
| Backend Service | Sim | Sim | Sim |
| Health check tradicional | Não | Não | Não |
| MIG | Não | Não | Não |

---

# 58. Comparação com backend baseado em MIG

| Característica | MIG | Serverless NEG |
|---|---|---|
| Backend | VMs | Serviço serverless |
| Instance Template | Sim | Não |
| Named Port | Normalmente sim | Não |
| Health Check tradicional | Sim | Não neste cenário |
| Gerenciamento de VM | Sim | Não |
| Backend Service | Sim | Sim |
| URL Map | Sim | Sim |
| Autoscaling | MIG Autoscaler | Plataforma serverless |

---

# 59. Questões estilo ACE

## Questão 1

O Regional Internal Application Load Balancer recebe:

```text
/teste
```

Não existe Path Rule correspondente.

Para onde a requisição será enviada?

**Resposta:**

```text
Default Backend Service
→ cf-default
```

---

## Questão 2

Qual componente determina que:

```text
/cf-backend
```

deve ser enviado para `cf-backend`?

**Resposta:**

```text
URL Map / Path Rule
```

---

## Questão 3

Qual componente associa o Backend Service a um serviço serverless?

**Resposta:**

```text
Serverless NEG
```

---

## Questão 4

Há três aplicações serverless e apenas um IP interno.

Como o Load Balancer escolhe a aplicação?

**Resposta:**

```text
URL Map
```

---

## Questão 5

Uma requisição para:

```text
/cr-backend
```

está chegando em `cf-default`.

Os demais endpoints funcionam.

Qual componente deve ser investigado primeiro?

**Resposta:**

```text
URL Map / Path Rule
```

---

## Questão 6

Quando `urlRewrite` é necessário?

**Resposta:**

Quando o path ou hostname exposto ao cliente precisa ser diferente daquele recebido pelo backend.

Exemplo:

```text
cliente:
GET /cr-backend

backend implementa:
GET /
```

Nesse caso pode-se usar:

```text
/cr-backend
→ rewrite
→ /
```

---

# 60. Exercício de investigação

Usando somente `gcloud`, encontre:

1. IP interno do Load Balancer;
2. Porta do frontend;
3. Forwarding Rule;
4. Target HTTP Proxy;
5. URL Map;
6. Backend Service padrão;
7. Backend Service de `cf-backend`;
8. Backend Service de `cr-backend`;
9. Serverless NEG de `cf-default`;
10. Serverless NEG de `cf-backend`;
11. Serverless NEG de `cr-backend`;
12. Cloud Function `cf-default`;
13. Cloud Function `cf-backend`;
14. Cloud Run `cr-backend`;
15. Proxy-only subnet.

---

# 61. Cleanup

A ordem é importante porque existem dependências entre os recursos.

## Forwarding Rule

```bash
gcloud compute forwarding-rules delete "$FORWARDING_RULE" \
  --region="$REGION" \
  --quiet
```

## IP interno

```bash
gcloud compute addresses delete "$IP_NAME" \
  --region="$REGION" \
  --quiet
```

## Target HTTP Proxy

```bash
gcloud compute target-http-proxies delete "$HTTP_PROXY" \
  --region="$REGION" \
  --quiet
```

## URL Map

```bash
gcloud compute url-maps delete "$URL_MAP" \
  --region="$REGION" \
  --quiet
```

## Backend Service `cf-default`

```bash
gcloud compute backend-services delete "$CF_DEFAULT_BS" \
  --region="$REGION" \
  --quiet
```

## Backend Service `cf-backend`

```bash
gcloud compute backend-services delete "$CF_BACKEND_BS" \
  --region="$REGION" \
  --quiet
```

## Backend Service `cr-backend`

```bash
gcloud compute backend-services delete "$CR_BACKEND_BS" \
  --region="$REGION" \
  --quiet
```

## Serverless NEG `cf-default`

```bash
gcloud compute network-endpoint-groups delete "$CF_DEFAULT_NEG" \
  --region="$REGION" \
  --quiet
```

## Serverless NEG `cf-backend`

```bash
gcloud compute network-endpoint-groups delete "$CF_BACKEND_NEG" \
  --region="$REGION" \
  --quiet
```

## Serverless NEG `cr-backend`

```bash
gcloud compute network-endpoint-groups delete "$CR_BACKEND_NEG" \
  --region="$REGION" \
  --quiet
```

## VM cliente

```bash
gcloud compute instances delete "$CLIENT" \
  --zone="$ZONE" \
  --quiet
```

## Regra IAP

```bash
gcloud compute firewall-rules delete \
  allow-iap-ssh-serverless-ialb \
  --quiet
```

## Cloud Function `cf-backend`

```bash
gcloud functions delete "$CF_BACKEND" \
  --gen2 \
  --region="$REGION" \
  --quiet
```

## Cloud Function `cf-default`

```bash
gcloud functions delete "$CF_DEFAULT" \
  --gen2 \
  --region="$REGION" \
  --quiet
```

## Cloud Run

```bash
gcloud run services delete "$CR_BACKEND" \
  --region="$REGION" \
  --quiet
```

## Proxy-only subnet

```bash
gcloud compute networks subnets delete "$PROXY_SUBNET" \
  --region="$REGION" \
  --quiet
```

## Arquivos locais

```bash
rm -rf \
  cf-default \
  cf-backend \
  cr-backend

rm -f \
  url-map.yaml \
  url-map-broken.yaml \
  url-map-current.yaml \
  url-map-fixed.yaml \
  url-map-exported.yaml
```

---

# 62. Checklist final

- [ ] Criei `cf-default`;
- [ ] Entendo que `cf-default` é o backend padrão;
- [ ] Criei `cf-backend`;
- [ ] Criei `cr-backend`;
- [ ] Criei três Serverless NEGs;
- [ ] Criei três Backend Services;
- [ ] Criei a proxy-only subnet;
- [ ] Criei o URL Map base;
- [ ] Criei `url-map.yaml`;
- [ ] Configurei `cf-default` como `defaultService`;
- [ ] Configurei `/cf-backend → cf-backend`;
- [ ] Configurei `/cr-backend → cr-backend`;
- [ ] Apliquei o YAML com `gcloud compute url-maps import`;
- [ ] Exportei o URL Map com `gcloud compute url-maps export`;
- [ ] Entendo quando `urlRewrite` é necessário;
- [ ] Entendo a diferença entre routing e rewriting;
- [ ] Criei o Target HTTP Proxy;
- [ ] Criei a Forwarding Rule `INTERNAL_MANAGED`;
- [ ] Testei `/`;
- [ ] Testei um path sem regra e observei `cf-default`;
- [ ] Testei `/cf-backend`;
- [ ] Testei `/cr-backend`;
- [ ] Quebrei propositalmente `/cr-backend`;
- [ ] Identifiquei o problema no URL Map;
- [ ] Corrigi o YAML;
- [ ] Reimportei a configuração correta;
- [ ] Entendo Backend Service x Serverless NEG;
- [ ] Entendo Path Rule x Default Service;
- [ ] Removi os recursos.

---

# 63. O que memorizar para o ACE

```text
Forwarding Rule
      ↓
Target HTTP Proxy
      ↓
URL Map
      ↓
Backend Service
      ↓
Serverless NEG
      ↓
Serverless application
```

O ponto central deste laboratório é:

```text
                         URL Map
                            |
               +------------+------------+
               |            |            |
         /cf-backend  /cr-backend     default
               |            |            |
               v            v            v
          cf-backend   cr-backend    cf-default
```

Portanto:

```text
Path conhecido
→ Backend específico
```

```text
Path sem regra
→ Default Backend
```

E:

```text
Routing
→ escolhe o backend
```

```text
URL Rewrite
→ altera o host e/ou path enviado ao backend
```

---

# 64. Referências oficiais

- Google Cloud — Regional Internal Application Load Balancer with Cloud Run:
  https://cloud.google.com/load-balancing/docs/l7-internal/setting-up-l7-internal-serverless

- Google Cloud — Serverless NEGs:
  https://cloud.google.com/load-balancing/docs/negs/serverless-neg-concepts

- Google Cloud — Traffic management for Internal Application Load Balancers:
  https://cloud.google.com/load-balancing/docs/l7-internal/setting-up-traffic-management
