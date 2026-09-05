# AUDITORIA-P-FALSOS-POSITIVOS.md

## Objetivo

Revisar tópicos marcados como `P` na matriz e procurar casos em que a evidência real era apenas menção, comando isolado ou inspeção superficial.

## Regra utilizada

Um tópico operacional só permanece `P` quando há evidência suficiente de:

```text
conceito operacional
↓
configuração/ação
↓
inspeção
↓
teste ou comportamento observável
```

Quando a execução exige privilégios especiais, custo relevante ou alteração de política sensível, a parte correspondente é `P*`.

## Falsos positivos encontrados e corrigidos

| Tópico | Problema na v8 | Correção v9 | Resultado |
|---|---|---|---|
| Cloud Audit Logs | consulta genérica e menções; não ensinava tipos, protoPayload nem configuração | 4 tipos, campos, Admin Activity real, filtros, teste, falha, troubleshooting e Data Access `auditConfigs` como P* | `P/P*` |
| VM Manager | API/metadata + observação no Console, com pouca evidência operacional | feature settings, OS inventory via CLI, inspeção e troubleshooting | `P` |
| GKE Regional cluster | criação/describe sem teste de workload explícito | Deployment de validação, wait, pods, topology labels e cleanup | `P` |

## Itens reavaliados que permaneceram P

Foram rechecados os grupos operacionais de maior risco de falso positivo, incluindo:

- Cloud Run revisions, traffic splitting e autoscaling;
- HPA e VPA;
- snapshots e images;
- Cloud DNS e Cloud NAT;
- Dataflow e BigQuery job status;
- custom/log-based metrics;
- Ops Agent;
- IAM policies, roles e Service Accounts;
- Terraform;
- Cloud Storage lifecycle e proteção de objetos.

Nesses casos, a baseline mantém prática, inspeção e comportamento observável suficientes para o nível indicado na matriz.

## Observação importante

`P*` continua sendo diferente de `P`. Ele sinaliza que existe roteiro técnico, porém a execução integral pode depender de Organization, permissões administrativas, custo ou alteração sensível. Isso evita marcar como prática real algo que o aluno não deve executar indiscriminadamente.
