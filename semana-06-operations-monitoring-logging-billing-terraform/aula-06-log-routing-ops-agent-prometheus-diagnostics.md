# Aula 6 — Log Routing, Ops Agent, Managed Prometheus e Cloud Diagnostics

## Objetivos

Ao final, você deverá:
- explicar o papel do Log Router, log buckets, views e sinks;
- criar uma VM de laboratório e instalar o Ops Agent pela linha de comando;
- gerar e consultar logs coletados pelo Ops Agent;
- explicar o papel do Managed Service for Prometheus;
- usar evidências de Monitoring, Logging e status da plataforma em troubleshooting;
- reconhecer o papel de Audit Logs e exportação de registros.

---


## Cobertura no exam guide

Exam Guide 4.6: custom metrics, log export/routing, buckets/views, diagnostics, Google Cloud status, Ops Agent, Managed Service for Prometheus e Audit Logs.

**Custos:** sinks para BigQuery/Storage e VMs podem gerar cobrança.

## 1. Conceito

Ops Agent coleta logs/métricas de VMs. Log Router direciona entradas para buckets e sinks. Managed Service for Prometheus fornece monitoramento gerenciado compatível com Prometheus para workloads. Cloud Status ajuda a distinguir incidente da plataforma de falha da sua configuração.

### Arquitetura / modelo mental

```text
VM/App → Ops Agent → Logging/Monitoring
Logs → Log Router → bucket/view/sink
Prometheus metrics → Managed Service for Prometheus
Incident? → logs/metrics + Google Cloud status
```

## 2. Criar / Configurar

Nesta etapa, vamos criar uma VM pequena, instalar o Ops Agent usando o script oficial de instalação e gerar um log local para validar a coleta.

### 2.1 Definir variáveis do laboratório

```bash
# Explicação: Define a região em que os recursos do laboratório serão criados.
export REGION=us-central1

# Explicação: Define a zona usada pela VM. A zona precisa pertencer à região escolhida.
export ZONE=us-central1-a

# Explicação: Define o nome da VM que será criada para o laboratório.
export VM_NAME=ace-ops-agent-vm

# Explicação: Obtém o ID do projeto atualmente configurado no gcloud.
export PROJECT_ID=$(gcloud config get-value project)
```

Valide as variáveis:

```bash
# Explicação: Exibe os valores que serão usados nos próximos comandos.
echo "PROJECT_ID=$PROJECT_ID"
echo "REGION=$REGION"
echo "ZONE=$ZONE"
echo "VM_NAME=$VM_NAME"
```

### 2.2 Habilitar as APIs necessárias

```bash
# Explicação: Habilita a API do Compute Engine, necessária para criar a VM.
gcloud services enable compute.googleapis.com

# Explicação: Habilita a Cloud Logging API, usada pelo Ops Agent para enviar logs.
gcloud services enable logging.googleapis.com

# Explicação: Habilita a Cloud Monitoring API, usada pelo Ops Agent para enviar métricas.
gcloud services enable monitoring.googleapis.com
```

Confirme:

```bash
# Explicação: Lista apenas as APIs habilitadas relacionadas a Compute, Logging e Monitoring.
gcloud services list --enabled \
  --filter='NAME:(compute.googleapis.com logging.googleapis.com monitoring.googleapis.com)'
```

### 2.3 Criar uma Service Account dedicada ao Ops Agent

Para evitar depender das permissões implícitas da Compute Engine default service account, vamos usar uma identidade dedicada.

```bash
# Explicação: Cria uma Service Account que será anexada à VM.
gcloud iam service-accounts create ace-ops-agent-sa \
  --display-name="ACE Ops Agent VM"
```

Conceda apenas as permissões necessárias para enviar logs e métricas:

```bash
# Explicação: Permite que a Service Account grave entradas no Cloud Logging.
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:ace-ops-agent-sa@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/logging.logWriter"

# Explicação: Permite que a Service Account envie métricas ao Cloud Monitoring.
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:ace-ops-agent-sa@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/monitoring.metricWriter"
```

