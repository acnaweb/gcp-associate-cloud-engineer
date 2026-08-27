# Aula 3 — Cloud NAT, Private Google Access e Cloud DNS

## Objetivos

Ao final desta aula, você deverá ser capaz de:

- Entender por que uma VM privada pode precisar de saída para a internet;
- Entender o papel do **Cloud NAT**;
- Entender por que Cloud NAT não é um proxy nem um firewall;
- Criar uma VPC e subnet customizadas;
- Criar uma VM **sem IP externo**;
- Criar um **Cloud Router**;
- Criar e testar um **Public NAT**;
- Entender o papel do **Private Google Access**;
- Diferenciar acesso à internet de acesso às APIs e serviços do Google;
- Habilitar e desabilitar Private Google Access;
- Entender o papel do **Cloud DNS**;
- Criar uma **Private DNS Zone**;
- Criar registros DNS privados;
- Resolver nomes internos dentro de uma VPC;
- Simular falhas de NAT, Private Google Access e DNS;
- Executar troubleshooting com `gcloud`, `curl`, `dig`, `nslookup` e inspeção de rotas;
- Relacionar os conceitos com questões da certificação Associate Cloud Engineer.

---

# 1. O problema que esta aula resolve

Considere uma VM sem endereço IP público:

```text
Internet
   X
   |
+----------------+
| VM privada     |
| 10.10.0.2      |
| sem IP externo |
+----------------+
```

Ela pode participar normalmente da VPC, mas não possui um endereço externo próprio para iniciar conexões com a internet.

Em ambientes corporativos, isso é bastante comum:

```text
VM privada
    |
    +--> baixar pacotes
    +--> acessar repositórios
    +--> chamar APIs externas
    +--> acessar APIs Google
```

Mas precisamos resolver esses cenários sem necessariamente atribuir um IP externo para cada VM.

É aqui que entram:

```text
Cloud NAT
Private Google Access
Cloud DNS
```

---

# 2. Visão geral

```text
                          VPC
                           |
              +------------+------------+
              |                         |
              v                         v
         VM privada                 Cloud DNS
         10.10.0.2                private zone
              |
              |
      +-------+-------+
      |               |
      v               v
 Cloud NAT      Private Google Access
      |               |
      v               v
  Internet        Google APIs
```

Simplificação útil para o ACE:

```text
Cloud NAT
→ saída para internet sem IP externo na VM

Private Google Access
→ acesso a APIs e serviços Google por VMs sem IP externo

Cloud DNS
→ resolução de nomes DNS gerenciada
```

---

# 3. Cloud NAT

## Conceito

Cloud NAT permite que recursos que não possuem IP externo iniciem conexões de saída.

Arquitetura:

```text
VM privada
10.10.0.2
    |
    v
Cloud NAT
    |
    v
Internet
```

A resposta retorna pela mesma tradução NAT.

---

# 4. O que Cloud NAT não faz

Cloud NAT não é:

```text
Load Balancer
Firewall
Proxy HTTP
VPN
```

Ele também não permite, por si só, que clientes da internet iniciem conexões com a VM privada.

```text
Internet
   |
   X  conexão iniciada de fora
   |
VM privada
```

O objetivo principal do Public NAT neste laboratório é:

> permitir conexões de saída iniciadas por recursos privados.

---

# 5. Private Google Access

Por padrão, uma VM sem IP externo possui acesso limitado a destinos internos.

Ao habilitar **Private Google Access** na subnet, VMs sem IP externo podem acessar os endereços utilizados por APIs e serviços Google elegíveis.

Arquitetura conceitual:

```text
VM sem IP externo
       |
       v
Private Google Access
       |
       v
Google APIs e Services
```

Exemplos de serviços:

```text
Cloud Storage API
BigQuery API
Artifact Registry
Google APIs
```

> Private Google Access é habilitado na **subnet**, não individualmente na VM.

---

# 6. Cloud NAT x Private Google Access

Essa diferença é essencial para o ACE.

## Cloud NAT

```text
VM privada
    |
    v
Internet
```

Permite saída para destinos externos em geral.

---

## Private Google Access

```text
VM privada
    |
    v
Google APIs
```

Permite acesso a APIs e serviços Google elegíveis mesmo sem IP externo.

