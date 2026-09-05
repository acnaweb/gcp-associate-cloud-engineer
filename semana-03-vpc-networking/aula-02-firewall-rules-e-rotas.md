# Aula 2 — Firewall Rules e Rotas no Google Cloud

## Objetivos

Ao final desta aula, você deverá ser capaz de:

- Entender o papel das **Firewall Rules**;
- Entender o papel das **rotas** em uma VPC;
- Diferenciar claramente **rota x firewall**;
- Entender regras de **INGRESS** e **EGRESS**;
- Entender prioridade de regras;
- Entender `source-ranges`, `target-tags` e `service accounts`;
- Criar regras de firewall com `gcloud`;
- Criar subnets e VMs para testar conectividade;
- Verificar rotas criadas automaticamente pelo Google Cloud;
- Criar uma rota estática customizada;
- Simular falhas de conectividade;
- Diagnosticar problemas usando `gcloud`;
- Relacionar os conceitos com questões da certificação Associate Cloud Engineer.

---

# 1. O problema que esta aula resolve

Considere duas VMs:

```text
VM A
10.10.0.2
   |
   v
VPC
   |
   v
VM B
10.20.0.2
```

Para que VM A consiga acessar VM B, duas perguntas precisam ser respondidas:

```text
1. Existe caminho até o destino?
        |
        v
      ROTA
```

e:

```text
2. O tráfego está permitido?
        |
        v
    FIREWALL
```

Essa distinção é uma das mais importantes da aula.

---

# 2. Rota x Firewall

## Rota

A rota responde:

> Para onde o pacote deve ir?

Exemplo:

```text
Destino: 10.20.0.0/24
Próximo salto: VPC / gateway / appliance
```

---

## Firewall

O firewall responde:

> Esse tráfego pode passar?

Exemplo:

```text
Permitir TCP 80
Origem: 10.10.0.0/24
Destino: VMs com tag web
```

---

## Regra mental

```text
ROTA
= caminho

FIREWALL
= permissão
```

Sem rota:

```text
não há caminho
```

Sem firewall:

```text
há caminho, mas o tráfego pode ser bloqueado
```

---

# 3. Firewall Rules no Google Cloud

As regras de firewall da VPC são **stateful**.

Isso significa que, quando uma conexão permitida é iniciada, o tráfego de resposta correspondente é permitido automaticamente.

Exemplo:

```text
VM A ---- TCP 80 ----> VM B
       permitido

VM B ---- resposta ---> VM A
       permitida pelo estado da conexão
```

---

# 4. INGRESS x EGRESS

## INGRESS

Controla tráfego entrando nos recursos.

```text
Cliente
   |
   v
VM
```

Exemplo:

```text
Permitir TCP 22
Origem 10.10.0.0/24
```

---

## EGRESS

Controla tráfego saindo dos recursos.

```text
VM
 |
 v
Destino
```

Exemplo:

```text
Permitir saída TCP 443
```

---

# 5. Prioridade

As regras possuem prioridade.

Quanto menor o número, maior a prioridade.

Exemplo:

```text
priority 100
priority 1000
priority 2000
```

A regra `100` é avaliada antes da `1000`.

---

# 6. Targets

Uma regra pode ser aplicada a:

- todas as VMs da rede;
- VMs com determinada **network tag**;
- VMs usando determinada **service account**.

Exemplo com tag:

```text
web-server
```

A regra pode permitir:

```text
tcp:80
```

somente para VMs que tenham essa tag.

---

# 7. Pré-requisitos do laboratório

Abra o Cloud Shell.

Defina:

```bash
# Explicação: Define `PROJECT_ID` com o ID do projeto Google Cloud usado pelos comandos seguintes.
export PROJECT_ID=$(gcloud config get-value project)
# Explicação: Define `REGION` com o valor da região padrão usada pelos recursos do laboratório.
export REGION=us-central1
# Explicação: Define `ZONE` com o valor da zona padrão usada pelos recursos zonais do laboratório.
export ZONE=us-central1-a
```