### 2.4 Criar a VM

```bash
# Explicação: Cria uma VM Linux pequena para o laboratório.
# --machine-type=e2-micro mantém o recurso pequeno.
# --image-family e --image-project selecionam uma imagem Debian suportada.
# --service-account associa a identidade criada anteriormente.
# --scopes=cloud-platform permite que as credenciais da VM sejam usadas com as APIs,
# enquanto o IAM continua limitando o que a Service Account realmente pode fazer.
gcloud compute instances create "$VM_NAME" \
  --zone="$ZONE" \
  --machine-type=e2-micro \
  --image-family=debian-12 \
  --image-project=debian-cloud \
  --service-account="ace-ops-agent-sa@$PROJECT_ID.iam.gserviceaccount.com" \
  --scopes=https://www.googleapis.com/auth/cloud-platform
```

### 2.5 Inspecionar a VM antes de instalar o agente

```bash
# Explicação: Exibe os principais campos da VM para confirmar estado, zona e Service Account.
gcloud compute instances describe "$VM_NAME" \
  --zone="$ZONE" \
  --format='yaml(name,status,zone,machineType,serviceAccounts)'
```

O estado esperado é:

```text
status: RUNNING
```

### 2.6 Instalar o Ops Agent por gcloud SSH

A documentação oficial para uma VM Linux individual usa o script:

```text
add-google-cloud-ops-agent-repo.sh
```

Vamos executar exatamente esse fluxo remotamente usando `gcloud compute ssh`.

```bash
# Explicação: Conecta à VM via SSH e executa os comandos de instalação sem precisar
# abrir um terminal interativo manualmente.
# curl baixa o script oficial do Google.
# --also-install adiciona o repositório e instala o Ops Agent na mesma execução.
gcloud compute ssh "$VM_NAME" \
  --zone="$ZONE" \
  --command='curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh && sudo bash add-google-cloud-ops-agent-repo.sh --also-install'
```

Após a instalação, o serviço deve iniciar automaticamente.

### 2.7 Verificar o serviço do Ops Agent

```bash
# Explicação: Executa systemctl dentro da VM para verificar se o serviço está ativo.
gcloud compute ssh "$VM_NAME" \
  --zone="$ZONE" \
  --command='sudo systemctl status google-cloud-ops-agent --no-pager'
```

Para uma saída mais simples:

```bash
# Explicação: Retorna apenas o estado do serviço. O valor esperado é "active".
gcloud compute ssh "$VM_NAME" \
  --zone="$ZONE" \
  --command='systemctl is-active google-cloud-ops-agent'
```

Resultado esperado:

```text
active
```

### 2.8 Gerar um log local

O comando `logger` envia uma mensagem para o syslog da VM. O Ops Agent coleta logs do sistema em sua configuração padrão.

```bash
# Explicação: Gera uma entrada de syslog com uma mensagem fácil de localizar no Cloud Logging.
gcloud compute ssh "$VM_NAME" \
  --zone="$ZONE" \
  --command='logger "ACE_OPS_AGENT_TESTE log gerado pelo laboratorio"'
```

Gere mais algumas entradas para facilitar a visualização:

```bash
# Explicação: Gera três mensagens adicionais, cada uma com um identificador diferente.
gcloud compute ssh "$VM_NAME" \
  --zone="$ZONE" \
  --command='for i in 1 2 3; do logger "ACE_OPS_AGENT_TESTE mensagem-$i"; sleep 1; done'
```

### 2.9 Inspecionar Log Router e buckets

```bash
# Explicação: Lista log sinks existentes para verificar roteamento configurado.
gcloud logging sinks list

# Explicação: Lista log buckets do Cloud Logging na localização global.
gcloud logging buckets list --location=global
```

## 3. Inspecionar

