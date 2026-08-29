# Aula 6 — Cloud Functions, Eventarc e Aplicações Orientadas a Eventos

## Cobertura no exam guide

Exam Guide 2.1 e 3.3: escolher Cloud Run/Cloud Functions e implementar aplicações que recebem eventos Pub/Sub/Cloud Storage/Eventarc.



## 1. Conceito

Cloud Functions é uma opção serverless orientada a funções/eventos. Eventarc roteia eventos de fontes suportadas para destinos como Cloud Run/Functions. Pub/Sub pode ser fonte de eventos.

### Arquitetura / modelo mental

```text
Event source (Pub/Sub/Storage/Google API)
       ↓
Eventarc trigger
       ↓
Cloud Run / Cloud Functions
```

## 2. Criar / Configurar

Faça primeiro um laboratório de decisão e inspeção para evitar deployment desnecessário.

```bash
gcloud services enable cloudfunctions.googleapis.com eventarc.googleapis.com pubsub.googleapis.com run.googleapis.com
gcloud functions list --gen2 --regions=us-central1
gcloud eventarc triggers list --location=us-central1
```

Crie um tópico Pub/Sub de laboratório para representar a origem:
```bash
gcloud pubsub topics create ace-events
```

## 3. Inspecionar

```bash
gcloud pubsub topics describe ace-events
gcloud eventarc triggers list --location=us-central1
```

No Console compare o formulário de criação de Cloud Run/Cloud Functions e os tipos de triggers Eventarc.

> A partir deste ponto, todos os elementos usados no troubleshooting já foram apresentados e inspecionados.

## 4. Testar

Publique um evento no tópico e explique que, sem trigger/destination configurado, não haverá aplicação consumidora automática.
```bash
gcloud pubsub topics publish ace-events --message='evento'
```

## 5. Quebrar propositalmente

Falha proposital: assumir que criar o tópico automaticamente invoca uma função/Cloud Run.

## 6. Troubleshooting

**Sintoma:** mensagem foi publicada, mas nenhuma aplicação executou.
**Hipótese:** não existe trigger/subscription/destination ligando fonte ao consumidor.
**Evidência:** `gcloud eventarc triggers list` e inspeção do tópico.
**Causa:** somente a fonte foi criada.
**Correção:** em uma arquitetura real, configurar Eventarc trigger ou mecanismo apropriado.

Use a sequência:

```text
Sintoma → Hipótese → Evidência → Causa → Correção
```

## 7. Corrigir

Desenhe a configuração completa antes de provisionar: source → trigger → destination → runtime identity/IAM.

## 8. Questões estilo ACE

1. Função pequena orientada a evento? **Cloud Functions** pode ser adequada.
2. Container HTTP com mais controle de runtime? **Cloud Run**.
3. Roteamento de eventos Google Cloud para destino serverless? **Eventarc**.

## 9. Cleanup

```bash
gcloud pubsub topics delete ace-events --quiet
```

## Checklist

- [ ] Consigo explicar os conceitos sem consultar;
- [ ] Sei localizar o recurso no Console e/ou CLI;
- [ ] Executei ou simulei o laboratório indicado;
- [ ] Inspecionei a configuração antes de provocar a falha;
- [ ] Diagnostiquei a falha com evidências;
- [ ] Sei reconhecer a alternativa correta em uma questão de cenário.
