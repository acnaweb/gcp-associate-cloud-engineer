# Aula 5 — Shared VPC, VPC Peering, Cloud VPN, Cloud Interconnect e Troubleshooting

## Objetivos

Ao final desta aula, você deverá ser capaz de:

- Entender quando utilizar **Shared VPC**;
- Entender quando utilizar **VPC Network Peering**;
- Diferenciar **Shared VPC x VPC Peering**;
- Entender o papel do **Cloud VPN**;
- Entender **HA VPN**, **Cloud Router** e **BGP**;
- Diferenciar **Cloud VPN x Cloud Interconnect**;
- Diferenciar **Dedicated Interconnect x Partner Interconnect**;
- Entender o papel de rotas, firewall e DNS no troubleshooting;
- Criar duas VPCs independentes;
- Criar subnets com faixas CIDR não sobrepostas;
- Criar VMs em redes diferentes;
- Criar um VPC Peering bidirecional;
- Testar comunicação privada entre as VPCs;
- Simular falhas de firewall e peering;
- Utilizar `gcloud` para diagnosticar conectividade;
- Utilizar **Connectivity Tests** para investigar problemas;
- Entender os comandos principais de Shared VPC;
- Entender a arquitetura de HA VPN;
- Relacionar os conceitos com questões da certificação Associate Cloud Engineer.

---

# 1. O problema que esta aula resolve

Até aqui trabalhamos principalmente com recursos dentro de uma única VPC.

Mas ambientes reais possuem cenários como:

```text
Projeto A
   |
   +--> VPC A

Projeto B
   |
   +--> VPC B
```

ou:

```text
Data Center
    |
    v
Google Cloud
```

ou ainda:

```text
Projeto de Rede
      |
      +--> Projeto Aplicação A
      +--> Projeto Aplicação B
      +--> Projeto Dados
```

Precisamos saber responder:

- Como conectar duas VPCs?
- Como compartilhar uma VPC entre projetos?
- Como conectar um data center ao Google Cloud?
- Quando usar VPN?
- Quando usar Interconnect?
- Por que duas VMs não conseguem se comunicar?
- O problema é rota, firewall, DNS, peering ou VPN?

---

# 2. Visão geral das opções

```text
                     CONECTIVIDADE
                          |
          +---------------+---------------+
          |               |               |
          v               v               v
      Entre VPCs      Entre Projetos    On-premises
          |               |               |
          v               v               v
     VPC Peering      Shared VPC      VPN/Interconnect
```

Simplificação útil para o ACE:

```text
Shared VPC
→ Compartilhar uma mesma rede entre projetos

VPC Peering
→ Conectar redes VPC diferentes

Cloud VPN
→ Conectar redes usando túneis IPsec pela internet

Cloud Interconnect
→ Conectividade dedicada/privada de maior capacidade
```

---

# 3. Shared VPC

Shared VPC permite que vários projetos utilizem recursos de uma VPC centralizada.

```text
                 ORGANIZATION
                     |
          +----------+----------+
          |                     |
          v                     v
     Host Project         Service Projects
          |                /      |       \
          v               v       v        v
       Shared VPC       App A   App B    Dados
          |
     +----+----+
     |         |
     v         v
  Subnet A   Subnet B
```

O projeto que possui a VPC é o:

```text
Host Project
```

Os projetos que consomem as subnets são:

```text
Service Projects
```

---

# 4. Por que usar Shared VPC?

Sem Shared VPC:

```text
app-dev  -> VPC
app-hml  -> VPC
app-prd  -> VPC
data-prd -> VPC
```

Com Shared VPC:

```text
network-host
     |
     v
 Shared VPC
     |
     +--> app-dev
     +--> app-hml
     +--> app-prd
     +--> data-prd
```

A equipe de redes pode centralizar:

- VPC;
- Subnets;
- Firewall;
- Rotas;
- Conectividade híbrida.

As equipes de aplicação continuam administrando seus recursos nos próprios projetos.

---

# 5. Shared VPC x VPC Peering

## Shared VPC

```text
Host Project
     |
     v
UMA VPC
     |
 +---+---+
 |       |
 v       v
Service Service
Project Project
```

