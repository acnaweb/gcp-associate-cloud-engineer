# Aula 1 — Cloud Storage: Buckets, Objetos e Classes

## Nível de cobertura M/E/P

```text
Storage Classes e seleção: E; bucket/object/classes em laboratório: P
```


## Objetivos

Ao final, você deverá:
- criar bucket;
- carregar, listar, ler e copiar objetos;
- entender localização e Storage Class;
- alterar a classe de um objeto;
- diagnosticar referência a objeto inexistente.


---

# 1. Conceito

Cloud Storage é object storage. Bucket é contêiner lógico com nome globalmente único e localização. Objeto é o dado armazenado; Storage Class expressa padrão de acesso/custo, não permissão.

## Arquitetura mental

```text
Bucket
 ├─ location
 ├─ default storage class
 └─ objects
```

---

# 2. Criar

```bash
export PROJECT_ID=$(gcloud config get-value project)
export BUCKET="gs://$PROJECT_ID-ace-storage-$RANDOM"

gcloud storage buckets create "$BUCKET" \
  --location=us-central1 \
  --default-storage-class=STANDARD

echo "arquivo 1" > arquivo.txt
gcloud storage cp arquivo.txt "$BUCKET/"
```

---

# 3. Inspecionar

Antes de provocar qualquer erro, confirme a configuração criada. O troubleshooting desta aula usará **somente elementos que você já observou aqui**.

```bash
gcloud storage buckets describe "$BUCKET"
gcloud storage ls -L "$BUCKET"
gcloud storage objects describe "$BUCKET/arquivo.txt"
```

---

# 4. Testar

```bash
gcloud storage cat "$BUCKET/arquivo.txt"
gcloud storage cp "$BUCKET/arquivo.txt" "$BUCKET/copia.txt"

gcloud storage objects update "$BUCKET/copia.txt" \
  --storage-class=NEARLINE

gcloud storage objects describe "$BUCKET/copia.txt"
```

---

# 5. Quebrar propositalmente

Tente acessar um nome errado:

```bash
gcloud storage cat "$BUCKET/arquivo-inexistente.txt"
```

---

# 6. Troubleshooting

Agora o erro já foi produzido e os componentes envolvidos já foram apresentados.

**Sintoma:** objeto não encontrado.

**Hipótese:** o bucket existe, mas o object name está incorreto.

**Evidências:**
```bash
gcloud storage buckets describe "$BUCKET"
gcloud storage ls "$BUCKET"
```

**Causa:** o nome usado não corresponde a nenhum objeto listado.

Não investigue IAM quando a própria listagem feita pelo mesmo principal confirma acesso e revela o nome correto.

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

Use o object name correto:

```bash
gcloud storage cat "$BUCKET/arquivo.txt"
```

---

# 8. Questões estilo ACE

1. Storage Class define autorização? **Não**.
2. Bucket name é único em qual escopo? **Global**.
3. Arquivo acessado frequentemente? **STANDARD**, em geral.

---

# 9. Cleanup

```bash
gcloud storage rm "$BUCKET/**"
gcloud storage buckets delete "$BUCKET" --quiet
rm -f arquivo.txt
```

---


---

# Cobertura ACE ampliada — Storage Classes, localização e custo

## Storage Classes

O exam guide cita explicitamente **Standard, Nearline, Coldline e Archive**.

| Classe | Perfil de acesso | Duração mínima típica | Exemplo |
|---|---|---:|---|
| **Standard** | Frequente | sem mínimo de classe fria | dados ativos, aplicações, analytics |
| **Nearline** | Aproximadamente mensal ou menos | 30 dias | backups mensais |
| **Coldline** | Aproximadamente trimestral ou menos | 90 dias | disaster recovery |
| **Archive** | Muito raro | 365 dias | retenção de longo prazo/compliance |

> Valores de preço mudam por região e operação. Para prova, foque no **padrão de acesso, duração mínima e retrieval/operation costs**, não em decorar preço.

Modelo mental:

```text
Acesso frequente        → Standard
~ mensal                → Nearline
~ trimestral            → Coldline
muito raro/longo prazo  → Archive
```

## Retrieval e minimum storage duration

Escolher a classe mais barata por GB pode sair mais caro se o objeto for recuperado frequentemente ou removido antes do período mínimo aplicável.

Considere:

```text
storage cost
+ retrieval cost
+ operation cost
+ minimum storage duration
+ access frequency
```

## Autoclass

Autoclass pode gerenciar automaticamente transições de classes para objetos do bucket conforme padrões e regras do recurso. Ele é útil quando o padrão de acesso é variável e você quer reduzir gerenciamento manual.

> Autoclass é relevante para prática/arquitetura, mesmo que o exam guide liste nominalmente as quatro classes principais.

## Localização

Diferencie:

```text
Region       → uma região
Dual-region  → duas regiões específicas suportadas
Multi-region → área geográfica ampla
```

Localização influencia latência, redundância, disponibilidade e custo.

## Laboratório adicional

Crie objetos com classes diferentes:

```bash
echo nearline > nearline.txt
gcloud storage cp nearline.txt "$BUCKET/nearline.txt" --additional-headers=x-goog-storage-class:NEARLINE

gcloud storage objects update "$BUCKET/arquivo.txt" --storage-class=COLDLINE
gcloud storage objects describe "$BUCKET/arquivo.txt"
```

Use `describe` e identifique `storageClass`.

## Questões adicionais

1. Dados acessados várias vezes por dia? **Standard**.
2. Backup acessado aproximadamente uma vez por mês? **Nearline**.
3. DR raramente acessado? **Coldline**, conforme frequência/retenção.
4. Arquivamento de anos? **Archive**.
5. Padrão imprevisível e desejo de automação de classes? Avalie **Autoclass**.

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