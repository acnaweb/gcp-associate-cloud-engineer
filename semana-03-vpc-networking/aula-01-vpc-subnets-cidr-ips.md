# Aula 1 — VPC, Subnets, CIDR e IPs no Google Cloud

## Objetivos

Ao final desta aula, você deverá ser capaz de:

- Entender o que é uma **VPC** no Google Cloud;
- Entender que uma VPC é um recurso **global**;
- Entender que **subnets são regionais**;
- Diferenciar **VPC auto mode** e **custom mode**;
- Entender o que é **CIDR**;
- Calcular faixas básicas de endereçamento;
- Entender IP interno e IP externo;
- Entender IP efêmero e IP estático;
- Criar uma VPC customizada;
- Criar subnets em regiões diferentes;
- Criar VMs utilizando subnets específicas;
- Observar comunicação privada entre subnets da mesma VPC;
- Verificar endereços internos e externos;
- Reservar um endereço IP estático;
- Identificar erros de sobreposição de CIDR;
- Usar `gcloud` para inspecionar redes e interfaces;
- Relacionar os conceitos com questões da certificação Associate Cloud Engineer.

---

# 1. O que é uma VPC?

VPC significa:

```text
Virtual Private Cloud
```

No Google Cloud, uma VPC representa uma rede virtual privada onde recursos podem se comunicar.

Exemplo:

```text
Google Cloud Project
        |
        v
+----------------------+
| VPC                  |
|                      |
|  subnet-a            |
|  subnet-b            |
|                      |
+----------------------+
```

A VPC define o domínio de rede.

---

# 2. VPC é global

Este é um conceito muito importante no Google Cloud.

A **VPC é global**.

Isso significa que uma mesma VPC pode possuir subnets em regiões diferentes.

Exemplo:

```text
                 ace-vpc
                    |
        +-----------+-----------+
        |                       |
        v                       v
us-central1                 southamerica-east1
subnet-a                    subnet-b
```

A rede continua sendo a mesma:

```text
ace-vpc
```

mesmo com subnets em regiões distintas.

---

# 3. Subnets são regionais

Enquanto a VPC é global:

```text
VPC
= global
```

a subnet pertence a uma região:

```text
Subnet
= regional
```

Exemplo:

```text
ace-vpc
   |
   +--> subnet-us
   |     us-central1
   |     10.10.0.0/24
   |
   +--> subnet-br
         southamerica-east1
         10.20.0.0/24
```

Uma subnet não pertence a uma zona.

Ela pertence a uma **região**.

---

# 4. Região x Zona

Exemplo:

```text
Região:
us-central1
```

Dentro dela existem zonas:

```text
us-central1-a
us-central1-b
us-central1-c
us-central1-f
```

Uma subnet criada em:

```text
us-central1
```

pode ser utilizada por VMs em diferentes zonas daquela região.

Exemplo:

```text
subnet-us
10.10.0.0/24
us-central1
      |
      +--> VM em us-central1-a
      |
      +--> VM em us-central1-b
```

---

# 5. Auto Mode x Custom Mode

Ao criar uma VPC no Google Cloud, você pode encontrar dois modelos principais.

## Auto Mode

O Google cria subnets automaticamente em regiões suportadas.

Exemplo conceitual:

```text
auto-vpc
   |
   +--> subnet us-central1
   +--> subnet europe-west1
   +--> subnet asia-east1
   +--> ...
```

É simples para começar.

---

## Custom Mode

Você decide:

- quais subnets existirão;
- em quais regiões;
- quais CIDRs utilizar;
- como organizar o endereçamento.

Exemplo:

```text
custom-vpc
   |
   +--> app-us
   |     10.10.0.0/24
   |
   +--> data-us
   |     10.20.0.0/24
   |
   +--> app-br
         10.30.0.0/24
```

Para ambientes corporativos, **custom mode** oferece maior controle.

Neste laboratório utilizaremos custom mode.

---

# 6. CIDR

CIDR significa:

```text
Classless Inter-Domain Routing
```

É uma notação utilizada para representar uma faixa de IPs.

Exemplo:

```text
10.10.0.0/24
```

Temos:

```text
10.10.0.0
```

como endereço base e:

```text
/24
```

como tamanho do prefixo.

---

# 7. Como interpretar /24?

IPv4 possui:

```text
32 bits
```

Quando usamos:

```text
/24
```

temos:

```text
24 bits
```

para identificar a rede.

Sobram:

```text
8 bits
```

para endereços dentro da faixa.

Quantidade teórica:

```text
2^8
=
256 endereços
```

Portanto:

```text
10.10.0.0/24
```

possui 256 endereços no bloco.

> Nem todos são utilizáveis por VMs. O Google Cloud reserva endereços em cada subnet.

