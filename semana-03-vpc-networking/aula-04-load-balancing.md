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
| 2.3 | Load Balancing | `E` | `P` |
