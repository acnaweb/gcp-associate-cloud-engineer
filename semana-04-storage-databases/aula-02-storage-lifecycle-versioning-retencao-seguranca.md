# Aula 2 — Lifecycle, Versioning, Retenção e Segurança no Storage

## Objetivos

Ao final desta aula, você deverá:

- Habilitar versioning;
- Criar lifecycle rule;
- Entender retention policy;
- Praticar IAM no bucket;

---

# 1. Modelo mental

```text
Objeto
 ├─ versões
 ├─ lifecycle
 ├─ retention policy
 └─ IAM
```

O objetivo desta aula não é apenas reconhecer nomes de serviços. Você deve conseguir **criar, inspecionar, testar e explicar** o comportamento dos recursos.

---

# 2. Regra de estudo da aula

Use sempre este ciclo:

```text
Conceito
   ↓
Criar
   ↓
Inspecionar
   ↓
Testar
   ↓
Quebrar propositalmente
   ↓
Diagnosticar
   ↓
Corrigir
   ↓
Remover
```

---

# 3. Laboratório principal

```bash
export PROJECT_ID=$(gcloud config get-value project)
export BUCKET=gs://$PROJECT_ID-ace-storage-sec-$RANDOM
gcloud storage buckets create $BUCKET --location=us-central1

gcloud storage buckets update $BUCKET --versioning
echo v1 > dado.txt
gcloud storage cp dado.txt $BUCKET/dado.txt
echo v2 > dado.txt
gcloud storage cp dado.txt $BUCKET/dado.txt

gcloud storage ls --all-versions $BUCKET
```

Lifecycle:
```bash
cat > lifecycle.json <<'EOF'
{
  "rule": [{
    "action": {"type": "Delete"},
    "condition": {"age": 30}
  }]
}
EOF

gcloud storage buckets update $BUCKET \
  --lifecycle-file=lifecycle.json
```

Retention:
```bash
gcloud storage buckets update $BUCKET \
  --retention-period=86400
gcloud storage buckets describe $BUCKET
```

---

# 4. Testes e falhas propositais

- Tente deletar um objeto ainda protegido por retention policy e observe bloqueio.
- Versioning não é o mesmo que retention.
- Lifecycle automatiza ações; não é backup por si só.

Para cada falha, não corrija imediatamente. Primeiro registre:

```text
Sintoma:
Hipótese:
Comando/evidência:
Causa:
Correção:
```

---

# 5. Troubleshooting

Use este fluxo:

```text
1. O recurso existe e está no estado esperado?
2. O escopo (project/region/zone) está correto?
3. A identidade/principal está correta?
4. IAM permite a operação?
5. Rede/rota/firewall permitem comunicação, quando aplicável?
6. A aplicação/serviço está saudável?
7. Há quota/capacidade suficiente?
8. Logs e métricas confirmam a hipótese?
```

Comandos-base:

```bash
gcloud config list
gcloud auth list
gcloud projects describe $(gcloud config get-value project)
gcloud logging read 'severity>=ERROR' --limit=10
```

---

# 6. Pegadinhas ACE

- Retention pode impedir exclusão até prazo.
- Lock de retention é decisão séria/irreversível em certos contextos: não faça no lab.
- Uniform bucket-level access simplifica IAM ao nível do bucket.

---

# 7. Questões estilo ACE

- Precisa impedir exclusão antes de 7 anos? → retention policy.
- Quer apagar objetos antigos automaticamente? → lifecycle management.

---

# 8. Checklist

- [ ] Consigo explicar o modelo mental da aula;
- [ ] Executei o laboratório;
- [ ] Inspecionei os recursos com `describe/list`;
- [ ] Provoquei ao menos uma falha;
- [ ] Diagnostiquei antes de corrigir;
- [ ] Consigo justificar a escolha do serviço;
- [ ] Consigo explicar as pegadinhas ACE;
- [ ] Fiz o cleanup.

---

# 9. O que memorizar

Não memorize apenas comandos. Memorize a relação:

```text
Requisito
   ↓
Serviço/recurso correto
   ↓
Escopo correto
   ↓
Permissão correta
   ↓
Operação correta
   ↓
Troubleshooting com evidência
```

Essa é a forma de raciocínio mais útil para o Associate Cloud Engineer.

