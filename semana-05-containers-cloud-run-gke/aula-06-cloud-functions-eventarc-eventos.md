# Aula 6 — Cloud Functions, Eventarc e Aplicações Orientadas a Eventos

## Nível de cobertura M/E/P

```text
Cloud Functions + Pub/Sub event: P; Cloud Storage/Eventarc: E/P*
```


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
# Explicação: Habilita a API/serviço indicado no projeto ativo para permitir o uso do recurso no laboratório.
gcloud services enable cloudfunctions.googleapis.com eventarc.googleapis.com pubsub.googleapis.com run.googleapis.com
# Explicação: Executa `gcloud functions list --gen2 --regions=us-central1` nesta etapa para aplicar ou inspecionar a configuração indicada.
gcloud functions list --gen2 --regions=us-central1
# Explicação: Lista triggers do Eventarc para confirmar o roteamento de eventos configurado.
gcloud eventarc triggers list --location=us-central1
```

Crie um tópico Pub/Sub de laboratório para representar a origem:
```bash
# Explicação: Cria um tópico Pub/Sub para receber mensagens dos produtores.
gcloud pubsub topics create ace-events
```

## 3. Inspecionar

```bash
# Explicação: Exibe a configuração do tópico Pub/Sub indicado.
gcloud pubsub topics describe ace-events
# Explicação: Lista triggers do Eventarc para confirmar o roteamento de eventos configurado.
gcloud eventarc triggers list --location=us-central1
```

No Console compare o formulário de criação de Cloud Run/Cloud Functions e os tipos de triggers Eventarc.

> A partir deste ponto, todos os elementos usados no troubleshooting já foram apresentados e inspecionados.

## 4. Testar

Publique um evento no tópico e explique que, sem trigger/destination configurado, não haverá aplicação consumidora automática.
```bash
# Explicação: Publica uma mensagem no tópico Pub/Sub para testar o fluxo de eventos.
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
# Explicação: Exclui o tópico Pub/Sub criado no laboratório.
gcloud pubsub topics delete ace-events --quiet
```

## Checklist

- [ ] Consigo explicar os conceitos sem consultar;
- [ ] Sei localizar o recurso no Console e/ou CLI;
- [ ] Executei ou simulei o laboratório indicado;
- [ ] Inspecionei a configuração antes de provocar a falha;
- [ ] Diagnostiquei a falha com evidências;
- [ ] Sei reconhecer a alternativa correta em uma questão de cenário.


---

# Cobertura ACE ampliada — serverless events

## Cloud Run functions

O exam guide atual usa a terminologia **Cloud Run functions**. Funções podem processar eventos sem você gerenciar servidores.

## Eventarc

Eventarc roteia eventos de fontes suportadas para destinos como Cloud Run.

```text
Cloud Storage object finalized
        ↓ Eventarc
Cloud Run / Cloud Run function
```

## Pub/Sub event

```text
Publisher → Pub/Sub topic → event trigger → serverless workload
```

Para prova, escolha trigger/event source apropriado em vez de polling manual.


---

# Cobertura obrigatória do guia anexado — decisão de implantação

O guia oficial anexado pede explicitamente que o candidato saiba decidir onde implantar uma aplicação entre:

```text
Cloud Run (totalmente gerenciado)
Cloud Run for Anthos
Cloud Functions
```

## Cloud Run totalmente gerenciado

Use quando o objetivo é executar containers HTTP/event-driven sem administrar cluster Kubernetes.

```text
Container
   ↓
Cloud Run
   ↓
Google gerencia a infraestrutura
```

## Cloud Run for Anthos

O **guia anexado utiliza essa terminologia**. Para a prova baseada nesse documento, associe-a ao cenário em que workloads Cloud Run são executados em uma plataforma baseada em Anthos/Kubernetes, em vez do ambiente totalmente gerenciado.

Modelo mental para a questão:

```text
Quer serverless container sem administrar cluster
→ Cloud Run totalmente gerenciado

Quer integração com ambiente Anthos/Kubernetes
→ Cloud Run for Anthos

Quer função pequena orientada a evento
→ Cloud Functions
```

## Eventos exigidos pelo guia

O documento cita explicitamente:

```text
Pub/Sub
Cloud Storage object change notification
Eventarc
```

Arquitetura:

```text
Pub/Sub message
      ↓
Eventarc / trigger
      ↓
Cloud Run ou Cloud Functions
```

e:

```text
Cloud Storage
object created/changed
      ↓
Eventarc / trigger
      ↓
