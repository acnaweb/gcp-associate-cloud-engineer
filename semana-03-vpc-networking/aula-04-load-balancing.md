# Aula 4 — Load Balancing no Google Cloud

## Objetivos

Ao final, você deverá:

- Entender por que usamos Load Balancers;
- Diferenciar **Application Load Balancer** e **Network Load Balancer**;
- Diferenciar **External** e **Internal Load Balancer**;
- Entender os conceitos de **frontend**, **forwarding rule**, **target proxy**, **URL map**, **backend service**, **health check** e **backend**;
- Entender a integração entre **Load Balancer e Managed Instance Group (MIG)**;
- Criar um **Global External Application Load Balancer HTTP** usando `gcloud`;
- Criar um **Internal Passthrough Network Load Balancer regional** usando `gcloud`;
- Criar um **Regional Internal Application Load Balancer HTTP** usando `gcloud`;
- Testar a distribuição de tráfego entre múltiplas VMs;
- Simular a falha de uma aplicação e observar o comportamento do health check;
- Diferenciar **Load Balancing**, **Health Check**, **Autohealing** e **Autoscaling**;
- Remover todos os recursos criados no laboratório.

---

# 1. Por que Load Balancing?

Imagine uma aplicação executando em apenas uma VM:

```text
Internet
   |
   v
+------+
| VM 1 |
+------+
```

Problemas:

- Se a VM falhar, a aplicação fica indisponível;
- Toda a carga fica concentrada em uma única máquina;
- Escalar a aplicação exige intervenção;
- O cliente precisa conhecer o endereço da VM.

Com Load Balancer:

```text
             Internet
                |
                v
        +----------------+
        | Load Balancer  |
        +----------------+
           |          |
           v          v
        +------+   +------+
        | VM 1 |   | VM 2 |
        +------+   +------+
```

O cliente conhece apenas o endereço do Load Balancer.

---

# 2. O que o Load Balancer resolve?

Principais benefícios:

- Distribuição de tráfego;
- Alta disponibilidade;
- Abstração dos backends;
- Integração com health checks;
- Integração com grupos de instâncias;
- Possibilidade de escalar horizontalmente;
- Um único ponto de entrada para clientes.

> O Load Balancer distribui tráfego. Ele não cria novas VMs automaticamente.

Quem pode criar ou remover VMs automaticamente é o **autoscaler do Managed Instance Group**.

---

# 3. Application Load Balancer x Network Load Balancer

## Application Load Balancer

Opera na camada de aplicação.

Principal cenário:

```text
HTTP
HTTPS
HTTP/2
```

Exemplo:

```text
Browser
   |
 HTTP
   v
Application Load Balancer
```

Por entender HTTP/HTTPS, pode realizar roteamento baseado em elementos da requisição.

```text
/api/*
   |
   +------> Backend API

/images/*
   |
   +------> Backend Images
```

## Network Load Balancer

Trabalha principalmente com tráfego de camada 4.

Exemplos:

```text
TCP
UDP
```

---

# 4. External x Internal

A diferença principal está em **quem consegue alcançar o frontend** do Load Balancer.

| Característica | External Load Balancer | Internal Load Balancer |
|---|---|---|
| Clientes | Internet e/ou origens externas permitidas | Clientes internos autorizados |
| Frontend | Endereço externo | Endereço interno |
| Uso típico | Site público, API pública | API interna, serviço entre aplicações |
| Exposição | Fora da conectividade privada | Dentro da conectividade privada |

## External

```text
Internet
   |
   v
Frontend externo
   |
   v
External Load Balancer
   |
   v
Backends
```

Use quando o serviço precisa receber tráfego externo.

## Internal

```text
VM / Serviço interno
        |
        v
Frontend interno
        |
        v
Internal Load Balancer
        |
        v
Backends privados
```

Use quando o serviço deve permanecer acessível apenas por conectividade privada autorizada.

Modelo mental para a ACE:

```text
External
→ entrada externa

Internal
→ entrada privada
```

---

# 5. Global x Regional

Para o ACE, pense primeiro nos requisitos:

```text
Interno ou externo?
        |
        v
HTTP/HTTPS ou TCP/UDP?
        |
        v
Global ou regional?
        |
        v
Que tipo de backend?
```

Neste laboratório criaremos um:

> **Global External Application Load Balancer HTTP**

---

# 6. Componentes que vamos construir

```text
Cliente
   |
   | HTTP :80
   v
+--------------------+
| Forwarding Rule    |
| IP público :80     |
+--------------------+
          |
          v
+--------------------+
| Target HTTP Proxy  |
+--------------------+
          |
          v
+--------------------+
| URL Map            |
+--------------------+
          |
          v
+--------------------+
| Backend Service    |
+--------------------+
          |
          +---------------- Health Check
          |
          v
+---------------------------+
| Regional Managed          |
| Instance Group (MIG)      |
+---------------------------+
       |              |
       v              v
   +------+        +------+
   | VM 1 |        | VM 2 |
   | nginx|        | nginx|
   +------+        +------+
```

---

# 7. Como pensar nos componentes

## Frontend

O **frontend** é o ponto de entrada usado pelo cliente para acessar o Load Balancer.

Pense nele como a combinação de:

```text
IP
+
porta
+
protocolo
+
forwarding rule
```

Exemplo:

```text
Cliente
   |
   v
IP:porta do frontend
   |
   v
Forwarding Rule
   |
   v
Target Proxy
   |
   v
URL Map
   |
   v
Backend Service
```

Modelo mental:

```text
Frontend
→ onde o cliente chega

Backend
→ onde a aplicação executa
```

## Forwarding Rule

É um componente do frontend do Load Balancer.

Define principalmente:

```text
IP + porta + protocolo
```

## Target HTTP Proxy

Recebe a conexão HTTP encaminhada pela forwarding rule e consulta o URL map.

## URL Map

Define para onde uma requisição HTTP será enviada.

## Backend Service

Associa:

- Backends;
- Health check;
- Protocolo;
- Política de balanceamento.

## Managed Instance Group

É o conjunto de VMs que executará nossa aplicação.

## Health Check

Verifica se os backends estão saudáveis.

```text
VM 1 -> HTTP :80 -> OK
VM 2 -> HTTP :80 -> OK
```

---

# 8. Laboratório — visão geral

Vamos criar:

```text
1. Configuration do gcloud
2. Instance Template
3. Regional MIG
4. Named Port
5. Firewall
6. Health Check
7. Backend Service
8. Backend
9. IP público
10. URL Map
11. Target HTTP Proxy
12. Forwarding Rule
13. Teste
14. Falha
15. Autoscaling
16. Limpeza
```

---

# 9. Pré-requisitos

Você precisa de:

- Projeto Google Cloud;
- Billing habilitado;
- Cloud Shell ou `gcloud` instalado;
- Permissão para criar recursos Compute Engine.

Verifique o projeto atual:

```bash
# Explicação: Consulta o projeto atualmente ativo na configuração `gcloud`.
gcloud config get-value project
```

Liste as configurations:

```bash
# Explicação: Lista as configurações do `gcloud` existentes na máquina/Cloud Shell.
gcloud config configurations list
```

---

# 10. Criando uma configuration exclusiva para o laboratório

Crie:

```bash
# Explicação: Cria uma configuração nomeada do `gcloud` para isolar projeto, região, zona e outras propriedades.
gcloud config configurations create ace-lb-lab
```

Ative:

