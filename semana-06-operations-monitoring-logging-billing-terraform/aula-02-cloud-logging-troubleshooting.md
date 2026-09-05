# Aula 2 — Cloud Logging e Troubleshooting

## Objetivos

Ao final, você deverá:
- consultar logs;
- filtrar por severity/resource;
- entender Audit Logs;
- provocar operação falha e encontrar evidência;
- diferenciar log, metric e log-based metric.


---

# 1. Conceito

Logging armazena entradas de eventos. Audit Logs registram atividades administrativas e acesso conforme categoria. Queries filtram campos estruturados.

## Arquitetura mental

```text
Action
  ↓
Log entry
  ├─ resource
  ├─ severity
  ├─ timestamp
  └─ protoPayload/textPayload
```

---

# 2. Criar

Crie e delete uma VM para gerar atividade administrativa:

```bash
# Explicação: Cria uma VM do Compute Engine com as opções de máquina, rede, disco e identidade informadas.
gcloud compute instances create ace-log-vm \
  --zone=us-central1-a \
  --machine-type=e2-micro \
  --image-family=debian-12 \
  --image-project=debian-cloud
```

---

# 3. Inspecionar

Antes de provocar qualquer erro, confirme a configuração criada. O troubleshooting desta aula usará **somente elementos que você já observou aqui**.

```bash
# Explicação: Consulta entradas do Cloud Logging usando o filtro informado para coletar evidências.
gcloud logging read \
 'resource.type="gce_instance"' \
 --limit=20 \
 --format="table(timestamp,severity,logName)"

# Explicação: Consulta entradas do Cloud Logging usando o filtro informado para coletar evidências.
gcloud logging read \
 'logName:"cloudaudit.googleapis.com"' \
 --limit=20
```

---

# 4. Testar

Faça uma operação inválida:

```bash
# Explicação: Interrompe a VM sem excluir seus discos persistentes.
gcloud compute instances stop vm-que-nao-existe \
  --zone=us-central1-a || true
```

Depois pesquise por erros/atividade relacionada no Logs Explorer e compare com saída do CLI.

---

# 5. Quebrar propositalmente

A falha já é a operação em recurso inexistente. O objetivo é não “inventar” causa de aplicação quando o CLI já informa resource not found.

---

# 6. Troubleshooting

Agora o erro já foi produzido e os componentes envolvidos já foram apresentados.

**Sintoma:** comando falha porque VM não existe.

**Hipótese:** nome/zone incorreto ou recurso inexistente.

**Evidências:**
```bash
# Explicação: Lista VMs do projeto para verificar inventário, zona, IPs e estado.
gcloud compute instances list
# Explicação: Consulta entradas do Cloud Logging usando o filtro informado para coletar evidências.
gcloud logging read 'severity>=ERROR' --limit=20
```

**Causa:** usamos `vm-que-nao-existe`.

A lição é correlacionar mensagem do comando com logs/audit quando aplicável.

Use sempre:

```text
Sintoma
   ↓
Hipótese
   ↓
Evidência
   ↓
Causa
   ↓
Correção
```

---

# 7. Corrigir

Use um recurso real:

```bash
# Explicação: Exibe a configuração e o estado detalhado da VM para inspeção/troubleshooting.
gcloud compute instances describe ace-log-vm \
  --zone=us-central1-a
```

---

# 8. Questões estilo ACE

1. “Quem alterou este recurso?” → **Audit Logs**.
2. Contar ocorrências de um padrão para alertar → **log-based metric**.
3. Log é série temporal numérica? **Não necessariamente**.

---

# 9. Cleanup

```bash
# Explicação: Exclui a VM indicada e libera os recursos associados que não foram preservados.
gcloud compute instances delete ace-log-vm \
  --zone=us-central1-a --quiet
```

---


---

# Cobertura ACE ampliada — audit, flow e firewall logs

## Tipos importantes de logs

```text
Cloud Audit Logs → ações administrativas/acesso conforme categoria
VPC Flow Logs    → amostras de fluxos de rede em subnets configuradas
Firewall Rules Logging → decisão/observação de regras habilitadas
```

Para troubleshooting, escolha o sinal correto:

```text
Quem alterou IAM?        → Audit Logs
Fluxo chegou à subnet?   → VPC Flow Logs
Qual regra firewall?     → Firewall Rules Logging
```

## Log details

No Logs Explorer, abra uma entrada e identifique:

- timestamp;
- resource;
- severity;
- principal (quando aplicável);
- methodName/status;
- labels/payload.

# 10. Checklist

- [ ] Entendi os conceitos usados no laboratório;
- [ ] Criei o recurso;
- [ ] Inspecionei estado e configuração;
- [ ] Testei o comportamento esperado;
- [ ] Provoquei a falha descrita;
- [ ] Diagnostiquei usando evidências;
- [ ] Corrigi sem aumentar privilégios ou alterar componentes desnecessários;
- [ ] Consigo relacionar o cenário a uma questão ACE;
- [ ] Executei o cleanup.