Os projetos usam a mesma rede.

## VPC Peering

```text
VPC A
  |
  | Peering
  |
VPC B
```

São redes distintas conectadas.

| Característica | Shared VPC | VPC Peering |
|---|---|---|
| Redes | Uma rede compartilhada | Redes diferentes |
| Projetos | Host + Service Projects | Mesmo ou diferentes projetos |
| Administração centralizada | Sim | Não necessariamente |
| Comunicação privada | Sim | Sim |
| Caso típico | Organização corporativa | Conectar redes independentes |

---

# 6. Pré-requisitos do laboratório

Usaremos:

```text
REGION = us-central1
ZONE   = us-central1-a
```

Abra o Cloud Shell.

```bash
gcloud config get-value project
```

Defina:

```bash
export PROJECT_ID=$(gcloud config get-value project)
export REGION=us-central1
export ZONE=us-central1-a
```

Confira:

```bash
echo $PROJECT_ID
echo $REGION
echo $ZONE
```

Habilite as APIs:

```bash
gcloud services enable \
  compute.googleapis.com \
  networkmanagement.googleapis.com
```

---

# 7. Laboratório 1 — Criando duas VPCs

Criaremos:

```text
ace-vpc-a
ace-vpc-b
```

com:

```text
ace-vpc-a
└── subnet-a
    10.10.0.0/24

ace-vpc-b
└── subnet-b
    10.20.0.0/24
```

As faixas CIDR não se sobrepõem.

---

# 8. Criando a VPC A

```bash
gcloud compute networks create ace-vpc-a \
  --subnet-mode=custom
```

```bash
gcloud compute networks subnets create subnet-a \
  --network=ace-vpc-a \
  --region=$REGION \
  --range=10.10.0.0/24
```

Verifique:

```bash
gcloud compute networks describe ace-vpc-a
```

```bash
gcloud compute networks subnets list \
  --network=ace-vpc-a
```

---

# 9. Criando a VPC B

```bash
gcloud compute networks create ace-vpc-b \
  --subnet-mode=custom
```

```bash
gcloud compute networks subnets create subnet-b \
  --network=ace-vpc-b \
  --region=$REGION \
  --range=10.20.0.0/24
```

```bash
gcloud compute networks subnets list \
  --network=ace-vpc-b
```

Temos agora:

```text
ace-vpc-a                ace-vpc-b
10.10.0.0/24             10.20.0.0/24
```

Ainda não há conectividade entre elas.

---

# 10. Criando regras SSH temporárias

VPC A:

```bash
gcloud compute firewall-rules create ace-vpc-a-allow-ssh \
  --network=ace-vpc-a \
  --allow=tcp:22 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=ssh-lab
```

VPC B:

```bash
gcloud compute firewall-rules create ace-vpc-b-allow-ssh \
  --network=ace-vpc-b \
  --allow=tcp:22 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=ssh-lab
```

> Para produção, evite SSH aberto para `0.0.0.0/0`. A regra aqui é temporária para simplificar o laboratório.

---

# 11. Criando as VMs

VM A:

```bash
gcloud compute instances create vm-a \
  --zone=$ZONE \
  --machine-type=e2-micro \
  --subnet=subnet-a \
  --tags=ssh-lab \
  --image-family=debian-12 \
  --image-project=debian-cloud
```

VM B:

```bash
gcloud compute instances create vm-b \
  --zone=$ZONE \
  --machine-type=e2-micro \
  --subnet=subnet-b \
  --tags=ssh-lab \
  --image-family=debian-12 \
  --image-project=debian-cloud
```

Liste:

```bash
gcloud compute instances list
```

Capture os IPs privados:

```bash
export VM_A_IP=$(gcloud compute instances describe vm-a \
  --zone=$ZONE \
  --format="value(networkInterfaces[0].networkIP)")

export VM_B_IP=$(gcloud compute instances describe vm-b \
  --zone=$ZONE \
  --format="value(networkInterfaces[0].networkIP)")
```

```bash
echo $VM_A_IP
echo $VM_B_IP
```

---

# 12. Testando antes do Peering