```bash
# Explicação: Ativa a configuração nomeada do `gcloud` que será usada nos próximos comandos.
gcloud config configurations activate ace-lb-lab
```

Defina o projeto:

```bash
# Explicação: Define o projeto ativo da configuração `gcloud`, evitando informar `--project` em cada comando.
gcloud config set project SEU_PROJECT_ID
```

Defina região e zona:

```bash
# Explicação: Define a região padrão da configuração `gcloud` para comandos regionais.
gcloud config set compute/region us-central1
# Explicação: Define a zona padrão da configuração `gcloud` para comandos zonais.
gcloud config set compute/zone us-central1-a
```

Veja a configuration:

```bash
# Explicação: Exibe as propriedades da configuração `gcloud` ativa para conferência.
gcloud config list
```

> Uma configuration não cria infraestrutura. Ela apenas mantém contexto para os comandos `gcloud`.

---

# 11. Habilitando a API necessária

```bash
# Explicação: Habilita a API/serviço indicado no projeto ativo para permitir o uso do recurso no laboratório.
gcloud services enable compute.googleapis.com
```

Verifique:

```bash
# Explicação: Lista as APIs já habilitadas no projeto para confirmar a configuração.
gcloud services list --enabled \
  --filter="NAME:compute.googleapis.com"
```

---

# 12. Variáveis do laboratório

```bash
# Explicação: Define `REGION` com o valor da região padrão usada pelos recursos do laboratório.
export REGION=us-central1
# Explicação: Define a variável `TEMPLATE` usada nas próximas etapas do laboratório.
export TEMPLATE=ace-web-template
# Explicação: Define a variável `MIG` usada nas próximas etapas do laboratório.
export MIG=ace-web-mig
# Explicação: Define a variável `HEALTH_CHECK` usada nas próximas etapas do laboratório.
export HEALTH_CHECK=ace-http-health-check
# Explicação: Define a variável `BACKEND` usada nas próximas etapas do laboratório.
export BACKEND=ace-web-backend
# Explicação: Define a variável `IP_NAME` usada nas próximas etapas do laboratório.
export IP_NAME=ace-lb-ip
# Explicação: Define a variável `URL_MAP` usada nas próximas etapas do laboratório.
export URL_MAP=ace-web-map
# Explicação: Define a variável `HTTP_PROXY` usada nas próximas etapas do laboratório.
export HTTP_PROXY=ace-http-proxy
# Explicação: Define a variável `FORWARDING_RULE` usada nas próximas etapas do laboratório.
export FORWARDING_RULE=ace-http-forwarding-rule
```

---

# 13. Criando o startup script

```bash
# Explicação: Exibe conteúdo de arquivo ou cria conteúdo via redirecionamento/heredoc, conforme a sintaxe usada.
cat > startup.sh <<'SCRIPT'
#!/bin/bash
apt-get update
apt-get install -y nginx

HOSTNAME=$(hostname)

cat > /var/www/html/index.html <<HTML
<!DOCTYPE html>
<html>
<head>
    <title>ACE Load Balancer Lab</title>
</head>
<body>
    <h1>Google Cloud ACE</h1>
    <h2>Load Balancing Lab</h2>
    <p>Respondendo pela VM:</p>
    <h2>${HOSTNAME}</h2>
</body>
</html>
HTML

systemctl enable nginx
systemctl restart nginx
SCRIPT
```

Cada VM exibirá seu próprio hostname.

---

# 14. Criando o Instance Template

```bash
# Explicação: Cria um Instance Template reutilizável para padronizar as VMs de um Managed Instance Group.
gcloud compute instance-templates create $TEMPLATE \
  --machine-type=e2-micro \
  --image-family=debian-12 \
  --image-project=debian-cloud \
  --tags=allow-health-check \
  --metadata-from-file=startup-script=startup.sh
```

Liste:

```bash
# Explicação: Executa `gcloud compute instance-templates list` nesta etapa para aplicar ou inspecionar a configuração indicada.
gcloud compute instance-templates list
```

Relação:

```text
Instance Template
       |
       v
      VMs
```

---

# 15. Criando o Regional MIG

```bash
# Explicação: Cria um Managed Instance Group baseado no template informado.
gcloud compute instance-groups managed create $MIG \
  --template=$TEMPLATE \
  --size=2 \
  --region=$REGION \
  --zones=us-central1-a,us-central1-b
```

Liste:

```bash
# Explicação: Executa `gcloud compute instance-groups managed list` nesta etapa para aplicar ou inspecionar a configuração indicada.
gcloud compute instance-groups managed list
```

Veja as VMs:

```bash
# Explicação: Lista as VMs pertencentes ao Managed Instance Group e seus estados.
gcloud compute instance-groups managed list-instances $MIG \
  --region=$REGION
```

---

# 16. Configurando Named Port

```bash
# Explicação: Define named ports no MIG para que o backend service saiba qual porta lógica atender.
gcloud compute instance-groups managed set-named-ports $MIG \
  --named-ports=http:80 \
  --region=$REGION
```

Verifique:

```bash
# Explicação: Executa `gcloud compute instance-groups managed get-named-ports $MIG --region=$REGION` nesta etapa para aplicar ou inspecionar a configuração indicada.
gcloud compute instance-groups managed get-named-ports $MIG \
  --region=$REGION
```

Resultado conceitual:

```text
http -> 80
```

> Named port não abre firewall.

---

# 17. Criando a regra de firewall

Para backends de instance group de um Global External Application Load Balancer, permita as faixas usadas pela infraestrutura do Google Cloud neste cenário.

```bash
# Explicação: Cria uma regra de firewall VPC; direção, origem/destino, alvo e protocolos/portas são definidos pelas flags.
gcloud compute firewall-rules create ace-allow-lb-health-check \
  --network=default \
  --action=allow \
  --direction=INGRESS \
  --target-tags=allow-health-check \
  --source-ranges=35.191.0.0/16,130.211.0.0/22 \
  --rules=tcp:80
```

Verifique:

```bash
# Explicação: Exibe detalhes da regra de firewall para confirmar prioridade, direção, ranges, alvos e ações.
gcloud compute firewall-rules describe ace-allow-lb-health-check
```

---

# 18. Criando o Health Check

```bash
# Explicação: Cria o health check que o load balancer/MIG usará para determinar se backends estão saudáveis.
gcloud compute health-checks create http $HEALTH_CHECK \
  --port=80 \
  --request-path=/
```

Liste:

```bash
# Explicação: Executa `gcloud compute health-checks list` nesta etapa para aplicar ou inspecionar a configuração indicada.
gcloud compute health-checks list
```

---

# 19. Criando o Backend Service

```bash
# Explicação: Cria o Backend Service do load balancer e associa parâmetros como protocolo e health check.
gcloud compute backend-services create $BACKEND \
  --load-balancing-scheme=EXTERNAL_MANAGED \
  --protocol=HTTP \
  --port-name=http \
  --health-checks=$HEALTH_CHECK \
  --global
```

Liste:

```bash
# Explicação: Executa `gcloud compute backend-services list` nesta etapa para aplicar ou inspecionar a configuração indicada.
gcloud compute backend-services list
```

---

# 20. Adicionando o MIG ao Backend Service

```bash
# Explicação: Adiciona o grupo de instâncias como backend do Backend Service.
gcloud compute backend-services add-backend $BACKEND \
  --instance-group=$MIG \
  --instance-group-region=$REGION \
  --balancing-mode=UTILIZATION \
  --max-utilization=0.8 \
  --global
```

Descreva:

```bash
# Explicação: Exibe a configuração do Backend Service para inspeção.
gcloud compute backend-services describe $BACKEND \
  --global
```

---

# 21. Verificando a saúde dos backends

```bash
# Explicação: Consulta a saúde dos backends vista pelo load balancer.
gcloud compute backend-services get-health $BACKEND \
  --global
```

Inicialmente pode aparecer `UNKNOWN`.

Depois, o esperado é:

```text
HEALTHY
```

---

# 22. Reservando o IP público

```bash
# Explicação: Reserva um endereço IP estático interno ou externo conforme escopo e flags informados.
gcloud compute addresses create $IP_NAME \
  --ip-version=IPV4 \
  --network-tier=PREMIUM \
  --global
```

Veja:

```bash
# Explicação: Exibe o endereço IP reservado e suas propriedades.
gcloud compute addresses describe $IP_NAME \
  --global \
  --format="value(address)"
```

Salve:

```bash
# Explicação: Define a variável `LB_IP` usada nas próximas etapas do laboratório.
export LB_IP=$(gcloud compute addresses describe $IP_NAME \
  --global \
  --format="value(address)")
```

Confira:

```bash
# Explicação: Exibe ou grava o valor/texto informado, normalmente para validar variável ou criar conteúdo de teste.
echo $LB_IP
```

---

# 23. Criando o URL Map

```bash
# Explicação: Cria o URL Map que define para qual Backend Service as requisições HTTP serão encaminhadas.
gcloud compute url-maps create $URL_MAP \
  --default-service=$BACKEND
```

Descreva:

```bash
# Explicação: Executa `gcloud compute url-maps describe $URL_MAP` nesta etapa para aplicar ou inspecionar a configuração indicada.
gcloud compute url-maps describe $URL_MAP
```

---

# 24. Criando o Target HTTP Proxy

```bash
# Explicação: Cria o Target HTTP Proxy que associa o frontend HTTP ao URL Map.
gcloud compute target-http-proxies create $HTTP_PROXY \
  --url-map=$URL_MAP
```

Liste:

```bash
# Explicação: Executa `gcloud compute target-http-proxies list` nesta etapa para aplicar ou inspecionar a configuração indicada.
gcloud compute target-http-proxies list
```

---

# 25. Criando a Forwarding Rule

```bash
# Explicação: Cria a Forwarding Rule que publica o frontend do load balancer no IP/porta definidos.
gcloud compute forwarding-rules create $FORWARDING_RULE \
  --load-balancing-scheme=EXTERNAL_MANAGED \
  --network-tier=PREMIUM \
  --address=$IP_NAME \
  --global \
  --target-http-proxy=$HTTP_PROXY \
  --ports=80
```

Liste:

```bash
# Explicação: Lista Forwarding Rules para localizar os frontends de load balancers.
gcloud compute forwarding-rules list
```

---

# 26. Arquitetura construída

```text
                         INTERNET
                            |
                            | HTTP :80
                            v
                   +------------------+
                   | Forwarding Rule  |
                   |     Public IP    |
                   +------------------+
                            |
                            v
                   +------------------+
                   | Target HTTP      |
                   | Proxy            |
                   +------------------+
                            |
                            v
                   +------------------+
                   | URL Map          |
                   +------------------+
                            |
                            v
                   +------------------+
                   | Backend Service  |
                   +------------------+
                       |          |
                       |          +------ Health Check
                       |
                       v
                 +-------------+
                 | Regional MIG|
                 +-------------+
                    |       |
                    v       v
                  VM 1     VM 2
                  nginx    nginx
```

---

# 27. Testando o Load Balancer

```bash
# Explicação: Exibe ou grava o valor/texto informado, normalmente para validar variável ou criar conteúdo de teste.
echo $LB_IP
# Explicação: Envia uma requisição HTTP ao endpoint informado para testar conectividade, resposta ou comportamento da aplicação.
curl http://$LB_IP
```

Execute várias vezes:

```bash
# Explicação: Executa `for i in {1..10}; do` nesta etapa para aplicar ou inspecionar a configuração indicada.
for i in {1..10}; do
  # Explicação: Envia uma requisição HTTP ao endpoint informado para testar conectividade, resposta ou comportamento da aplicação.
  curl -s http://$LB_IP | grep "ace-web-mig"
done
```

Você deverá observar respostas de VMs diferentes.

> Em poucos requests, a distribuição não precisa ser perfeitamente 50/50.

---

# 28. Abrindo no navegador

```bash
# Explicação: Exibe ou grava o valor/texto informado, normalmente para validar variável ou criar conteúdo de teste.
echo "http://$LB_IP"
```

Abra o endereço no navegador.

---

# 29. Simulando falha de uma VM

Liste as instâncias:

```bash
# Explicação: Lista as VMs pertencentes ao Managed Instance Group e seus estados.
gcloud compute instance-groups managed list-instances $MIG \
  --region=$REGION
```

Escolha uma VM e sua zona:

```bash
# Explicação: Define a variável `VM_FALHA` usada nas próximas etapas do laboratório.
export VM_FALHA=NOME_DA_VM
# Explicação: Define a variável `VM_FALHA_ZONE` usada nas próximas etapas do laboratório.
export VM_FALHA_ZONE=ZONA_DA_VM
```

Entre:

```bash
# Explicação: Abre uma sessão SSH na VM indicada; flags adicionais podem executar um comando remotamente.
gcloud compute ssh $VM_FALHA \
  --zone=$VM_FALHA_ZONE
```

Pare o nginx:

```bash
# Explicação: Interrompe propositalmente o serviço systemd indicado para simular a falha do laboratório.
sudo systemctl stop nginx
```

Saia:

```bash
# Explicação: Encerra a sessão atual do shell/SSH e retorna ao terminal anterior.
exit
```

---

# 30. Observando o Health Check

```bash
# Explicação: Consulta a saúde dos backends vista pelo load balancer.
gcloud compute backend-services get-health $BACKEND \
  --global
```

Depois de alguns ciclos, uma VM deverá ficar:

```text
UNHEALTHY
```

Teste novamente:

```bash
# Explicação: Executa `for i in {1..10}; do` nesta etapa para aplicar ou inspecionar a configuração indicada.
for i in {1..10}; do
  # Explicação: Envia uma requisição HTTP ao endpoint informado para testar conectividade, resposta ou comportamento da aplicação.
  curl -s http://$LB_IP | grep "ace-web-mig"
done
```

O tráfego continuará sendo atendido pelo backend saudável.

---

# 31. Health Check x Autohealing

## Load Balancer Health Check

```text
Detecta backend não saudável
        |
        v
Retira do tráfego
```

## MIG Autohealing

```text
VM não saudável
      |
      v
MIG detecta falha
      |
      v
Repara / recria VM
```

São mecanismos diferentes.

---

# 32. Recuperando a VM

```bash
# Explicação: Abre uma sessão SSH na VM indicada; flags adicionais podem executar um comando remotamente.
gcloud compute ssh $VM_FALHA \
  --zone=$VM_FALHA_ZONE
```

Dentro da VM:

```bash
# Explicação: Inicia o serviço systemd indicado para restaurar o funcionamento.
sudo systemctl start nginx
# Explicação: Encerra a sessão atual do shell/SSH e retorna ao terminal anterior.
exit
```

Verifique novamente:

```bash
# Explicação: Consulta a saúde dos backends vista pelo load balancer.
gcloud compute backend-services get-health $BACKEND \
  --global
```

---

