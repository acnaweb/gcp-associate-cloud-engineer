# Aula 4 — Load Balancing no Google Cloud

## Objetivos

Ao final desta aula, você deverá ser capaz de:

- Entender por que usamos Load Balancers;
- Diferenciar **Application Load Balancer** e **Network Load Balancer**;
- Diferenciar **External** e **Internal Load Balancer**;
- Entender os conceitos de **frontend**, **forwarding rule**, **target proxy**, **URL map**, **backend service**, **health check** e **backend**;
- Entender a integração entre **Load Balancer e Managed Instance Group (MIG)**;
- Criar um **Global External Application Load Balancer HTTP** usando `gcloud`;
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

## External

```text
Internet
   |
   v
External Load Balancer
   |
   v
Backends
```

## Internal

```text
VM / Serviço interno
        |
        v
Internal Load Balancer
        |
        v
Backends privados
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

## Forwarding Rule

É a entrada do Load Balancer.

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
gcloud config get-value project
```

Liste as configurations:

```bash
gcloud config configurations list
```

---

# 10. Criando uma configuration exclusiva para o laboratório

Crie:

```bash
gcloud config configurations create ace-lb-lab
```

Ative:

```bash
gcloud config configurations activate ace-lb-lab
```

Defina o projeto:

```bash
gcloud config set project SEU_PROJECT_ID
```

Defina região e zona:

```bash
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a
```

Veja a configuration:

```bash
gcloud config list
```

> Uma configuration não cria infraestrutura. Ela apenas mantém contexto para os comandos `gcloud`.

---

# 11. Habilitando a API necessária

```bash
gcloud services enable compute.googleapis.com
```

Verifique:

```bash
gcloud services list --enabled \
  --filter="NAME:compute.googleapis.com"
```

---

# 12. Variáveis do laboratório

```bash
export REGION=us-central1
export TEMPLATE=ace-web-template
export MIG=ace-web-mig
export HEALTH_CHECK=ace-http-health-check
export BACKEND=ace-web-backend
export IP_NAME=ace-lb-ip
export URL_MAP=ace-web-map
export HTTP_PROXY=ace-http-proxy
export FORWARDING_RULE=ace-http-forwarding-rule
```

---

# 13. Criando o startup script

```bash
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
gcloud compute instance-templates create $TEMPLATE \
  --machine-type=e2-micro \
  --image-family=debian-12 \
  --image-project=debian-cloud \
  --tags=allow-health-check \
  --metadata-from-file=startup-script=startup.sh
```

Liste:

```bash
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
gcloud compute instance-groups managed create $MIG \
  --template=$TEMPLATE \
  --size=2 \
  --region=$REGION \
  --zones=us-central1-a,us-central1-b
```

Liste:

```bash
gcloud compute instance-groups managed list
```

Veja as VMs:

```bash
gcloud compute instance-groups managed list-instances $MIG \
  --region=$REGION
```

---

# 16. Configurando Named Port

```bash
gcloud compute instance-groups managed set-named-ports $MIG \
  --named-ports=http:80 \
  --region=$REGION
```

Verifique:

```bash
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
gcloud compute firewall-rules describe ace-allow-lb-health-check
```

---

# 18. Criando o Health Check

```bash
gcloud compute health-checks create http $HEALTH_CHECK \
  --port=80 \
  --request-path=/
```

Liste:

```bash
gcloud compute health-checks list
```

---

# 19. Criando o Backend Service

```bash
gcloud compute backend-services create $BACKEND \
  --load-balancing-scheme=EXTERNAL_MANAGED \
  --protocol=HTTP \
  --port-name=http \
  --health-checks=$HEALTH_CHECK \
  --global
```

Liste:

```bash
gcloud compute backend-services list
```

---

# 20. Adicionando o MIG ao Backend Service

```bash
gcloud compute backend-services add-backend $BACKEND \
  --instance-group=$MIG \
  --instance-group-region=$REGION \
  --balancing-mode=UTILIZATION \
  --max-utilization=0.8 \
  --global
```

Descreva:

```bash
gcloud compute backend-services describe $BACKEND \
  --global
```

---

# 21. Verificando a saúde dos backends

```bash
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
gcloud compute addresses create $IP_NAME \
  --ip-version=IPV4 \
  --network-tier=PREMIUM \
  --global
```

Veja:

```bash
gcloud compute addresses describe $IP_NAME \
  --global \
  --format="value(address)"
```