---

# 8. Alguns CIDRs comuns

| CIDR | Quantidade teórica de endereços |
|---|---:|
| `/16` | 65.536 |
| `/20` | 4.096 |
| `/24` | 256 |
| `/28` | 16 |
| `/29` | 8 |

Uma regra importante:

```text
prefixo menor
=
rede maior
```

Exemplo:

```text
/16
```

é maior que:

```text
/24
```

---

# 9. Faixas privadas RFC1918

Faixas privadas comuns:

```text
10.0.0.0/8
```

```text
172.16.0.0/12
```

```text
192.168.0.0/16
```

Exemplo de planejamento:

```text
10.10.0.0/24
10.20.0.0/24
10.30.0.0/24
```

---

# 10. Sobreposição de CIDR

Duas subnets da mesma VPC não podem utilizar faixas primárias sobrepostas.

Exemplo válido:

```text
subnet-a
10.10.0.0/24

subnet-b
10.20.0.0/24
```

Exemplo problemático:

```text
subnet-a
10.10.0.0/24

subnet-b
10.10.0.128/25
```

A segunda faixa está contida na primeira.

---

# 11. IP interno

Uma VM ligada a uma subnet recebe um IP interno.

Exemplo:

```text
VM
 |
 v
10.10.0.2
```

Esse endereço é utilizado para comunicação privada.

Exemplo:

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

---

# 12. IP externo

Uma VM também pode possuir um endereço IP externo.

Exemplo:

```text
Internet
   |
   v
34.x.x.x
   |
   v
VM
   |
   v
10.10.0.2
```

A VM possui:

```text
IP externo
+
IP interno
```

O IP externo pode permitir comunicação com a internet, dependendo das regras e configuração.

---

# 13. IP efêmero x estático

## Efêmero

Um IP externo criado automaticamente pode ser efêmero.

Conceito:

```text
recurso
   |
   v
IP temporário
```

Ele não deve ser tratado como um endereço permanente.

---

## Estático

Pode ser reservado.

Exemplo:

```text
IP estático
   |
   v
34.x.x.x
```

É útil quando um endereço precisa permanecer estável.

Exemplos:

- Load Balancer;
- DNS;
- allowlist;
- endpoint externo.

---

# 14. Arquitetura do laboratório

Vamos construir:

```text
                         ace-vpc
                            |
               +------------+------------+
               |                         |
               v                         v
        subnet-us                  subnet-br
       10.10.0.0/24              10.20.0.0/24
        us-central1          southamerica-east1
               |                         |
               v                         v
             vm-us                     vm-br
```

Isso demonstrará que:

```text
VPC = global
Subnets = regionais
```

---

# 15. Pré-requisitos

Abra o Cloud Shell.

Veja o projeto:

```bash
# Explicação: Consulta o projeto atualmente ativo na configuração `gcloud`.
gcloud config get-value project
```

Defina:

```bash
# Explicação: Define `PROJECT_ID` com o ID do projeto Google Cloud usado pelos comandos seguintes.
export PROJECT_ID=$(gcloud config get-value project)
# Explicação: Define a variável `REGION_US` usada nas próximas etapas do laboratório.
export REGION_US=us-central1
# Explicação: Define a variável `ZONE_US` usada nas próximas etapas do laboratório.
export ZONE_US=us-central1-a
# Explicação: Define a variável `REGION_BR` usada nas próximas etapas do laboratório.
export REGION_BR=southamerica-east1
# Explicação: Define a variável `ZONE_BR` usada nas próximas etapas do laboratório.
export ZONE_BR=southamerica-east1-b
```

Veja:

```bash
# Explicação: Exibe ou grava o valor/texto informado, normalmente para validar variável ou criar conteúdo de teste.
echo $PROJECT_ID
# Explicação: Exibe ou grava o valor/texto informado, normalmente para validar variável ou criar conteúdo de teste.
echo $REGION_US
# Explicação: Exibe ou grava o valor/texto informado, normalmente para validar variável ou criar conteúdo de teste.
echo $ZONE_US
# Explicação: Exibe ou grava o valor/texto informado, normalmente para validar variável ou criar conteúdo de teste.
echo $REGION_BR
# Explicação: Exibe ou grava o valor/texto informado, normalmente para validar variável ou criar conteúdo de teste.
echo $ZONE_BR
```

Habilite Compute Engine:

```bash
# Explicação: Habilita a API/serviço indicado no projeto ativo para permitir o uso do recurso no laboratório.
gcloud services enable compute.googleapis.com
```

---

# 16. Criando uma configuração gcloud para o laboratório

Crie:

```bash
# Explicação: Cria uma configuração nomeada do `gcloud` para isolar projeto, região, zona e outras propriedades.
gcloud config configurations create ace-vpc-lab
```

Ative:

```bash
# Explicação: Ativa a configuração nomeada do `gcloud` que será usada nos próximos comandos.
gcloud config configurations activate ace-vpc-lab
```

Defina o projeto:

```bash
# Explicação: Define o projeto ativo da configuração `gcloud`, evitando informar `--project` em cada comando.
gcloud config set project $PROJECT_ID
```

Defina região e zona padrão:

```bash
# Explicação: Define a região padrão da configuração `gcloud` para comandos regionais.
gcloud config set compute/region $REGION_US
```

```bash
# Explicação: Define a zona padrão da configuração `gcloud` para comandos zonais.
gcloud config set compute/zone $ZONE_US
```

Veja:

```bash
# Explicação: Exibe as propriedades da configuração `gcloud` ativa para conferência.
gcloud config list
```

Lembre:

> A configuration não cria recursos. Ela mantém o contexto do `gcloud`.

---

# 17. Criando a VPC customizada

Execute:

```bash
# Explicação: Cria uma VPC; as flags definem, entre outros pontos, se a rede será custom mode ou auto mode.
gcloud compute networks create ace-vpc \
  --subnet-mode=custom
```

Liste:

```bash
# Explicação: Lista VPCs existentes no projeto.
gcloud compute networks list
```

Descreva:

```bash
# Explicação: Exibe propriedades da VPC para confirmar modo de subnet, roteamento e demais configurações.
gcloud compute networks describe ace-vpc
```

Observe:

```text
subnet mode = CUSTOM
```

---

# 18. Criando subnet nos Estados Unidos

Execute:

```bash
# Explicação: Cria uma sub-rede regional dentro da VPC com o intervalo CIDR informado.
gcloud compute networks subnets create subnet-us \
  --network=ace-vpc \
  --region=$REGION_US \
  --range=10.10.0.0/24
```

Descreva:

```bash
# Explicação: Exibe detalhes da sub-rede, incluindo CIDR, região e recursos de acesso privado.
gcloud compute networks subnets describe subnet-us \
  --region=$REGION_US
```

---

# 19. Criando subnet no Brasil

Execute:

```bash
# Explicação: Cria uma sub-rede regional dentro da VPC com o intervalo CIDR informado.
gcloud compute networks subnets create subnet-br \
  --network=ace-vpc \
  --region=$REGION_BR \
  --range=10.20.0.0/24
```

Liste:

```bash
# Explicação: Lista sub-redes para verificar região, VPC e intervalos de IP.
gcloud compute networks subnets list \
  --network=ace-vpc
```

Agora:

```text
                   ace-vpc
                      |
          +-----------+-----------+
          |                       |
          v                       v
      subnet-us                subnet-br
    us-central1          southamerica-east1
   10.10.0.0/24            10.20.0.0/24
```

---

# 20. Tentativa de CIDR sobreposto

Vamos provocar um erro proposital.

Tente criar:

```bash
# Explicação: Cria uma sub-rede regional dentro da VPC com o intervalo CIDR informado.
gcloud compute networks subnets create subnet-overlap \
  --network=ace-vpc \
  --region=$REGION_US \
  --range=10.10.0.128/25
```

A operação deverá falhar porque:

```text
10.10.0.128/25
```

sobrepõe:

```text
10.10.0.0/24
```

Esse é um excelente exemplo de erro de planejamento de endereçamento.

---

# 21. Criando regra SSH temporária

Crie:

```bash
# Explicação: Cria uma regra de firewall VPC; direção, origem/destino, alvo e protocolos/portas são definidos pelas flags.
gcloud compute firewall-rules create ace-vpc-allow-ssh \
  --network=ace-vpc \
  --direction=INGRESS \
  --priority=1000 \
  --action=ALLOW \
  --rules=tcp:22 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=ssh-lab
```

> Para produção, prefira métodos mais restritivos como IAP e não libere SSH para toda a internet.

---

# 22. Criando VM na subnet dos EUA

Execute:

```bash
# Explicação: Cria uma VM do Compute Engine com as opções de máquina, rede, disco e identidade informadas.
gcloud compute instances create vm-us \
  --zone=$ZONE_US \
  --machine-type=e2-micro \
  --subnet=subnet-us \
  --tags=ssh-lab \
  --image-family=debian-12 \
  --image-project=debian-cloud
```

Liste:

```bash
# Explicação: Lista VMs do projeto para verificar inventário, zona, IPs e estado.
gcloud compute instances list
```

---

# 23. Criando VM na subnet do Brasil

Execute:

```bash
# Explicação: Cria uma VM do Compute Engine com as opções de máquina, rede, disco e identidade informadas.
gcloud compute instances create vm-br \
  --zone=$ZONE_BR \
  --machine-type=e2-micro \
  --subnet=subnet-br \
  --tags=ssh-lab \
  --image-family=debian-12 \
  --image-project=debian-cloud
```

Liste:

```bash
# Explicação: Lista VMs do projeto para verificar inventário, zona, IPs e estado.
gcloud compute instances list
```

---

# 24. Observando os IPs

Execute:

```bash
# Explicação: Lista VMs do projeto para verificar inventário, zona, IPs e estado.
gcloud compute instances list \
  --format="table(name,zone,networkInterfaces[0].networkIP:label=INTERNAL_IP,networkInterfaces[0].accessConfigs[0].natIP:label=EXTERNAL_IP)"
```

Você deverá observar algo semelhante:

```text
NAME    ZONE                    INTERNAL_IP   EXTERNAL_IP
vm-us   us-central1-a           10.10.0.x     34.x.x.x
vm-br   southamerica-east1-b    10.20.0.x     35.x.x.x
```

Isso mostra:

```text
IP interno
+
IP externo
```

---

# 25. Inspecionando a interface de rede

Execute:

```bash
# Explicação: Exibe a configuração e o estado detalhado da VM para inspeção/troubleshooting.
gcloud compute instances describe vm-us \
  --zone=$ZONE_US
```

Procure:

```text
networkInterfaces
```

Você verá informações como:

```text
network
subnetwork
networkIP
accessConfigs
natIP
```

---

# 26. Salvando os IPs internos

Execute:

```bash
# Explicação: Define a variável `VM_US_IP` usada nas próximas etapas do laboratório.
export VM_US_IP=$(gcloud compute instances describe vm-us \
  --zone=$ZONE_US \
  --format="value(networkInterfaces[0].networkIP)")
```

```bash
# Explicação: Define a variável `VM_BR_IP` usada nas próximas etapas do laboratório.
export VM_BR_IP=$(gcloud compute instances describe vm-br \
  --zone=$ZONE_BR \
  --format="value(networkInterfaces[0].networkIP)")
```

Veja:

```bash
# Explicação: Exibe ou grava o valor/texto informado, normalmente para validar variável ou criar conteúdo de teste.
echo $VM_US_IP
# Explicação: Exibe ou grava o valor/texto informado, normalmente para validar variável ou criar conteúdo de teste.
echo $VM_BR_IP
```

---

# 27. Comunicação entre subnets da mesma VPC

As subnets estão em regiões diferentes:

```text
subnet-us
us-central1

subnet-br
southamerica-east1
```

mas pertencem à mesma:

```text
ace-vpc
```

Portanto existe roteamento de VPC entre suas faixas.

Porém firewall continua sendo aplicado.

---

# 28. Testando ICMP antes da regra

Entre na VM dos EUA:

```bash
# Explicação: Abre uma sessão SSH na VM indicada; flags adicionais podem executar um comando remotamente.
gcloud compute ssh vm-us \
  --zone=$ZONE_US
```

Teste:

```bash
# Explicação: Envia pacotes ICMP para testar alcance IP entre origem e destino.
ping -c 4 IP_INTERNO_VM_BR
```

Pode falhar porque ainda não liberamos ICMP.

Saia:

```bash
# Explicação: Encerra a sessão atual do shell/SSH e retorna ao terminal anterior.
exit
```

---

# 29. Criando regra ICMP interna

Execute:

```bash
# Explicação: Cria uma regra de firewall VPC; direção, origem/destino, alvo e protocolos/portas são definidos pelas flags.
gcloud compute firewall-rules create ace-vpc-allow-icmp \
  --network=ace-vpc \
  --direction=INGRESS \
  --priority=1000 \
  --action=ALLOW \
  --rules=icmp \
  --source-ranges=10.10.0.0/24,10.20.0.0/24
```

Teste:

```bash
# Explicação: Abre uma sessão SSH na VM indicada; flags adicionais podem executar um comando remotamente.
gcloud compute ssh vm-us \
  --zone=$ZONE_US \
  --command="ping -c 4 $VM_BR_IP"
```

Agora deverá funcionar.

---

# 30. O que este teste provou?

Provou que:

```text
VPC global
   |
   +--> subnet-us
   |
   +--> subnet-br
```

permite conectividade privada entre subnets, mesmo em regiões distintas, desde que:

```text
rota exista
+
firewall permita
```

---

# 31. Observando as rotas criadas automaticamente

Execute:

```bash
# Explicação: Lista rotas efetivas/estáticas visíveis no projeto para análise de caminho de rede.
gcloud compute routes list \
  --filter="network:ace-vpc"
```