Veja:

```bash
# Explicação: Exibe ou grava o valor/texto informado, normalmente para validar variável ou criar conteúdo de teste.
echo $PROJECT_ID
# Explicação: Exibe ou grava o valor/texto informado, normalmente para validar variável ou criar conteúdo de teste.
echo $REGION
# Explicação: Exibe ou grava o valor/texto informado, normalmente para validar variável ou criar conteúdo de teste.
echo $ZONE
```

Habilite Compute Engine:

```bash
# Explicação: Habilita a API/serviço indicado no projeto ativo para permitir o uso do recurso no laboratório.
gcloud services enable compute.googleapis.com
```

---

# 8. Criando uma VPC customizada

Crie:

```bash
# Explicação: Cria uma VPC; as flags definem, entre outros pontos, se a rede será custom mode ou auto mode.
gcloud compute networks create ace-firewall-vpc \
  --subnet-mode=custom
```

Verifique:

```bash
# Explicação: Exibe propriedades da VPC para confirmar modo de subnet, roteamento e demais configurações.
gcloud compute networks describe ace-firewall-vpc
```

---

# 9. Criando duas subnets

Subnet A:

```bash
# Explicação: Cria uma sub-rede regional dentro da VPC com o intervalo CIDR informado.
gcloud compute networks subnets create subnet-a \
  --network=ace-firewall-vpc \
  --region=$REGION \
  --range=10.10.0.0/24
```

Subnet B:

```bash
# Explicação: Cria uma sub-rede regional dentro da VPC com o intervalo CIDR informado.
gcloud compute networks subnets create subnet-b \
  --network=ace-firewall-vpc \
  --region=$REGION \
  --range=10.20.0.0/24
```

Liste:

```bash
# Explicação: Lista sub-redes para verificar região, VPC e intervalos de IP.
gcloud compute networks subnets list \
  --network=ace-firewall-vpc
```

Arquitetura:

```text
ace-firewall-vpc
   |
   +--> subnet-a 10.10.0.0/24
   |
   +--> subnet-b 10.20.0.0/24
```

---

# 10. Criando duas VMs

Crie VM A:

```bash
# Explicação: Cria uma VM do Compute Engine com as opções de máquina, rede, disco e identidade informadas.
gcloud compute instances create vm-a \
  --zone=$ZONE \
  --machine-type=e2-micro \
  --subnet=subnet-a \
  --tags=ssh-lab \
  --image-family=debian-12 \
  --image-project=debian-cloud
```

Crie VM B:

```bash
# Explicação: Cria uma VM do Compute Engine com as opções de máquina, rede, disco e identidade informadas.
gcloud compute instances create vm-b \
  --zone=$ZONE \
  --machine-type=e2-micro \
  --subnet=subnet-b \
  --tags=ssh-lab,web \
  --image-family=debian-12 \
  --image-project=debian-cloud
```

Liste:

```bash
# Explicação: Lista VMs do projeto para verificar inventário, zona, IPs e estado.
gcloud compute instances list
```

Capture IPs internos:

```bash
# Explicação: Define a variável `VM_A_IP` usada nas próximas etapas do laboratório.
export VM_A_IP=$(gcloud compute instances describe vm-a \
  --zone=$ZONE \
  --format="value(networkInterfaces[0].networkIP)")

# Explicação: Define a variável `VM_B_IP` usada nas próximas etapas do laboratório.
export VM_B_IP=$(gcloud compute instances describe vm-b \
  --zone=$ZONE \
  --format="value(networkInterfaces[0].networkIP)")
```

Veja:

```bash
# Explicação: Exibe ou grava o valor/texto informado, normalmente para validar variável ou criar conteúdo de teste.
echo $VM_A_IP
# Explicação: Exibe ou grava o valor/texto informado, normalmente para validar variável ou criar conteúdo de teste.
echo $VM_B_IP
```