Salve:

```bash
export LB_IP=$(gcloud compute addresses describe $IP_NAME \
  --global \
  --format="value(address)")
```

Confira:

```bash
echo $LB_IP
```

---

# 23. Criando o URL Map

```bash
gcloud compute url-maps create $URL_MAP \
  --default-service=$BACKEND
```

Descreva:

```bash
gcloud compute url-maps describe $URL_MAP
```

---

# 24. Criando o Target HTTP Proxy

```bash
gcloud compute target-http-proxies create $HTTP_PROXY \
  --url-map=$URL_MAP
```

Liste:

```bash
gcloud compute target-http-proxies list
```

---

# 25. Criando a Forwarding Rule

```bash
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
echo $LB_IP
curl http://$LB_IP
```

Execute várias vezes:

```bash
for i in {1..10}; do
  curl -s http://$LB_IP | grep "ace-web-mig"
done
```

Você deverá observar respostas de VMs diferentes.

> Em poucos requests, a distribuição não precisa ser perfeitamente 50/50.

---

# 28. Abrindo no navegador

```bash
echo "http://$LB_IP"
```

Abra o endereço no navegador.

---

# 29. Simulando falha de uma VM

Liste as instâncias:

```bash
gcloud compute instance-groups managed list-instances $MIG \
  --region=$REGION
```

Escolha uma VM e sua zona:

```bash
export VM_FALHA=NOME_DA_VM
export VM_FALHA_ZONE=ZONA_DA_VM
```

Entre:

```bash
gcloud compute ssh $VM_FALHA \
  --zone=$VM_FALHA_ZONE
```

Pare o nginx:

```bash
sudo systemctl stop nginx
```

Saia:

```bash
exit
```

---

# 30. Observando o Health Check

```bash
gcloud compute backend-services get-health $BACKEND \
  --global
```

Depois de alguns ciclos, uma VM deverá ficar:

```text
UNHEALTHY
```

Teste novamente:

```bash
for i in {1..10}; do
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
gcloud compute ssh $VM_FALHA \
  --zone=$VM_FALHA_ZONE
```

Dentro da VM:

```bash
sudo systemctl start nginx
exit
```

Verifique novamente:

```bash
gcloud compute backend-services get-health $BACKEND \
  --global
```

---

# 33. Adicionando Autoscaling ao MIG

```bash
gcloud compute instance-groups managed set-autoscaling $MIG \
  --region=$REGION \
  --min-num-replicas=2 \
  --max-num-replicas=4 \
  --target-cpu-utilization=0.60 \
  --cool-down-period=60
```

Veja:

```bash
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
gcloud compute forwarding-rules list

gcloud compute target-http-proxies list

gcloud compute url-maps list

gcloud compute backend-services list

gcloud compute health-checks list

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

# 41. Limpeza do laboratório

## Forwarding Rule

```bash
gcloud compute forwarding-rules delete $FORWARDING_RULE \
  --global \
  --quiet
```

## Target HTTP Proxy

```bash
gcloud compute target-http-proxies delete $HTTP_PROXY \
  --quiet
```

## URL Map

```bash
gcloud compute url-maps delete $URL_MAP \
  --quiet
```

## Backend Service

```bash
gcloud compute backend-services delete $BACKEND \
  --global \
  --quiet
```

## Health Check

```bash
gcloud compute health-checks delete $HEALTH_CHECK \
  --quiet
```

## IP

```bash
gcloud compute addresses delete $IP_NAME \
  --global \
  --quiet
```

## MIG

```bash
gcloud compute instance-groups managed delete $MIG \
  --region=$REGION \
  --quiet
```

## Instance Template

```bash
gcloud compute instance-templates delete $TEMPLATE \
  --quiet
```

## Firewall

```bash
gcloud compute firewall-rules delete ace-allow-lb-health-check \
  --quiet
```

Remova o arquivo local:

```bash
rm -f startup.sh
```

---

# 42. Removendo a configuration do laboratório

Ative outra configuration:

```bash
gcloud config configurations activate default
```

Exclua:

```bash
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
- [ ] Consegui acessar o Load Balancer;
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
gcloud compute addresses list \
  --format='table(name,address,region,networkTier,status)'

gcloud compute forwarding-rules list \
  --format='table(name,loadBalancingScheme,networkTier,IPAddress)'
```

Não escolha tier apenas por preço: valide escopo do recurso e requisito de rede.
