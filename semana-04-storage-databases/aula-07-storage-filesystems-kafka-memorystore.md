# Aula 7 — Filestore, NetApp Volumes, Managed Lustre, Managed Kafka e Memorystore

## Objetivos

Ao final, você deverá:

- diferenciar block, object e file storage;
- explicar a arquitetura do Filestore e seu uso com NFS;
- criar e inspecionar uma instância Filestore quando houver quota disponível;
- montar um file share Filestore em uma VM;
- escrever e ler dados pelo filesystem compartilhado;
- provocar e diagnosticar uma falha simples de montagem NFS;
- diferenciar Cloud Storage, Filestore, NetApp Volumes e Managed Lustre;
- reconhecer workloads adequados para Enterprise NAS;
- reconhecer workloads HPC/AI adequados para Managed Lustre;
- diferenciar Pub/Sub e Managed Service for Apache Kafka;
- reconhecer quando compatibilidade com Kafka é requisito determinante;
- explicar o papel do Memorystore como serviço in-memory;
- diferenciar cache de sistema persistente de registro;
- escolher o serviço apropriado a partir de cenários;
- executar o cleanup dos recursos faturáveis do laboratório.

> **Custos e quota:** Filestore e a VM cliente geram cobrança. Além disso, a quota de algumas classes Filestore pode iniciar em `0` no projeto/região. Se não houver quota, não tente contornar o limite criando recursos maiores ou mais caros: execute a parte de inspeção e arquitetura e classifique a criação/mount como `P*`. NetApp Volumes, Managed Lustre, Managed Kafka e Memorystore não serão provisionados no fluxo principal para evitar custo e requisitos adicionais desnecessários ao objetivo ACE.

---

# 1. Três famílias de serviços

Esta aula agrupa os produtos pelo problema que resolvem.

```text
Aula 7
├── File Storage
│   ├── Filestore
│   ├── NetApp Volumes
│   └── Managed Lustre
├── Event Streaming
│   ├── Pub/Sub
│   └── Managed Service for Apache Kafka
└── In-memory
    └── Memorystore
```

O objetivo não é decorar nomes.

Pergunte:

```text
qual é o modelo de acesso?
qual protocolo/ecossistema é requisito?
qual workload precisa ser atendido?
qual nível de performance é necessário?
os dados são persistentes ou cache?
```

---

# 2. Block × Object × File

## 2.1 Block storage

Modelo:

```text
VM
↓
dispositivo de bloco
↓
filesystem criado pelo sistema operacional
```

Exemplos no Google Cloud:

```text
Persistent Disk
Hyperdisk
```

## 2.2 Object storage

Modelo:

```text
aplicação
↓
API
↓
bucket
↓
objects
```

Exemplo:

```text
Cloud Storage
```

## 2.3 File storage

Modelo:

```text
cliente
↓
protocolo de arquivo
↓
filesystem compartilhado
```

Nesta aula:

```text
Filestore
NetApp Volumes
Managed Lustre
```

Resumo:

| Modelo | Unidade mental | Exemplo |
|---|---|---|
| block | blocos/disco | Persistent Disk / Hyperdisk |
| object | objetos em bucket | Cloud Storage |
| file | arquivos/diretórios compartilhados | Filestore / NetApp / Lustre |

---

# 3. Filestore — NFS gerenciado

Filestore fornece armazenamento de arquivos gerenciado.

Arquitetura do laboratório:

```text
Compute Engine VM
      |
      | NFS
      v
Filestore
      |
      └── /vol1
```

A VM e a instância Filestore precisam de conectividade de rede compatível.

Conceitos que usaremos:

```text
instance
file share
IP
NFS
mount point
```

Não confunda:

```text
Filestore
≠
Persistent Disk
≠
Cloud Storage
```

---

# 4. Laboratório Filestore — preparar

## 4.1 Variáveis

```bash
# Obtém o projeto configurado.
export PROJECT_ID="$(gcloud config get-value project)"
# Define região e zona do laboratório.
export REGION=us-central1
export ZONE=us-central1-c
# Define os recursos.
export FILESTORE_INSTANCE=ace-filestore
export FILESTORE_SHARE=vol1
export NFS_CLIENT=ace-nfs-client
# Usa a VPC default para reduzir dependências do laboratório.
export NETWORK=default
# Exibe a configuração antes de criar recursos.
printf 'PROJECT_ID=%s\nREGION=%s\nZONE=%s\nFILESTORE_INSTANCE=%s\nNFS_CLIENT=%s\n' \
  "$PROJECT_ID" "$REGION" "$ZONE" "$FILESTORE_INSTANCE" "$NFS_CLIENT"
```