---

# 11. Criando regra SSH para o laboratório

Crie:

```bash
# Explicação: Cria uma regra de firewall VPC; direção, origem/destino, alvo e protocolos/portas são definidos pelas flags.
gcloud compute firewall-rules create ace-allow-ssh \
  --network=ace-firewall-vpc \
  --direction=INGRESS \
  --priority=1000 \
  --action=ALLOW \
  --rules=tcp:22 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=ssh-lab
```

> Para produção, evite liberar SSH para `0.0.0.0/0`. Aqui é apenas para simplificar o laboratório.

---

# 12. Testando conectividade antes de criar regra ICMP

Entre na VM A:

```bash
# Explicação: Abre uma sessão SSH na VM indicada; flags adicionais podem executar um comando remotamente.
gcloud compute ssh vm-a \
  --zone=$ZONE
```

Teste:

```bash
# Explicação: Envia pacotes ICMP para testar alcance IP entre origem e destino.
ping -c 4 $VM_B_IP
```

A comunicação pode falhar porque ainda não permitimos ICMP.

Isso mostra algo importante:

```text
As duas VMs estão na mesma VPC
        |
        v
rotas existem
```

mas:

```text
firewall pode bloquear
```

Saia:

```bash
# Explicação: Encerra a sessão atual do shell/SSH e retorna ao terminal anterior.
exit
```

---

# 13. Criando regra ICMP

Crie:

```bash
# Explicação: Cria uma regra de firewall VPC; direção, origem/destino, alvo e protocolos/portas são definidos pelas flags.
gcloud compute firewall-rules create ace-allow-icmp-internal \
  --network=ace-firewall-vpc \
  --direction=INGRESS \
  --priority=1000 \
  --action=ALLOW \
  --rules=icmp \
  --source-ranges=10.10.0.0/24,10.20.0.0/24
```

Liste:

```bash
# Explicação: Lista regras de firewall para inspecionar a política efetiva da VPC.
gcloud compute firewall-rules list \
  --filter="network:ace-firewall-vpc"
```

Teste novamente:

```bash
# Explicação: Abre uma sessão SSH na VM indicada; flags adicionais podem executar um comando remotamente.
gcloud compute ssh vm-a \
  --zone=$ZONE \
  --command="ping -c 4 $VM_B_IP"
```

Agora deverá funcionar.

---

# 14. Instalando um servidor web na VM B

Execute:

```bash
# Explicação: Abre uma sessão SSH na VM indicada; flags adicionais podem executar um comando remotamente.
gcloud compute ssh vm-b \
  --zone=$ZONE \
  --command="sudo apt-get update && sudo apt-get install -y nginx"
```

Verifique:

```bash
# Explicação: Abre uma sessão SSH na VM indicada; flags adicionais podem executar um comando remotamente.
gcloud compute ssh vm-b \
  --zone=$ZONE \
  --command="curl -s localhost | head"
```

---

# 15. Testando HTTP antes da regra

Da VM A:

```bash
# Explicação: Abre uma sessão SSH na VM indicada; flags adicionais podem executar um comando remotamente.
gcloud compute ssh vm-a \
  --zone=$ZONE \
  --command="curl --connect-timeout 5 http://$VM_B_IP"
```

A conexão deverá falhar.

Por quê?

Temos:

```text
rota = OK
serviço = OK
firewall tcp:80 = NÃO
```

---

# 16. Criando regra HTTP usando target tag

Crie:

```bash
# Explicação: Cria uma regra de firewall VPC; direção, origem/destino, alvo e protocolos/portas são definidos pelas flags.
gcloud compute firewall-rules create ace-allow-http-from-subnet-a \
  --network=ace-firewall-vpc \
  --direction=INGRESS \
  --priority=1000 \
  --action=ALLOW \
  --rules=tcp:80 \
  --source-ranges=10.10.0.0/24 \
  --target-tags=web
```