Entre na VM A:

```bash
gcloud compute ssh vm-a --zone=$ZONE
```

Tente:

```bash
ping -c 4 IP_PRIVADO_VM_B
```

A comunicação ainda não deve funcionar.

```text
VM A
 |
 v
VPC A

     X

VPC B
 |
 v
VM B
```

Saia:

```bash
exit
```

---

# 13. Criando o VPC Peering

O peering deve ser configurado dos dois lados.

```bash
gcloud compute networks peerings create peer-a-to-b \
  --network=ace-vpc-a \
  --peer-network=ace-vpc-b
```

```bash
gcloud compute networks peerings create peer-b-to-a \
  --network=ace-vpc-b \
  --peer-network=ace-vpc-a
```

Liste:

```bash
gcloud compute networks peerings list
```

O estado deverá chegar a:

```text
ACTIVE
```

Arquitetura:

```text
10.10.0.0/24                10.20.0.0/24
     |                           |
  VPC A ===== VPC PEERING ===== VPC B
     |                           |
    VM A                        VM B
```

---

# 14. Peering não substitui Firewall

Na VPC B, permita ICMP proveniente da VPC A:

```bash
gcloud compute firewall-rules create ace-vpc-b-allow-icmp-from-a \
  --network=ace-vpc-b \
  --allow=icmp \
  --source-ranges=10.10.0.0/24
```

Na VPC A:

```bash
gcloud compute firewall-rules create ace-vpc-a-allow-icmp-from-b \
  --network=ace-vpc-a \
  --allow=icmp \
  --source-ranges=10.20.0.0/24
```

---

# 15. Testando o Peering

```bash
gcloud compute ssh vm-a --zone=$ZONE
```

```bash
ping -c 4 IP_PRIVADO_VM_B
```

Depois teste da VM B para A.

```text
VM A
 |
 | 10.10.0.x
 |
 VPC A
   |
   | PEERING
   |
 VPC B
 |
 | 10.20.0.x
 |
VM B
```

---

# 16. Observando as rotas

```bash
gcloud compute routes list
```

Filtre:

```bash
gcloud compute routes list \
  --filter="network:ace-vpc-a"
```

```bash
gcloud compute routes list \
  --filter="network:ace-vpc-b"
```

Conceito:

```text
Peering
   |
   v
Troca de rotas de subnet
```

---

# 17. Pegadinha importante — Peering não é transitivo

```text
VPC A <----> VPC B <----> VPC C
```

Isso não cria automaticamente:

```text
VPC A <----> VPC C
```

Para o ACE:

> Não trate uma VPC peer como roteador de trânsito apenas porque ela possui outro peering.

---

# 18. Troubleshooting 1 — quebrando o Firewall

Delete a regra de ICMP de A para B:

```bash
gcloud compute firewall-rules delete \
  ace-vpc-b-allow-icmp-from-a \
  --quiet
```

Teste de VM A:

```bash
ping -c 4 $VM_B_IP
```

Agora verifique:

```bash
gcloud compute networks peerings list
```

O peering continua:

```text
ACTIVE
```

Diagnóstico:

```text
Routing OK
Firewall FAIL
```

---

# 19. Recriando a regra

```bash
gcloud compute firewall-rules create ace-vpc-b-allow-icmp-from-a \
  --network=ace-vpc-b \
  --allow=icmp \
  --source-ranges=10.10.0.0/24
```

Teste novamente.

---

# 20. Troubleshooting — ordem mental

Quando uma conexão não funciona:

```text
1. Recurso existe?
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
5. Serviço está ouvindo?
      |
      v
6. DNS resolve?
      |
      v
7. Peering/VPN está ativo?
```

---

# 21. Comandos fundamentais de troubleshooting

## IPs

```bash
gcloud compute instances list
```

## VM

```bash
gcloud compute instances describe vm-a \
  --zone=$ZONE
```

## Subnets

```bash
gcloud compute networks subnets list
```

## Rotas

```bash
gcloud compute routes list
```

## Firewall

```bash
gcloud compute firewall-rules list
```

## Peering

```bash
gcloud compute networks peerings list
```

---