## 4.2 APIs

```bash
# Habilita Filestore e Compute Engine.
gcloud services enable \
  file.googleapis.com \
  compute.googleapis.com
```

## 4.3 Inspecionar antes de criar

```bash
# Lista instâncias Filestore existentes.
gcloud filestore instances list
# Lista VMs existentes.
gcloud compute instances list
```

> Se a criação do Filestore falhar por quota, registre a evidência. Isso é uma restrição do projeto/região, não uma razão para alterar aleatoriamente o comando.

---

# 5. Criar Filestore

Para manter o laboratório simples, usamos `BASIC_HDD`, que exige no mínimo 1 TB.

```bash
# Cria uma instância Filestore zonal Basic HDD com um file share NFS.
gcloud filestore instances create "$FILESTORE_INSTANCE" \
  --zone="$ZONE" \
  --tier=BASIC_HDD \
  --file-share="name=$FILESTORE_SHARE,capacity=1TB" \
  --network="name=$NETWORK"
```

> **Atenção:** 1 TB é a capacidade mínima desse tier e gera cobrança. Faça o cleanup assim que terminar.

## 5.1 Inspecionar

```bash
# Lista as instâncias após a criação.
gcloud filestore instances list
# Exibe detalhes da instância.
gcloud filestore instances describe "$FILESTORE_INSTANCE" \
  --zone="$ZONE"
```

Procure:

```text
state
fileShares
networks
ipAddresses
tier
protocol
```

Capture o IP:

```bash
# Extrai o primeiro IP retornado pela configuração de rede.
export FILESTORE_IP="$(gcloud filestore instances describe "$FILESTORE_INSTANCE" \
  --zone="$ZONE" \
  --format='value(networks[0].ipAddresses[0])')"
# Confirma o IP.
echo "$FILESTORE_IP"
```

---

# 6. Criar VM cliente

Use uma VM pequena apenas para montar o NFS.

```bash
# Cria uma VM Linux na mesma VPC usada pelo Filestore.
gcloud compute instances create "$NFS_CLIENT" \
  --zone="$ZONE" \
  --machine-type=e2-micro \
  --network="$NETWORK" \
  --image-family=debian-12 \
  --image-project=debian-cloud
```

Inspecione:

```bash
# Confirma estado, zona e IP interno da VM.
gcloud compute instances describe "$NFS_CLIENT" \
  --zone="$ZONE" \
  --format="table(name,status,zone.basename(),networkInterfaces[0].networkIP)"
```

---

# 7. Instalar NFS e montar o share

Para evitar SSH aberto à internet, usamos IAP.

## 7.1 Instalar cliente NFS

```bash
# Instala o cliente NFS na VM via túnel IAP.
gcloud compute ssh "$NFS_CLIENT" \
  --zone="$ZONE" \
  --tunnel-through-iap \
  --command="sudo apt-get update && sudo apt-get install -y nfs-common"
```

## 7.2 Criar mount point

```bash
# Cria o diretório de montagem.
gcloud compute ssh "$NFS_CLIENT" \
  --zone="$ZONE" \
  --tunnel-through-iap \
  --command="sudo mkdir -p /mnt/filestore"
```

## 7.3 Montar

```bash
# Monta o file share NFS usando IP e nome do share.
gcloud compute ssh "$NFS_CLIENT" \
  --zone="$ZONE" \
  --tunnel-through-iap \
  --command="sudo mount ${FILESTORE_IP}:/${FILESTORE_SHARE} /mnt/filestore"
```

## 7.4 Inspecionar mount

```bash
# Confirma o filesystem NFS montado.
gcloud compute ssh "$NFS_CLIENT" \
  --zone="$ZONE" \
  --tunnel-through-iap \
  --command="df -h --type=nfs"
```

---

# 8. Testar leitura e escrita

Crie um arquivo:

```bash
# Escreve um arquivo no filesystem compartilhado.
gcloud compute ssh "$NFS_CLIENT" \
  --zone="$ZONE" \
  --tunnel-through-iap \
  --command="echo 'ACE Filestore' | sudo tee /mnt/filestore/ace.txt"
```

Leia:

```bash
# Lê o arquivo a partir do share.
gcloud compute ssh "$NFS_CLIENT" \
  --zone="$ZONE" \
  --tunnel-through-iap \
  --command="cat /mnt/filestore/ace.txt"
```

Resultado esperado:

```text
ACE Filestore
```

Modelo:

```text
VM
→ mount NFS
→ write
→ Filestore
→ read
```

---

# 9. Quebrar propositalmente — share incorreto

Primeiro desmonte:

```bash
# Desmonta o share correto para testar uma montagem incorreta.
gcloud compute ssh "$NFS_CLIENT" \
  --zone="$ZONE" \
  --tunnel-through-iap \
  --command="sudo umount /mnt/filestore"
```

Altere somente uma variável: o nome do share.

```bash
# Tenta montar um export que não existe.
gcloud compute ssh "$NFS_CLIENT" \
  --zone="$ZONE" \
  --tunnel-through-iap \
  --command="sudo mount ${FILESTORE_IP}:/share-inexistente /mnt/filestore"
```

## Sintoma

```text
mount falha
```

## Hipótese

```text
nome do file share está incorreto
```

## Evidência

```bash
# Reinspeciona o recurso para descobrir o share configurado.
gcloud filestore instances describe "$FILESTORE_INSTANCE" \
  --zone="$ZONE" \
  --format="yaml(fileShares,networks)"
```

Confirme:

```text
share configurado
→ vol1
share usado na falha
→ share-inexistente
```

## Causa

```text
export NFS inexistente
```

## Correção

```bash
# Monta novamente usando o share configurado.
gcloud compute ssh "$NFS_CLIENT" \
  --zone="$ZONE" \
  --tunnel-through-iap \
  --command="sudo mount ${FILESTORE_IP}:/${FILESTORE_SHARE} /mnt/filestore"
```

Valide:

```bash
# Confirma mount e persistência do arquivo.
gcloud compute ssh "$NFS_CLIENT" \
  --zone="$ZONE" \
  --tunnel-through-iap \
  --command="df -h --type=nfs && cat /mnt/filestore/ace.txt"
```

---

# 10. NetApp Volumes — Enterprise NAS

Google Cloud NetApp Volumes atende workloads de file storage empresarial.

Modelo mental:

```text
Enterprise NAS
+
workloads tradicionais
+
protocolos de arquivo
+
recursos empresariais
↓
NetApp Volumes
```

Nesta aula não provisionaremos um volume.

Motivos:

```text
custo
+
quota/capacidade
+
requisitos de rede
+
objetivo ACE de reconhecimento/decisão
```

Nível:

```text
arquitetura
→ E
provisionamento
→ P*
```

Use NetApp Volumes quando requisitos de NAS empresarial, migração de workloads tradicionais e funcionalidades específicas de file services forem determinantes.

Não conclua:

```text
"preciso de arquivos"
→ sempre NetApp Volumes
```

Filestore pode ser uma solução mais simples para NFS gerenciado.

---

# 11. Managed Lustre — HPC e AI

Managed Lustre deve ser reconhecido pelo workload.

Modelo:

```text
muitos workers
+
filesystem compartilhado
+
I/O paralelo
+
alto throughput
↓
Managed Lustre
```

Casos típicos:

```text
HPC
AI/ML
treinamento distribuído
processamento intensivo em I/O
```

Compare:

```text
NFS geral para VM/GKE
→ Filestore
Enterprise NAS
→ NetApp Volumes
filesystem paralelo de alto desempenho
→ Managed Lustre
```

Nesta aula:

```text
arquitetura
→ E
provisionamento
→ P*
```

---

# 12. Matriz de File Storage

| Requisito dominante | Candidato |
|---|---|
| objetos via API | Cloud Storage |
| disco de VM | Persistent Disk / Hyperdisk |
| NFS gerenciado para VM/GKE | Filestore |
| Enterprise NAS | NetApp Volumes |
| filesystem paralelo para HPC/AI | Managed Lustre |

## 12.1 Cenário Windows/enterprise

> Uma empresa quer migrar aplicações tradicionais que dependem de file services empresariais e requisitos de NAS.

Não escolha automaticamente Cloud Storage apenas porque os dados são arquivos.

Pergunte:

```text
protocolo
compatibilidade
features de NAS
performance
workload
```

A resposta pode apontar para NetApp Volumes conforme os requisitos concretos.

---

# 13. Managed Service for Apache Kafka

A Aula 6 praticou Pub/Sub.

Agora compare:

```text
Pub/Sub
→ mensageria/eventos nativos Google Cloud
→ serviço serverless
Managed Kafka
→ compatibilidade com Apache Kafka
→ ecossistema e clientes Kafka
```

O ponto de decisão não é:

```text
qual produto tem "mensagens"?
```

É:

```text
compatibilidade Kafka é requisito?
há aplicações/produtores/consumidores Kafka existentes?
o ecossistema Kafka precisa ser preservado?
```

## 13.1 Inspeção sem provisionamento

Habilitar a API não cria cluster:

```bash
# Habilita a API do Managed Kafka.
gcloud services enable managedkafka.googleapis.com
```

Liste clusters existentes:

```bash
# Lista clusters Managed Kafka na região sem criar um cluster novo.
gcloud managed-kafka clusters list \
  --location="$REGION"
```

Se não houver clusters:

```text
lista vazia
→ comportamento esperado em um projeto sem Managed Kafka provisionado
```

Um cluster real implicaria capacidade e cobrança; por isso, criação fica `P*`.

## 13.2 Pub/Sub × Managed Kafka

| Requisito | Pub/Sub | Managed Kafka |
|---|---:|---:|
| integração nativa GCP | forte | possível |
| operação serverless de mensageria | sim | não é o mesmo modelo |
| compatibilidade Kafka | não é Kafka | sim |
| migração de aplicações Kafka | exige adaptação | forte candidato |
| ecossistema Kafka existente | não preserva API Kafka | preserva compatibilidade |

Cenário:

> Dezenas de aplicações já usam clientes Kafka e a empresa quer serviço gerenciado com mínima alteração.

```text
Managed Service for Apache Kafka
```

Não escolha Pub/Sub apenas porque ambos podem aparecer em arquiteturas event-driven.

---

# 14. Memorystore — in-memory

Memorystore atende casos em que baixa latência e dados em memória são importantes.

Modelo:

```text
Application
   |
   +------> Memorystore
   |          |
   |       cache hit
   |
   +------> persistent database
            Cloud SQL / Spanner / etc.
```

Casos comuns:

```text
cache
sessões
dados temporários
aceleração de leitura
```

A distinção fundamental:

```text
cache
≠
system of record
```

Não use Memorystore automaticamente como substituto de um banco persistente.

## 14.1 Cenário

> Uma API consulta repetidamente no Cloud SQL informações que mudam pouco e precisa reduzir latência e carga sobre o banco.

Modelo:

```text
request
↓
Memorystore
├─ cache hit → resposta
└─ cache miss
   ↓
   Cloud SQL
   ↓
   popula cache
```

Nesta aula:

```text
arquitetura
→ E
provisionamento
→ P*
```

---

# 15. Matriz geral da Aula 7

| Necessidade | Serviço |
|---|---|
| object storage | Cloud Storage |
| block storage para VM | Persistent Disk / Hyperdisk |
| NFS gerenciado | Filestore |
| Enterprise NAS | NetApp Volumes |
| filesystem paralelo HPC/AI | Managed Lustre |
| messaging/eventos serverless | Pub/Sub |
| compatibilidade/ecossistema Kafka | Managed Kafka |
| cache/in-memory | Memorystore |

A pergunta central:

```text
qual requisito diferencia o cenário?
```

---

# 16. Anti-patterns

## 16.1 Todo arquivo vai para Cloud Storage

Errado.

```text
arquivo
≠
necessariamente object storage
```

Um workload pode exigir filesystem montável e protocolo de arquivo.

## 16.2 Filestore e Persistent Disk são equivalentes

Errado.

```text
Persistent Disk
→ block storage
Filestore
→ file storage / NFS
```

## 16.3 Filestore e Managed Lustre são equivalentes

Errado.

```text
Filestore
→ NFS gerenciado geral
Managed Lustre
→ filesystem paralelo de alto desempenho
```

## 16.4 Pub/Sub é Kafka

Errado.

Eles podem resolver problemas relacionados a eventos, mas possuem APIs, modelo operacional e ecossistemas diferentes.

## 16.5 Memorystore é o banco principal

Não necessariamente.

Para cache:

```text
Memorystore
+
banco persistente
```

é um padrão mais apropriado.

---

# 17. Cenários estilo ACE

### Cenário 1

> Duas VMs Linux precisam compartilhar diretórios usando NFS.

**Resposta:** Filestore.

### Cenário 2

> Uma aplicação precisa armazenar imagens como objetos acessados por API.

**Resposta:** Cloud Storage.

### Cenário 3

> Workload empresarial exige NAS e funcionalidades avançadas de file services.

**Resposta:** avaliar NetApp Volumes.

### Cenário 4

> Milhares de workers de HPC precisam de filesystem paralelo de alto throughput.

**Resposta:** Managed Lustre.

### Cenário 5

> Aplicações existentes usam clientes Kafka e a migração deve minimizar alterações.

