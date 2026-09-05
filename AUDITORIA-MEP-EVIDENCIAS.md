# AUDITORIA-MEP-EVIDENCIAS.md

## Objetivo

Esta auditoria corrige o problema de **falso positivo M/E/P**: um tópico não pode ser marcado como `P` apenas porque seu nome ou um comando aparece na aula.

## Critério de `P`

```text
1. conceito operacional explicado
2. configuração/comando executável e comentado
3. inspeção do recurso/estado
4. teste ou comportamento observável
```

Quando existe laboratório de falha, também é exigido:

```text
Sintoma → Hipótese → Evidência → Causa → Correção
```

`P*` continua reservado a práticas condicionais por custo, Organization, privilégio ou infraestrutura especial.

## Correções estruturais aplicadas

- Aula 5 de GKE: HPA saiu de resumo superficial para laboratório completo com `requests.cpu`, target, min/max, observação de réplicas, falha deliberada e troubleshooting.
- Aula 7 de GKE: VPA passou a explicar recommendation, requests, update modes, `Off`, targetRef, inspeção e troubleshooting; node pools e StatefulSet também passaram a ter conceito antes da prática.
- Todas as aulas agora possuem seção explícita de **critério de aceite M/E/P** e os tópicos do exam guide mapeados para aquela aula.
- A matriz M/E/P recebeu critério reforçado: comando isolado não conta como `P`.

## Regra de regressão

```text
P  → não pode virar apenas E sem justificativa
E  → não pode virar apenas M sem justificativa
P* → não pode ser apresentado como laboratório executado universalmente
```

## Verificações automatizadas da baseline

O arquivo `VALIDACAO-BASELINE-V8.md` registra contagem de aulas, presença do rodapé M/E/P e validação do ZIP final.