---

## Comparação

| Recurso | Cloud NAT | Private Google Access |
|---|---|---|
| Acesso à internet em geral | Sim | Não |
| Acesso a APIs Google sem IP externo | Pode permitir | Sim, propósito específico |
| Configuração | Cloud Router/NAT | Subnet |
| Dá IP externo à VM | Não | Não |
| Entrada da internet para VM | Não | Não |

---

# 7. Cloud DNS

Cloud DNS é o serviço DNS gerenciado do Google Cloud.

Pode trabalhar com zonas:

```text
Public
Private
```

Neste laboratório usaremos uma **Private Zone**.

Arquitetura:

```text
ace.internal
      |
      +--> vm-app.ace.internal -> 10.10.0.2
      |
      +--> vm-db.ace.internal  -> 10.10.0.3
```

A zona será visível somente para a VPC autorizada.

---

# 8. Laboratório — visão geral

Vamos construir:

```text
1. VPC customizada
2. Subnet privada
3. VM sem IP externo
4. Cloud Router
5. Cloud NAT
6. Teste de saída para internet
7. Private Google Access
8. Teste de API Google
9. Segunda VM privada
10. Cloud DNS Private Zone
11. Registros A privados
12. Resolução por nome
13. Falha proposital de NAT
14. Falha proposital de PGA
15. Falha proposital de DNS
16. Troubleshooting
17. Cleanup
```

---

# 9. Pré-requisitos

Abra o Cloud Shell.

Confira o projeto:

```bash
gcloud config get-value project
```

Defina variáveis:

```bash
export PROJECT_ID=$(gcloud config get-value project)
export REGION=us-central1
export ZONE=us-central1-a

export NETWORK=ace-private-vpc
export SUBNET=ace-private-subnet
export ROUTER=ace-nat-router
export NAT=ace-public-nat
export DNS_ZONE=ace-private-zone
```

Veja:

```bash
echo $PROJECT_ID
echo $REGION
echo $ZONE
```

Habilite as APIs:

```bash
gcloud services enable \
  compute.googleapis.com \
  dns.googleapis.com \
  storage.googleapis.com
```

---

# 10. Criando a VPC

Crie uma VPC customizada:

```bash
gcloud compute networks create $NETWORK \
  --subnet-mode=custom
```

Verifique:

```bash
gcloud compute networks describe $NETWORK
```

---

# 11. Criando a subnet

Crie:

```bash
gcloud compute networks subnets create $SUBNET \
  --network=$NETWORK \
  --region=$REGION \
  --range=10.10.0.0/24
```

Observe que **ainda não habilitamos Private Google Access**.

Verifique:

```bash
gcloud compute networks subnets describe $SUBNET \
  --region=$REGION
```

---

# 12. Criando regra de firewall para SSH via IAP

Vamos usar IAP para acessar VMs sem IP externo.

Crie:

```bash
gcloud compute firewall-rules create ace-allow-iap-ssh \
  --network=$NETWORK \
  --direction=INGRESS \
  --action=ALLOW \
  --rules=tcp:22 \
  --source-ranges=35.235.240.0/20 \
  --target-tags=iap-ssh
```

Isso permite SSH originado da faixa usada pelo IAP TCP forwarding.

---

# 13. Criando uma VM sem IP externo

Crie:

```bash
gcloud compute instances create vm-private \
  --zone=$ZONE \
  --machine-type=e2-micro \
  --subnet=$SUBNET \
  --no-address \
  --tags=iap-ssh \
  --image-family=debian-12 \
  --image-project=debian-cloud
```

Liste:

```bash
gcloud compute instances list
```

Observe:

```text
INTERNAL_IP     EXTERNAL_IP
10.10.0.x       -
```

Essa VM não possui IP externo.

---

# 14. Acessando a VM pelo IAP

Execute:

```bash
gcloud compute ssh vm-private \
  --zone=$ZONE \
  --tunnel-through-iap
```

Dentro da VM, veja os endereços:

```bash
ip addr
```

Teste internet:

```bash
curl --connect-timeout 5 https://example.com
```

O esperado neste momento é falhar, pois:

```text
VM sem IP externo
      |
      X
   Internet
```

Saia:

```bash
exit
```