# 33. Adicionando Autoscaling ao MIG

```bash
# Explicação: Configura autoscaling do Managed Instance Group conforme a métrica/alvo e limites definidos.
gcloud compute instance-groups managed set-autoscaling $MIG \
  --region=$REGION \
  --min-num-replicas=2 \
  --max-num-replicas=4 \
  --target-cpu-utilization=0.60 \
  --cool-down-period=60
```

Veja:

```bash
# Explicação: Exibe configuração, target size, políticas e estado do Managed Instance Group.
gcloud compute instance-groups managed describe $MIG \
  --region=$REGION
```

---

# 34. Load Balancer x Autoscaling

```text
Load Balancer
   -> distribui tráfego

Autoscaler
   -> aumenta ou reduz VMs

MIG
   -> mantém o grupo de VMs

Health Check
   -> identifica a saúde do backend
```

---

# 35. Investigando recursos

```bash
# Explicação: Lista Forwarding Rules para localizar os frontends de load balancers.
gcloud compute forwarding-rules list

# Explicação: Executa `gcloud compute target-http-proxies list` nesta etapa para aplicar ou inspecionar a configuração indicada.
gcloud compute target-http-proxies list

# Explicação: Executa `gcloud compute url-maps list` nesta etapa para aplicar ou inspecionar a configuração indicada.
gcloud compute url-maps list

# Explicação: Executa `gcloud compute backend-services list` nesta etapa para aplicar ou inspecionar a configuração indicada.
gcloud compute backend-services list

# Explicação: Executa `gcloud compute health-checks list` nesta etapa para aplicar ou inspecionar a configuração indicada.
gcloud compute health-checks list

# Explicação: Executa `gcloud compute instance-groups managed list` nesta etapa para aplicar ou inspecionar a configuração indicada.
gcloud compute instance-groups managed list
```

Agora esses comandos têm contexto: você criou cada recurso.

---

# 36. Desafio prático

Complete:

```text
IP público
    |
    v
?????????
    |
    v
Target HTTP Proxy
    |
    v
?????????
    |
    v
Backend Service
    |
    v
?????????
    |
    v
VMs
```

Resposta:

```text
IP público
    |
    v
Forwarding Rule
    |
    v
Target HTTP Proxy
    |
    v
URL Map
    |
    v
Backend Service
    |
    v
MIG
    |
    v
VMs
```

---

# 37. Exercício de investigação

Utilizando somente `gcloud`, encontre:

1. IP público do Load Balancer;
2. Porta publicada;
3. Target proxy;
4. URL map;
5. Backend service;
6. Health check;
7. MIG;
8. VMs;
9. Região do MIG;
10. Status dos backends.

---

# 38. Fluxo mental para o ACE

```text
1. Interno ou externo?
2. HTTP/HTTPS ou TCP/UDP?
3. Global ou regional?
4. Qual tipo de backend?
5. Como verificar a saúde?
6. Precisa autoscaling?
```

---

# 39. Pegadinhas ACE

- Load Balancer não faz autoscaling;
- MIG não é Load Balancer;
- Named Port não abre firewall;
- Health check não é apenas monitoramento;
- Backend Service não é uma VM;
- URL Map não armazena o IP público;
- Health Check e Autohealing são conceitos diferentes.

---

# 40. Questões estilo ACE

## Questão 1

Aplicação HTTP pública deve distribuir requisições entre várias VMs e remover backends que parem de responder.

**Resposta:** External Application Load Balancer + Backend Service + Health Check + Instance Group/MIG.

## Questão 2

É necessário aumentar a quantidade de VMs quando a CPU subir.

**Resposta:** Autoscaling do MIG.

## Questão 3

A VM existe, mas a aplicação HTTP não responde.

**Resposta:** Health Check detecta a condição para o Load Balancer.

## Questão 4

`/api/*` deve ir para um backend e `/images/*` para outro.

**Resposta:** URL Map.

## Questão 5

Qual recurso define o IP e porta de entrada?

**Resposta:** Forwarding Rule.

---

# Laboratório 2 — Internal Passthrough Network Load Balancer

Agora vamos construir um segundo Load Balancer, desta vez **interno**.

O primeiro laboratório criou:

```text
Internet
   ↓
Global External Application Load Balancer
   ↓
MIG
```

Agora construiremos:

```text
VM cliente
   ↓
IP interno
   ↓
Internal Passthrough Network Load Balancer
   ↓
mesmo MIG
```

O objetivo é comparar as duas arquiteturas sem recriar desnecessariamente os backends.

---

## Arquitetura do Laboratório 2

```text
                      VPC default
                          |
                          |
                  +----------------+
                  | VM cliente     |
                  +----------------+
                          |
                          | HTTP :80
                          v
                  +----------------+
                  | Internal IP    |
                  | regional       |
                  +----------------+
                          |
                          v
                  +----------------+
                  | Forwarding Rule|
                  | INTERNAL       |
                  +----------------+
                          |
                          v
                  +----------------+
                  | Backend Service|
                  | regional / TCP |
                  +----------------+
                          |
                    Health Check
                          |
                          v
                  +----------------+
                  | Regional MIG   |
                  +----------------+
                     |          |
                     v          v
                   VM 1        VM 2
                   nginx       nginx
```

Observe uma diferença importante em relação ao Application Load Balancer:

```text
Internal Passthrough Network Load Balancer
→ não usa Target HTTP Proxy
→ não usa URL Map
```

Ele opera como um Load Balancer de camada 4.

---

## Variáveis do Laboratório 2

```bash
# Nome do health check regional.
export ILB_HEALTH_CHECK=ace-ilb-health-check

# Nome do backend service regional.
export ILB_BACKEND=ace-ilb-backend

# Nome do endereço IP interno reservado.
export ILB_IP_NAME=ace-ilb-ip

# Nome da forwarding rule interna.
export ILB_FORWARDING_RULE=ace-ilb-forwarding-rule

# VM que atuará como cliente do Internal Load Balancer.
export ILB_CLIENT=ace-ilb-client

# Zona da VM cliente.
export ILB_CLIENT_ZONE=us-central1-a
```

---

## Inspecionar a subnet usada

Neste laboratório vamos reutilizar a subnet `default` da região.

```bash
# Exibe a faixa CIDR da subnet default em us-central1.
gcloud compute networks subnets describe default \
  --region="$REGION" \
  --format="table(name,region,ipCidrRange,network)"
```

Armazene o CIDR:

```bash
export ILB_SUBNET_CIDR="$(gcloud compute networks subnets describe default \
  --region="$REGION" \
  --format='value(ipCidrRange)')"

echo "$ILB_SUBNET_CIDR"
```

---

## Criar o Health Check regional

O primeiro laboratório usou um health check global.

Para este Internal Passthrough Network Load Balancer, usaremos um **health check regional**.

```bash
# Cria um health check HTTP regional na porta 80.
gcloud compute health-checks create http "$ILB_HEALTH_CHECK" \
  --region="$REGION" \
  --port=80
```

Inspecione:

```bash
gcloud compute health-checks describe "$ILB_HEALTH_CHECK" \
  --region="$REGION"
```

---

## Criar o Backend Service interno

```bash
# Cria o backend service regional do Internal Passthrough Network Load Balancer.
#
# --load-balancing-scheme=INTERNAL
#   define que este backend pertence a um Internal Passthrough Network Load Balancer.
#
# --protocol=TCP
#   define o protocolo de camada 4 usado pelo backend service.
gcloud compute backend-services create "$ILB_BACKEND" \
  --load-balancing-scheme=INTERNAL \
  --protocol=TCP \
  --region="$REGION" \
  --health-checks="$ILB_HEALTH_CHECK" \
  --health-checks-region="$REGION"
```

