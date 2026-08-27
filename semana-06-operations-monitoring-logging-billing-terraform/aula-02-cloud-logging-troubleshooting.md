# Aula 2 — Cloud Logging e Troubleshooting

## Objetivos

Ao final desta aula, você deverá:

- Usar Logs Explorer/gcloud logging;
- Filtrar logs;
- Criar falha e localizar causa;
- Entender log-based metric;

---

# 1. Modelo mental

```text
Workload ── logs ──> Cloud Logging
                      ├─ query
                      ├─ sinks
                      └─ log-based metrics
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

Gere logs com uma VM:
```bash
gcloud compute instances create ace-log-vm \
  --zone=us-central1-a \
  --machine-type=e2-micro \
  --image-family=debian-12 --image-project=debian-cloud
```

Leia audit logs recentes:
```bash
gcloud logging read \
  'resource.type="gce_instance"' \
  --limit=20 \
  --format="table(timestamp,severity,logName)"
```

Filtre erro:
```bash
gcloud logging read \
  'severity>=ERROR' \
  --limit=20
```

No Logs Explorer pratique:
```text
resource.type="gce_instance"
severity>=ERROR
```

Crie uma operação inválida/erro controlado e compare timestamp + principal + recurso nos Audit Logs.

---

# 4. Testes e falhas propositais

- Filtro muito amplo pode gerar ruído/custo/tempo.
- Logs de auditoria ajudam a responder 'quem fez o quê'.
- Log-based metric transforma ocorrência em métrica para alerting.

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

- Logging = eventos/registros; Monitoring = métricas/time series.
- Audit logs são essenciais em IAM/troubleshooting.
- Sink exporta logs para destinos suportados.

---

# 7. Questões estilo ACE

- Quem deletou VM? → Audit Logs.
- Contar ocorrências de mensagem ERROR e alertar? → log-based metric + alert.

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

