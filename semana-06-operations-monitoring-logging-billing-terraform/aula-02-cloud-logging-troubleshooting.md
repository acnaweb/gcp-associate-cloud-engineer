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
gcloud logging read \
 'resource.type="gce_instance"' \
 --limit=20 \
 --format="table(timestamp,severity,logName)"

gcloud logging read \
 'logName:"cloudaudit.googleapis.com"' \
 --limit=20
```

---

# 4. Testar

Faça uma operação inválida:

```bash
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
gcloud compute instances list
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
gcloud compute instances delete ace-log-vm \
  --zone=us-central1-a --quiet
```

---

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
