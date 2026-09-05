# Aula 6 — Log Routing, Ops Agent, Managed Prometheus e Cloud Diagnostics

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

Crie uma VM pequena e instale Ops Agent pelo fluxo recomendado no Console/documentação atual, ou use a opção de instalação fornecida pelo Monitoring para a VM. Depois gere um log local.

Inspeção de routing:
```bash
# Explicação: Lista log sinks existentes para verificar roteamento configurado.
gcloud logging sinks list
# Explicação: Lista log buckets do Cloud Logging na localização informada.
gcloud logging buckets list --location=global
```

## 3. Inspecionar

```bash
# Explicação: Consulta entradas do Cloud Logging usando o filtro informado para coletar evidências.
gcloud logging read 'resource.type="gce_instance"' --limit=20
# Explicação: Lista log sinks existentes para verificar roteamento configurado.
gcloud logging sinks list
# Explicação: Lista log buckets do Cloud Logging na localização informada.
gcloud logging buckets list --location=global
```

No Console: Monitoring → Prometheus e Observability → Diagnostics/Logs Explorer. Consulte também Google Cloud Service Health/Status.

> A partir deste ponto, todos os elementos usados no troubleshooting já foram apresentados e inspecionados.

## 4. Testar

Pare um serviço local monitorado ou gere uma linha de log conhecida e confirme a evidência no Logging/Monitoring.

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

Delete VM de laboratório e sinks/destinos extras criados.

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

Audit Logs ajudam a responder perguntas como:

```text
quem?
fez o quê?
em qual recurso?
quando?
```

Exemplo de consulta:

```bash
# Explicação: Consulta entradas do Cloud Logging usando o filtro informado para coletar evidências.
gcloud logging read \
  'logName:"cloudaudit.googleapis.com"' \
  --limit=20
```

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

### Managed Service for Prometheus

**Nível:** `P*` se você não possuir cluster GKE de laboratório ativo.

Em um cluster compatível, identifique/configure coleta gerenciada e confirme no Monitoring a existência de métricas Prometheus. O objetivo operacional é conseguir distinguir:

```text
Prometheus metric collection
→ Managed Service for Prometheus

VM logs/metrics agent
→ Ops Agent
```

Não marque este tópico como `P` se você apenas leu a definição.

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
| 4.6 | Export logs externo/on-prem/BigQuery | `P` | `P/P*` |
| 4.6 | Log buckets/router/analytics | `P` | `P/P*` |
| 4.6 | Cloud diagnostics | `P` | `E/P*` |
| 4.6 | Google Cloud status | `P` | `P*` |
| 4.6 | Ops Agent | `P` | `P` |
| 4.6 | Managed Service for Prometheus | `P` | `P*` |
