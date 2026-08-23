# Aula 1 — Cloud Storage: Buckets, Objetos e Classes

## Objetivos

Ao final desta aula, você deverá:

- Entender Cloud Storage;
- Diferenciar bucket e objeto;
- Criar buckets e enviar arquivos;
- Entender classes de armazenamento;
- Escolher a classe adequada para frequência de acesso.

---

# 1. O que é Cloud Storage?

Cloud Storage é o serviço de armazenamento de objetos do Google Cloud.

```text
Bucket
  │
  ├── arquivo.csv
  ├── imagem.jpg
  ├── backup.zip
  └── logs.json
```

Ele não é um filesystem tradicional nem um banco de dados.

---

# 2. Bucket x Object

## Bucket

É o contêiner lógico onde os objetos são armazenados.

## Object

É o conteúdo armazenado dentro do bucket.

Exemplo:

```text
gs://ace-lab-storage/dados/clientes.csv
```

Onde:

```text
ace-lab-storage → bucket
dados/clientes.csv → nome do objeto
```

---

# 3. Localização do Bucket

Buckets podem ser criados em diferentes tipos de localização.

Para o ACE, entenda principalmente:

- Region;
- Dual-region;
- Multi-region.

---

# 4. Classes de armazenamento

As classes principais são:

```text
Standard
Nearline
Coldline
Archive
```

Resumo:

| Classe | Acesso típico | Duração mínima |
|---|---|---:|
| Standard | Frequente | Nenhuma |
| Nearline | Aproximadamente mensal ou menos | 30 dias |
| Coldline | Aproximadamente trimestral ou menos | 90 dias |
| Archive | Raramente / arquivamento | 365 dias |

---

# 5. Standard

Use para dados acessados frequentemente.

Exemplos:

- Conteúdo ativo;
- Aplicações;
- Analytics;
- Dados recentes.

---

# 6. Nearline

Boa opção para dados acessados aproximadamente uma vez ao mês ou menos.

Exemplos:

- Backup mensal;
- Dados históricos;
- Conteúdo menos acessado.

---

# 7. Coldline

Use quando o acesso for ainda menos frequente.

Exemplos:

- Backup trimestral;
- Disaster recovery;
- Arquivos históricos.

---

# 8. Archive

Use para retenção de longo prazo e acesso raro.

Exemplos:

- Arquivamento;
- Compliance;
- Backup de longo prazo.

---

# 9. Laboratório — Criar Bucket

```bash
PROJECT_ID=$(gcloud config get-value project)

gcloud storage buckets create gs://$PROJECT_ID-ace-storage \
  --location=southamerica-east1
```

---

# 10. Enviar arquivo

```bash
echo "id,nome" > clientes.csv
echo "1,Ana" >> clientes.csv
```

Upload:

```bash
gcloud storage cp clientes.csv \
  gs://$PROJECT_ID-ace-storage/
```

---

# 11. Listar

```bash
gcloud storage ls \
  gs://$PROJECT_ID-ace-storage/
```

---

# 12. Download

```bash
gcloud storage cp \
  gs://$PROJECT_ID-ace-storage/clientes.csv \
  ./clientes-download.csv
```

---

# 13. Trocar classe de objeto

Conceitualmente, um objeto pode mudar de classe manualmente ou via Lifecycle Management.

No ACE, o mais importante é entender:

```text
Acesso frequente   → Standard
Mensal             → Nearline
Trimestral         → Coldline
Muito raro         → Archive
```

---

# 14. Pegadinhas ACE

- Cloud Storage é object storage.
- Bucket não é diretório.
- "Pastas" são parte do nome do objeto.
- Nearline, Coldline e Archive possuem duração mínima.
- Classes frias custam menos para armazenar, mas podem ter custos de recuperação e exclusão antecipada.

---

# 15. Questões Estilo ACE

## Questão 1

Dados são acessados várias vezes por dia.

**Resposta:** Standard.

## Questão 2

Backup é acessado aproximadamente uma vez por trimestre.

**Resposta:** Coldline.

## Questão 3

Dados precisam ser arquivados por anos e quase nunca são lidos.

**Resposta:** Archive.

---

# 16. Checklist

- [ ] Entendo bucket
- [ ] Entendo object
- [ ] Sei criar bucket
- [ ] Sei fazer upload/download
- [ ] Sei diferenciar classes
- [ ] Entendo duração mínima