---

---

# 10. Cloud Audit Logs — conceito, tipos, consulta e configuração

O **Cloud Audit Logs** registra ações administrativas, acessos a dados, eventos gerados pelo próprio Google Cloud e negações causadas por políticas de segurança. Uma entrada de auditoria é uma entrada do Cloud Logging cujo `protoPayload` contém um objeto de auditoria.

## 10.1 Modelo mental

```text
Ação sobre recurso Google Cloud
          ↓
Cloud Audit Logs
          ↓
LogEntry
├── logName
├── timestamp
├── resource
└── protoPayload
    ├── authenticationInfo.principalEmail
    ├── serviceName
    ├── methodName
    ├── resourceName
    └── status
```

Use as perguntas:

```text
Quem?             → principalEmail
Fez o quê?        → methodName
Em qual serviço?  → serviceName
Em qual recurso?  → resourceName
Quando?           → timestamp
Ocorreu erro?     → protoPayload.status
```

## 10.2 Os quatro tipos de Audit Logs

| Tipo | O que registra | Comportamento importante |
|---|---|---|
| Admin Activity | ações que alteram configuração ou metadata | sempre gerado; não pode ser desabilitado |
| Data Access | leitura de metadata/configuração e acesso a dados do usuário, conforme permission type | geralmente desabilitado por padrão; BigQuery é exceção importante |
| System Event | alterações feitas por sistemas do Google Cloud | sempre gerado; não decorre diretamente de ação do usuário |
| Policy Denied | acesso negado por violação de política de segurança | gerado por padrão; pode ser excluído do armazenamento por filtros |

Os nomes lógicos usados nos filtros incluem:

```text
activity      → Admin Activity
data_access   → Data Access
system_event  → System Event
policy        → Policy Denied
```

## 10.3 Criar uma ação auditável

A VM criada no início da aula já produz **Admin Activity**. Para gerar mais uma alteração auditável sem criar outro recurso, adicione uma label:

```bash
# Explicação: Adiciona uma label à VM existente. Essa alteração modifica metadata/configuração do recurso e deve gerar uma entrada de Admin Activity.
gcloud compute instances add-labels ace-log-vm \
  --zone=us-central1-a \
  --labels=audit-demo=true
```

## 10.4 Consultar Audit Logs do projeto

```bash
# Explicação: Obtém o Project ID atualmente selecionado para montar filtros de Audit Logs sem hardcode.
PROJECT_ID="$(gcloud config get-value project)"

# Explicação: Lê entradas de Cloud Audit Logs do projeto atual. O filtro procura qualquer log cujo nome pertença a cloudaudit.googleapis.com.
gcloud logging read \
  "logName:projects/${PROJECT_ID}/logs/cloudaudit.googleapis.com" \
  --project="$PROJECT_ID" \
  --limit=20
```

Agora filtre especificamente **Admin Activity**:

```bash
# Explicação: Filtra somente Admin Activity. `%2Factivity` é a forma codificada do sufixo `/activity` no logName.
gcloud logging read \
  "logName=projects/${PROJECT_ID}/logs/cloudaudit.googleapis.com%2Factivity" \
  --project="$PROJECT_ID" \
  --limit=20
```

## 10.5 Inspecionar quem fez o quê

```bash
# Explicação: Mostra os campos mais úteis de uma entrada de auditoria: horário, principal, serviço, método e recurso afetado.
gcloud logging read \
  "logName=projects/${PROJECT_ID}/logs/cloudaudit.googleapis.com%2Factivity" \
  --project="$PROJECT_ID" \
  --limit=10 \
  --format='table(timestamp,protoPayload.authenticationInfo.principalEmail,protoPayload.serviceName,protoPayload.methodName,protoPayload.resourceName)'
```

Procure uma entrada relacionada ao Compute Engine:

```bash
# Explicação: Restringe a consulta ao serviço Compute Engine para facilitar a correlação com a alteração feita na VM.
gcloud logging read \
  'protoPayload.serviceName="compute.googleapis.com" AND logName:"cloudaudit.googleapis.com%2Factivity"' \
  --project="$PROJECT_ID" \
  --limit=20
```

O comportamento esperado é encontrar uma ação administrativa recente associada ao principal autenticado e a um método do Compute Engine.

## 10.6 Teste positivo

Confirme três evidências na mesma entrada:

```text
principalEmail  → sua identidade ou identidade que executou a ação
methodName      → método correspondente à alteração
resourceName    → recurso afetado
```

No Logs Explorer, faça a mesma consulta e expanda `protoPayload` para conferir os campos estruturados.

## 10.7 Quebrar propositalmente — filtro errado

Use deliberadamente o tipo errado de Audit Log:

```bash
# Explicação: Procura System Event para uma ação manual que deveria aparecer em Admin Activity. O resultado pode ser vazio e isso é proposital.
gcloud logging read \
  "logName=projects/${PROJECT_ID}/logs/cloudaudit.googleapis.com%2Fsystem_event AND protoPayload.serviceName=\"compute.googleapis.com\"" \
  --project="$PROJECT_ID" \
  --limit=20
```

