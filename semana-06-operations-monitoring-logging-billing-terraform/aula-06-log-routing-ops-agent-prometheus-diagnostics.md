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
gcloud logging sinks list
gcloud logging buckets list --location=global
```

## 3. Inspecionar

```bash
gcloud logging read 'resource.type="gce_instance"' --limit=20
gcloud logging sinks list
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