**Resposta:** Managed Service for Apache Kafka.

### Cenário 6

> Uma aplicação nova precisa apenas desacoplar eventos usando um serviço nativo e serverless no Google Cloud.

**Resposta:** Pub/Sub.

### Cenário 7

> Uma API sobrecarrega o banco persistente executando repetidamente leituras de dados que mudam pouco.

**Resposta:** avaliar Memorystore como cache.

### Cenário 8

> Uma VM precisa de um disco para instalar sistema de arquivos e armazenar dados locais persistentes.

**Resposta:** Persistent Disk ou Hyperdisk, conforme requisitos.

---

# 18. M/E/P

| Conteúdo | Nível |
|---|---:|
| Block × Object × File | `E` |
| Filestore — arquitetura NFS | `E` |
| Filestore — criar/inspecionar | `P/P*` |
| Filestore — mount/read/write | `P/P*` |
| Filestore — falha/troubleshooting | `P/P*` |
| Cloud Storage × Filestore | `E/P` |
| NetApp Volumes — arquitetura/decisão | `E` |
| NetApp Volumes — provisionamento | `P*` |
| Managed Lustre — arquitetura/decisão | `E` |
| Managed Lustre — provisionamento | `P*` |
| Managed Kafka — arquitetura/decisão | `E` |
| Managed Kafka — listar clusters | `P` |
| Managed Kafka — provisionamento | `P*` |
| Pub/Sub × Managed Kafka | `E/P` |
| Memorystore — arquitetura/cache | `E` |
| Memorystore — provisionamento | `P*` |
| Matriz geral | `E/P` |

`P/P*` no Filestore significa:

```text
P
→ quando o projeto/região possui quota e o laboratório é executado
P*
→ quando quota impede criação, mas arquitetura/comandos/inspeção são seguidos de forma guiada
```

---

# 19. Checklist

- [ ] Diferenciei block, object e file storage;
- [ ] Expliquei a arquitetura NFS do Filestore;
- [ ] Verifiquei quota/condições antes do provisionamento;
- [ ] Criei e inspecionei Filestore quando permitido;
- [ ] Criei a VM cliente;
- [ ] Usei IAP para executar comandos na VM;
- [ ] Instalei o cliente NFS;
- [ ] Montei o file share;
- [ ] Escrevi e li um arquivo;
- [ ] Provoquei falha usando share incorreto;
- [ ] Diagnostiquei usando `describe`;
- [ ] Corrigi e validei o mount;
- [ ] Diferenciei Filestore, NetApp Volumes e Managed Lustre;
- [ ] Diferenciei Pub/Sub e Managed Kafka;
- [ ] Listei clusters Managed Kafka sem provisionar um;
- [ ] Expliquei cache e system of record;
- [ ] Expliquei o papel do Memorystore;
- [ ] Resolvi os cenários de decisão;
- [ ] Executei o cleanup.

---

# 20. Cleanup

> **Obrigatório:** Filestore gera cobrança enquanto existir. Execute esta seção imediatamente após terminar o laboratório.

## 20.1 Desmontar

```bash
# Desmonta o filesystem antes de remover os recursos.
gcloud compute ssh "$NFS_CLIENT" \
  --zone="$ZONE" \
  --tunnel-through-iap \
  --command="sudo umount /mnt/filestore"
```

## 20.2 Remover VM

```bash
# Exclui a VM cliente.
gcloud compute instances delete "$NFS_CLIENT" \
  --zone="$ZONE" \
  --quiet
```

## 20.3 Remover Filestore

```bash
# Exclui a instância Filestore.
gcloud filestore instances delete "$FILESTORE_INSTANCE" \
  --zone="$ZONE" \
  --quiet
```

## 20.4 Confirmar

```bash
# Confirma que a instância Filestore não existe mais.
gcloud filestore instances list
# Confirma que a VM cliente não existe mais.
gcloud compute instances list \
  --filter="name=$NFS_CLIENT"
```

Nenhum recurso NetApp Volumes, Managed Lustre, Managed Kafka ou Memorystore precisa ser excluído porque não foi provisionado no fluxo principal.

---

# 21. Referências oficiais

- Filestore — criar instância com Google Cloud CLI.
- Filestore — montar file share em cliente Compute Engine.
- Google Cloud NetApp Volumes — conceitos e workloads.
- Managed Lustre — conceitos e workloads HPC/AI.
- Managed Service for Apache Kafka — clusters e recursos.
- Memorystore — conceitos e casos de uso.
- Associate Cloud Engineer — exam guide.