Primeiro, descubra o ID numérico da VM, que aparece nos `resource.labels` dos logs de Compute Engine:

```bash
# Explicação: Obtém o ID numérico da VM para usá-lo como filtro preciso no Cloud Logging.
export INSTANCE_ID=$(gcloud compute instances describe "$VM_NAME" \
  --zone="$ZONE" \
  --format='value(id)')

echo "INSTANCE_ID=$INSTANCE_ID"
```

Agora procure especificamente a mensagem gerada com `logger`:

```bash
# Explicação: Consulta logs da VM e procura pelo texto usado no teste.
# O filtro combina o resource type de VM, o instance_id e a mensagem criada no laboratório.
gcloud logging read \
  "resource.type=\"gce_instance\" AND resource.labels.instance_id=\"$INSTANCE_ID\" AND textPayload:\"ACE_OPS_AGENT_TESTE\"" \
  --limit=20 \
  --format='table(timestamp,logName,textPayload)'
```

Se ainda não houver resultado, aguarde alguns segundos e repita a consulta, pois a ingestão não é instantânea.

Inspecione também o agente dentro da VM:

```bash
# Explicação: Exibe as últimas mensagens do serviço Ops Agent no journal do systemd.
gcloud compute ssh "$VM_NAME" \
  --zone="$ZONE" \
  --command='sudo journalctl -u google-cloud-ops-agent -n 50 --no-pager'
```

E revise o roteamento:

```bash
# Explicação: Lista log sinks existentes para verificar roteamento configurado.
gcloud logging sinks list

# Explicação: Lista log buckets do Cloud Logging na localização informada.
gcloud logging buckets list --location=global
```

No Console: Monitoring → Prometheus e Observability → Diagnostics/Logs Explorer. Consulte também Google Cloud Service Health/Status.

> A partir deste ponto, todos os elementos usados no troubleshooting já foram apresentados e inspecionados.

## 4. Testar

O teste positivo desta parte da aula é provar o caminho completo:

```text
logger na VM
   ↓
syslog
   ↓
Ops Agent
   ↓
Cloud Logging
   ↓
gcloud logging read
```

Gere uma nova mensagem:

```bash
# Explicação: Cria uma nova entrada para validar o pipeline ponta a ponta.
gcloud compute ssh "$VM_NAME" \
  --zone="$ZONE" \
  --command='logger "ACE_OPS_AGENT_TESTE validacao-final"'
```

Depois consulte novamente:

```bash
# Explicação: Procura especificamente a mensagem de validação final no Cloud Logging.
gcloud logging read \
  "resource.type=\"gce_instance\" AND resource.labels.instance_id=\"$INSTANCE_ID\" AND textPayload:\"ACE_OPS_AGENT_TESTE validacao-final\"" \
  --limit=10 \
  --format='table(timestamp,textPayload)'
```

O teste está concluído quando a mensagem aparece na consulta.

## 5. Quebrar propositalmente

Falha proposital: filtre Logs Explorer por um resource type incorreto e observe “nenhum resultado”, apesar de o log existir.

## 6. Troubleshooting

**Sintoma:** consulta retorna zero logs.
**Hipótese:** filtro está errado, não necessariamente coleta.
**Evidência:** remova cláusulas do filtro progressivamente e confirme resource type real.
**Causa:** filtro deliberadamente incorreto.
**Correção:** usar resource labels/type observados no log.

Use a sequência:

```text
Sintoma → Hipótese → Evidência → Causa → Correção
```

## 7. Corrigir

Corrija filtro. Antes de reinstalar agente, sempre valide se os logs chegam com consulta ampla.

## 8. Questões estilo ACE

1. Coletar logs/métricas de VM? **Ops Agent**.
2. Exportar logs para BigQuery? **Log Router sink**.
3. Métricas Prometheus em GCP de forma gerenciada? **Managed Service for Prometheus**.
4. Suspeita de incidente geral do Google Cloud? Consulte **Service Health/Status** junto às suas evidências.

