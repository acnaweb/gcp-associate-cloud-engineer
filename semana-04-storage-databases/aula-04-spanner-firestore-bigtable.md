# Aula 4 — Spanner, Firestore e Bigtable

## Objetivos

Ao final desta aula, você deverá:

- Entender Spanner;
- Entender Firestore;
- Entender Bigtable;
- Saber diferenciar relacional distribuído, documentos e wide-column;
- Escolher o serviço adequado por cenário.

---

# 1. Spanner

Spanner é um banco relacional distribuído, horizontalmente escalável.

Modelo:

```text
Application
    │
    ▼
Spanner
    │
    ├── SQL
    ├── Transactions
    └── Horizontal Scale
```

Use quando precisa de:

- Escala horizontal relacional;
- Alta disponibilidade;
- Distribuição regional/global;
- Consistência forte;
- SQL.

---

# 2. Quando Spanner não é necessário

Evite escolher Spanner apenas porque "é o banco mais poderoso".

Se um Cloud SQL atende ao requisito, ele pode ser mais simples.

A prova valoriza:

> Solução adequada, não a mais sofisticada.

---

# 3. Firestore

Firestore é um banco NoSQL orientado a documentos e serverless.

Modelo:

```text
Collection
   │
   ├── Document
   ├── Document
   └── Document
```

Bom para:

- Apps web/mobile;
- Estruturas flexíveis;
- Serverless;
- Documentos JSON-like.

---

# 4. Bigtable

Bigtable é um banco wide-column distribuído para grande escala e baixa latência.

```text
Row Key
   │
Column Families
   │
Huge Scale
```

Bom para:

- Time series;
- IoT;
- Telemetria;
- AdTech;
- Grandes volumes;
- Baixa latência.

---

# 5. Spanner x Firestore x Bigtable

| Requisito | Serviço |
|---|---|
| SQL relacional distribuído | Spanner |
| Documentos serverless | Firestore |
| Wide-column / time series | Bigtable |

---

# 6. Cenários

## Sistema financeiro global

```text
Transactions + SQL + scale
→ Spanner
```

## Aplicação mobile

```text
Documents + serverless
→ Firestore
```

## Telemetria de milhões de dispositivos

```text
Wide-column + high throughput
→ Bigtable
```

---

# 7. Questões Estilo ACE

## Questão 1

Banco relacional precisa escalar horizontalmente globalmente.

**Resposta:** Spanner.

## Questão 2

App mobile precisa de documentos serverless.

**Resposta:** Firestore.

## Questão 3

Milhões de eventos de telemetria precisam de leitura/escrita de baixa latência.

**Resposta:** Bigtable.

---

# 8. Checklist

- [ ] Entendo Spanner
- [ ] Entendo Firestore
- [ ] Entendo Bigtable
- [ ] Sei diferenciar os três
- [ ] Sei escolher por requisito