# 22. Connectivity Tests

O **Connectivity Tests**, do Network Intelligence Center, ajuda a analisar o caminho entre endpoints.

```text
Source
  |
  v
Connectivity Tests
  |
  +--> routes
  +--> firewall
  +--> network
  +--> destination
```

---

# 23. Criando um Connectivity Test

Instale nginx na VM B:

```bash
gcloud compute ssh vm-b \
  --zone=$ZONE \
  --command="sudo apt-get update && sudo apt-get install -y nginx"
```

Crie firewall HTTP:

```bash
gcloud compute firewall-rules create ace-vpc-b-allow-http-from-a \
  --network=ace-vpc-b \
  --allow=tcp:80 \
  --source-ranges=10.10.0.0/24
```

Crie o teste:

```bash
gcloud network-management connectivity-tests create ace-a-to-b-http \
  --source-ip-address=$VM_A_IP \
  --source-network=ace-vpc-a \
  --source-network-type=GCP_NETWORK \
  --destination-ip-address=$VM_B_IP \
  --destination-port=80 \
  --protocol=TCP
```

Descreva:

```bash
gcloud network-management connectivity-tests describe \
  ace-a-to-b-http
```

---

# 24. Testando HTTP de verdade

```bash
gcloud compute ssh vm-a --zone=$ZONE
```

```bash
curl http://$VM_B_IP
```

Você deverá receber a página padrão do nginx.

---

# 25. Troubleshooting 2 — falha na porta 80

Delete a regra:

```bash
gcloud compute firewall-rules delete \
  ace-vpc-b-allow-http-from-a \
  --quiet
```

Teste:

```bash
gcloud compute ssh vm-a \
  --zone=$ZONE \
  --command="curl --connect-timeout 5 http://$VM_B_IP"
```

Raciocínio esperado:

```text
Peering        ACTIVE
Route          existente
Destination    existente
Firewall       bloqueando TCP:80
```

---

# 26. Shared VPC — laboratório com Organization

> Esta seção exige uma Google Cloud Organization e pelo menos dois projetos. Contas pessoais sem Organization normalmente não conseguem executar o laboratório completo.

Arquitetura:

```text
Organization
    |
    +--> Host Project
    |      |
    |      v
    |   Shared VPC
    |      |
    |      +--> subnet-app
    |
    +--> Service Project
           |
           v
        VM / GKE / App
        usando subnet
        do Host Project
```

---

# 27. Habilitando um Host Project

```bash
export HOST_PROJECT_ID=SEU_HOST_PROJECT_ID
export SERVICE_PROJECT_ID=SEU_SERVICE_PROJECT_ID
```

```bash
gcloud compute shared-vpc enable \
  $HOST_PROJECT_ID
```

Obtenha a organização:

```bash
gcloud organizations list
```

Depois:

```bash
gcloud compute shared-vpc organizations list-host-projects \
  ORG_ID
```

---

# 28. Associando um Service Project

```bash
gcloud compute shared-vpc associated-projects add \
  $SERVICE_PROJECT_ID \
  --host-project=$HOST_PROJECT_ID
```

Verifique:

```bash
gcloud compute shared-vpc get-host-project \
  $SERVICE_PROJECT_ID
```

---

# 29. IAM no Shared VPC

Padrão conceitual:

```text
Network Admin
     |
     v
Host Project
     |
     +--> VPC
     +--> subnet
     +--> firewall
```

Enquanto:

```text
Application Team
      |
      v
Service Project
      |
      +--> VM
      +--> usa subnet compartilhada
```

Papel importante:

```text
roles/compute.networkUser
```

Para o ACE:

> Shared VPC não elimina IAM. O usuário precisa de permissão para utilizar a subnet compartilhada.

---

# 30. Pegadinha Shared VPC

Vários projetos precisam usar uma rede corporativa central.

Resposta típica:

```text
Shared VPC
```

Não crie uma malha de Peerings quando o requisito real é centralização de rede.

---

# 31. Cloud VPN

Cloud VPN cria túneis criptografados IPsec.

```text
On-Premises
    |
    | Internet
    | IPsec
    v
Cloud VPN
    |
    v
Google Cloud VPC
```