Você deverá encontrar rotas relacionadas a:

```text
10.10.0.0/24
10.20.0.0/24
```

Essas rotas permitem que os recursos da VPC encontrem as subnets.

---

# 32. Criando uma VM sem IP externo

Agora vamos criar uma VM privada.

Execute:

```bash
# Explicação: Cria uma VM do Compute Engine com as opções de máquina, rede, disco e identidade informadas.
gcloud compute instances create vm-private \
  --zone=$ZONE_US \
  --machine-type=e2-micro \
  --subnet=subnet-us \
  --no-address \
  --image-family=debian-12 \
  --image-project=debian-cloud
```

Liste:

```bash
# Explicação: Lista VMs do projeto para verificar inventário, zona, IPs e estado.
gcloud compute instances list
```

Observe:

```text
vm-private
INTERNAL_IP = 10.10.0.x
EXTERNAL_IP = vazio
```

Isso significa:

```text
VM possui IP privado
```

mas:

```text
não possui IP externo
```

---

# 33. IP externo não é obrigatório

Uma VM pode funcionar perfeitamente sem IP externo.

Exemplo:

```text
VM privada
10.10.0.5
```

pode:

- comunicar com outras VMs privadas;
- acessar recursos internos;
- utilizar Cloud NAT para saída à internet;
- utilizar Private Google Access para APIs Google;
- receber tráfego via Load Balancer.

Isso será aprofundado nas próximas aulas.

---

# 34. Criando um IP externo estático

Agora vamos praticar endereços estáticos.

Crie um IP regional:

```bash
# Explicação: Reserva um endereço IP estático interno ou externo conforme escopo e flags informados.
gcloud compute addresses create ace-static-ip \
  --region=$REGION_US
```

Liste:

```bash
# Explicação: Lista endereços IP estáticos reservados no projeto.
gcloud compute addresses list
```

Veja o endereço:

```bash
# Explicação: Exibe o endereço IP reservado e suas propriedades.
gcloud compute addresses describe ace-static-ip \
  --region=$REGION_US \
  --format="value(address)"
```

Salve:

```bash
# Explicação: Define a variável `STATIC_IP` usada nas próximas etapas do laboratório.
export STATIC_IP=$(gcloud compute addresses describe ace-static-ip \
  --region=$REGION_US \
  --format="value(address)")
```

Veja:

```bash
# Explicação: Exibe ou grava o valor/texto informado, normalmente para validar variável ou criar conteúdo de teste.
echo $STATIC_IP
```

---

# 35. IP regional x global

Esse é um ponto importante.

Um IP pode possuir escopo compatível com o recurso.

Exemplo conceitual:

```text
VM
→ IP externo regional
```

Enquanto certos Load Balancers globais utilizam:

```text
IP global
```

Não assuma que todo endereço reservado tem o mesmo escopo.

---

# 36. Atribuindo o IP estático a uma VM

Para simplificar o laboratório, vamos criar uma nova VM já usando o IP reservado.

Execute:

```bash
# Explicação: Cria uma VM do Compute Engine com as opções de máquina, rede, disco e identidade informadas.
gcloud compute instances create vm-static \
  --zone=$ZONE_US \
  --machine-type=e2-micro \
  --subnet=subnet-us \
  --address=$STATIC_IP \
  --tags=ssh-lab \
  --image-family=debian-12 \
  --image-project=debian-cloud
```

Liste:

```bash
# Explicação: Lista VMs do projeto para verificar inventário, zona, IPs e estado.
gcloud compute instances list
```

Você deverá observar:

```text
vm-static
EXTERNAL_IP = valor reservado
```

---

# 37. Endereço efêmero x estático na prática

Temos agora:

```text
vm-us
→ IP externo efêmero
```

```text
vm-static
→ IP externo estático
```

E:

```text
vm-private
→ sem IP externo
```

Esses três casos são importantes.

---

# 38. Inspecionando endereços reservados

Execute:

```bash
# Explicação: Lista endereços IP estáticos reservados no projeto.
gcloud compute addresses list
```

Observe campos como:

```text
NAME
ADDRESS
REGION
STATUS
```

O status pode mostrar se o endereço está em uso.

---

# 39. Laboratório de troubleshooting 1 — subnet errada

Imagine que uma aplicação deveria estar em:

```text
subnet-br
```

mas foi criada em:

```text
subnet-us
```

Como verificar?

Execute:

```bash
# Explicação: Exibe a configuração e o estado detalhado da VM para inspeção/troubleshooting.
gcloud compute instances describe vm-us \
  --zone=$ZONE_US \
  --format="yaml(networkInterfaces)"
```

Isso permite confirmar:

