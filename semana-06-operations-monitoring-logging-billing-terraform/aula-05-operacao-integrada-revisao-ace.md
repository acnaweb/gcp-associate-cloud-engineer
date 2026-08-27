# Aula 5 — Operação Integrada e Revisão ACE

## Objetivos

Ao final desta aula, você deverá:

- Praticar fluxo operacional completo;
- Classificar falha IAM/rede/quota/app;
- Usar describe/logging/monitoring;
- Treinar decisão ACE;

---

# 1. Modelo mental

```text
Sintoma
  ↓
Recurso/status
  ↓
IAM
  ↓
rede
  ↓
quota
  ↓
logs/metrics
  ↓
ação corretiva
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

### Caso integrado
Crie VM:
```bash
gcloud compute instances create ace-ops-vm \
  --zone=us-central1-a --machine-type=e2-micro \
  --image-family=debian-12 --image-project=debian-cloud
```

Checklist operacional:
```bash
gcloud compute instances describe ace-ops-vm --zone=us-central1-a
gcloud compute firewall-rules list
gcloud compute routes list
gcloud logging read 'resource.type="gce_instance"' --limit=10
gcloud compute project-info describe --format="yaml(quotas)"
```

Agora provoque uma falha por vez:
1. VM STOPPED.
2. firewall ausente.
3. serviço nginx parado.
4. principal sem role.
5. quota hipotética/real atingida.

Para cada falha, registre:
```text
Sintoma
Hipótese
Comando de evidência
Correção
Prevenção
```

---

# 4. Testes e falhas propositais

- Não altere três coisas ao mesmo tempo.
- Leia mensagem de erro antes de escalar privilégio.
- 403 → IAM/auth; timeout → rede/serviço; RESOURCE_EXHAUSTED → quota/capacidade.

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

- Troubleshooting ACE é seleção da ação mínima correta.
- Least privilege também vale em incidentes.
- Logs + metrics + resource describe formam triângulo operacional útil.

---

# 7. Questões estilo ACE

- 403 ao acessar bucket: primeiro verificar IAM, não firewall.
- VM sem resposta externa: status, IP/rota/firewall/serviço.

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