---

# 32. HA VPN

Arquitetura simplificada:

```text
On-Premises
  |       |
  |       |
Tunnel 1 Tunnel 2
  |       |
  v       v
+-----------+
| HA VPN    |
| Gateway   |
+-----------+
      |
      v
    VPC
```

Um HA VPN Gateway possui duas interfaces.

---

# 33. Cloud Router

Cloud Router é utilizado com roteamento dinâmico/BGP.

```text
On-prem Router
      |
      | BGP
      v
Cloud Router
      |
      v
Google VPC
```

> Cloud Router não é um appliance tradicional por onde todos os pacotes passam. Ele gerencia a troca dinâmica de rotas.

---

# 34. BGP

```text
Border Gateway Protocol
```

Exemplo:

```text
On-premises anuncia:
192.168.0.0/16
          |
          v
      Cloud Router

Google anuncia:
10.10.0.0/24
          |
          v
   Router On-premises
```

---

# 35. Laboratório de observação — HA VPN

Crie uma VPC:

```bash
gcloud compute networks create ace-vpn-vpc \
  --subnet-mode=custom
```

Crie subnet:

```bash
gcloud compute networks subnets create ace-vpn-subnet \
  --network=ace-vpn-vpc \
  --region=$REGION \
  --range=10.30.0.0/24
```

Crie HA VPN Gateway:

```bash
gcloud compute vpn-gateways create ace-ha-vpn-gw \
  --network=ace-vpn-vpc \
  --region=$REGION
```

Descreva:

```bash
gcloud compute vpn-gateways describe ace-ha-vpn-gw \
  --region=$REGION
```

Observe as duas interfaces.

---

# 36. Criando um Cloud Router

```bash
gcloud compute routers create ace-vpn-router \
  --network=ace-vpn-vpc \
  --region=$REGION \
  --asn=64514
```

Liste:

```bash
gcloud compute routers list
```

Descreva:

```bash
gcloud compute routers describe ace-vpn-router \
  --region=$REGION
```

Temos:

```text
VPC
 |
 +--> HA VPN Gateway
 |
 +--> Cloud Router
```

Ainda falta o peer.

---

# 37. O que falta para completar uma HA VPN?

```text
Peer VPN Gateway
        |
        v
VPN Tunnel
        |
        v
Cloud Router Interface
        |
        v
BGP Peer
```

Fluxo:

```text
On-prem Router
      |
Peer VPN Gateway
      |
   IPsec Tunnel
      |
HA VPN Gateway
      |
Cloud Router
      |
     VPC
```

Para o ACE, entenda a função de cada componente.

---

# 38. Cloud VPN x VPC Peering

## VPC Peering

```text
VPC A
  |
  v
VPC B
```

## Cloud VPN

```text
On-premises
    |
 Internet + IPsec
    |
Google Cloud
```

---

# 39. Cloud Interconnect

Cloud Interconnect é utilizado para conectividade de alta capacidade e baixa latência entre redes externas e o Google Cloud.

```text
Data Center
     |
     | conexão dedicada
     |
     v
Google Network
     |
     v
Google Cloud VPC
```

Cloud VPN:

```text
VPN
→ IPsec sobre internet
```

Cloud Interconnect:

```text
Interconnect
→ conexão dedicada ou via parceiro
→ caminho não depende da internet pública
```

---

# 40. Dedicated Interconnect

```text
Data Center
    |
    | circuito físico
    v
Google Colocation
    |
    v
Google Network
    |
    v
VPC
```

Indicado quando há requisitos como:

- Alto throughput;
- Grande volume de dados;
- Baixa latência;
- Conectividade privada;
- Infraestrutura compatível com colocation.

---

# 41. Partner Interconnect

```text
Data Center
    |
    v
Service Provider
    |
    v
Google Network
    |
    v
VPC
```

Útil quando:

- A empresa não alcança diretamente uma colocation do Google;
- Prefere contratar conectividade de um parceiro;
- Precisa de capacidades flexíveis.

---

# 42. Dedicated x Partner Interconnect