Cloud Run ou Cloud Functions
```

## Questões estilo ACE

**1.** Uma equipe quer implantar um container HTTP sem operar Kubernetes.

**Resposta:** Cloud Run totalmente gerenciado.

**2.** Uma função deve executar após um evento de criação de objeto em Cloud Storage.

**Resposta:** Cloud Functions ou destino serverless apropriado acionado pelo mecanismo de eventos; o guia espera reconhecimento de Cloud Storage events/Eventarc.

**3.** O enunciado da prova, seguindo o guia anexado, menciona execução de Cloud Run integrada ao Anthos.

**Resposta:** reconhecer **Cloud Run for Anthos** como a alternativa descrita pelo guia.


---

## Laboratório executável — Cloud Function acionada por Pub/Sub

**Custos:** a função e serviços associados podem gerar pequena cobrança. Faça cleanup.

### 1. Criar código

```bash
# Explicação: Cria o diretório usado pelos arquivos/configurações do laboratório.
mkdir -p ~/ace-function && cd ~/ace-function

# Explicação: Exibe conteúdo de arquivo ou cria conteúdo via redirecionamento/heredoc, conforme a sintaxe usada.
cat > main.py <<'EOF'
import base64

def hello_pubsub(event, context):
    data = event.get('data')
    msg = base64.b64decode(data).decode('utf-8') if data else 'sem mensagem'
    print(f'ACE recebeu: {msg}')
EOF

# Explicação: Exibe conteúdo de arquivo ou cria conteúdo via redirecionamento/heredoc, conforme a sintaxe usada.
cat > requirements.txt <<'EOF'
functions-framework==3.*
EOF
```

### 2. Criar tópico e deploy

```bash
# Explicação: Cria um tópico Pub/Sub para receber mensagens dos produtores.
gcloud pubsub topics create ace-events 2>/dev/null || true

# Explicação: Implanta/atualiza uma Cloud Function com runtime, entrada e trigger definidos pelas flags.
gcloud functions deploy ace-pubsub-function \
  --gen2 \
  --runtime=python312 \
  --region=us-central1 \
  --source=. \
  --entry-point=hello_pubsub \
  --trigger-topic=ace-events
```

### 3. Inspecionar

```bash
# Explicação: Exibe a configuração e o estado da Cloud Function.
gcloud functions describe ace-pubsub-function \
  --gen2 \
  --region=us-central1

# Explicação: Lista triggers do Eventarc para confirmar o roteamento de eventos configurado.
gcloud eventarc triggers list --location=us-central1
```

### 4. Testar

```bash
# Explicação: Publica uma mensagem no tópico Pub/Sub para testar o fluxo de eventos.
gcloud pubsub topics publish ace-events --message='evento ACE'
```

Leia logs:

```bash
# Explicação: Executa `gcloud functions logs read ace-pubsub-function --gen2 --region=us-central1 --limit=20` nesta etapa para aplicar ou inspecionar a configuração indicada.
gcloud functions logs read ace-pubsub-function \
  --gen2 \
  --region=us-central1 \
  --limit=20
```

Procure `ACE recebeu: evento ACE`.

### 5. Quebrar propositalmente

Publique em outro tópico que não é o trigger:

```bash
# Explicação: Cria um tópico Pub/Sub para receber mensagens dos produtores.
gcloud pubsub topics create ace-outro-topic
# Explicação: Publica uma mensagem no tópico Pub/Sub para testar o fluxo de eventos.
gcloud pubsub topics publish ace-outro-topic --message='nao deve acionar'
```

### 6. Troubleshooting

```text
Sintoma: função não executa para a mensagem
Hipótese: evento foi enviado a uma fonte diferente do trigger
Evidência: describe da função/Eventarc trigger + nomes dos tópicos
Causa: ace-outro-topic não está associado ao trigger
Correção: publicar em ace-events ou reconfigurar trigger
```

### 7. Cloud Storage + Eventarc

O guia também cita eventos de alteração de objetos no Cloud Storage. Antes de criar outro recurso, identifique no Console/CLI quais triggers Eventarc estão disponíveis e reconheça o padrão:

```text
Cloud Storage object event
        ↓
Eventarc
        ↓
Cloud Run / Cloud Function
```

### Cleanup

```bash
# Explicação: Exclui a Cloud Function criada no laboratório.
gcloud functions delete ace-pubsub-function \
  --gen2 --region=us-central1 --quiet

# Explicação: Exclui o tópico Pub/Sub criado no laboratório.
gcloud pubsub topics delete ace-events --quiet
# Explicação: Exclui o tópico Pub/Sub criado no laboratório.
gcloud pubsub topics delete ace-outro-topic --quiet
# Explicação: Remove o arquivo/diretório temporário indicado durante correção ou cleanup.
rm -rf ~/ace-function
```
