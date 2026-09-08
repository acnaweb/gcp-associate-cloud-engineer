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


# 11. Refinamento prático — custo e CMEK

## Laboratório — estimar custos de Cloud Storage com cenários comparáveis

O objetivo não é decorar preços. Preços variam por localização, classe e data. O objetivo é aprender **quais variáveis entram na estimativa** e comparar cenários de maneira reproduzível.

### Modelo de custo

```text
Custo estimado
=
armazenamento em repouso
+ operações
+ recuperação de dados (quando aplicável)
+ transferência de rede (quando aplicável)
+ efeito da duração mínima de armazenamento
```

### Cenário

Compare 100 GiB mantidos por 30 dias em quatro alternativas:

```text
Standard
Nearline
Coldline
Archive
```

Considere dois padrões de acesso:

```text
Cenário A — dados ativos
100 GiB armazenados
50 GiB recuperados no mês
muitas leituras

Cenário B — arquivo
100 GiB armazenados
0 GiB recuperados no mês
poucas operações
```

### 1. Colete os parâmetros do cenário

```bash
# Explicação: Define o volume lógico que será usado para comparar as classes.
export STORAGE_GIB=100

# Explicação: Define o volume de recuperação do cenário A.
export RETRIEVAL_GIB_ACTIVE=50

# Explicação: Define o volume de recuperação do cenário B.
export RETRIEVAL_GIB_ARCHIVE=0

# Explicação: Exibe os parâmetros para evitar comparar cenários com premissas diferentes.
printf 'Storage=%s GiB | retrieval-active=%s GiB | retrieval-archive=%s GiB\n' \
  "$STORAGE_GIB" "$RETRIEVAL_GIB_ACTIVE" "$RETRIEVAL_GIB_ARCHIVE"
```

### 2. Use a Google Cloud Pricing Calculator

Na Pricing Calculator oficial:

1. adicione **Cloud Storage**;
2. use a mesma localização para todas as alternativas;
3. informe `100 GiB`;
4. calcule Standard, Nearline, Coldline e Archive separadamente;
5. adicione recuperação/operações quando o cenário exigir;
6. salve ou anote o custo mensal estimado;
7. compare o resultado com o padrão de acesso.

Preencha:

| Classe | Cenário A — ativo | Cenário B — arquivo | Observação |
|---|---:|---:|---|
| Standard | | | |
| Nearline | | | |
| Coldline | | | |
| Archive | | | |

### 3. Interprete

Não escolha automaticamente a classe com menor preço de armazenamento.

```text
Classe mais barata em repouso
      +
retrieval frequente
      +
minimum storage duration
      ↓
pode custar mais no cenário real
```

### Teste de prova

Uma empresa lê os objetos várias vezes por dia. Qual classe deve ser avaliada primeiro?

**Resposta:** Standard. O padrão de acesso frequente pesa mais do que o menor preço nominal de armazenamento de classes frias.

---

## Laboratório — CMEK com Cloud KMS e Cloud Storage

Por padrão, o Cloud Storage já criptografa os dados em repouso com chaves gerenciadas pelo Google. Use **CMEK** quando o requisito exige que a organização controle a chave, rotação, acesso e ciclo de vida no Cloud KMS.

### Arquitetura mental

```text
Usuário grava objeto
      ↓
Cloud Storage
      ↓
Cloud Storage service agent
      ↓ usa
Cloud KMS CryptoKey
      ↓
objeto protegido com CMEK
```

### 1. Variáveis e APIs

```bash
# Explicação: Obtém o projeto ativo.
export PROJECT_ID="$(gcloud config get-value project)"

# Explicação: Obtém o número do projeto; ele compõe o e-mail do service agent do Cloud Storage.
export PROJECT_NUMBER="$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')"

# Explicação: Usa a mesma região para bucket e chave KMS neste laboratório.
export REGION=us-central1
export KEYRING=ace-storage-ring
export KEY=ace-storage-key
export BUCKET="gs://${PROJECT_ID}-ace-cmek-${PROJECT_NUMBER}"
export STORAGE_SERVICE_AGENT="service-${PROJECT_NUMBER}@gs-project-accounts.iam.gserviceaccount.com"

# Explicação: Habilita Cloud KMS e Cloud Storage APIs.
gcloud services enable cloudkms.googleapis.com storage.googleapis.com
```

### 2. Crie KeyRing e CryptoKey

