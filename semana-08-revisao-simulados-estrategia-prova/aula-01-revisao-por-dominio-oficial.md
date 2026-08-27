# Aula 1 — Revisão por Domínio Oficial

## Objetivos

Ao final desta aula, você deverá:

- Revisar domínios ACE por ação prática;
- Detectar lacunas;
- Executar comandos-chave sem consulta;

---

# 1. Modelo mental

```text
ACE
 ├─ Set up cloud solution environment
 ├─ Plan/configure cloud solution
 ├─ Deploy/implement
 └─ Ensure successful operation
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

Faça um circuito de 45–60 minutos:

```bash
# contexto
gcloud config list

# IAM
gcloud projects get-iam-policy $(gcloud config get-value project)

# compute
gcloud compute instances list

# networking
gcloud compute networks list
gcloud compute firewall-rules list
gcloud compute routes list

# storage
gcloud storage buckets list

# Cloud Run/GKE
gcloud run services list --region=us-central1
gcloud container clusters list

# operations
gcloud logging read 'severity>=ERROR' --limit=5

# quotas
gcloud compute project-info describe --format='yaml(quotas)'
```

Para cada domínio, escreva:
```text
Consigo fazer sem consultar?
Consigo diagnosticar?
Consigo explicar por que escolhi o serviço?
```

---

# 4. Testes e falhas propositais

- Não revise apenas definições: pratique decisões.
- Marque erros por categoria e volte à aula correspondente.
- Uma questão pode misturar IAM + rede + operação.

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

- A prova cobra execução e julgamento operacional.
- Prefira solução gerenciada e mínima que atende requisito.
- Leia verbos: create, grant, troubleshoot, migrate, monitor.

---

# 7. Questões estilo ACE

- Cenário pede ação mais simples e segura: elimine opções amplas/manuais sem necessidade.
- Erro de permissão não é resolvido com mudança de rede.

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