---

# 15. Criando o Cloud Router

Cloud NAT é configurado associado a um Cloud Router.

Crie:

```bash
gcloud compute routers create $ROUTER \
  --network=$NETWORK \
  --region=$REGION
```

Liste:

```bash
gcloud compute routers list
```

> Neste cenário, o Cloud Router é usado como recurso de controle para a configuração do NAT. Ele não significa que o tráfego da VM passa por uma VM roteadora criada por você.

---

# 16. Criando o Public NAT

Crie:

```bash
gcloud compute routers nats create $NAT \
  --router=$ROUTER \
  --region=$REGION \
  --nat-all-subnet-ip-ranges \
  --auto-allocate-nat-external-ips
```

Esse comando configura NAT para todas as faixas IPv4 das subnets elegíveis na região e faz o Google Cloud alocar automaticamente os IPs externos usados pelo NAT.

Verifique:

```bash
gcloud compute routers nats describe $NAT \
  --router=$ROUTER \
  --region=$REGION
```

---

# 17. Arquitetura atual

```text
VM privada
10.10.0.x
sem IP externo
     |
     v
 ace-private-subnet
     |
     v
 Cloud NAT
     |
     v
IP externo do NAT
     |
     v
 Internet
```

A VM continua sem IP externo próprio.

---

# 18. Testando internet após Cloud NAT

Entre novamente:

```bash
gcloud compute ssh vm-private \
  --zone=$ZONE \
  --tunnel-through-iap
```

Teste:

```bash
curl https://example.com
```

Agora deve funcionar.

Teste o IP de saída:

```bash
curl https://ifconfig.me
```

Esse endereço é o IP utilizado na tradução NAT, e não um IP externo associado à interface da VM.

Confirme que a VM continua sem IP externo:

```bash
exit
```

```bash
gcloud compute instances describe vm-private \
  --zone=$ZONE \
  --format="get(networkInterfaces[0].accessConfigs)"
```

O resultado deve estar vazio.

---

# 19. Cloud NAT e segurança

Importante:

```text
VM sem IP externo
      |
      v
Cloud NAT
      |
      v
Internet
```

Isso permite **saída**.

Não significa:

```text
Internet
   |
   v
VM privada
```

Cloud NAT não cria uma entrada pública para a VM.

---

# 20. Habilitando logs do NAT

Atualize:

```bash
gcloud compute routers nats update $NAT \
  --router=$ROUTER \
  --region=$REGION \
  --enable-logging \
  --log-filter=ALL
```

Isso permite observar traduções e erros do NAT no Cloud Logging.

Para ACE, lembre que logs podem ajudar no troubleshooting.

---

# 21. Private Google Access — observando o estado atual

Veja:

```bash
gcloud compute networks subnets describe $SUBNET \
  --region=$REGION \
  --format="get(privateIpGoogleAccess)"
```

O esperado é:

```text
False
```

ou valor equivalente indicando que está desabilitado.

---

# 22. Habilitando Private Google Access

Execute:

```bash
gcloud compute networks subnets update $SUBNET \
  --region=$REGION \
  --enable-private-ip-google-access
```

Verifique:

```bash
gcloud compute networks subnets describe $SUBNET \
  --region=$REGION \
  --format="get(privateIpGoogleAccess)"
```

Agora:

```text
True
```

Importante:

> Private Google Access é uma propriedade da subnet.

---

# 23. Como demonstrar Private Google Access de verdade

Se Cloud NAT permanecer ativo, a VM já tem saída geral e fica difícil visualizar o papel específico de Private Google Access.

Então vamos temporariamente remover o NAT.

Delete:

```bash
gcloud compute routers nats delete $NAT \
  --router=$ROUTER \
  --region=$REGION \
  --quiet
```

Agora a arquitetura fica:

```text
                 Internet
                    X
                    |
VM privada ----------
    |
    |
    +--> Private Google Access
             |
             v
         Google APIs
```

---

# 24. Teste: internet geral sem NAT

Entre:

```bash
gcloud compute ssh vm-private \
  --zone=$ZONE \
  --tunnel-through-iap
```

Teste:

```bash
curl --connect-timeout 5 https://example.com
```

A tendência é falhar porque removemos a saída geral via NAT.

