# Aula 1 — IAM Avançado, Herança e Roles

## Objetivos

Ao final desta aula, você deverá:

- Entender herança;
- Comparar basic/predefined/custom;
- Inspecionar policies;
- Praticar role customizada em projeto;

---

# 1. Modelo mental

```text
Organization
  ↓ policy herdada
Folder
  ↓
Project
  ↓
Resource

Permissões efetivas = grants aplicáveis + herança
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
gcloud projects get-iam-policy $PROJECT_ID
gcloud iam roles list --filter="name:storage"
```

Crie role customizada de laboratório:
```bash
cat > role.yaml <<'EOF'
title: "ACE Bucket Metadata Reader"
description: "Lab role"
stage: "GA"
includedPermissions:
- storage.buckets.get
- storage.buckets.list
EOF

gcloud iam roles create aceBucketMetadataReader \
  --project=$PROJECT_ID \
  --file=role.yaml

gcloud iam roles describe aceBucketMetadataReader \
  --project=$PROJECT_ID
```

> Custom role exige permissões administrativas adequadas.

---

# 4. Testes e falhas propositais

- Conceder role no projeto pode afetar todos os recursos do projeto compatíveis.
- IAM grants são cumulativos; uma role restrita não 'nega' uma role ampla já concedida.
- Custom role deve ser usada quando predefined não atende.

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

- Basic roles são amplas.
- Predefined roles são preferidas.
- Herança flui da hierarquia para baixo.
- IAM tradicional é allow-based; deny policies são mecanismo separado.

---

# 7. Questões estilo ACE

- Precisa conjunto exato não coberto por predefined? → custom role.
- Usuário já é Editor e recebeu Viewer: continua com privilégios de Editor.

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

