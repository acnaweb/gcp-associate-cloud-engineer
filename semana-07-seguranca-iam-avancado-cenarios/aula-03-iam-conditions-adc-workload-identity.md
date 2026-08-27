# Aula 3 — IAM Conditions, ADC e Workload Identity Federation

## Objetivos

Ao final desta aula, você deverá:

- Entender IAM Conditions;
- Entender ADC;
- Praticar credenciais locais sem key;
- Compreender Workload Identity Federation;

---

# 1. Modelo mental

```text
IAM Binding + Condition
ADC → procura credenciais padrão
External identity → WIF → short-lived Google credentials
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

### IAM Condition (exemplo conceitual)
```bash
gcloud projects add-iam-policy-binding $(gcloud config get-value project) \
  --member="user:SEU_EMAIL" \
  --role="roles/viewer" \
  --condition="expression=request.time < timestamp('2027-01-01T00:00:00Z'),title=temporary-viewer"
```

> Use apenas com uma identidade de laboratório e remova depois.

### ADC
```bash
gcloud auth application-default login
gcloud auth application-default print-access-token | head -c 20
echo
```

Explique a diferença:
```text
gcloud auth login
→ identidade para CLI

gcloud auth application-default login
→ credenciais para bibliotecas que usam ADC
```

### Workload Identity Federation
Laboratório de arquitetura:
```text
AWS/Azure/GitHub/OIDC
       ↓
Workload Identity Pool/Provider
       ↓
credencial curta
       ↓
Google Cloud API
```
Evite criar key JSON apenas para demonstrar acesso externo.

---

# 4. Testes e falhas propositais

- Condition com expressão errada pode bloquear acesso esperado.
- ADC não significa 'uma conta fixa': é estratégia de descoberta de credenciais.
- WIF remove necessidade de key persistente para identidades externas compatíveis.

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

- IAM Conditions adicionam contexto ao binding.
- ADC é mecanismo de descoberta.
- WIF é federação sem SA key de longa duração.

---

# 7. Questões estilo ACE

- GitHub Actions precisa acessar GCP sem JSON key. Melhor padrão? → Workload Identity Federation.
- App local usa client library: ADC é padrão comum.

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