Teste:

```bash
# Explicação: Abre uma sessão SSH na VM indicada; flags adicionais podem executar um comando remotamente.
gcloud compute ssh vm-a \
  --zone=$ZONE \
  --command="curl -s http://$VM_B_IP | head"
```

Agora deverá funcionar.

---

# 17. O papel da target tag

A regra foi criada com:

```text
target-tags=web
```

A VM B possui:

```text
web
```

Portanto:

```text
regra aplica
```

Se removermos a tag da VM B, a regra deixa de atingir aquele recurso.

---

# 18. Removendo a tag web

Execute:

```bash
# Explicação: Executa `gcloud compute instances remove-tags vm-b --zone=$ZONE --tags=web` nesta etapa para aplicar ou inspecionar a configuração indicada.
gcloud compute instances remove-tags vm-b \
  --zone=$ZONE \
  --tags=web
```

Teste novamente:

```bash
# Explicação: Abre uma sessão SSH na VM indicada; flags adicionais podem executar um comando remotamente.
gcloud compute ssh vm-a \
  --zone=$ZONE \
  --command="curl --connect-timeout 5 http://$VM_B_IP"
```

A conexão deverá falhar.

Isso mostra que:

```text
firewall rule existe
        |
        v
mas target não corresponde
```

---

# 19. Recolocando a tag

Execute:

```bash
# Explicação: Executa `gcloud compute instances add-tags vm-b --zone=$ZONE --tags=web` nesta etapa para aplicar ou inspecionar a configuração indicada.
gcloud compute instances add-tags vm-b \
  --zone=$ZONE \
  --tags=web
```

Teste:

```bash
# Explicação: Abre uma sessão SSH na VM indicada; flags adicionais podem executar um comando remotamente.
gcloud compute ssh vm-a \
  --zone=$ZONE \
  --command="curl -s http://$VM_B_IP | head"
```

---

# 20. Inspecionando as rotas automáticas

Liste:

```bash
# Explicação: Lista rotas efetivas/estáticas visíveis no projeto para análise de caminho de rede.
gcloud compute routes list \
  --filter="network:ace-firewall-vpc"
```

Você deverá encontrar rotas relacionadas às subnets:

```text
10.10.0.0/24
10.20.0.0/24
```

Isso explica por que VMs em subnets da mesma VPC conseguem encontrar caminho umas para as outras.

---

# 21. Rotas de subnet

Quando criamos:

```text
subnet-a 10.10.0.0/24
subnet-b 10.20.0.0/24
```

o Google Cloud cria rotas para essas faixas.

Conceitualmente:

```text
Destino 10.10.0.0/24
        |
        v
subnet-a

Destino 10.20.0.0/24
        |
        v
subnet-b
```

---

# 22. Rotas e prioridade

Rotas também possuem prioridade.

Quanto menor o valor, maior a preferência, considerando o algoritmo de seleção de rotas.

Você pode visualizar:

```bash
# Explicação: Lista rotas efetivas/estáticas visíveis no projeto para análise de caminho de rede.
gcloud compute routes list
```

---

# 23. Rota default

Normalmente existe uma rota padrão:

```text
0.0.0.0/0
```

Essa rota representa:

```text
qualquer destino não conhecido por rotas mais específicas
```

Ela é importante para tráfego de saída.

---

# 24. Criando uma rota customizada de laboratório

Criaremos uma rota estática para uma faixa fictícia:

```text
10.99.0.0/24
```

usando a VM B como next hop.

Primeiro habilite IP forwarding na VM B exigiria recriação/configuração apropriada; portanto, este passo serve para praticar a criação e inspeção da rota, não para transformá-la em appliance funcional.

Crie:

```bash
# Explicação: Cria uma rota estática na VPC com destino e próximo salto definidos nas flags.
gcloud compute routes create ace-route-10-99 \
  --network=ace-firewall-vpc \
  --destination-range=10.99.0.0/24 \
  --next-hop-instance=vm-b \
  --next-hop-instance-zone=$ZONE \
  --priority=900
```