Agora teste uma API Google:

```bash
curl -I https://storage.googleapis.com
```

O importante não é receber HTTP 200; respostas como `400`, `403` ou outra resposta HTTP comprovam que a VM conseguiu chegar ao endpoint.

Podemos também testar resolução:

```bash
getent hosts storage.googleapis.com
```

Saia:

```bash
exit
```

---

# 25. O que o experimento demonstrou?

```text
example.com
    |
    X
sem NAT
```

mas:

```text
storage.googleapis.com
         |
         v
Private Google Access
         |
         v
Google APIs
```

Essa diferença é uma excelente questão de ACE.

---

# 26. Falha proposital — desabilitando Private Google Access

Execute:

```bash
gcloud compute networks subnets update $SUBNET \
  --region=$REGION \
  --no-enable-private-ip-google-access
```

Verifique:

```bash
gcloud compute networks subnets describe $SUBNET \
  --region=$REGION \
  --format="get(privateIpGoogleAccess)"
```

Agora teste novamente a partir da VM:

```bash
gcloud compute ssh vm-private \
  --zone=$ZONE \
  --tunnel-through-iap \
  --command="curl -I --connect-timeout 5 https://storage.googleapis.com"
```

A conectividade deve deixar de funcionar nesse cenário sem NAT.

Temos agora:

```text
NAT                    ausente
Private Google Access  desabilitado
VM external IP         ausente
```

Portanto não existe caminho de saída apropriado.

---

# 27. Reabilitando Private Google Access

Execute:

```bash
gcloud compute networks subnets update $SUBNET \
  --region=$REGION \
  --enable-private-ip-google-access
```

---

# 28. Recriando Cloud NAT

Para as próximas etapas, recrie:

```bash
gcloud compute routers nats create $NAT \
  --router=$ROUTER \
  --region=$REGION \
  --nat-all-subnet-ip-ranges \
  --auto-allocate-nat-external-ips
```

---

# 29. Cloud DNS — criando uma segunda VM

Crie:

```bash
gcloud compute instances create vm-db \
  --zone=$ZONE \
  --machine-type=e2-micro \
  --subnet=$SUBNET \
  --no-address \
  --tags=iap-ssh \
  --image-family=debian-12 \
  --image-project=debian-cloud
```

Liste:

```bash
gcloud compute instances list
```

Capture os IPs privados:

```bash
export VM_APP_IP=$(gcloud compute instances describe vm-private \
  --zone=$ZONE \
  --format="value(networkInterfaces[0].networkIP)")

export VM_DB_IP=$(gcloud compute instances describe vm-db \
  --zone=$ZONE \
  --format="value(networkInterfaces[0].networkIP)")
```

Veja:

```bash
echo $VM_APP_IP
echo $VM_DB_IP
```

---

# 30. Criando uma Cloud DNS Private Zone

Vamos criar a zona:

```text
ace.internal.
```

Execute:

```bash
gcloud dns managed-zones create $DNS_ZONE \
  --dns-name=ace.internal. \
  --description="ACE private DNS zone" \
  --visibility=private \
  --networks=$NETWORK
```

Liste:

```bash
gcloud dns managed-zones list
```

Descreva:

```bash
gcloud dns managed-zones describe $DNS_ZONE
```

Conceito:

```text
ace.internal
     |
     v
Private Zone
     |
     v
ace-private-vpc
```

Somente redes autorizadas podem consultar essa zona privada.

---

# 31. Criando registros DNS privados

Vamos criar:

```text
app.ace.internal -> IP da vm-private
db.ace.internal  -> IP da vm-db
```

Inicie uma transação:

```bash
gcloud dns record-sets transaction start \
  --zone=$DNS_ZONE
```

Adicione o registro da aplicação:

```bash
gcloud dns record-sets transaction add $VM_APP_IP \
  --name=app.ace.internal. \
  --ttl=300 \
  --type=A \
  --zone=$DNS_ZONE
```

Adicione o banco:

```bash
gcloud dns record-sets transaction add $VM_DB_IP \
  --name=db.ace.internal. \
  --ttl=300 \
  --type=A \
  --zone=$DNS_ZONE
```

Execute a transação:

```bash
gcloud dns record-sets transaction execute \
  --zone=$DNS_ZONE
```