```text
VPC
subnet
IP interno
IP externo
```

---

# 40. Laboratório de troubleshooting 2 — CIDR incorreto

Considere que alguém planejou:

```text
subnet-app
10.10.0.0/24
```

e depois tentou criar:

```text
subnet-data
10.10.0.128/25
```

Problema:

```text
overlap
```

Antes de criar subnets, sempre valide o plano de endereçamento.

---

# 41. Laboratório de troubleshooting 3 — comunicação entre regiões

Suponha:

```text
vm-us
não alcança
vm-br
```

Não conclua:

> "É porque estão em regiões diferentes."

Essa conclusão seria errada.

Primeiro verifique:

```text
1. Mesma VPC?
2. IP correto?
3. Rotas existem?
4. Firewall permite?
5. VM está RUNNING?
```

A VPC do Google Cloud é global.

---

# 42. Comandos fundamentais

## Redes

```bash
# Explicação: Lista VPCs existentes no projeto.
gcloud compute networks list
```

## Subnets

```bash
# Explicação: Lista sub-redes para verificar região, VPC e intervalos de IP.
gcloud compute networks subnets list
```

## VMs

```bash
# Explicação: Lista VMs do projeto para verificar inventário, zona, IPs e estado.
gcloud compute instances list
```

## IPs reservados

```bash
# Explicação: Lista endereços IP estáticos reservados no projeto.
gcloud compute addresses list
```

## Rotas

```bash
# Explicação: Lista rotas efetivas/estáticas visíveis no projeto para análise de caminho de rede.
gcloud compute routes list
```

## Firewall

```bash
# Explicação: Lista regras de firewall para inspecionar a política efetiva da VPC.
gcloud compute firewall-rules list
```

---

# 43. Exercício — identifique os escopos

Classifique:

```text
VPC
Subnet
VM
IP estático regional
```

Resposta:

```text
VPC
→ global

Subnet
→ regional

VM
→ zonal

IP estático regional
→ regional
```

Essa relação é muito importante para o ACE.

---

# 44. Exercício — CIDR

Considere:

```text
10.10.0.0/24
```

Perguntas:

1. Quantos bits possui um IPv4?
2. Quantos bits são usados pelo prefixo?
3. Quantos bits restam?
4. Quantos endereços teóricos existem?

Resposta:

```text
IPv4 = 32 bits

prefixo = 24

restam = 8

2^8 = 256
```

---

# 45. Exercício — planejamento de rede

Você precisa de três subnets.

Uma possibilidade:

```text
app
10.10.0.0/24

data
10.20.0.0/24

management
10.30.0.0/24
```

Pergunta:

> Elas se sobrepõem?

Resposta:

```text
Não.
```

---

# 46. Exercício — identifique o problema

Considere:

```text
subnet-a
10.10.0.0/24

subnet-b
10.10.0.0/25
```

Problema:

```text
CIDRs sobrepostos
```

---

# 47. Pegadinhas ACE

## Pegadinha 1

> VPC é regional.

**Errado.**

No Google Cloud, a VPC é global.

---

## Pegadinha 2

> Subnet é zonal.

**Errado.**

Subnet é regional.

---

## Pegadinha 3

> Duas VMs em regiões diferentes precisam de VPC Peering.

**Errado**, se estiverem em subnets da mesma VPC.

A VPC é global.

---

## Pegadinha 4

> Toda VM precisa de IP externo.

**Errado.**

VMs privadas podem operar sem IP externo.

---

## Pegadinha 5

> IP externo e interno são a mesma coisa.

**Errado.**

IP interno é usado para comunicação privada.

IP externo é utilizado para comunicação externa, conforme configuração.

---

## Pegadinha 6

> `/16` é uma rede menor que `/24`.

**Errado.**

`/16` possui mais endereços.

---

## Pegadinha 7

> Subnets podem usar qualquer CIDR mesmo que se sobreponham.

**Errado.**

Sobreposição causa conflitos e restrições.

---

# 48. Questões estilo ACE

## Questão 1

Uma empresa quer uma VPC com subnets apenas nas regiões escolhidas pela equipe de arquitetura.

Qual modo deve utilizar?

**Resposta:** Custom mode.

---

## Questão 2

Uma empresa possui uma subnet em `us-central1` e outra em `southamerica-east1`, ambas na mesma VPC.

É necessário VPC Peering para comunicação privada entre elas?

**Resposta:** Não.

---

## Questão 3

Qual é o escopo de uma VPC no Google Cloud?

**Resposta:** Global.

---

## Questão 4

Qual é o escopo de uma subnet?

**Resposta:** Regional.

---

## Questão 5

Uma VM não deve possuir endereço público, mas precisa acessar a internet para atualizações.