Liste:

```bash
# Explicação: Lista rotas efetivas/estáticas visíveis no projeto para análise de caminho de rede.
gcloud compute routes list \
  --filter="name:ace-route-10-99"
```

Observe:

```text
Destino:
10.99.0.0/24

Next hop:
vm-b
```

---

# 25. O que uma rota customizada pode representar?

Em ambientes reais, rotas customizadas podem apontar para:

- appliance de segurança;
- gateway;
- VPN;
- instância com IP forwarding;
- outros próximos saltos suportados.

Exemplo:

```text
VM
 |
 v
Firewall Appliance
 |
 v
Destino
```

---

# 26. Rota mais específica

Considere:

```text
0.0.0.0/0

10.20.0.0/24
```

Para um destino:

```text
10.20.0.5
```

a rota:

```text
10.20.0.0/24
```

é mais específica.

Esse conceito é fundamental em roteamento.

---

# 27. Laboratório de troubleshooting 1 — firewall

Delete a regra HTTP:

```bash
# Explicação: Remove a regra de firewall criada ou alterada para o laboratório.
gcloud compute firewall-rules delete \
  ace-allow-http-from-subnet-a \
  --quiet
```

Teste:

```bash
# Explicação: Abre uma sessão SSH na VM indicada; flags adicionais podem executar um comando remotamente.
gcloud compute ssh vm-a \
  --zone=$ZONE \
  --command="curl --connect-timeout 5 http://$VM_B_IP"
```

Falhou.

Agora pergunte:

```text
Existe rota para 10.20.0.0/24?
```

Verifique:

```bash
# Explicação: Lista rotas efetivas/estáticas visíveis no projeto para análise de caminho de rede.
gcloud compute routes list \
  --filter="network:ace-firewall-vpc"
```

A rota existe.

Logo:

```text
ROTA = OK
FIREWALL = FAIL
```

---

# 28. Recriando a regra HTTP

```bash
# Explicação: Cria uma regra de firewall VPC; direção, origem/destino, alvo e protocolos/portas são definidos pelas flags.
gcloud compute firewall-rules create ace-allow-http-from-subnet-a \
  --network=ace-firewall-vpc \
  --direction=INGRESS \
  --priority=1000 \
  --action=ALLOW \
  --rules=tcp:80 \
  --source-ranges=10.10.0.0/24 \
  --target-tags=web
```

Teste novamente.

---

# 29. Laboratório de troubleshooting 2 — aplicação

Agora pare o nginx:

```bash
# Explicação: Abre uma sessão SSH na VM indicada; flags adicionais podem executar um comando remotamente.
gcloud compute ssh vm-b \
  --zone=$ZONE \
  --command="sudo systemctl stop nginx"
```

Teste da VM A:

```bash
# Explicação: Abre uma sessão SSH na VM indicada; flags adicionais podem executar um comando remotamente.
gcloud compute ssh vm-a \
  --zone=$ZONE \
  --command="curl --connect-timeout 5 http://$VM_B_IP"
```

Falhou.

Mas agora:

```text
rota = OK
firewall = OK
aplicação = FAIL
```

Isso mostra por que troubleshooting não pode parar no firewall.

---

# 30. Verificando a aplicação

Na VM B:

```bash
# Explicação: Abre uma sessão SSH na VM indicada; flags adicionais podem executar um comando remotamente.
gcloud compute ssh vm-b \
  --zone=$ZONE \
  --command="sudo systemctl status nginx --no-pager"
```

Inicie novamente:

```bash
# Explicação: Abre uma sessão SSH na VM indicada; flags adicionais podem executar um comando remotamente.
gcloud compute ssh vm-b \
  --zone=$ZONE \
  --command="sudo systemctl start nginx"
```

---

# 31. Laboratório de prioridade de firewall