Liste:

```bash
gcloud dns record-sets list \
  --zone=$DNS_ZONE
```

---

# 32. Testando resolução DNS

Entre na VM privada:

```bash
gcloud compute ssh vm-private \
  --zone=$ZONE \
  --tunnel-through-iap
```

Teste:

```bash
getent hosts db.ace.internal
```

ou:

```bash
nslookup db.ace.internal
```

Se `dig` estiver disponível:

```bash
dig db.ace.internal
```

O resultado deverá apontar para o IP privado da `vm-db`.

Teste também:

```bash
getent hosts app.ace.internal
```

Saia:

```bash
exit
```

---

# 33. DNS não é conectividade

Esse conceito é muito importante.

Ter:

```text
db.ace.internal -> 10.10.0.x
```

significa apenas que o nome foi resolvido.

Não significa necessariamente que:

```text
TCP:5432 funciona
HTTP funciona
ICMP funciona
```

DNS responde:

> Qual IP corresponde ao nome?

Firewall e aplicação respondem:

> É possível usar determinado protocolo/porta nesse IP?

---

# 34. Criando regra ICMP interna para teste

Crie:

```bash
gcloud compute firewall-rules create ace-allow-internal-icmp \
  --network=$NETWORK \
  --allow=icmp \
  --source-ranges=10.10.0.0/24
```

Agora:

```bash
gcloud compute ssh vm-private \
  --zone=$ZONE \
  --tunnel-through-iap \
  --command="ping -c 4 db.ace.internal"
```

Temos:

```text
DNS
 |
 v
db.ace.internal
 |
 v
10.10.0.x
 |
 v
Firewall ICMP
 |
 v
vm-db
```

---

# 35. Falha proposital — DNS incorreto

Vamos alterar o registro do banco para um IP incorreto.

Primeiro descubra o registro atual:

```bash
gcloud dns record-sets list \
  --zone=$DNS_ZONE \
  --name=db.ace.internal. \
  --type=A
```

Inicie transação:

```bash
gcloud dns record-sets transaction start \
  --zone=$DNS_ZONE
```

Remova o registro correto:

```bash
gcloud dns record-sets transaction remove $VM_DB_IP \
  --name=db.ace.internal. \
  --ttl=300 \
  --type=A \
  --zone=$DNS_ZONE
```

Adicione um IP incorreto:

```bash
gcloud dns record-sets transaction add 10.10.0.250 \
  --name=db.ace.internal. \
  --ttl=300 \
  --type=A \
  --zone=$DNS_ZONE
```

Execute:

```bash
gcloud dns record-sets transaction execute \
  --zone=$DNS_ZONE
```

Teste:

```bash
gcloud compute ssh vm-private \
  --zone=$ZONE \
  --tunnel-through-iap \
  --command="getent hosts db.ace.internal"
```

O DNS funciona.

Mas retorna o destino errado.

Esse é um caso interessante:

```text
DNS operacional
     |
     v
registro incorreto
     |
     v
aplicação falha
```

---

# 36. Corrigindo o DNS

Inicie:

```bash
gcloud dns record-sets transaction start \
  --zone=$DNS_ZONE
```

Remova:

```bash
gcloud dns record-sets transaction remove 10.10.0.250 \
  --name=db.ace.internal. \
  --ttl=300 \
  --type=A \
  --zone=$DNS_ZONE
```

Adicione novamente:

```bash
gcloud dns record-sets transaction add $VM_DB_IP \
  --name=db.ace.internal. \
  --ttl=300 \
  --type=A \
  --zone=$DNS_ZONE
```

Execute:

```bash
gcloud dns record-sets transaction execute \
  --zone=$DNS_ZONE
```

---

# 37. Arquitetura final do laboratório