## 9. Cleanup

Remova os recursos criados neste laboratório.

```bash
# Explicação: Exclui a VM e encerra o consumo de Compute Engine associado a ela.
gcloud compute instances delete "$VM_NAME" \
  --zone="$ZONE" \
  --quiet
```

Remova os papéis concedidos à Service Account:

```bash
# Explicação: Remove a permissão de escrita no Cloud Logging concedida para o laboratório.
gcloud projects remove-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:ace-ops-agent-sa@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/logging.logWriter"

# Explicação: Remove a permissão de escrita de métricas no Cloud Monitoring.
gcloud projects remove-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:ace-ops-agent-sa@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/monitoring.metricWriter"
```

Por fim:

```bash
# Explicação: Exclui a Service Account dedicada ao laboratório.
gcloud iam service-accounts delete \
  "ace-ops-agent-sa@$PROJECT_ID.iam.gserviceaccount.com" \
  --quiet
```

Se você criou sinks ou destinos extras nas seções posteriores da aula, remova-os também.

## Checklist

- [ ] Consigo explicar os conceitos sem consultar;
- [ ] Sei localizar o recurso no Console e/ou CLI;
- [ ] Executei ou simulei o laboratório indicado;
- [ ] Inspecionei a configuração antes de provocar a falha;
- [ ] Diagnostiquei a falha com evidências;
- [ ] Sei reconhecer a alternativa correta em uma questão de cenário.


---

# Cobertura ACE ampliada — observability completa

## Log Router, sinks, buckets, views e Log Analytics

```text
Log entry
   ↓ Log Router
   ├─ _Required/_Default buckets
   ├─ custom log bucket
   └─ sink → BigQuery / Storage / Pub/Sub / destino suportado
```

- **Sink**: roteia/exporta logs.
- **Log bucket**: armazena logs.
- **Log view**: controla subconjunto visível.
- **Log Analytics**: consultas analíticas sobre logs em configuração compatível.

## Ops Agent

Agente recomendado para coletar métricas/logs de VMs em cenários suportados.

Inspeção em VM configurada:

```bash
# Explicação: Consulta o estado do serviço systemd indicado sem alterar sua execução.
sudo systemctl status google-cloud-ops-agent
```

## Managed Service for Prometheus

Use para monitoramento compatível com Prometheus sem operar toda a infraestrutura de armazenamento/consulta por conta própria.

## Diagnostic tools

O guia cita ferramentas como:

- Cloud Trace;
- Cloud Profiler;
- Query Insights;
- index advisor.

Modelo:

```text
latência distribuída → Trace
CPU/perfil de código → Profiler
SQL/database issue   → Query Insights / index advisor
```

## Personalized Service Health

Use para verificar eventos/incidentes de serviços Google relevantes ao seu ambiente antes de assumir que o problema está na aplicação.

## Cloud Hub

Fornece visão agregada de eventos ativos e dados de saúde de aplicações/recursos em cenários suportados.


---

# Cobertura obrigatória do guia anexado — exportação e diagnóstico

## Exportar logs para sistemas externos

O guia anexado exige reconhecer exportação de registros para:

```text
sistemas externos
on-premises
BigQuery
```

Modelo mental:

```text
Cloud Logging
     ↓
Log Router
     ↓
Sink
 ├─ BigQuery
 ├─ Cloud Storage
 ├─ Pub/Sub
 └─ integração/encaminhamento para consumidor externo, conforme arquitetura
```

### Exemplo: sink para BigQuery

```bash
# Explicação: Cria um log sink para rotear entradas que correspondem ao filtro até o destino configurado.
gcloud logging sinks create ace-bq-sink \
  bigquery.googleapis.com/projects/PROJECT_ID/datasets/DATASET_ID \
  --log-filter='severity>=ERROR'
```