Inspecione:

```bash
gcloud compute backend-services describe "$ILB_BACKEND" \
  --region="$REGION"
```

---

## Adicionar o MIG ao backend interno

Vamos reutilizar o mesmo Regional MIG criado no primeiro laboratório.

```bash
# Adiciona o Regional MIG como backend do serviço interno.
gcloud compute backend-services add-backend "$ILB_BACKEND" \
  --region="$REGION" \
  --instance-group="$MIG" \
  --instance-group-region="$REGION"
```

Verifique:

```bash
gcloud compute backend-services describe "$ILB_BACKEND" \
  --region="$REGION"
```

Modelo:

```text
External Application LB
          \
           \
            → Regional MIG
           /
          /
Internal Passthrough LB
```

O mesmo grupo pode participar de diferentes arquiteturas de Load Balancing, desde que as configurações sejam compatíveis.

---

## Reservar um IP interno regional

```bash
# Reserva um IP interno na subnet default da região.
gcloud compute addresses create "$ILB_IP_NAME" \
  --region="$REGION" \
  --subnet=default
```

Obtenha o endereço:

```bash
export ILB_IP="$(gcloud compute addresses describe "$ILB_IP_NAME" \
  --region="$REGION" \
  --format='value(address)')"

echo "$ILB_IP"
```

Modelo:

```text
IP interno
→ pertence à subnet
→ não é endereço público da internet
```

---

## Criar regra de firewall para clientes internos

O firewall existente já permite os health checks para as VMs do MIG.

Agora precisamos permitir que clientes da subnet acessem HTTP nos backends.

```bash
# Permite TCP/80 a partir da própria subnet
# para as VMs do MIG que possuem a tag allow-health-check.
gcloud compute firewall-rules create ace-ilb-allow-client \
  --network=default \
  --direction=INGRESS \
  --action=ALLOW \
  --rules=tcp:80 \
  --source-ranges="$ILB_SUBNET_CIDR" \
  --target-tags=allow-health-check
```

Inspecione:

```bash
gcloud compute firewall-rules describe ace-ilb-allow-client
```

---

## Criar a Forwarding Rule interna

A forwarding rule será regional e usará o IP interno reservado.

```bash
# Cria o frontend do Internal Passthrough Network Load Balancer.
gcloud compute forwarding-rules create "$ILB_FORWARDING_RULE" \
  --region="$REGION" \
  --load-balancing-scheme=INTERNAL \
  --network=default \
  --subnet=default \
  --address="$ILB_IP" \
  --ip-protocol=TCP \
  --ports=80 \
  --backend-service="$ILB_BACKEND" \
  --backend-service-region="$REGION"
```

Inspecione:

```bash
gcloud compute forwarding-rules describe "$ILB_FORWARDING_RULE" \
  --region="$REGION"
```

Observe:

```text
loadBalancingScheme
→ INTERNAL

IPAddress
→ endereço privado

region
→ us-central1
```

---

## Verificar a saúde dos backends

```bash
# Consulta a saúde do backend regional.
gcloud compute backend-services get-health "$ILB_BACKEND" \
  --region="$REGION"
```

Espere até os backends aparecerem como:

```text
HEALTHY
```

---

## Criar uma VM cliente

Cloud Shell está fora da VPC do laboratório e não é o melhor local para testar diretamente um frontend privado.

Por isso, criaremos uma VM cliente na mesma VPC.

```bash
# Cria uma VM cliente na VPC default.
gcloud compute instances create "$ILB_CLIENT" \
  --zone="$ILB_CLIENT_ZONE" \
  --machine-type=e2-micro \
  --image-family=debian-12 \
  --image-project=debian-cloud \
  --network=default
```

Inspecione:

```bash
gcloud compute instances describe "$ILB_CLIENT" \
  --zone="$ILB_CLIENT_ZONE" \
  --format="table(name,networkInterfaces[0].networkIP,status)"
```

---

## Testar o Internal Load Balancer

Execute o teste diretamente por SSH, sem abrir sessão interativa:

```bash
# Instala curl na VM cliente e acessa o IP interno do Load Balancer.
gcloud compute ssh "$ILB_CLIENT" \
  --zone="$ILB_CLIENT_ZONE" \
  --command="sudo apt-get update -qq && sudo apt-get install -y curl >/dev/null && curl -s http://$ILB_IP"
```

Execute várias vezes:

```bash
for i in {1..10}; do
  gcloud compute ssh "$ILB_CLIENT" \
    --zone="$ILB_CLIENT_ZONE" \
    --command="curl -s http://$ILB_IP | grep ace-web-mig"
done
```

Você deverá observar respostas dos backends do MIG.

O fluxo agora é:

```text
VM cliente
   |
   | IP privado :80
   v
Internal Forwarding Rule
   |
   v
Regional Backend Service
   |
   v
Regional MIG
```

---

## Comparação prática dos dois laboratórios

| Item | Laboratório 1 | Laboratório 2 |
|---|---|---|
| Tipo | Application Load Balancer | Passthrough Network Load Balancer |
| Alcance | External | Internal |
| Escopo | Global | Regional |
| Protocolo de frontend | HTTP | TCP |
| IP | Público | Privado |
| Target Proxy | Sim | Não |
| URL Map | Sim | Não |
| Backend Service | Global | Regional |
| Health Check | Global | Regional |
| Backend | Regional MIG | Mesmo Regional MIG |

Para a ACE:

```text
Application Load Balancer
→ entende HTTP
→ pode usar URL Map

Passthrough Network Load Balancer
→ camada 4
→ não usa URL Map
→ não usa Target HTTP Proxy
```

---

## Quebrar propositalmente

Agora vamos quebrar **somente o firewall de tráfego do cliente**.

Remova a regra:

```bash
# Remove a regra que permite o tráfego da VM cliente aos backends.
gcloud compute firewall-rules delete ace-ilb-allow-client \
  --quiet
```

Repita o teste:

```bash
gcloud compute ssh "$ILB_CLIENT" \
  --zone="$ILB_CLIENT_ZONE" \
  --command="curl --connect-timeout 5 -s http://$ILB_IP"
```

Resultado esperado:

```text
timeout
ou
falha de conexão
```

---

## Troubleshooting do Internal Load Balancer

### Sintoma

```text
VM cliente não consegue acessar o IP interno do Load Balancer.
```

### Hipótese

A forwarding rule existe, os backends estão saudáveis, mas o firewall pode estar bloqueando o tráfego do cliente.

### Evidência

Verifique o frontend:

```bash
gcloud compute forwarding-rules describe "$ILB_FORWARDING_RULE" \
  --region="$REGION"
```

Verifique os backends:

```bash
gcloud compute backend-services get-health "$ILB_BACKEND" \
  --region="$REGION"
```

Liste as regras:

```bash
gcloud compute firewall-rules list \
  --filter="network:default"
```

Observe que:

```text
ace-ilb-allow-client
→ não existe
```

### Causa

A regra que permitia `tcp:80` da subnet para os backends foi removida.

### Correção

Recrie exatamente a regra:

```bash
gcloud compute firewall-rules create ace-ilb-allow-client \
  --network=default \
  --direction=INGRESS \
  --action=ALLOW \
  --rules=tcp:80 \
  --source-ranges="$ILB_SUBNET_CIDR" \
  --target-tags=allow-health-check
```