| Característica | Dedicated | Partner |
|---|---|---|
| Conexão direta ao Google | Sim | Via provedor |
| Colocation compatível | Necessária | Não necessariamente |
| Provedor terceiro | Não para o circuito direto | Sim |
| Cenário | Grandes demandas | Flexibilidade via parceiro |

---

# 43. Cloud VPN x Interconnect

| Característica | Cloud VPN | Cloud Interconnect |
|---|---|---|
| Caminho | Internet pública | Dedicado / parceiro |
| IPsec | Sim | Não por padrão |
| Implantação | Mais simples | Mais complexa |
| Capacidade | Menor | Maior |
| Caso típico | Híbrido rápido | Alta capacidade corporativa |

> Cloud Interconnect não fornece criptografia IPsec por padrão. Quando necessário, arquiteturas podem combinar HA VPN com Cloud Interconnect.

---

# 44. Fluxo de decisão para o ACE

```text
Preciso compartilhar uma VPC entre projetos?
       |
       +--> Shared VPC

Preciso conectar duas VPCs independentes?
       |
       +--> VPC Peering

Preciso conectar on-premises pela internet com criptografia?
       |
       +--> Cloud VPN

Preciso alta capacidade e conectividade dedicada?
       |
       +--> Cloud Interconnect
```

---

# 45. Troubleshooting — camada por camada

```text
Aplicação
   ↓
Porta
   ↓
DNS
   ↓
Firewall
   ↓
Rotas
   ↓
Peering / VPN
   ↓
Subnet / VPC
   ↓
Recurso
```

---

# 46. Diagnóstico 1 — recurso

Perguntas:

- A VM está ligada?
- O IP está correto?
- Está na VPC correta?
- Está na subnet correta?

```bash
gcloud compute instances describe vm-a \
  --zone=$ZONE
```

---

# 47. Diagnóstico 2 — aplicação

```bash
sudo systemctl status nginx
```

```bash
curl localhost
```

```text
Rede funcionando
        ≠
Aplicação funcionando
```

---

# 48. Diagnóstico 3 — porta

```bash
sudo ss -lntp
```

Exemplo:

```text
:80 LISTEN
```

---

# 49. Diagnóstico 4 — firewall

```bash
gcloud compute firewall-rules list
```

Verifique:

- Network;
- Direction;
- Source ranges;
- Target tags;
- Protocol;
- Port.

---

# 50. Diagnóstico 5 — rotas

```bash
gcloud compute routes list
```

Pergunta:

> Existe uma rota para o destino?

---

# 51. Diagnóstico 6 — Peering

```bash
gcloud compute networks peerings list
```

Estado desejado:

```text
ACTIVE
```

---

# 52. Diagnóstico 7 — VPN

```bash
gcloud compute vpn-gateways list
```

```bash
gcloud compute vpn-tunnels list
```

```bash
gcloud compute routers list
```

```bash
gcloud compute routers get-status ace-vpn-router \
  --region=$REGION
```

Em BGP, observe sessões:

```text
UP / DOWN
```

---

# 53. Diagnóstico 8 — DNS

Se isto funciona:

```bash
ping 10.20.0.5
```

mas isto não:

```bash
ping servidor.internal
```

pode ser DNS.

Ferramentas:

```bash
nslookup servidor.internal
```

```bash
dig servidor.internal
```

---

# 54. Exercício prático de troubleshooting

Cenário:

```text
VM A
10.10.0.x
   |
VPC A
   |
Peering
   |
VPC B
   |
VM B
10.20.0.x
```

VM A não consegue acessar:

```text
http://10.20.0.x
```

Investigue na ordem:

```text
1. VM B está RUNNING?
2. nginx está rodando?
3. Porta 80 está ouvindo?
4. Peering está ACTIVE?
5. Existe rota?
6. Firewall permite TCP:80?
7. O IP está correto?
```

---

# 55. Cenários estilo ACE

## Cenário 1

Uma organização possui 20 projetos. A equipe central de redes deve administrar subnets, firewall e conectividade, enquanto as equipes de aplicação criam VMs nos próprios projetos.

**Resposta:** Shared VPC.

## Cenário 2