Agora vamos criar uma regra de negação com prioridade maior.

Crie:

```bash
# Explicação: Cria uma regra de firewall VPC; direção, origem/destino, alvo e protocolos/portas são definidos pelas flags.
gcloud compute firewall-rules create ace-deny-http-priority \
  --network=ace-firewall-vpc \
  --direction=INGRESS \
  --priority=500 \
  --action=DENY \
  --rules=tcp:80 \
  --source-ranges=10.10.0.0/24 \
  --target-tags=web
```

Temos:

```text
DENY priority 500
ALLOW priority 1000
```

Teste:

```bash
# Explicação: Abre uma sessão SSH na VM indicada; flags adicionais podem executar um comando remotamente.
gcloud compute ssh vm-a \
  --zone=$ZONE \
  --command="curl --connect-timeout 5 http://$VM_B_IP"
```

Deverá falhar.

Por quê?

```text
500
<
1000
```

A regra de prioridade 500 é considerada antes.

---

# 32. Removendo a regra de negação

```bash
# Explicação: Remove a regra de firewall criada ou alterada para o laboratório.
gcloud compute firewall-rules delete \
  ace-deny-http-priority \
  --quiet
```

Teste novamente.

---

# 33. EGRESS

Até agora trabalhamos principalmente com INGRESS.

Uma regra EGRESS controla tráfego saindo da VM.

Exemplo conceitual:

```text
VM
 |
 | tcp:443
 v
Internet / API
```

Pode ser usada para restringir destinos e portas.

---

# 34. Firewall implícito

É importante lembrar que uma VPC possui comportamentos implícitos.

Simplificação útil para o ACE:

```text
INGRESS
→ deny implícito se nada permitir

EGRESS
→ allow implícito, salvo regras mais específicas
```

Não trate isso como substituto para governança de segurança.

---

# 35. Network Tags x Service Accounts

## Network Tags

Permitem aplicar regras por tag.

Exemplo:

```text
web
db
app
```

---

## Service Accounts

Também podem ser usadas como alvo em regras de firewall.

Isso pode ser útil quando a política deve acompanhar a identidade da workload, em vez de uma tag manual.

---

# 36. Fluxo mental para troubleshooting

Quando uma conexão falhar:

```text
1. Recurso está RUNNING?
        |
        v
2. IP está correto?
        |
        v
3. Existe rota?
        |
        v
4. Firewall permite?
        |
        v
5. Target da regra corresponde?
        |
        v
6. Porta está correta?
        |
        v
7. Aplicação está ouvindo?
```

---

# 37. Comandos essenciais

## VMs

```bash
# Explicação: Lista VMs do projeto para verificar inventário, zona, IPs e estado.
gcloud compute instances list
```

## Firewall

```bash
# Explicação: Lista regras de firewall para inspecionar a política efetiva da VPC.
gcloud compute firewall-rules list
```

## Rota

```bash
# Explicação: Lista rotas efetivas/estáticas visíveis no projeto para análise de caminho de rede.
gcloud compute routes list
```

## Subnets

```bash
# Explicação: Lista sub-redes para verificar região, VPC e intervalos de IP.
gcloud compute networks subnets list
```

## VPCs

```bash
# Explicação: Lista VPCs existentes no projeto.
gcloud compute networks list
```

---

# 38. Exercício prático

Cenário:

```text
VM A
10.10.0.2
   |
   v
subnet-a
   |
   v
VPC
   |
   v
subnet-b
   |
   v
VM B
10.20.0.2
```

VM A não acessa:

```text
http://10.20.0.2
```

Investigue:

```text
1. VM B está RUNNING?
2. nginx está ativo?
3. porta 80 está ouvindo?
4. existe rota para 10.20.0.0/24?
5. existe regra INGRESS tcp:80?
6. source range inclui 10.10.0.0/24?
7. target tag corresponde à VM B?
8. existe alguma regra DENY com prioridade maior?
```

---