### Reteste

```bash
gcloud compute ssh "$ILB_CLIENT" \
  --zone="$ILB_CLIENT_ZONE" \
  --command="curl -s http://$ILB_IP"
```

Resultado esperado:

```text
HTTP response
```

Modelo mental:

```text
Sintoma
→ Internal LB não responde

Hipótese
→ firewall

Evidência
→ frontend existe
→ backend HEALTHY
→ regra do cliente ausente

Causa
→ tcp:80 bloqueado

Correção
→ recriar firewall rule
```

---

## Cleanup do Laboratório 2

Remova primeiro a forwarding rule:

```bash
gcloud compute forwarding-rules delete "$ILB_FORWARDING_RULE" \
  --region="$REGION" \
  --quiet
```

Remova o endereço interno:

```bash
gcloud compute addresses delete "$ILB_IP_NAME" \
  --region="$REGION" \
  --quiet
```

Remova o backend service regional:

```bash
gcloud compute backend-services delete "$ILB_BACKEND" \
  --region="$REGION" \
  --quiet
```

Remova o health check regional:

```bash
gcloud compute health-checks delete "$ILB_HEALTH_CHECK" \
  --region="$REGION" \
  --quiet
```

Remova a VM cliente:

```bash
gcloud compute instances delete "$ILB_CLIENT" \
  --zone="$ILB_CLIENT_ZONE" \
  --quiet
```

Remova a regra de firewall do cliente:

```bash
gcloud compute firewall-rules delete ace-ilb-allow-client \
  --quiet
```

> Não remova o MIG neste momento. Ele ainda pertence ao Laboratório 1 e será removido no cleanup principal abaixo.

---

# Laboratório 3 — Regional Internal Application Load Balancer

Agora vamos construir um Load Balancer **interno de camada 7**.

Nos laboratórios anteriores:

```text
Laboratório 1
→ Global External Application Load Balancer

Laboratório 2
→ Internal Passthrough Network Load Balancer
```

Agora:

```text
Laboratório 3
→ Regional Internal Application Load Balancer
```

A diferença essencial é:

```text
Internal Passthrough Network LB
→ camada 4
→ TCP
→ sem URL Map
→ sem Target HTTP Proxy

Internal Application LB
→ camada 7
→ HTTP
→ URL Map
→ Target HTTP Proxy
```

---

## Arquitetura do Laboratório 3

```text
VM cliente
   |
   | HTTP :80
   v
IP interno regional
   |
   v
Internal Managed Forwarding Rule
   |
   v
Regional Target HTTP Proxy
   |
   v
Regional URL Map
   |
   v
Regional Backend Service HTTP
   |
   v
Regional MIG
   |
   +--> VM 1
   |
   +--> VM 2
```

Transversalmente:

```text
Proxy-only subnet
   |
   v
Google-managed Envoy proxies
   |
   v
Backends
```

> A proxy-only subnet é usada pelos proxies gerenciados pelo Google. Ela **não** deve fornecer o IP do frontend.

---

## Variáveis do Laboratório 3

```bash
export IALB_PROXY_SUBNET=ace-ialb-proxy-only
export IALB_PROXY_CIDR=172.16.0.0/23
export IALB_HEALTH_CHECK=ace-ialb-health-check
export IALB_BACKEND=ace-ialb-backend
export IALB_URL_MAP=ace-ialb-url-map
export IALB_HTTP_PROXY=ace-ialb-http-proxy
export IALB_IP_NAME=ace-ialb-ip
export IALB_FORWARDING_RULE=ace-ialb-forwarding-rule
export IALB_CLIENT=ace-ialb-client
export IALB_CLIENT_ZONE=us-central1-a
```

---

## Validar o Named Port do MIG

O Internal Application Load Balancer usará o mesmo Regional MIG criado no primeiro laboratório.

Confirme o named port:

```bash
# Inspeciona os named ports do Regional MIG.
gcloud compute instance-groups managed get-named-ports "$MIG" \
  --region="$REGION"
```

Resultado esperado:

```text
NAME  PORT
http  80
```

Se ainda não existir:

```bash
# Define o named port http:80 no Regional MIG.
gcloud compute instance-groups managed set-named-ports "$MIG" \
  --region="$REGION" \
  --named-ports=http:80
```

---

## Criar a proxy-only subnet

Um Regional Internal Application Load Balancer precisa de uma subnet reservada para os proxies gerenciados.

```bash
# Cria uma proxy-only subnet para Envoy proxies gerenciados pelo Google.
#
# --purpose=REGIONAL_MANAGED_PROXY
#   identifica a subnet como exclusiva dos proxies regionais gerenciados.
#
# --role=ACTIVE
#   define esta subnet como a proxy-only subnet ativa da região.
gcloud compute networks subnets create "$IALB_PROXY_SUBNET" \
  --network=default \
  --region="$REGION" \
  --range="$IALB_PROXY_CIDR" \
  --purpose=REGIONAL_MANAGED_PROXY \
  --role=ACTIVE
```

Inspecione:

```bash
gcloud compute networks subnets describe "$IALB_PROXY_SUBNET" \
  --region="$REGION"
```

Observe:

```text
purpose
→ REGIONAL_MANAGED_PROXY

role
→ ACTIVE
```

Modelo mental:

```text
Proxy-only subnet
→ origem das conexões dos proxies até os backends

Frontend IP
→ vem de uma subnet normal
```

---

## Criar o Health Check regional

```bash
# Cria um health check HTTP regional.
# --use-serving-port usa o named port do backend.
gcloud compute health-checks create http "$IALB_HEALTH_CHECK" \
  --region="$REGION" \
  --use-serving-port
```

Inspecione:

```bash
gcloud compute health-checks describe "$IALB_HEALTH_CHECK" \
  --region="$REGION"
```

---

## Criar o Backend Service regional

```bash
# Cria um Backend Service regional para Internal Application Load Balancer.
gcloud compute backend-services create "$IALB_BACKEND" \
  --load-balancing-scheme=INTERNAL_MANAGED \
  --protocol=HTTP \
  --health-checks="$IALB_HEALTH_CHECK" \
  --health-checks-region="$REGION" \
  --region="$REGION"
```

Inspecione:

```bash
gcloud compute backend-services describe "$IALB_BACKEND" \
  --region="$REGION"
```

Confirme:

```text
loadBalancingScheme
→ INTERNAL_MANAGED

protocol
→ HTTP
```

---

## Adicionar o Regional MIG

```bash
# Adiciona o Regional MIG ao Backend Service interno L7.
gcloud compute backend-services add-backend "$IALB_BACKEND" \
  --region="$REGION" \
  --instance-group="$MIG" \
  --instance-group-region="$REGION" \
  --balancing-mode=UTILIZATION
```

Inspecione:

```bash
gcloud compute backend-services describe "$IALB_BACKEND" \
  --region="$REGION"
```

---

## Permitir tráfego da proxy-only subnet para os backends

Os proxies gerenciados precisam alcançar as VMs do MIG.

```bash
# Permite HTTP da proxy-only subnet para as VMs do MIG.
gcloud compute firewall-rules create ace-ialb-allow-proxy \
  --network=default \
  --direction=INGRESS \
  --action=ALLOW \
  --rules=tcp:80 \
  --source-ranges="$IALB_PROXY_CIDR" \
  --target-tags=allow-health-check
```

Inspecione:

```bash
gcloud compute firewall-rules describe ace-ialb-allow-proxy
```

Modelo:

```text
Envoy proxy
IP da proxy-only subnet
        |
        | tcp:80
        v
Firewall
        |
        v
VM backend
```

---

## Criar o URL Map regional

```bash
# Cria um URL Map regional apontando para o Backend Service interno.
gcloud compute url-maps create "$IALB_URL_MAP" \
  --default-service="$IALB_BACKEND" \
  --region="$REGION"
```

Inspecione:

```bash
gcloud compute url-maps describe "$IALB_URL_MAP" \
  --region="$REGION"
```

Modelo:

```text
URL Map
→ decide para qual Backend Service a requisição será enviada
```

---

## Criar o Target HTTP Proxy regional

```bash
# Cria o Target HTTP Proxy regional.
gcloud compute target-http-proxies create "$IALB_HTTP_PROXY" \
  --url-map="$IALB_URL_MAP" \
  --url-map-region="$REGION" \
  --region="$REGION"
```

Inspecione:

```bash
gcloud compute target-http-proxies describe "$IALB_HTTP_PROXY" \
  --region="$REGION"
```

Modelo:

```text
Forwarding Rule
   ↓
Target HTTP Proxy
   ↓
URL Map
```

---

## Reservar o IP interno do frontend

O IP do frontend deve vir de uma subnet normal, **não** da proxy-only subnet.

```bash
# Reserva um IP interno regional na subnet default.
gcloud compute addresses create "$IALB_IP_NAME" \
  --region="$REGION" \
  --subnet=default
```

Obtenha o endereço:

```bash
export IALB_IP="$(gcloud compute addresses describe "$IALB_IP_NAME" \
  --region="$REGION" \
  --format='value(address)')"

echo "$IALB_IP"
```

---

## Criar a Forwarding Rule interna L7

```bash
# Cria o frontend do Regional Internal Application Load Balancer.
gcloud compute forwarding-rules create "$IALB_FORWARDING_RULE" \
  --load-balancing-scheme=INTERNAL_MANAGED \
  --network=default \
  --subnet=default \
  --address="$IALB_IP_NAME" \
  --ports=80 \
  --region="$REGION" \
  --target-http-proxy="$IALB_HTTP_PROXY" \
  --target-http-proxy-region="$REGION"
```

Inspecione:

```bash
gcloud compute forwarding-rules describe "$IALB_FORWARDING_RULE" \
  --region="$REGION"
```

Confirme:

```text
loadBalancingScheme
→ INTERNAL_MANAGED

IPAddress
→ IP privado

target
→ Regional Target HTTP Proxy
```

---

## Verificar a saúde dos backends

```bash
gcloud compute backend-services get-health "$IALB_BACKEND" \
  --region="$REGION"
```

Aguarde:

```text
HEALTHY
```

---

## Criar VM cliente interna

```bash
# Cria uma VM cliente na mesma VPC.
gcloud compute instances create "$IALB_CLIENT" \
  --zone="$IALB_CLIENT_ZONE" \
  --machine-type=e2-micro \
  --image-family=debian-12 \
  --image-project=debian-cloud \
  --network=default
```

Inspecione:

```bash
gcloud compute instances describe "$IALB_CLIENT" \
  --zone="$IALB_CLIENT_ZONE" \
  --format="table(name,networkInterfaces[0].networkIP,status)"
```

---

## Testar o Internal Application Load Balancer

```bash
# Instala curl e acessa o frontend interno HTTP.
gcloud compute ssh "$IALB_CLIENT" \
  --zone="$IALB_CLIENT_ZONE" \
  --command="sudo apt-get update -qq && sudo apt-get install -y curl >/dev/null && curl -s http://$IALB_IP"
```

Repita:

```bash
for i in {1..10}; do
  gcloud compute ssh "$IALB_CLIENT" \
    --zone="$IALB_CLIENT_ZONE" \
    --command="curl -s http://$IALB_IP | grep ace-web-mig"
done
```

Fluxo:

```text
Cliente
   ↓ HTTP
Internal IP
   ↓
Forwarding Rule
   ↓
Target HTTP Proxy
   ↓
URL Map
   ↓
Backend Service
   ↓
MIG
```

---

## Comparação dos três laboratórios

| Item | Lab 1 | Lab 2 | Lab 3 |
|---|---|---|---|
| Produto | External Application LB | Internal Passthrough Network LB | Internal Application LB |
| Camada | L7 | L4 | L7 |
| Alcance | External | Internal | Internal |
| Escopo | Global | Regional | Regional |
| Protocolo | HTTP | TCP | HTTP |
| URL Map | Sim | Não | Sim |
| Target HTTP Proxy | Sim | Não | Sim |
| Proxy-only subnet | Não neste lab | Não | Sim |
| Backend Service | Global | Regional | Regional |
| Frontend IP | Público | Privado | Privado |

Modelo para memorizar:

```text
Internal Passthrough
→ INTERNAL
→ L4
→ sem proxy L7

Internal Application
→ INTERNAL_MANAGED
→ L7
→ Target Proxy + URL Map
→ proxy-only subnet
```

---

## Quebrar propositalmente

Agora vamos quebrar **somente a comunicação dos proxies com os backends**.

Remova a regra:

```bash
# Remove a regra que permite tráfego da proxy-only subnet aos backends.
gcloud compute firewall-rules delete ace-ialb-allow-proxy \
  --quiet
```

Aguarde alguns segundos e repita:

```bash
gcloud compute ssh "$IALB_CLIENT" \
  --zone="$IALB_CLIENT_ZONE" \
  --command="curl --connect-timeout 5 -i http://$IALB_IP"
```

Você poderá observar:

```text
HTTP 5xx
ou
falha/timeout
```

---

## Troubleshooting do Internal Application Load Balancer

### Sintoma

```text
Cliente alcança o frontend,
mas a aplicação não responde corretamente.
```

### Hipótese

Os proxies gerenciados podem não conseguir alcançar os backends.

### Evidência

Verifique a forwarding rule:

```bash
gcloud compute forwarding-rules describe "$IALB_FORWARDING_RULE" \
  --region="$REGION"
```

Verifique o Target HTTP Proxy:

```bash
gcloud compute target-http-proxies describe "$IALB_HTTP_PROXY" \
  --region="$REGION"
```

Verifique o URL Map:

```bash
gcloud compute url-maps describe "$IALB_URL_MAP" \
  --region="$REGION"
```

Verifique a saúde:

```bash
gcloud compute backend-services get-health "$IALB_BACKEND" \
  --region="$REGION"
```

Liste as regras de firewall:

```bash
gcloud compute firewall-rules list \
  --filter="network:default"
```

Observe:

```text
ace-ialb-allow-proxy
→ ausente
```

### Causa

A proxy-only subnet perdeu permissão para acessar `tcp:80` nos backends.

### Correção

```bash
gcloud compute firewall-rules create ace-ialb-allow-proxy \
  --network=default \
  --direction=INGRESS \
  --action=ALLOW \
  --rules=tcp:80 \
  --source-ranges="$IALB_PROXY_CIDR" \
  --target-tags=allow-health-check
```

### Reteste

```bash
gcloud compute ssh "$IALB_CLIENT" \
  --zone="$IALB_CLIENT_ZONE" \
  --command="curl -s http://$IALB_IP"
```

Resultado esperado:

```text
HTTP response
```

---

## Cleanup do Laboratório 3

Remova a forwarding rule:

```bash
gcloud compute forwarding-rules delete "$IALB_FORWARDING_RULE" \
  --region="$REGION" \
  --quiet
```

Remova o Target HTTP Proxy:

```bash
gcloud compute target-http-proxies delete "$IALB_HTTP_PROXY" \
  --region="$REGION" \
  --quiet
```

Remova o URL Map:

```bash
gcloud compute url-maps delete "$IALB_URL_MAP" \
  --region="$REGION" \
  --quiet
```

Remova o Backend Service:

```bash
gcloud compute backend-services delete "$IALB_BACKEND" \
  --region="$REGION" \
  --quiet
```

Remova o Health Check:

```bash
gcloud compute health-checks delete "$IALB_HEALTH_CHECK" \
  --region="$REGION" \
  --quiet
```

Remova o IP interno:

```bash
gcloud compute addresses delete "$IALB_IP_NAME" \
  --region="$REGION" \
  --quiet
```

Remova a VM cliente:

```bash
gcloud compute instances delete "$IALB_CLIENT" \
  --zone="$IALB_CLIENT_ZONE" \
  --quiet
```

Remova a regra de firewall:

```bash
gcloud compute firewall-rules delete ace-ialb-allow-proxy \
  --quiet
```

Por último, remova a proxy-only subnet:

```bash
gcloud compute networks subnets delete "$IALB_PROXY_SUBNET" \
  --region="$REGION" \
  --quiet
```

> Não remova o MIG aqui. Ele continua pertencendo ao laboratório principal e será excluído no cleanup geral da aula.

---

# 41. Limpeza do laboratório

## Forwarding Rule

```bash
# Explicação: Exclui a Forwarding Rule e deixa de publicar o frontend correspondente.
gcloud compute forwarding-rules delete $FORWARDING_RULE \
  --global \
  --quiet
```

## Target HTTP Proxy

```bash
# Explicação: Exclui o Target HTTP Proxy.
gcloud compute target-http-proxies delete $HTTP_PROXY \
  --quiet
```

## URL Map

```bash
# Explicação: Exclui o URL Map criado para o load balancer.
gcloud compute url-maps delete $URL_MAP \
  --quiet
```

## Backend Service

```bash
# Explicação: Exclui o Backend Service do load balancer.
gcloud compute backend-services delete $BACKEND \
  --global \
  --quiet
```

## Health Check

```bash
# Explicação: Exclui o health check usado no laboratório.
gcloud compute health-checks delete $HEALTH_CHECK \
  --quiet
```

## IP

```bash
# Explicação: Libera o endereço IP estático reservado no laboratório.
gcloud compute addresses delete $IP_NAME \
  --global \
  --quiet
```

## MIG

```bash
# Explicação: Exclui o Managed Instance Group e as instâncias gerenciadas por ele.
gcloud compute instance-groups managed delete $MIG \
  --region=$REGION \
  --quiet
```

## Instance Template

```bash
# Explicação: Exclui o Instance Template após remover os recursos que dependem dele.
gcloud compute instance-templates delete $TEMPLATE \
  --quiet
```

## Firewall

```bash
# Explicação: Remove a regra de firewall criada ou alterada para o laboratório.
gcloud compute firewall-rules delete ace-allow-lb-health-check \
  --quiet
```

Remova o arquivo local:

```bash
# Explicação: Remove o arquivo/diretório temporário indicado durante correção ou cleanup.
rm -f startup.sh
```

---

# 42. Removendo a configuration do laboratório

Ative outra configuration:

```bash
# Explicação: Ativa a configuração nomeada do `gcloud` que será usada nos próximos comandos.
gcloud config configurations activate default
```

Exclua:

```bash
# Explicação: Remove a configuração do `gcloud` criada para o laboratório.
gcloud config configurations delete ace-lb-lab
```

---

# 43. Checklist final

- [ ] Entendo Application x Network Load Balancer;
- [ ] Entendo External x Internal;
- [ ] Entendo Global x Regional;
- [ ] Sei o que é Forwarding Rule;
- [ ] Sei o que é Target HTTP Proxy;
- [ ] Sei o que é URL Map;
- [ ] Sei o que é Backend Service;
- [ ] Sei o que é Health Check;
- [ ] Sei o que é MIG;
- [ ] Sei o que é Instance Template;
- [ ] Entendo Named Ports;
- [ ] Entendo Load Balancer x Autoscaling;
- [ ] Entendo Health Check x Autohealing;
- [ ] Consegui acessar o Load Balancer externo;
- [ ] Criei um Internal Passthrough Network Load Balancer;
- [ ] Acessei o Internal Load Balancer por uma VM cliente;
- [ ] Entendo por que o Internal Passthrough LB não usa URL Map nem Target HTTP Proxy;
- [ ] Criei um Regional Internal Application Load Balancer;
- [ ] Criei e entendi a função da proxy-only subnet;
- [ ] Entendo por que o frontend não usa um IP da proxy-only subnet;
- [ ] Entendo a cadeia Forwarding Rule → Target HTTP Proxy → URL Map → Backend Service;
- [ ] Observei VMs diferentes respondendo;
- [ ] Simulei uma falha;
- [ ] Observei um backend `UNHEALTHY`;
- [ ] Removi os recursos do laboratório.

---

# 44. O que memorizar para o ACE

```text
Cliente
   |
   v
Forwarding Rule
   |
   v
Target Proxy
   |
   v
URL Map
   |
   v
Backend Service
   |
   v
MIG
   |
   v
VMs
```

Transversalmente:

```text
Health Check
     |
     v
Backend Health
```

E:

```text
Instance Template
      |
      v
Como criar as VMs
```

```text
Autoscaler
    |
    v
Quantas VMs o MIG deve manter
```

Se você consegue explicar essas relações sem consultar o material, domina a parte central de Load Balancing para o nível Associate Cloud Engineer.

---

# Cobertura adicional — Network Service Tiers

O exam guide inclui **Network Service Tiers**.

Modelo mental para ACE:

```text
Premium Tier
→ tráfego usa mais extensivamente a rede global do Google
→ necessário/normal para vários recursos globais

Standard Tier
→ opção regional/custo diferente para casos suportados
```

Inspecione endereços e forwarding rules:

```bash
# Explicação: Lista endereços IP estáticos reservados no projeto.
gcloud compute addresses list \
  --format='table(name,address,region,networkTier,status)'

# Explicação: Lista Forwarding Rules para localizar os frontends de load balancers.
gcloud compute forwarding-rules list \
  --format='table(name,loadBalancingScheme,networkTier,IPAddress)'
```

Não escolha tier apenas por preço: valide escopo do recurso e requisito de rede.


---

# Cobertura ACE ampliada — escolha de Load Balancer

## Escolha de load balancer

Antes de criar, responda:

```text
Camada 7 HTTP/HTTPS?        → Application Load Balancer
TCP/UDP pass-through/proxy? → Network Load Balancer adequado
Externo ou interno?
Global ou regional?
Backends serverless, VM, GKE?
```

Para ACE, o essencial é reconhecer o tipo que atende protocolo, alcance e backend.

## Network Service Tier

Ao reservar endereços/forwarding rules, observe se o recurso suporta/usa Premium ou Standard e quais implicações de alcance existem.

---

<!-- MEP-ACCEPTANCE-V9 -->
# Critério de aceite M/E/P desta aula

> Esta seção não substitui o conteúdo acima; ela explicita o critério usado na auditoria da baseline v9.

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
| 2.3 | Load Balancing | `E` | `P` |
