# Aula 6 — Pub/Sub, Dataflow, Storage Transfer e Jobs

## Cobertura no exam guide

Exam Guide 3.3, 3.4 e 4.4: Pub/Sub, Dataflow, eventos, Storage Transfer Service e revisão de status de jobs.

**Custos:** não crie Dataflow jobs sem necessidade; jobs podem gerar cobrança de compute.

## 1. Conceito

Pub/Sub desacopla produtores e consumidores por mensagens. Dataflow executa pipelines batch/stream Apache Beam. Storage Transfer Service move dados entre origens suportadas e Cloud Storage. A ACE deve reconhecer e operar o básico, não desenvolver pipelines Beam complexos.

### Arquitetura / modelo mental

```text
Producer → Pub/Sub Topic → Subscription → Consumer
Data source → Dataflow job → sink
External/GCS source → Storage Transfer Service → GCS
```

## 2. Criar / Configurar

Pub/Sub hands-on:

```bash
gcloud services enable pubsub.googleapis.com dataflow.googleapis.com storagetransfer.googleapis.com
gcloud pubsub topics create ace-topic
gcloud pubsub subscriptions create ace-sub --topic=ace-topic
```

Para Dataflow/Storage Transfer, liste jobs/configurações antes de provisionar pipelines que possam gerar custo.

## 3. Inspecionar

```bash
gcloud pubsub topics list
gcloud pubsub subscriptions describe ace-sub
gcloud dataflow jobs list --region=us-central1
gcloud transfer jobs list 2>/dev/null || true
```

> A partir deste ponto, todos os elementos usados no troubleshooting já foram apresentados e inspecionados.

## 4. Testar

```bash
gcloud pubsub topics publish ace-topic --message='ACE'
gcloud pubsub subscriptions pull ace-sub --auto-ack --limit=1
```

## 5. Quebrar propositalmente

Publique uma mensagem e tente puxar de uma subscription com nome incorreto: `ace-sub-errada`.

## 6. Troubleshooting

**Sintoma:** recurso não encontrado.
**Hipótese:** subscription ID incorreto.
**Evidência:** `gcloud pubsub subscriptions list`.
**Causa:** nome deliberadamente errado.
**Correção:** usar `ace-sub`.

Para Dataflow, quando um job falhar, primeiro liste e descreva o **job**, antes de supor erro de Pub/Sub ou Storage.

Use a sequência:

```text
Sintoma → Hipótese → Evidência → Causa → Correção
```

## 7. Corrigir

Repita pull com a subscription correta. Registre a matriz: Pub/Sub=mensageria, Dataflow=pipeline, Storage Transfer=movimentação gerenciada de objetos/dados suportados.

## 8. Questões estilo ACE

1. Desacoplar eventos? **Pub/Sub**.
2. Pipeline Apache Beam batch/stream? **Dataflow**.
3. Mover grande conjunto de objetos de fonte suportada para Cloud Storage? **Storage Transfer Service**.
4. Ver execução Dataflow? **Dataflow jobs**.

## 9. Cleanup

```bash
gcloud pubsub subscriptions delete ace-sub --quiet
gcloud pubsub topics delete ace-topic --quiet
```

## Checklist

- [ ] Consigo explicar os conceitos sem consultar;
- [ ] Sei localizar o recurso no Console e/ou CLI;
- [ ] Executei ou simulei o laboratório indicado;
- [ ] Inspecionei a configuração antes de provocar a falha;
- [ ] Diagnostiquei a falha com evidências;
- [ ] Sei reconhecer a alternativa correta em uma questão de cenário.