Inspecione:

```bash
# Explicação: Exibe configuração e writer identity do log sink.
gcloud logging sinks describe ace-bq-sink
```

> O destino precisa existir e a identidade do sink precisa das permissões adequadas no destino.

Para sistemas externos/on-premises, pense no pipeline como:

```text
Cloud Logging
   ↓
export / sink
   ↓
destino intermediário suportado
   ↓
processo/consumer
   ↓
sistema externo
```

O ponto cobrado é saber que logs podem ser **roteados/exportados**, não apenas visualizados no Logs Explorer.

---

## Log Buckets, Log Router e análise de dados de registro

```text
Log entry
   ↓
Log Router
   ├─ Log Bucket
   └─ Sink
```

- **Log Router** decide para onde as entradas são encaminhadas.
- **Log Bucket** armazena logs.
- Recursos de análise permitem consultar/avaliar dados armazenados de acordo com a configuração.

Inspeção:

```bash
# Explicação: Lista log sinks existentes para verificar roteamento configurado.
gcloud logging sinks list
# Explicação: Lista log buckets do Cloud Logging na localização informada.
gcloud logging buckets list --location=global
```

---

## Visualizar detalhes específicos da mensagem

No Logs Explorer, não pare na lista.

Abra uma entrada e identifique:

```text
timestamp
severity
resource.type
resource.labels
logName
textPayload / jsonPayload
protoPayload
```

O troubleshooting deve usar esses campos como evidência.

---

## Cloud diagnostics

O guia anexado usa a expressão **diagnóstico de nuvem** para pesquisar problemas da aplicação.

Modelo operacional:

```text
Sintoma
   ↓
Monitoring
   ↓
Logging
   ↓
traces/profiling/diagnostic evidence quando aplicável
   ↓
causa
```

A prova pode pedir a ferramenta/fluxo mais apropriado para investigar um problema, não apenas criar um alerta.

---

## Status do Google Cloud

Antes de assumir que uma falha é da sua aplicação, valide se há problema no serviço Google Cloud.

```text
Aplicação falhou
   ↓
logs/metrics locais
   +
status do Google Cloud
```

Isso ajuda a diferenciar:

```text
falha da workload
vs
incidente da plataforma
```

---

## Audit Logs

A prática completa de **Cloud Audit Logs** está na **Semana 6 / Aula 2 — Cloud Logging e Troubleshooting**, onde são ensinados e testados:

```text
Admin Activity
Data Access
System Event
Policy Denied
protoPayload
principalEmail
methodName
resourceName
configuração auditConfigs (P*)
```

Nesta aula, retome Audit Logs apenas para correlacionar auditoria com roteamento, buckets e diagnóstico. Não considere esta seção isoladamente como evidência `P`; a evidência prática está na Aula 2.

## Cleanup do sink de laboratório

Se criou o sink:

```bash
# Explicação: Exclui o log sink criado no laboratório.
gcloud logging sinks delete ace-bq-sink
```


---

## Laboratórios operacionais — Ops Agent, Log Router e Prometheus

### Ops Agent

Crie/ reutilize uma VM de laboratório e instale o agente pelo fluxo recomendado no Console ou script oficial exibido pela página **Monitoring → VM instances**.

Depois valide na VM:

```bash
# Explicação: Consulta o estado do serviço systemd indicado sem alterar sua execução.
sudo systemctl status google-cloud-ops-agent --no-pager
```

Gere uma linha de syslog:

```bash
# Explicação: Executa `logger 'ACE OPS AGENT TEST'` nesta etapa para aplicar ou inspecionar a configuração indicada.
logger 'ACE OPS AGENT TEST'
```

No Logs Explorer, pesquise pela VM e pela mensagem.

**Falha proposital:** pare o agent:

```bash
# Explicação: Interrompe propositalmente o serviço systemd indicado para simular a falha do laboratório.
sudo systemctl stop google-cloud-ops-agent
```