```text
                         Internet
                            |
                            v
                      +-----------+
                      | Cloud NAT |
                      +-----------+
                            |
                            |
                     +-------------+
                     | Cloud Router|
                     +-------------+
                            |
                            v
+------------------------------------------------------+
|                    ace-private-vpc                   |
|                                                      |
|  +------------------------------------------------+  |
|  |          ace-private-subnet 10.10.0.0/24       |  |
|  |                                                |  |
|  |   +----------------+     +----------------+    |  |
|  |   | vm-private     |     | vm-db          |    |  |
|  |   | sem IP externo|     | sem IP externo|    |  |
|  |   +----------------+     +----------------+    |  |
|  |                                                |  |
|  |      Private Google Access = ENABLED           |  |
|  +------------------------------------------------+  |
|                                                      |
|       Cloud DNS Private Zone: ace.internal           |
|                                                      |
|       app.ace.internal -> vm-private                  |
|       db.ace.internal  -> vm-db                       |
+------------------------------------------------------+
                  |
                  v
             Google APIs
```

---

# 38. Como pensar em cada componente

## Cloud NAT

Pergunta:

> A VM privada precisa iniciar conexão com a internet?

```text
Sim -> Cloud NAT pode ser a solução
```

---

## Private Google Access

Pergunta:

> A VM sem IP externo precisa acessar APIs Google?

```text
Sim -> habilitar Private Google Access na subnet
```

---

## Cloud DNS

Pergunta:

> Quero resolver nomes de forma gerenciada?

```text
Sim -> Cloud DNS
```

Se somente recursos internos devem resolver:

```text
Private Zone
```

---

# 39. Troubleshooting — VM privada não acessa internet

Use esta sequência:

```text
1. VM tem IP externo?
       |
       +--> não
       |
2. Existe Cloud NAT?
       |
3. NAT cobre a subnet?
       |
4. Cloud Router está na região correta?
       |
5. Existe rota default?
       |
6. Firewall e políticas permitem saída?
```

Comandos:

```bash
gcloud compute instances describe vm-private \
  --zone=$ZONE
```

```bash
gcloud compute routers list
```

```bash
gcloud compute routers nats list \
  --router=$ROUTER \
  --region=$REGION
```

```bash
gcloud compute routes list \
  --filter="network:$NETWORK"
```

---

# 40. Troubleshooting — Google API não funciona

Pergunte:

```text
VM possui IP externo?
     |
     +--> não
     |
Private Google Access está habilitado?
     |
     v
DNS resolve googleapis.com?
     |
     v
Firewall/políticas permitem saída?
```

Veja:

```bash
gcloud compute networks subnets describe $SUBNET \
  --region=$REGION \
  --format="get(privateIpGoogleAccess)"
```

---

# 41. Troubleshooting — nome não resolve

Pergunte:

```text
1. A zona existe?
2. É pública ou privada?
3. A VPC está associada à private zone?
4. O registro existe?
5. O FQDN está correto?
6. O TTL pode estar mantendo cache?
```

Comandos:

```bash
gcloud dns managed-zones list
```

```bash
gcloud dns managed-zones describe $DNS_ZONE
```

```bash
gcloud dns record-sets list \
  --zone=$DNS_ZONE
```

---

# 42. Cloud NAT x Load Balancer

Não confunda.

## Cloud NAT

```text
VM
 |
 | saída
 v
Internet
```

## Load Balancer

```text
Internet
   |
   | entrada
   v
Load Balancer
   |
   v
Backends
```

Um resolve principalmente **egress**.

O outro recebe e distribui **ingress**.

---

# 43. Cloud NAT x External IP

Duas opções para saída:

## IP externo individual

```text
VM 1 -> IP público 1
VM 2 -> IP público 2
VM 3 -> IP público 3
```

## Cloud NAT

```text
VM 1 --\
VM 2 ----> Cloud NAT -> Internet
VM 3 --/
```

Cloud NAT permite manter as interfaces das VMs sem endereços externos.

---

# 44. Private DNS x Public DNS

## Public Zone

```text
Internet
   |
   v
api.example.com
```

Registros públicos podem ser resolvidos externamente conforme a delegação DNS.

---

## Private Zone

```text
VPC autorizada
     |
     v
db.ace.internal
```

Somente redes autorizadas possuem visibilidade da zona privada.

---

# 45. Pegadinhas ACE

## Pegadinha 1

> Cloud NAT atribui um IP público à VM.

**Errado.**

A VM continua sem external IP.

---

## Pegadinha 2

> Cloud NAT permite conexão iniciada da internet para a VM privada.

**Errado.**

Public NAT é usado para conexões de saída iniciadas pelos recursos elegíveis.

