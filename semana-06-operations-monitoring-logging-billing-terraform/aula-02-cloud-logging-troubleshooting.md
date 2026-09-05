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

# Cobertura adicional — Log Router, Sinks, Buckets, Views e Audit Logs

Fluxo:

```text
Log entries
   ↓
Log Router
   ├─ _Required bucket
   ├─ _Default bucket
   └─ Sink → BigQuery / Storage / Pub/Sub / projeto etc.
```

Liste sinks:

```bash
# Explicação: Lista log sinks existentes para verificar roteamento configurado.
gcloud logging sinks list
```

Liste buckets:

```bash
# Explicação: Lista log buckets do Cloud Logging na localização informada.
gcloud logging buckets list --location=global
```

Exemplo de sink para BigQuery exige dataset previamente criado e permissões da writer identity retornada pelo sink.

## Audit Logs

Categorias importantes incluem Admin Activity e outros tipos conforme serviço/configuração.

Filtro útil:

```bash
# Explicação: Consulta entradas do Cloud Logging usando o filtro informado para coletar evidências.
gcloud logging read \
  'logName:"cloudaudit.googleapis.com"' \
  --limit=20
```

Pergunta de prova:

> “Quem alterou/deletou o recurso?”

Comece por **Cloud Audit Logs**, não por métrica de CPU.

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
| 4.6 | View/filter/details logs | `P` | `P` |
| 4.6 | Audit Logs | `P` | `P` |