Gere outra mensagem e compare ingestão. Antes de alterar IAM ou firewall, confirme:

```bash
# Explicação: Consulta o estado do serviço systemd indicado sem alterar sua execução.
sudo systemctl status google-cloud-ops-agent --no-pager
```

### Log Router + BigQuery sink

Para tornar a exportação prática, primeiro crie um dataset:

```bash
# Explicação: Define `PROJECT_ID` com o ID do projeto Google Cloud usado pelos comandos seguintes.
export PROJECT_ID=$(gcloud config get-value project)
# Explicação: Cria um recurso BigQuery, como dataset ou tabela, conforme as flags.
bq mk --dataset --location=US "$PROJECT_ID:ace_logs"
```

Crie o sink:

```bash
# Explicação: Cria um log sink para rotear entradas que correspondem ao filtro até o destino configurado.
gcloud logging sinks create ace-bq-sink \
  "bigquery.googleapis.com/projects/$PROJECT_ID/datasets/ace_logs" \
  --log-filter='severity>=ERROR'
```

Inspecione a identidade escritora:

```bash
# Explicação: Exibe configuração e writer identity do log sink.
gcloud logging sinks describe ace-bq-sink
```

Conceda ao writer identity a permissão necessária no dataset conforme o valor real retornado pelo `describe`.

Gere um erro:

```bash
# Explicação: Grava uma entrada de log de teste no Cloud Logging.
gcloud logging write ace-export-test 'ERRO EXPORTADO' --severity=ERROR
```

Depois valide a chegada quando o destino estiver configurado corretamente.

### Managed Service for Prometheus — laboratório operacional

O Managed Service for Prometheus permite coletar métricas no formato/ecossistema Prometheus e armazená-las no backend de métricas gerenciado do Google Cloud.

Modelo:

```text
application / exporter
      ↓ /metrics
PodMonitoring
      ↓
managed collector
      ↓
Managed Service for Prometheus
      ↓
Cloud Monitoring / PromQL
```

No GKE moderno, a **managed collection** é normalmente a opção preferida. Ela reduz a necessidade de administrar servidores Prometheus, sharding e collectors manualmente.

> **Nível:** `P*` se você não possuir um cluster GKE de laboratório. Se você já tiver um cluster GKE criado na Semana 5, execute o laboratório e trate como `P`.

#### 1. Reutilizar um cluster GKE

```bash
# Define projeto, região e cluster.
export PROJECT_ID="$(gcloud config get-value project)"
export REGION="us-central1"
export CLUSTER="ace-gke"

# Obtém credenciais do cluster.
# Ajuste o nome caso tenha usado outro cluster na Semana 5.
gcloud container clusters get-credentials "$CLUSTER" \
  --region="$REGION"
```

Se o cluster for zonal, use `--zone` em vez de `--region`.

#### 2. Confirmar/ativar managed collection

```bash
# Exibe a configuração do cluster e permite verificar
# se Managed Service for Prometheus está habilitado.
gcloud container clusters describe "$CLUSTER" \
  --region="$REGION" \
  --format="yaml(monitoringConfig)"
```

Se precisar habilitar explicitamente:

```bash
# Habilita a coleta gerenciada do Managed Service for Prometheus.
gcloud container clusters update "$CLUSTER" \
  --region="$REGION" \
  --enable-managed-prometheus
```

#### 3. Criar namespace do laboratório

```bash
# Cria um namespace isolado para a aplicação Prometheus de exemplo.
kubectl create namespace gmp-test
```

#### 4. Implantar aplicação que expõe métricas

```bash
# Implanta o aplicativo oficial de exemplo.
# Ele expõe métricas Prometheus na porta nomeada "metrics".
kubectl -n gmp-test apply \
  -f https://raw.githubusercontent.com/GoogleCloudPlatform/prometheus-engine/v0.17.2/examples/example-app.yaml
```