```bash
# Explicação: Cria o KeyRing que agrupa as chaves KMS na localização escolhida.
gcloud kms keyrings create "$KEYRING" \
  --location="$REGION"

# Explicação: Cria uma chave simétrica com finalidade de criptografia.
gcloud kms keys create "$KEY" \
  --keyring="$KEYRING" \
  --location="$REGION" \
  --purpose=encryption
```

### 3. Autorize o service agent do Cloud Storage

```bash
# Explicação: Permite que o service agent do Cloud Storage use a chave para criptografar e descriptografar objetos.
gcloud kms keys add-iam-policy-binding "$KEY" \
  --keyring="$KEYRING" \
  --location="$REGION" \
  --member="serviceAccount:${STORAGE_SERVICE_AGENT}" \
  --role="roles/cloudkms.cryptoKeyEncrypterDecrypter"
```

### 4. Crie o bucket e configure a chave padrão

```bash
# Explicação: Cria o bucket na mesma região usada pela chave neste laboratório.
gcloud storage buckets create "$BUCKET" \
  --location="$REGION" \
  --uniform-bucket-level-access

# Explicação: Monta o nome completo do recurso CryptoKey.
export KMS_KEY="projects/${PROJECT_ID}/locations/${REGION}/keyRings/${KEYRING}/cryptoKeys/${KEY}"

# Explicação: Define a CMEK como chave padrão para novos objetos gravados no bucket.
gcloud storage buckets update "$BUCKET" \
  --default-encryption-key="$KMS_KEY"
```

### 5. Inspecione

```bash
# Explicação: Mostra a configuração do bucket; procure o campo da chave KMS padrão.
gcloud storage buckets describe "$BUCKET"

# Explicação: Mostra a política IAM da CryptoKey para confirmar o service agent autorizado.
gcloud kms keys get-iam-policy "$KEY" \
  --keyring="$KEYRING" \
  --location="$REGION"
```

### 6. Teste positivo

```bash
# Explicação: Cria um objeto local de teste.
echo 'conteudo protegido por CMEK' > /tmp/ace-cmek.txt

# Explicação: Faz upload; como o bucket possui default encryption key, o novo objeto usa a CMEK.
gcloud storage cp /tmp/ace-cmek.txt "$BUCKET/ace-cmek.txt"

# Explicação: Inspeciona os metadados do objeto para confirmar a chave KMS associada.
gcloud storage objects describe "$BUCKET/ace-cmek.txt"
```

### 7. Quebrar propositalmente — remover o acesso do service agent

```bash
# Explicação: Remove exatamente a permissão que o Cloud Storage precisa para usar a CryptoKey.
gcloud kms keys remove-iam-policy-binding "$KEY" \
  --keyring="$KEYRING" \
  --location="$REGION" \
  --member="serviceAccount:${STORAGE_SERVICE_AGENT}" \
  --role="roles/cloudkms.cryptoKeyEncrypterDecrypter"

# Explicação: Tenta gravar um novo objeto; a operação deve falhar por falta de acesso à chave.
echo 'falha esperada' > /tmp/ace-cmek-falha.txt
gcloud storage cp /tmp/ace-cmek-falha.txt "$BUCKET/falha.txt"
```

### Troubleshooting

```text
Sintoma
upload falha
      ↓
Hipótese
Cloud Storage não consegue usar a CMEK
      ↓
Evidência
IAM policy da CryptoKey não contém o service agent
      ↓
Causa
roles/cloudkms.cryptoKeyEncrypterDecrypter removida
      ↓
Correção
restaurar o binding
```

```bash
# Explicação: Confirma a ausência do principal esperado na política da chave.
gcloud kms keys get-iam-policy "$KEY" \
  --keyring="$KEYRING" \
  --location="$REGION"

# Explicação: Restaura o acesso do Cloud Storage service agent à chave.
gcloud kms keys add-iam-policy-binding "$KEY" \
  --keyring="$KEYRING" \
  --location="$REGION" \
  --member="serviceAccount:${STORAGE_SERVICE_AGENT}" \
  --role="roles/cloudkms.cryptoKeyEncrypterDecrypter"
```

### 8. Cleanup

```bash
# Explicação: Remove objetos e bucket para encerrar cobrança de armazenamento.
gcloud storage rm --recursive "$BUCKET"

# Explicação: Remove arquivos locais temporários.
rm -f /tmp/ace-cmek.txt /tmp/ace-cmek-falha.txt
```

> KeyRings e CryptoKeys não são recursos que você simplesmente exclui como buckets. Para laboratório, evite criar chaves desnecessárias. Versões de chave têm ciclo de vida próprio e destruição deve ser tratada com cuidado.
