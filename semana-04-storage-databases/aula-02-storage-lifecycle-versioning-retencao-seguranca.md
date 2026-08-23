# Aula 2 — Lifecycle, Versioning, Retenção e Segurança no Storage

## Objetivos

Ao final desta aula, você deverá:

- Entender Object Lifecycle Management;
- Entender Versioning;
- Entender retenção;
- Entender IAM em buckets;
- Entender signed URLs;
- Reconhecer boas práticas de segurança.

---

# 1. Object Lifecycle Management

Lifecycle Management automatiza ações sobre objetos.

Exemplo:

```text
Object created
   ↓
30 days
   ↓
Nearline
   ↓
90 days
   ↓
Coldline
   ↓
365 days
   ↓
Delete
```

---

# 2. Casos de uso

Você pode:

- Alterar storage class;
- Excluir objetos antigos;
- Gerenciar versões não atuais;
- Automatizar retenção técnica.

---

# 3. Exemplo de regra

Arquivo `lifecycle.json`:

```json
{
  "rule": [
    {
      "action": {
        "type": "SetStorageClass",
        "storageClass": "COLDLINE"
      },
      "condition": {
        "age": 90
      }
    }
  ]
}
```

Aplicar:

```bash
gcloud storage buckets update \
  gs://SEU_BUCKET \
  --lifecycle-file=lifecycle.json
```

---

# 4. Versioning

Quando versioning está habilitado, substituições/exclusões podem manter versões anteriores.

```text
clientes.csv
   ├── generation 1
   ├── generation 2
   └── generation 3
```

Bom para:

- Recuperação de sobrescrita acidental;
- Histórico;
- Proteção operacional.

---

# 5. Habilitar Versioning

```bash
gcloud storage buckets update \
  gs://SEU_BUCKET \
  --versioning
```

---

# 6. Retention Policy

Retention policy impede exclusão/modificação de objetos antes de determinado período.

```text
Object
   │
Retention Period
   │
No delete before expiry
```

Importante para compliance.

---

# 7. IAM em Cloud Storage

Exemplos de roles:

```text
roles/storage.objectViewer
roles/storage.objectCreator
roles/storage.objectAdmin
```

Use sempre menor privilégio.

---

# 8. Uniform Bucket-Level Access

Esse modelo centraliza controle via IAM no nível do bucket, evitando ACLs por objeto.

Para o ACE, lembre:

> Prefira IAM consistente e simples em vez de misturar mecanismos desnecessariamente.

---

# 9. Signed URLs

Signed URL fornece acesso temporário a um objeto.

```text
User
  │
Signed URL
  │
  ▼
Cloud Storage Object
```

Bom para:

- Download temporário;
- Upload controlado;
- Compartilhamento sem tornar bucket público.

---

# 10. Autoclass

Autoclass pode gerenciar automaticamente transições de storage class com base em padrões de acesso.

Para a prova, entenda o conceito:

> O serviço pode ajustar a classe automaticamente, reduzindo gestão manual.

---

# 11. Segurança

Evite:

```text
Bucket público sem necessidade
```

Prefira:

- IAM;
- Signed URLs;
- Service Accounts;
- Least privilege;
- Retention quando necessário.

---

# 12. Questões Estilo ACE

## Questão 1

Objetos com mais de 90 dias devem migrar automaticamente para Coldline.

**Resposta:** Lifecycle Management.

## Questão 2

Usuário precisa baixar um arquivo por 10 minutos sem acesso permanente.

**Resposta:** Signed URL.

## Questão 3

Empresa precisa impedir exclusão antes de 7 anos.

**Resposta:** Retention Policy.

---

# 13. Checklist

- [ ] Entendo Lifecycle
- [ ] Entendo Versioning
- [ ] Entendo Retention Policy
- [ ] Entendo IAM em Storage
- [ ] Entendo Signed URLs
- [ ] Entendo Autoclass em nível conceitual
