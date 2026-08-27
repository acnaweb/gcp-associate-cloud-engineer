# Aula 5 — Checklist Final e Plano Pré-Prova

## Objetivos

Ao final desta aula, você deverá:

- Validar prontidão;
- Criar plano de revisão;
- Repetir labs críticos;
- Evitar estudo caótico na véspera;

---

# 1. Modelo mental

```text
Lacunas
  ↓ labs dirigidos
  ↓ simulado
  ↓ análise de erros
  ↓ revisão final
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

### Checklist hands-on mínimo
Execute ou explique sem consultar:

```text
[ ] criar/configurar projeto/contexto gcloud
[ ] criar VM e operar start/stop/reset
[ ] disk + snapshot
[ ] VPC/subnet/firewall/route
[ ] Cloud NAT/PGA/DNS
[ ] MIG + health check + LB
[ ] bucket + IAM + lifecycle
[ ] Cloud SQL/BigQuery escolha e operação básica
[ ] Artifact Registry + Cloud Run
[ ] GKE kubectl básico
[ ] Monitoring/Logging
[ ] quota/budget
[ ] Terraform init/plan/apply/destroy
[ ] SA + impersonation + least privilege
```

### Plano pré-prova
- D-7 a D-4: repetir labs onde errou.
- D-3: simulado completo.
- D-2: revisar erros, IAM e networking.
- D-1: revisão leve; não abrir novos temas.
- Dia da prova: validar horário/documentos/regras e chegar com margem.

### Critério objetivo
Você está pronto quando:
1. acerta consistentemente simulados;
2. explica por que alternativas erradas estão erradas;
3. executa comandos fundamentais sem copiar receita;
4. distingue rapidamente IAM, rede, quota, aplicação e serviço inadequado.

---

# 4. Testes e falhas propositais

- Não decore só gcloud; entenda o recurso.
- Evite estudar produto fora do escopo sacrificando fundamentos.
- Sono e leitura cuidadosa têm impacto real em prova de cenário.

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

- Revisão final deve ser baseada em erros reais.
- IAM + networking + compute + operações merecem prioridade alta.
- Prática é melhor que releitura passiva.

---

# 7. Questões estilo ACE

- Se você não consegue explicar por que a opção errada está errada, ainda há lacuna.
- Última revisão deve consolidar, não expandir.

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