Duas equipes possuem VPCs independentes em projetos diferentes e precisam comunicação privada.

**Resposta:** VPC Network Peering, quando os requisitos forem compatíveis.

## Cenário 3

A empresa precisa conectar um pequeno escritório ao Google Cloud rapidamente usando internet e criptografia.

**Resposta:** Cloud VPN.

## Cenário 4

Um grande data center transfere grande volume de dados e precisa conectividade dedicada de alta capacidade.

**Resposta:** Cloud Interconnect.

## Cenário 5

A organização quer Interconnect, mas não possui presença em uma instalação de colocation adequada.

**Resposta:** Partner Interconnect.

## Cenário 6

VPC A tem peering com B e B tem peering com C. A aplicação assume que A falará automaticamente com C.

**Resposta:** A premissa está errada. VPC Peering não é transitivo.

## Cenário 7

Peering está `ACTIVE`, as rotas existem, mas TCP 443 não funciona.

**Resposta:** Verifique firewall e disponibilidade do serviço na porta 443.

---

# 56. Pegadinhas ACE

## Pegadinha 1

> Shared VPC e VPC Peering são equivalentes.

**Errado.** Shared VPC compartilha uma rede; Peering conecta redes distintas.

## Pegadinha 2

> Peering automaticamente permite todo tráfego.

**Errado.** Firewall continua sendo aplicado.

## Pegadinha 3

> VPC Peering é transitivo.

**Errado.**

## Pegadinha 4

> Cloud VPN utiliza conexão física dedicada.

**Errado.** VPN utiliza IPsec sobre a internet.

## Pegadinha 5

> Cloud Interconnect é criptografado por padrão.

**Errado.**

## Pegadinha 6

> Cloud Router é um appliance por onde todos os pacotes passam.

**Errado.** Ele gerencia roteamento dinâmico/BGP.

## Pegadinha 7

> Se o ping falha, o problema necessariamente é rota.

**Errado.** Pode ser firewall, aplicação, DNS, peering, VPN ou outro componente.

---

# 57. Questões estilo ACE

## Questão 1

Uma empresa precisa centralizar redes em um projeto e permitir que outros projetos criem VMs nessas subnets.

**Resposta:** Shared VPC.

## Questão 2

Duas VPCs precisam comunicação privada direta, mantendo administração separada.

**Resposta:** VPC Network Peering.

## Questão 3

Qual serviço conecta on-premises ao Google Cloud usando túneis IPsec?

**Resposta:** Cloud VPN.

## Questão 4

Qual componente troca rotas dinamicamente usando BGP?

**Resposta:** Cloud Router.

## Questão 5

A empresa precisa de uma conexão física direta com o Google.

**Resposta:** Dedicated Interconnect.

## Questão 6

A empresa deseja Interconnect por meio de um provedor suportado.

**Resposta:** Partner Interconnect.

## Questão 7

Uma VM não consegue acessar outra. O peering está ativo e há rota para a subnet de destino.

**Resposta:** Verifique firewall e serviço/porta de destino.

---

# 58. Desafio de interpretação

Associe:

```text
A. Shared VPC
B. VPC Peering
C. Cloud VPN
D. Dedicated Interconnect
E. Partner Interconnect
F. Cloud Router
```

a:

```text
1. BGP
2. Compartilhar rede entre projetos
3. IPsec pela internet
4. Conectar VPCs distintas
5. Circuito direto ao Google
6. Conectividade por provedor
```

Resposta:

```text
A -> 2
B -> 4
C -> 3
D -> 5
E -> 6
F -> 1
```

---

# 59. Limpeza — Connectivity Test

```bash
gcloud network-management connectivity-tests delete \
  ace-a-to-b-http \
  --quiet
```

---

# 60. Limpeza — VPN de laboratório

```bash
gcloud compute vpn-gateways delete ace-ha-vpn-gw \
  --region=$REGION \
  --quiet
```

```bash
gcloud compute routers delete ace-vpn-router \
  --region=$REGION \
  --quiet
```

```bash
gcloud compute networks subnets delete ace-vpn-subnet \
  --region=$REGION \
  --quiet
```