---

## Pegadinha 3

> Private Google Access é habilitado na VM.

**Errado.**

É configurado na subnet.

---

## Pegadinha 4

> Private Google Access substitui Cloud NAT para acesso a qualquer site da internet.

**Errado.**

Seu foco são APIs e serviços Google elegíveis.

---

## Pegadinha 5

> Cloud Router no Cloud NAT significa que o tráfego passa por uma VM roteadora.

**Errado.**

Cloud Router é um recurso gerenciado de controle de rede; não é uma VM appliance criada pelo usuário.

---

## Pegadinha 6

> Se DNS resolve, a aplicação necessariamente funciona.

**Errado.**

Ainda podem existir problemas de firewall, rota, porta ou aplicação.

---

## Pegadinha 7

> Private DNS Zone pode ser consultada por qualquer dispositivo na internet.

**Errado.**

A visibilidade é restrita às redes autorizadas.

---

# 46. Questões estilo ACE

## Questão 1

Uma VM não possui IP externo, mas precisa baixar atualizações de um repositório público na internet.

Qual solução é apropriada?

**Resposta:** Cloud NAT.

---

## Questão 2

Uma VM sem IP externo precisa acessar APIs do Cloud Storage.

Qual configuração deve ser considerada na subnet?

**Resposta:** Private Google Access.

---

## Questão 3

Uma empresa deseja resolver `database.corp.internal` apenas dentro de determinada VPC.

Qual recurso?

**Resposta:** Cloud DNS Private Zone.

---

## Questão 4

Uma VM usa Cloud NAT. Qual afirmação é correta?

**Resposta:** A VM pode iniciar conexões de saída sem possuir IP externo próprio.

---

## Questão 5

Uma VM sem IP externo consegue acessar uma API Google, mas não consegue acessar `example.com`. Cloud NAT não está configurado.

Qual recurso provavelmente permite o acesso à API Google?

**Resposta:** Private Google Access.

---

## Questão 6

`db.ace.internal` resolve para o IP esperado, mas a conexão TCP 5432 falha.

Qual afirmação é correta?

**Resposta:** DNS está funcionando; deve-se investigar firewall, porta, aplicação e rota.

---

# 47. Exercício de interpretação

Associe:

```text
A. Cloud NAT
B. Private Google Access
C. Cloud DNS Private Zone
D. Cloud Router
```

com:

```text
1. Resolução DNS visível apenas para redes autorizadas
2. Acesso de VM privada a APIs Google
3. Recurso necessário para configurar Public NAT
4. Saída para internet de recursos sem IP externo
```

Resposta:

```text
A -> 4
B -> 2
C -> 1
D -> 3
```

---

# 48. Desafio prático

Sem consultar os passos anteriores, faça:

1. Verifique se `vm-private` possui IP externo;
2. Identifique a subnet da VM;
3. Verifique se Private Google Access está habilitado;
4. Liste o Cloud Router;
5. Liste a configuração NAT;
6. Identifique quais subnets utilizam NAT;
7. Liste todas as DNS zones;
8. Liste os registros da zona `ace.internal`;
9. Resolva `db.ace.internal` de dentro da VM;
10. Explique por que a VM consegue sair para internet sem external IP.

---

# 49. Comandos para revisão

## VPC

```bash
gcloud compute networks list
```

## Subnets

```bash
gcloud compute networks subnets list
```

## Private Google Access

```bash
gcloud compute networks subnets describe $SUBNET \
  --region=$REGION \
  --format="get(privateIpGoogleAccess)"
```

## Cloud Router

```bash
gcloud compute routers list
```

## Cloud NAT

```bash
gcloud compute routers nats list \
  --router=$ROUTER \
  --region=$REGION
```

## Cloud DNS

```bash
gcloud dns managed-zones list
```

```bash
gcloud dns record-sets list \
  --zone=$DNS_ZONE
```

---

# 50. Limpeza — registros DNS

Delete a zona diretamente depois de remover seus registros customizados, se necessário.

Inicie:

```bash
gcloud dns record-sets transaction start \
  --zone=$DNS_ZONE
```

Remova `app`:

```bash
gcloud dns record-sets transaction remove $VM_APP_IP \
  --name=app.ace.internal. \
  --ttl=300 \
  --type=A \
  --zone=$DNS_ZONE
```

Remova `db`:

```bash
gcloud dns record-sets transaction remove $VM_DB_IP \
  --name=db.ace.internal. \
  --ttl=300 \
  --type=A \
  --zone=$DNS_ZONE
```

Execute:

```bash
gcloud dns record-sets transaction execute \
  --zone=$DNS_ZONE
```

---

# 51. Limpeza — Cloud DNS

```bash
gcloud dns managed-zones delete $DNS_ZONE \
  --quiet
```

---

# 52. Limpeza — VMs

```bash
gcloud compute instances delete vm-private vm-db \
  --zone=$ZONE \
  --quiet
```

---

# 53. Limpeza — Cloud NAT

```bash
gcloud compute routers nats delete $NAT \
  --router=$ROUTER \
  --region=$REGION \
  --quiet
```

Caso ele já tenha sido excluído durante algum teste, apenas prossiga.

---

# 54. Limpeza — Cloud Router

```bash
gcloud compute routers delete $ROUTER \
  --region=$REGION \
  --quiet
```

---

# 55. Limpeza — Firewall

```bash
gcloud compute firewall-rules delete \
  ace-allow-iap-ssh \
  ace-allow-internal-icmp \
  --quiet
```

---

# 56. Limpeza — Subnet

```bash
gcloud compute networks subnets delete $SUBNET \
  --region=$REGION \
  --quiet
```

---

# 57. Limpeza — VPC

```bash
gcloud compute networks delete $NETWORK \
  --quiet
```

---

# 58. Checklist final

- [ ] Entendo por que VMs privadas podem precisar de Cloud NAT;
- [ ] Sei criar uma VM sem IP externo;
- [ ] Sei acessar uma VM privada usando IAP;
- [ ] Sei criar um Cloud Router;
- [ ] Sei criar Public NAT;
- [ ] Entendo que Cloud NAT não atribui IP externo à VM;
- [ ] Entendo que Cloud NAT é voltado a conexões de saída;
- [ ] Consegui acessar a internet usando Cloud NAT;
- [ ] Sei onde Private Google Access é configurado;
- [ ] Sei diferenciar Cloud NAT e Private Google Access;
- [ ] Consegui testar uma API Google sem NAT e com PGA habilitado;
- [ ] Entendo Cloud DNS;
- [ ] Sei diferenciar public zone e private zone;
- [ ] Consegui criar uma Private DNS Zone;
- [ ] Consegui criar registros A;
- [ ] Consegui resolver `db.ace.internal`;
- [ ] Entendo que DNS não substitui conectividade;
- [ ] Consegui simular falha de NAT;
- [ ] Consegui simular falha de Private Google Access;
- [ ] Consegui simular registro DNS incorreto;
- [ ] Consegui remover os recursos.

---

# 59. O que você deve memorizar para o ACE

## Cloud NAT

```text
VM sem external IP
       |
       v
Cloud NAT
       |
       v
Internet
```

Memorize:

```text
saída
sem IP externo por VM
Cloud Router + NAT configuration
```

---

## Private Google Access

```text
VM sem IP externo
       |
       v
Subnet com PGA
       |
       v
Google APIs
```

Memorize:

```text
configurado na subnet
focado em APIs/serviços Google elegíveis
não é internet genérica
```

---

## Cloud DNS

```text
nome
 |
 v
DNS record
 |
 v
IP
```

Private Zone:

```text
visibilidade restrita às VPCs autorizadas
```

---

# 60. Fluxo mental para questões ACE

Quando aparecer um cenário, pergunte:

```text
VM não tem IP externo e precisa internet?
        |
        +--> Cloud NAT

VM não tem IP externo e precisa Google APIs?
        |
        +--> Private Google Access

Precisa resolver nomes públicos?
        |
        +--> Cloud DNS Public Zone

Precisa resolver nomes apenas internamente?
        |
        +--> Cloud DNS Private Zone
```

Se você consegue explicar por que **Cloud NAT, Private Google Access e Cloud DNS resolvem problemas diferentes**, e consegue provar isso em uma VM sem IP externo, já domina o núcleo desta aula para o nível Associate Cloud Engineer.
