# Aula 1 — Cloud Storage: Buckets, Objetos e Classes

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