# 39. Pegadinhas ACE

## Pegadinha 1

> Firewall cria rota.

**Errado.**

Firewall controla permissão.

Rota controla caminho.

---

## Pegadinha 2

> Se duas VMs estão na mesma VPC, todo tráfego é automaticamente permitido.

**Errado.**

As rotas podem existir, mas firewall continua sendo aplicado.

---

## Pegadinha 3

> Quanto maior o número da prioridade, maior a prioridade.

**Errado.**

Número menor = prioridade maior.

---

## Pegadinha 4

> Target tag define origem da conexão.

**Errado.**

Target tag identifica os recursos aos quais a regra se aplica.

---

## Pegadinha 5

> `0.0.0.0/0` significa apenas rede interna.

**Errado.**

Representa qualquer endereço IPv4.

---

## Pegadinha 6

> Se `curl` falha, o problema é firewall.

**Errado.**

Pode ser rota, serviço parado, porta errada, IP incorreto ou outros fatores.

---

## Pegadinha 7

> Uma rota mais específica perde para uma rota menos específica apenas por prioridade.

**Errado.**

A seleção de rota considera especificidade/prefixo e prioridade conforme as regras de roteamento do Google Cloud.

---

# 40. Questões estilo ACE

## Questão 1

Uma VM não consegue acessar outra em subnet diferente da mesma VPC. As rotas de subnet existem.

Qual item deve ser verificado?

**Resposta:** Firewall.

---

## Questão 2

Qual componente define por onde o tráfego deve seguir?

**Resposta:** Rota.

---

## Questão 3

Qual componente decide se TCP 443 pode entrar em uma VM?

**Resposta:** Firewall Rule.

---

## Questão 4

Duas regras se aplicam ao mesmo tráfego:

```text
DENY priority 500
ALLOW priority 1000
```

Qual prevalece?

**Resposta:** DENY priority 500.

---

## Questão 5

Você deseja permitir HTTP apenas para VMs de frontend identificadas com `web`.

Qual mecanismo pode ser usado?

**Resposta:** Target tag `web`.

---

## Questão 6

Existe uma rota para o destino e firewall permite a conexão, mas o serviço ainda não responde.

O que verificar?

**Resposta:** Se a aplicação está ativa e ouvindo na porta correta.

---

# 41. Desafio de interpretação

Associe:

```text
A. Rota
B. Firewall
C. Source Range
D. Target Tag
E. Priority
```

a:

```text
1. Origem permitida
2. Caminho do pacote
3. Recurso alvo da regra
4. Ordem de avaliação
5. Permissão de tráfego
```

Resposta:

```text
A -> 2
B -> 5
C -> 1
D -> 3
E -> 4
```

---

# 42. Arquitetura final do laboratório

```text
                    ace-firewall-vpc
                           |
              +------------+------------+
              |                         |
              v                         v
      subnet-a 10.10.0.0/24     subnet-b 10.20.0.0/24
              |                         |
              v                         v
            VM A                      VM B
                                      |
                                      +--> nginx :80
                                      |
                                      +--> tag web
```

Rotas:

```text
10.10.0.0/24
10.20.0.0/24
```

Firewall:

```text
SSH
ICMP
HTTP
```

---

# 43. Limpeza — rota customizada

```bash
# Explicação: Exclui a rota estática criada no laboratório.
gcloud compute routes delete ace-route-10-99 \
  --quiet
```

---

# 44. Limpeza — VMs

```bash
# Explicação: Exclui a VM indicada e libera os recursos associados que não foram preservados.
gcloud compute instances delete vm-a vm-b \
  --zone=$ZONE \
  --quiet
```

---

# 45. Limpeza — firewall rules

```bash
# Explicação: Remove a regra de firewall criada ou alterada para o laboratório.
gcloud compute firewall-rules delete \
  ace-allow-ssh \
  ace-allow-icmp-internal \
  ace-allow-http-from-subnet-a \
  --quiet
```

