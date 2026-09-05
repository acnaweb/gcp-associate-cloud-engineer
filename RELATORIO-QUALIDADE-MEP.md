# RELATORIO-QUALIDADE-MEP.md

## Objetivo

Evitar que um tópico seja marcado como “coberto” apenas porque seu nome aparece em uma aula.

## Critério

- **Mencionado**: nome/referência curta.
- **Explicado**: conceito + quando usar + diferenças/decisão.
- **Praticado**: criação/configuração + inspeção + teste, ou prática guiada explícita quando a execução depende de pré-requisitos externos.

## Lacunas corrigidas nesta revisão

- Cloud Run autoscaling: de `E` para `P` com min/max/concurrency, carga e troubleshooting.
- Cloud Functions/Eventarc: de inspeção para deploy real com Pub/Sub.
- GKE regional/node pools/StatefulSet/VPA: adicionados comandos e manifests de prática.
- VM Manager: adicionada habilitação de OS Config e validação.
- Custom Machine Types e Spot: adicionada criação real.
- Images e Snapshot Schedules: adicionada prática completa.
- Dataflow job status: adicionada execução guiada de job e `describe`.
- Storage Transfer: adicionada prática guiada de transferência pequena.
- Firestore backup/restore: prática guiada condicional explicitada.
- Custom Metrics: adicionada log-based metric executável.
- Ops Agent: adicionada prática de status/stop/test.
- Billing/Cloud Identity/Quota increase/Organization Policy: marcados `P*` quando dependem de privilégios que não devem ser contornados.

## Regra de regressão

Uma futura versão não pode transformar um item `P` em `E` ou `M` sem justificativa explícita. Itens `P*` só podem ser promovidos a `P` quando o laboratório for realmente executável sem depender de infraestrutura/permissões não disponíveis ao aluno comum.


---

# Revisão v8 — evidência real

A baseline v8 substitui o critério antigo de presença por um critério de evidência. Em especial, HPA e VPA foram reclassificados/reconstruídos com explicação e prática efetiva. Veja `AUDITORIA-MEP-EVIDENCIAS.md`.
