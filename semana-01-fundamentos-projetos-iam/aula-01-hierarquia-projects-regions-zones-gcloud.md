# Aula 1 — Hierarquia, Projects, Regions, Zones e gcloud

## Objetivos

Ao final desta aula, você deverá:

- Navegar pela hierarquia de recursos;
- Diferenciar Project ID e Project Number;
- Criar e alternar gcloud configurations;
- Habilitar APIs e inspecionar regions/zones;

---

# 1. Modelo mental

```text
Organization (quando existir)
  └─ Folder
      └─ Project
          └─ Resources

gcloud configuration
  ├─ account
  ├─ project
  ├─ region
  └─ zone
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

### 1. Identifique sua conta e projeto
```bash
gcloud auth list
gcloud projects list
gcloud config get-value project
gcloud projects describe $(gcloud config get-value project)
```

### 2. Crie uma configuration isolada
```bash
export PROJECT_ID=$(gcloud config get-value project)

gcloud config configurations create ace-fundamentos-lab
gcloud config configurations activate ace-fundamentos-lab
gcloud config set project $PROJECT_ID
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a
gcloud config list
```

### 3. Compare ID e Number
```bash
gcloud projects describe $PROJECT_ID \
  --format="table(projectId,projectNumber,name)"
```

### 4. Explore regiões e zonas
```bash
gcloud compute regions list
gcloud compute zones list --filter="region:us-central1"
```

### 5. APIs
```bash
gcloud services list --enabled
gcloud services enable compute.googleapis.com
gcloud services list --enabled --filter="NAME:compute.googleapis.com"
```

> API desabilitada = recurso pode existir no catálogo do Google Cloud, mas o projeto não pode usar aquela API até habilitá-la.

---

# 4. Testes e falhas propositais

- Ative uma configuration sem projeto e execute um comando para observar o erro/contexto faltante.
- Defina uma zona inválida e compare com `gcloud compute zones list`.
- Desabilitar APIs pode afetar recursos existentes; não faça isso em projeto compartilhado.

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

- Configuration não é Project.
- Project ID é string globalmente única; Project Number é numérico.
- Region contém zones; subnet é regional e VM geralmente zonal.
- Habilitar uma API não cria automaticamente recursos.

---

# 7. Questões estilo ACE

- Você precisa manter contexts dev e lab no mesmo computador. Qual recurso do gcloud ajuda? → configurations.
- Uma VM deve ficar próxima de usuários de determinada localidade. O primeiro critério é escolher region/zone adequadas.

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