### Troubleshooting

```text
Sintoma
→ não encontro a alteração manual da VM

Hipótese
→ estou consultando a categoria errada de Audit Log

Evidência
→ a ação foi feita por usuário/CLI e modificou configuração do recurso

Causa
→ filtro usa system_event, mas a ação pertence a Admin Activity

Correção
→ consultar activity e então filtrar por serviceName/methodName/resourceName
```

Corrija:

```bash
# Explicação: Volta para Admin Activity, categoria adequada para a alteração administrativa realizada pelo usuário.
gcloud logging read \
  "logName=projects/${PROJECT_ID}/logs/cloudaudit.googleapis.com%2Factivity" \
  --project="$PROJECT_ID" \
  --limit=20
```

## 10.8 Data Access — configuração P* e impacto de custo

**Data Access** merece tratamento separado porque pode aumentar o volume de logs e, em muitos serviços, não vem habilitado por padrão. A configuração é feita no `auditConfigs` da IAM policy do projeto, pasta ou organização.

> **Nível P\***: execute a alteração somente em um projeto de laboratório e com permissão apropriada. Alterar uma IAM policy incorretamente pode remover acessos. Preserve `bindings` e `etag` exatamente como recebidos.

Primeiro faça backup da policy atual:

```bash
# Explicação: Salva a IAM policy atual em YAML. Esse arquivo contém bindings e etag e será usado como base segura para a alteração.
gcloud projects get-iam-policy "$PROJECT_ID" > /tmp/policy-before-audit.yaml

# Explicação: Cria uma segunda cópia editável, preservando o backup original para eventual restauração.
cp /tmp/policy-before-audit.yaml /tmp/policy-audit.yaml
```

No arquivo `/tmp/policy-audit.yaml`, adicione somente a seção `auditConfigs`. Exemplo didático para habilitar Data Access de todos os serviços:

```yaml
auditConfigs:
- service: allServices
  auditLogConfigs:
  - logType: ADMIN_READ
  - logType: DATA_READ
  - logType: DATA_WRITE
```

Depois de conferir que `bindings` e `etag` continuam intactos, aplique **somente se estiver em projeto de laboratório**:

```bash
# Explicação: Substitui a IAM policy do projeto pelo arquivo editado. Execute apenas depois de revisar bindings, etag e auditConfigs.
gcloud projects set-iam-policy "$PROJECT_ID" /tmp/policy-audit.yaml
```

Inspecione a configuração efetiva no projeto:

```bash
# Explicação: Mostra somente a seção auditConfigs da IAM policy para confirmar os tipos de Data Access configurados.
gcloud projects get-iam-policy "$PROJECT_ID" \
  --format='yaml(auditConfigs)'
```

Para desfazer o laboratório, restaure o backup original:

```bash
# Explicação: Restaura a IAM policy salva antes da alteração. Use apenas se você realmente aplicou a configuração de Data Access neste laboratório.
gcloud projects set-iam-policy "$PROJECT_ID" /tmp/policy-before-audit.yaml
```

## 10.9 IAM para visualizar Audit Logs

Para prova, associe:

```text
roles/logging.viewer
→ leitura de Admin Activity, System Event e Policy Denied, conforme acesso ao recurso

roles/logging.privateLogViewer
→ inclui capacidade necessária para visualizar Data Access no _Default bucket
```

Evite conceder permissões amplas apenas para investigar logs.

## 10.10 Questões estilo ACE — Audit Logs

1. Um administrador quer descobrir quem alterou uma regra de IAM. Qual sinal deve consultar primeiro?  
   **Cloud Audit Logs / Admin Activity**.

2. Uma equipe quer auditar leituras de dados que não aparecem nos logs atuais. O que verificar?  
   **Configuração de Data Access audit logs** para o serviço relevante.

3. Uma VM foi adicionada automaticamente a um MIG por ação interna do Google Cloud. Qual categoria pode registrar a alteração?  
   **System Event**.

4. Uma solicitação foi negada por uma política de segurança. Qual categoria investigar?  
   **Policy Denied**.

## 10.11 Cleanup específico

```bash
# Explicação: Remove a label de laboratório para devolver a VM ao estado anterior antes do cleanup geral da aula.
gcloud compute instances remove-labels ace-log-vm \
  --zone=us-central1-a \
  --labels=audit-demo
```

> Se você habilitou Data Access, restaure a policy original conforme mostrado acima antes de sair do laboratório.

## Referências oficiais usadas nesta seção

- Cloud Audit Logs overview: https://cloud.google.com/logging/docs/audit
- Understanding audit logs: https://cloud.google.com/logging/docs/audit/understanding-audit-logs
- Enable Data Access audit logs: https://cloud.google.com/logging/docs/audit/configure-data-access

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
| 4.6 | View/filter/details logs | `P` | `P` |
| 4.6 | Audit Logs | `P` | `P` |
