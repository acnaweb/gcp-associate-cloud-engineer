# Aula 4 — Spanner, Firestore e Bigtable

## Objetivos

Ao final desta aula, você deverá:

- Diferenciar Spanner, Firestore e Bigtable;
- Executar hands-on leve com Firestore quando possível;
- Relacionar padrões de dados aos serviços;

---

# 1. Modelo mental

```text
Relacional global/consistente → Spanner
Documentos serverless       → Firestore
Wide-column baixa latência  → Bigtable
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

### Laboratório de decisão (sem custos altos)
Crie uma matriz:
```text
Cenário                         Serviço
Banco relacional global         Spanner
App mobile/web documentos       Firestore
Telemetria por chave/tempo       Bigtable
```

### Firestore (se o projeto ainda não tiver database)
No Console: Firestore → Create database → Native mode.

Com `gcloud`:
```bash
gcloud firestore databases list
```

Use o console para criar uma collection `clientes` e documentos simples.

### Spanner: inspeção
```bash
gcloud spanner instances list
gcloud spanner databases list --instance=INSTANCE_ID 2>/dev/null || true
```

### Bigtable: inspeção
```bash
gcloud bigtable instances list
```

> Spanner/Bigtable podem gerar custo relevante; para ACE, a decisão correta de serviço é mais importante que provisionar clusters caros.

---

# 4. Testes e falhas propositais

- Escolha errada proposital: tente modelar consultas ad hoc analíticas em Bigtable e explique por que BigQuery é melhor.
- Firestore não é relacional.
- Spanner é relacional distribuído; não é simplesmente 'Cloud SQL maior'.

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

- Spanner: SQL + consistência + escala horizontal/global.
- Firestore: documentos e aplicações serverless.
- Bigtable: enorme throughput por chave, séries temporais/IoT.

---

# 7. Questões estilo ACE

- Milhões de eventos por device_id/time com baixa latência? → Bigtable.
- Banco relacional global horizontal? → Spanner.
- Documentos de app mobile? → Firestore.

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