Caso ainda exista:

```bash
# Explicação: Remove a regra de firewall criada ou alterada para o laboratório.
gcloud compute firewall-rules delete \
  ace-deny-http-priority \
  --quiet
```

---

# 46. Limpeza — subnets

```bash
# Explicação: Exclui a sub-rede indicada.
gcloud compute networks subnets delete subnet-a \
  --region=$REGION \
  --quiet
```

```bash
# Explicação: Exclui a sub-rede indicada.
gcloud compute networks subnets delete subnet-b \
  --region=$REGION \
  --quiet
```

---

# 47. Limpeza — VPC

```bash
# Explicação: Exclui a VPC depois que os recursos dependentes foram removidos.
gcloud compute networks delete ace-firewall-vpc \
  --quiet
```

---

# 48. Checklist final

- [ ] Entendo a diferença entre rota e firewall;
- [ ] Sei diferenciar INGRESS e EGRESS;
- [ ] Entendo prioridade de firewall;
- [ ] Sei usar `source-ranges`;
- [ ] Sei usar `target-tags`;
- [ ] Entendo firewall stateful;
- [ ] Consegui criar uma VPC customizada;
- [ ] Consegui criar duas subnets;
- [ ] Consegui criar VMs em subnets diferentes;
- [ ] Consegui liberar ICMP;
- [ ] Consegui liberar HTTP por tag;
- [ ] Consegui bloquear HTTP removendo a tag;
- [ ] Consegui observar rotas automáticas;
- [ ] Consegui criar uma rota customizada;
- [ ] Consegui provocar falha de firewall;
- [ ] Consegui provocar falha de aplicação;
- [ ] Consegui testar prioridade com DENY e ALLOW;
- [ ] Sei investigar rota, firewall, porta e aplicação;
- [ ] Consegui remover os recursos do laboratório.

---

# 49. O que você deve memorizar para o ACE

A regra principal:

```text
ROTA
= para onde o tráfego vai
```

```text
FIREWALL
= se o tráfego pode passar
```

Além disso:

```text
INGRESS
= entrada
```

```text
EGRESS
= saída
```

```text
priority menor
= maior prioridade
```

```text
source-ranges
= quem pode originar
```

```text
target-tags
= quais VMs recebem a regra
```

E para troubleshooting:

```text
Recurso
  ↓
IP
  ↓
Rota
  ↓
Firewall
  ↓
Target
  ↓
Porta
  ↓
Aplicação
```

Se você consegue identificar rapidamente se uma falha é de **caminho** ou de **permissão**, já domina o núcleo desta aula para o nível Associate Cloud Engineer.


---

# Cobertura ACE ampliada — Cloud NGFW, secure tags e service accounts

## VPC Firewall Rules x Cloud NGFW policies

O exam guide atual cobra ambos.

```text
VPC firewall rules
→ regras tradicionais associadas à VPC

Cloud NGFW policies
→ políticas de firewall hierárquicas/regionais/globais conforme recurso,
   com capacidades modernas e integração com tags
```

Atributos cobrados:

- ingress / egress;
- action;
- source;
- destination;
- targets;
- protocols;
- ports.

## Secure Tags

Secure Tags são recursos de Resource Manager que podem ser usados como identidade/atributo em políticas compatíveis, incluindo Cloud NGFW.

Não confunda:

```text
Network tag tradicional → string na VM
Secure Tag             → recurso governado, com IAM
```

## Service Account em regras

Service accounts também podem ser usadas como alvo/origem conforme mecanismo de firewall suportado, permitindo políticas baseadas na identidade da workload.

## Laboratório de decisão

Para cada requisito escolha:

```text
Permitir tcp:80 para VMs com tag simples em uma VPC → VPC firewall rule pode bastar
Guardrail central baseado em secure tags → Cloud NGFW policy
```

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
| 3.5 | Firewall ingress/egress/ranges/tags/SAs | `P` | `P` |
