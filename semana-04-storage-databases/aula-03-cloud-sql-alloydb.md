# Aula 3 — Cloud SQL e AlloyDB

## Objetivos

Ao final desta aula, você deverá:

- Entender Cloud SQL;
- Entender AlloyDB;
- Saber quando escolher cada um;
- Entender HA, backups e replicas em nível ACE;
- Reconhecer principais engines suportadas.

---

# 1. Cloud SQL

Cloud SQL é o serviço gerenciado de banco relacional para:

```text
MySQL
PostgreSQL
SQL Server
```

Use quando precisa de banco relacional tradicional gerenciado.

---

# 2. Modelo

```text
Application
    │
    ▼
Cloud SQL
    │
    ├── MySQL
    ├── PostgreSQL
    └── SQL Server
```

---

# 3. Casos típicos

- Aplicações web;
- Sistemas corporativos;
- Migração de bancos tradicionais;
- Workloads OLTP de pequeno/médio porte.

---

# 4. Alta disponibilidade

Cloud SQL pode ser configurado com HA regional.

Modelo:

```text
Region
  │
  ├── Primary
  └── Standby
```

O serviço gerencia failover conforme a configuração.

---

# 5. Read Replicas

Read replicas podem ser usadas para descarregar leituras.

```text
Primary
  │
  ├── Read Replica 1
  └── Read Replica 2
```

Não confunda read replica com mecanismo principal de HA.

---

# 6. Backups

Estude:

- Automated backups;
- Point-in-time recovery;
- Restore;
- Maintenance.

No ACE, o mais importante é reconhecer o requisito.

---

# 7. AlloyDB

AlloyDB é um banco totalmente gerenciado, compatível com PostgreSQL, voltado a workloads enterprise e alta performance.

```text
Application
    │
    ▼
AlloyDB
    │
PostgreSQL-compatible
```

---

# 8. Quando considerar AlloyDB

- PostgreSQL enterprise;
- Maior exigência de performance;
- Workloads analíticos e transacionais combinados;
- Modernização de aplicações PostgreSQL.

---

# 9. Cloud SQL x AlloyDB

| Requisito | Serviço |
|---|---|
| MySQL gerenciado | Cloud SQL |
| SQL Server gerenciado | Cloud SQL |
| PostgreSQL tradicional gerenciado | Cloud SQL |
| PostgreSQL enterprise/performance | AlloyDB |

---

# 10. Conectividade

Pense em:

- IP privado;
- IAM;
- Service Accounts;
- Auth Proxy / connectors;
- Firewall/VPC;
- SSL/TLS.

---

# 11. Questões Estilo ACE

## Questão 1

Aplicação usa MySQL e precisa de serviço gerenciado.

**Resposta:** Cloud SQL.

## Questão 2

Aplicação SQL Server precisa ser migrada com pouca mudança arquitetural.

**Resposta:** Cloud SQL.

## Questão 3

Workload PostgreSQL enterprise exige alta performance.

**Resposta:** considerar AlloyDB.

---

# 12. Checklist

- [ ] Sei quando usar Cloud SQL
- [ ] Sei engines suportadas
- [ ] Entendo HA
- [ ] Entendo read replicas
- [ ] Entendo backups
- [ ] Sei quando considerar AlloyDB