Qual arquitetura pode ser utilizada?

**Resposta:** VM sem IP externo + Cloud NAT.

---

## Questão 6

Um endereço público precisa permanecer estável para uso em DNS e allowlists.

Qual opção?

**Resposta:** IP estático reservado.

---

## Questão 7

Duas subnets são configuradas com:

```text
10.10.0.0/24
10.10.0.128/25
```

Qual é o problema?

**Resposta:** Sobreposição de CIDR.

---

# 49. Desafio de interpretação

Associe:

```text
A. VPC
B. Subnet
C. VM
D. IP interno
E. IP estático
F. CIDR
```

a:

```text
1. Endereço privado
2. Recurso global de rede
3. Faixa de endereços
4. Endereço reservado
5. Recurso regional de rede
6. Recurso de compute normalmente zonal
```

Resposta:

```text
A -> 2
B -> 5
C -> 6
D -> 1
E -> 4
F -> 3
```

---

# 50. Arquitetura final do laboratório

```text
                              ace-vpc
                                |
                  +-------------+-------------+
                  |                           |
                  v                           v
              subnet-us                  subnet-br
             10.10.0.0/24              10.20.0.0/24
              us-central1          southamerica-east1
                  |                           |
        +---------+---------+                 |
        |         |         |                 |
        v         v         v                 v
      vm-us   vm-private  vm-static          vm-br
        |         |         |
        |         |         +--> IP estático
        |         |
        |         +------------> sem IP externo
        |
        +----------------------> IP efêmero
```

---

# 51. Relação com as próximas aulas

Esta aula fornece a base para entender:

```text
Aula 2
Firewall Rules e Rotas
```

porque agora sabemos:

```text
VPC
subnets
IPs
CIDRs
```

Depois:

```text
Aula 3
Cloud NAT
Private Google Access
Cloud DNS
```

que parte do cenário:

```text
VM privada
sem IP externo
```

Depois:

```text
Aula 4
Load Balancing
```

e:

```text
Aula 5
Shared VPC
Peering
VPN
Interconnect
```

---

# 52. Limpeza — VMs

Remova:

```bash
# Explicação: Exclui a VM indicada e libera os recursos associados que não foram preservados.
gcloud compute instances delete vm-us \
  --zone=$ZONE_US \
  --quiet
```

```bash
# Explicação: Exclui a VM indicada e libera os recursos associados que não foram preservados.
gcloud compute instances delete vm-private \
  --zone=$ZONE_US \
  --quiet
```

```bash
# Explicação: Exclui a VM indicada e libera os recursos associados que não foram preservados.
gcloud compute instances delete vm-static \
  --zone=$ZONE_US \
  --quiet
```

```bash
# Explicação: Exclui a VM indicada e libera os recursos associados que não foram preservados.
gcloud compute instances delete vm-br \
  --zone=$ZONE_BR \
  --quiet
```

---

# 53. Limpeza — IP estático

```bash
# Explicação: Libera o endereço IP estático reservado no laboratório.
gcloud compute addresses delete ace-static-ip \
  --region=$REGION_US \
  --quiet
```

---

# 54. Limpeza — firewall

```bash
# Explicação: Remove a regra de firewall criada ou alterada para o laboratório.
gcloud compute firewall-rules delete \
  ace-vpc-allow-ssh \
  ace-vpc-allow-icmp \
  --quiet
```

---

# 55. Limpeza — subnets

```bash
# Explicação: Exclui a sub-rede indicada.
gcloud compute networks subnets delete subnet-us \
  --region=$REGION_US \
  --quiet
```

```bash
# Explicação: Exclui a sub-rede indicada.
gcloud compute networks subnets delete subnet-br \
  --region=$REGION_BR \
  --quiet
```

---

# 56. Limpeza — VPC

```bash
# Explicação: Exclui a VPC depois que os recursos dependentes foram removidos.
gcloud compute networks delete ace-vpc \
  --quiet
```

---

# 57. Removendo a configuration

Ative outra configuração:

```bash
# Explicação: Ativa a configuração nomeada do `gcloud` que será usada nos próximos comandos.
gcloud config configurations activate default
```

Depois:

```bash
# Explicação: Remove a configuração do `gcloud` criada para o laboratório.
gcloud config configurations delete ace-vpc-lab
```

Liste:

```bash
# Explicação: Lista as configurações do `gcloud` existentes na máquina/Cloud Shell.
gcloud config configurations list
```

---

# 58. Checklist final