Inspecione:

```bash
# Confirma Pods e labels do aplicativo.
kubectl -n gmp-test get pods -o wide
```

#### 5. Criar PodMonitoring

`PodMonitoring` diz ao collector **quais Pods devem ser descobertos e qual endpoint `/metrics` deve ser coletado**.

```bash
# Aplica o recurso PodMonitoring oficial do exemplo.
kubectl -n gmp-test apply \
  -f https://raw.githubusercontent.com/GoogleCloudPlatform/prometheus-engine/v0.17.2/examples/pod-monitoring.yaml
```

Inspecione:

```bash
# Lista recursos PodMonitoring em todos os namespaces.
kubectl get podmonitoring -A
```

```bash
# Mostra selector, endpoint, porta e conditions.
kubectl -n gmp-test describe podmonitoring prom-example
```

Modelo mental:

```text
selector
→ encontra Pods

port: metrics
→ indica o endpoint que será raspado

interval
→ frequência de coleta
```

#### 6. Testar comportamento observável

Depois de alguns minutos, use Cloud Monitoring → Metrics Explorer e procure métricas Prometheus do exemplo.

A aplicação oficial gera métricas como:

```text
example_requests_total
example_random_numbers
```

O objetivo do laboratório não é decorar a UI, mas reconhecer o fluxo:

```text
app expõe métrica
→ PodMonitoring seleciona target
→ collector coleta
→ métrica aparece no backend gerenciado
```

#### 7. Quebrar propositalmente

Crie uma cópia do PodMonitoring com selector que não corresponde aos Pods:

```bash
cat > /tmp/podmonitoring-bad.yaml <<'EOF'
apiVersion: monitoring.googleapis.com/v1
kind: PodMonitoring
metadata:
  name: prom-example-bad
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: label-inexistente
  endpoints:
  - port: metrics
    interval: 30s
EOF

# Aplica um PodMonitoring que não encontra targets.
kubectl -n gmp-test apply -f /tmp/podmonitoring-bad.yaml
```

Inspecione:

```bash
# Verifique selector e ausência de targets correspondentes.
kubectl -n gmp-test describe podmonitoring prom-example-bad

# Compare com os labels reais dos Pods.
kubectl -n gmp-test get pods --show-labels
```

#### 8. Troubleshooting

```text
Sintoma
→ métricas não aparecem

Hipótese 1
→ selector do PodMonitoring não encontra Pods

Evidência
→ kubectl get pods --show-labels
→ kubectl describe podmonitoring

Hipótese 2
→ port/path do endpoint está incorreto

Evidência
→ manifesto do PodMonitoring + portas do Pod

Hipótese 3
→ managed collection não está habilitada

Evidência
→ gcloud container clusters describe

Causa
→ localizar a primeira diferença comprovada pela evidência

Correção
→ alinhar selector/endpoint ou habilitar managed collection
```

#### 9. Corrigir

```bash
# Remove o PodMonitoring propositalmente incorreto.
kubectl -n gmp-test delete podmonitoring prom-example-bad
```

Confirme que o correto continua presente:

```bash
kubectl -n gmp-test get podmonitoring
```

#### 10. Cleanup

```bash
# Remove todos os recursos do namespace de laboratório.
kubectl delete namespace gmp-test

# Remove o arquivo temporário.
rm -f /tmp/podmonitoring-bad.yaml
```

Não desabilite Managed Service for Prometheus se o cluster continuar sendo usado em outros laboratórios.

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
| 4.6 | Export logs externo/on-prem/BigQuery | `P` | `P/P*` |
| 4.6 | Log buckets/router/analytics | `P` | `P/P*` |
| 4.6 | Cloud diagnostics | `P` | `E/P*` |
| 4.6 | Google Cloud status | `P` | `P*` |
| 4.6 | Ops Agent | `P` | `P` |
| 4.6 | Managed Service for Prometheus | `P` | `P*` |
