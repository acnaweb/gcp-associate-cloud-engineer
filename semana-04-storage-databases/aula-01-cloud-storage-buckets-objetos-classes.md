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
# Explicação: Define `PROJECT_ID` com o ID do projeto Google Cloud usado pelos comandos seguintes.
export PROJECT_ID=$(gcloud config get-value project)
# Explicação: Define `BUCKET` com o nome do bucket usado no laboratório.
export BUCKET="gs://$PROJECT_ID-ace-storage-$RANDOM"

# Explicação: Cria um bucket Cloud Storage com localização e opções informadas.
gcloud storage buckets create "$BUCKET" \
  --location=us-central1 \
  --default-storage-class=STANDARD

# Explicação: Exibe ou grava o valor/texto informado, normalmente para validar variável ou criar conteúdo de teste.
echo "arquivo 1" > arquivo.txt
# Explicação: Copia arquivo(s) entre o ambiente local e Cloud Storage, ou entre localizações no Cloud Storage.
gcloud storage cp arquivo.txt "$BUCKET/"
```

---

# 3. Inspecionar

Antes de provocar qualquer erro, confirme a configuração criada. O troubleshooting desta aula usará **somente elementos que você já observou aqui**.

```bash
# Explicação: Exibe propriedades do bucket, como localização, storage class, versioning e políticas.
gcloud storage buckets describe "$BUCKET"
# Explicação: Lista buckets/objetos; flags podem incluir versões antigas e detalhes adicionais.
gcloud storage ls -L "$BUCKET"
# Explicação: Exibe metadados de um objeto Cloud Storage, como geração, tamanho e storage class.
gcloud storage objects describe "$BUCKET/arquivo.txt"
```

---

# 4. Testar

```bash
# Explicação: Lê o conteúdo de um objeto do Cloud Storage diretamente no terminal.
gcloud storage cat "$BUCKET/arquivo.txt"
# Explicação: Copia arquivo(s) entre o ambiente local e Cloud Storage, ou entre localizações no Cloud Storage.
gcloud storage cp "$BUCKET/arquivo.txt" "$BUCKET/copia.txt"

# Explicação: Atualiza metadados/configurações suportadas do objeto Cloud Storage.
gcloud storage objects update "$BUCKET/copia.txt" \
  --storage-class=NEARLINE

# Explicação: Exibe metadados de um objeto Cloud Storage, como geração, tamanho e storage class.
gcloud storage objects describe "$BUCKET/copia.txt"
```

---

# 5. Quebrar propositalmente

Tente acessar um nome errado:

```bash
# Explicação: Lê o conteúdo de um objeto do Cloud Storage diretamente no terminal.
gcloud storage cat "$BUCKET/arquivo-inexistente.txt"
```

---

# 6. Troubleshooting

Agora o erro já foi produzido e os componentes envolvidos já foram apresentados.

**Sintoma:** objeto não encontrado.

**Hipótese:** o bucket existe, mas o object name está incorreto.

**Evidências:**
```bash
# Explicação: Exibe propriedades do bucket, como localização, storage class, versioning e políticas.
gcloud storage buckets describe "$BUCKET"
# Explicação: Lista buckets/objetos; flags podem incluir versões antigas e detalhes adicionais.
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
# Explicação: Lê o conteúdo de um objeto do Cloud Storage diretamente no terminal.
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
# Explicação: Remove objeto(s) do Cloud Storage conforme o caminho/padrão informado.
gcloud storage rm "$BUCKET/**"
# Explicação: Exclui o bucket; ele precisa estar vazio ou ser removido recursivamente conforme o comando.
gcloud storage buckets delete "$BUCKET" --quiet
# Explicação: Remove o arquivo/diretório temporário indicado durante correção ou cleanup.
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
# Explicação: Exibe ou grava o valor/texto informado, normalmente para validar variável ou criar conteúdo de teste.
echo nearline > nearline.txt
# Explicação: Copia arquivo(s) entre o ambiente local e Cloud Storage, ou entre localizações no Cloud Storage.
gcloud storage cp nearline.txt "$BUCKET/nearline.txt" --additional-headers=x-goog-storage-class:NEARLINE

# Explicação: Atualiza metadados/configurações suportadas do objeto Cloud Storage.
gcloud storage objects update "$BUCKET/arquivo.txt" --storage-class=COLDLINE
# Explicação: Exibe metadados de um objeto Cloud Storage, como geração, tamanho e storage class.
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

---

<!-- MEP-ACCEPTANCE-V9 -->
# Critério de aceite M/E/P desta aula

> Esta seção não substitui o conteúdo acima; ela explicita o critério usado na auditoria da baseline v9.

Para um tópico ser classificado como `P` nesta baseline, não basta existir um comando. A aula precisa apresentar:

```text
conceito operacional
   ↓
configuração/comando
   ↓
inspeção
   ↓
teste ou comportamento observável
```

Quando a execução depender de Organization, privilégio administrativo, custo relevante ou infraestrutura especial, use `P*`.

## Tópicos do guia mapeados para esta aula

| Seção | Tópico | Esperado | Nível da matriz |
|---|---|---:|---:|
| 2.2 | Standard/Nearline/Coldline/Archive | `E` | `E/P` |
| 3.4 | Cloud Storage | `P` | `P` |
| 3.4 | Upload CLI / carga de GCS | `P` | `P` |
| 4.4 | Gerenciar/proteger objetos Storage | `P` | `P` |
| 4.4 | Estimar custo de storage | `P` | `E/P*` |