- [ ] Entendo o que é uma VPC;
- [ ] Sei que VPC é global;
- [ ] Sei que subnet é regional;
- [ ] Sei que VM normalmente é zonal;
- [ ] Entendo auto mode;
- [ ] Entendo custom mode;
- [ ] Entendo CIDR;
- [ ] Sei interpretar `/24`;
- [ ] Entendo sobreposição de CIDR;
- [ ] Conheço faixas privadas RFC1918;
- [ ] Sei diferenciar IP interno e externo;
- [ ] Sei diferenciar IP efêmero e estático;
- [ ] Consegui criar uma VPC customizada;
- [ ] Consegui criar subnets em regiões diferentes;
- [ ] Consegui criar VMs em subnets diferentes;
- [ ] Consegui observar IP interno e externo;
- [ ] Consegui criar uma VM sem IP externo;
- [ ] Consegui testar comunicação privada entre regiões;
- [ ] Consegui observar as rotas das subnets;
- [ ] Consegui provocar erro de CIDR sobreposto;
- [ ] Consegui reservar um IP estático;
- [ ] Consegui remover os recursos do laboratório.

---

# 59. O que você deve memorizar para o ACE

A relação mais importante:

```text
VPC
= global
```

```text
Subnet
= regional
```

```text
VM
= zonal
```

Também:

```text
CIDR
= faixa de endereços
```

```text
/16
= bloco maior
```

```text
/24
= bloco menor
```

```text
IP interno
= comunicação privada
```

```text
IP externo
= comunicação externa
```

```text
IP estático
= endereço reservado
```

```text
Custom Mode
= controle sobre subnets e CIDRs
```

Arquitetura mental:

```text
VPC global
   |
   +--> subnet regional
   |       |
   |       +--> VM zonal
   |
   +--> subnet regional
           |
           +--> VM zonal
```

Se você consegue olhar para uma arquitetura e identificar corretamente **VPC, subnet, região, zona, CIDR, IP interno e IP externo**, já domina a base de networking necessária para avançar nas próximas aulas do Associate Cloud Engineer.

---

# Cobertura adicional do exam guide — expansão de subnet e IP interno estático

## Expandir uma subnet

O primary IPv4 range pode ser expandido, não reduzido.

Exemplo após validar ausência de conflito:

```bash
# Explicação: Executa `gcloud compute networks subnets expand-ip-range subnet-us --region=us-central1 --pre…` nesta etapa para aplicar ou inspecionar a configuração indicada.
gcloud compute networks subnets expand-ip-range subnet-us \
  --region=us-central1 \
  --prefix-length=23
```

Antes:

```text
10.10.0.0/24
```

Depois:

```text
10.10.0.0/23
```

Inspecione:

```bash
# Explicação: Exibe detalhes da sub-rede, incluindo CIDR, região e recursos de acesso privado.
gcloud compute networks subnets describe subnet-us \
  --region=us-central1 \
  --format='value(ipCidrRange)'
```

## Reservar IP interno estático

```bash
# Explicação: Reserva um endereço IP estático interno ou externo conforme escopo e flags informados.
gcloud compute addresses create ace-internal-ip \
  --region=us-central1 \
  --subnet=subnet-us \
  --addresses=10.10.0.50

# Explicação: Exibe o endereço IP reservado e suas propriedades.
gcloud compute addresses describe ace-internal-ip \
  --region=us-central1
```

Lembre-se: a faixa deve pertencer à subnet e não estar em uso/reservada.


---

# Cobertura ACE ampliada — resize de subnet e IP interno estático

## Expandir subnet IPv4

O guia cobra resize da faixa IPv4. A expansão deve usar um prefixo maior em capacidade, sem sobreposição.

Exemplo:

```bash
# Explicação: Executa `gcloud compute networks subnets expand-ip-range subnet-us --region=us-central1 --pre…` nesta etapa para aplicar ou inspecionar a configuração indicada.
gcloud compute networks subnets expand-ip-range subnet-us \
  --region=us-central1 \
  --prefix-length=23
```

> Uma subnet `10.10.0.0/24` pode ser expandida para uma faixa compatível maior; não é um mecanismo para encolher livremente a subnet.

## IP interno estático

Além de IP externo estático, você pode reservar endereço interno regional:

```bash
# Explicação: Reserva um endereço IP estático interno ou externo conforme escopo e flags informados.
gcloud compute addresses create ace-internal-ip \
  --region=us-central1 \
  --subnet=subnet-us \
  --addresses=10.10.0.50
```

Inspecione:

```bash
# Explicação: Exibe o endereço IP reservado e suas propriedades.
gcloud compute addresses describe ace-internal-ip --region=us-central1
```

## Network Service Tiers

```text
Premium Tier  → tráfego usa backbone premium do Google por mais do percurso
Standard Tier → opção de custo/roteamento diferente para casos suportados
```

A escolha depende do tipo de recurso, alcance e requisitos de performance/custo.
