# Aula 7 — Filestore, NetApp Volumes, Managed Lustre, Managed Kafka e Memorystore

> **Classificação em relação ao guia oficial anexado:** conteúdo complementar. Os tópicos desta aula não aparecem explicitamente no PDF usado como fonte de verdade nesta versão. Estude depois de concluir os itens obrigatórios do guia.


## Método da aula

```text
Conceito → Criar/Configurar → Inspecionar → Testar → Quebrar → Troubleshooting → Corrigir → Questões → Cleanup
```

> O troubleshooting usa apenas conceitos apresentados antes na própria aula.

## 1. Conceito

O exam guide atual cita explicitamente opções além de Cloud Storage e bancos tradicionais.

### Storage

```text
Cloud Storage  → objetos
Filestore      → NFS gerenciado
NetApp Volumes → file storage empresarial
Managed Lustre → filesystem paralelo HPC/AI
```

### Data/messaging/cache

```text
Pub/Sub        → messaging/event ingestion nativo
Managed Kafka  → Kafka gerenciado/ecossistema Kafka
Memorystore    → cache/in-memory
```

## 2. Criar / configurar

Provisionar NetApp/Lustre/Kafka apenas para observação pode gerar custo relevante. Use inspeção:

```bash
# Explicação: Lista APIs/serviços disponíveis ou habilitados, conforme os filtros informados.
gcloud services list --available | grep -Ei 'file|lustre|kafka|redis|memorystore' | head -30
```

Para Filestore, veja tiers/locations disponíveis no Console ou CLI compatível.

## 3. Inspecionar

Construa a tabela:

| Requisito | Produto |
|---|---|
| Object storage | Cloud Storage |
| Compartilhamento NFS | Filestore |
| Recursos NetApp empresariais | NetApp Volumes |
| HPC paralelo | Managed Lustre |
| Cache | Memorystore |
| Protocolo/ecossistema Kafka | Managed Kafka |
| Eventos nativos GCP | Pub/Sub |

## 4. Testar

Classifique cinco workloads reais seus ou exemplos do roadmap pela tabela.

## 5. Quebrar propositalmente

> Escolher Cloud Storage para aplicação legada que exige filesystem NFS montável.

## 6. Troubleshooting

**Sintoma:** aplicação exige semântica de filesystem e não funciona sobre API de objetos.

**Hipótese:** categoria de storage incorreta.

**Evidência:** requisito explícito de NFS/POSIX-like file access.

**Causa:** Cloud Storage é object storage.

## 7. Corrigir

Avalie **Filestore** ou opção de file storage adequada.

## 8. Questões ACE

1. NFS gerenciado → **Filestore**.
2. HPC com filesystem paralelo → **Managed Lustre**.
3. Cache de baixa latência → **Memorystore**.
4. Migração Kafka que exige compatibilidade Kafka → **Managed Service for Apache Kafka**.

## 9. Cleanup

Nenhum serviço de alto custo foi provisionado.

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