```bash
gcloud compute networks delete ace-vpn-vpc \
  --quiet
```

---

# 61. Limpeza — Peering

```bash
gcloud compute networks peerings delete peer-a-to-b \
  --network=ace-vpc-a \
  --quiet
```

```bash
gcloud compute networks peerings delete peer-b-to-a \
  --network=ace-vpc-b \
  --quiet
```

---

# 62. Limpeza — VMs

```bash
gcloud compute instances delete vm-a vm-b \
  --zone=$ZONE \
  --quiet
```

---

# 63. Limpeza — Firewall

```bash
gcloud compute firewall-rules delete \
  ace-vpc-a-allow-ssh \
  ace-vpc-b-allow-ssh \
  ace-vpc-a-allow-icmp-from-b \
  ace-vpc-b-allow-icmp-from-a \
  --quiet
```

Caso a regra HTTP ainda exista:

```bash
gcloud compute firewall-rules delete \
  ace-vpc-b-allow-http-from-a \
  --quiet
```

---

# 64. Limpeza — Subnets

```bash
gcloud compute networks subnets delete subnet-a \
  --region=$REGION \
  --quiet
```

```bash
gcloud compute networks subnets delete subnet-b \
  --region=$REGION \
  --quiet
```

---

# 65. Limpeza — VPCs

```bash
gcloud compute networks delete ace-vpc-a \
  --quiet
```

```bash
gcloud compute networks delete ace-vpc-b \
  --quiet
```

---

# 66. Checklist final

- [ ] Entendo Shared VPC;
- [ ] Sei identificar Host Project;
- [ ] Sei identificar Service Project;
- [ ] Entendo `roles/compute.networkUser`;
- [ ] Sei diferenciar Shared VPC e VPC Peering;
- [ ] Consegui criar duas VPCs;
- [ ] Consegui criar subnets customizadas;
- [ ] Entendo por que CIDRs não devem se sobrepor;
- [ ] Consegui criar duas VMs em redes diferentes;
- [ ] Consegui criar VPC Peering;
- [ ] Entendo que Peering não substitui firewall;
- [ ] Entendo que VPC Peering não é transitivo;
- [ ] Consegui testar comunicação por IP privado;
- [ ] Consegui quebrar a conectividade removendo firewall;
- [ ] Consegui diagnosticar a falha;
- [ ] Conheço Connectivity Tests;
- [ ] Entendo Cloud VPN;
- [ ] Entendo HA VPN;
- [ ] Entendo Cloud Router;
- [ ] Entendo BGP;
- [ ] Sei diferenciar VPN e Interconnect;
- [ ] Sei diferenciar Dedicated e Partner Interconnect;
- [ ] Sei a ordem básica de troubleshooting;
- [ ] Consegui remover os recursos do laboratório.

---

# 67. O que você deve memorizar para o ACE

## Shared VPC

```text
Organization
   |
Host Project
   |
Shared VPC
   |
Service Projects
```

Use quando:

```text
vários projetos
      +
rede centralizada
```

## VPC Peering

```text
VPC A
  |
Peering
  |
VPC B
```

Lembre:

```text
redes distintas
+
IP privado
+
não transitivo
+
firewall continua valendo
```

## Cloud VPN

```text
On-premises
     |
IPsec / Internet
     |
Google Cloud
```

## HA VPN

```text
2 interfaces
+
redundância
+
Cloud Router/BGP
```

## Cloud Interconnect

```text
On-premises
      |
conectividade dedicada
      |
Google Network
      |
VPC
```

## Dedicated Interconnect

```text
conexão direta ao Google
```

## Partner Interconnect

```text
conexão via provedor
```

## Troubleshooting

Memorize:

```text
Recurso
  ↓
IP
  ↓
Aplicação / Porta
  ↓
Firewall
  ↓
Rotas
  ↓
Peering / VPN
  ↓
DNS
```

Se você consegue explicar **por que Shared VPC, Peering, VPN e Interconnect resolvem problemas diferentes** e consegue investigar uma falha de conectividade seguindo uma sequência lógica, já domina o núcleo desta aula para o nível Associate Cloud Engineer.
