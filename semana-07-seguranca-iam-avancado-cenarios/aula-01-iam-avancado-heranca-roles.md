# Aula 1 — IAM Avançado, Herança e Roles

## Objetivos

Ao final, você deverá:
- entender herança;
- comparar basic, predefined e custom roles;
- criar custom role de laboratório;
- entender grants cumulativos;
- diagnosticar excesso de privilégio por escopo.


---

# 1. Conceito

Policies aplicadas em níveis superiores da hierarquia podem ser herdadas. Roles agrupam permissions. Grants são cumulativos; adicionar role restrita não remove outra ampla.

## Arquitetura mental

```text
Organization
  ↓
Folder
  ↓
Project
  ↓
Resource

principal + role + scope = grant
```

---

# 2. Criar

```bash
export PROJECT_ID=$(gcloud config get-value project)

cat > role.yaml <<'EOF'
title: "ACE Bucket Metadata Reader"
description: "Role de laboratório"
stage: "GA"
includedPermissions:
- storage.buckets.get
- storage.buckets.list
EOF

gcloud iam roles create aceBucketMetadataReader \
  --project="$PROJECT_ID" \
  --file=role.yaml
```

---

# 3. Inspecionar

Antes de provocar qualquer erro, confirme a configuração criada. O troubleshooting desta aula usará **somente elementos que você já observou aqui**.

```bash
gcloud iam roles describe aceBucketMetadataReader \
  --project="$PROJECT_ID"

gcloud projects get-iam-policy "$PROJECT_ID"
```

---

# 4. Testar

Compare:

```bash
gcloud iam roles describe roles/storage.admin
gcloud iam roles describe roles/storage.objectViewer
gcloud iam roles describe aceBucketMetadataReader \
  --project="$PROJECT_ID"
```

---

# 5. Quebrar propositalmente

Falha de decisão:

> “Para resolver leitura de objetos, concedi `roles/storage.admin` no projeto inteiro.”

Liste por que isso amplia **ações** e **escopo** além do necessário.

---

# 6. Troubleshooting

Agora o erro já foi produzido e os componentes envolvidos já foram apresentados.

**Sintoma:** solução funciona, mas viola least privilege.

**Hipótese:** role e/ou scope são amplos.

**Evidência:** `gcloud iam roles describe` revela permissions e `get-iam-policy` revela escopo do binding.

**Causa:** escolha de `Storage Admin` em projeto inteiro para necessidade de leitura.

**Correção:** escolher role mínima e escopo mais restrito, por exemplo bucket.

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

Para exercícios, prefira:
```text
necessidade: ler objetos
role: roles/storage.objectViewer
scope: bucket específico
```

Não é necessário aplicar binding amplo só para provar o conceito.

---

# 8. Questões estilo ACE

1. Custom role quando predefined atende? **Prefira predefined**.
2. Grants IAM são cumulativos? **Sim**.
3. Role menor “anula” Owner já concedido? **Não**.

---

# 9. Cleanup

```bash
gcloud iam roles delete aceBucketMetadataReader \
  --project="$PROJECT_ID"
rm -f role.yaml
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

---

# Revisão obrigatória — Basic, Predefined e Custom Roles

A prova cita explicitamente os três tipos.

```bash
gcloud iam roles describe roles/viewer
gcloud iam roles describe roles/editor
gcloud iam roles describe roles/owner
gcloud iam roles describe roles/compute.viewer
gcloud iam roles describe roles/compute.admin
gcloud iam roles list --project="$(gcloud config get-value project)"
```

O aluno deve conseguir responder:

```text
Viewer/Editor/Owner → Basic roles
Compute Viewer      → Predefined role
aceMinhaRole        → Custom role
```

E também explicar que **role contém permissions**; binding associa principal + role em um resource/scope.
