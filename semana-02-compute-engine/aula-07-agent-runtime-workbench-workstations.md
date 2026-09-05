# Aula 7 — Agent Runtime, Workbench e Cloud Workstations

> **Classificação em relação ao guia oficial anexado:** conteúdo complementar. Os tópicos desta aula não aparecem explicitamente no PDF usado como fonte de verdade nesta versão. Estude depois de concluir os itens obrigatórios do guia.


## Método da aula

```text
Conceito → Criar/Configurar → Inspecionar → Testar → Quebrar → Troubleshooting → Corrigir → Questões → Cleanup
```

> O troubleshooting usa apenas conceitos apresentados antes na própria aula.

## 1. Conceito

O exam guide atual inclui três áreas modernas de operação:

```text
Agent Runtime (Gemini Enterprise Agent Platform)
→ executar/deployar agentes gerenciados

Workbench / notebooks
→ ambientes interativos de análise/ML, incluindo integrações atuais

Cloud Workstations
→ ambientes de desenvolvimento gerenciados
```

### Quando escolher

| Necessidade | Serviço/conceito |
|---|---|
| Executar um agente gerenciado | Agent Runtime |
| Notebook para análise/ML | Workbench/notebooks compatíveis |
| IDE/dev environment padronizado e gerenciado | Cloud Workstations |

## 2. Criar / configurar

Esses produtos podem exigir APIs, configuração corporativa e custos. Faça laboratório de **inventário e decisão**, não provisionamento artificial.

```bash
# Explicação: Lista APIs/serviços disponíveis ou habilitados, conforme os filtros informados.
gcloud services list --available --filter='NAME:workstations.googleapis.com'
# Explicação: Executa `gcloud workstations clusters list --region=us-central1 2>/dev/null || true` nesta etapa para aplicar ou inspecionar a configuração indicada.
gcloud workstations clusters list --region=us-central1 2>/dev/null || true
```

No Console, localize:

- Cloud Workstations;
- áreas atuais do Gemini Enterprise Agent Platform;
- notebooks/BigQuery notebooks conforme interface atual.

## 3. Inspecionar

Para cada produto, registre:

```text
resource hierarchy
region/location
runtime/compute subjacente
identity
network
cost trigger
```

## 4. Testar

Dado o cenário, escolha sem provisionar:

1. Desenvolvedores precisam IDE padronizada em rede corporativa → **Cloud Workstations**.
2. Cientista precisa notebook interativo → **Workbench/notebook adequado**.
3. Equipe precisa executar agente gerenciado → **Agent Runtime**.

## 5. Quebrar propositalmente

Falha de decisão:

> “Vou criar VMs individuais para todos os desenvolvedores, embora o requisito peça ambientes de desenvolvimento gerenciados e padronizados.”

## 6. Troubleshooting

**Sintoma:** operação manual alta e ambientes inconsistentes.

**Hipótese:** compute genérico foi escolhido apesar do requisito de dev environment gerenciado.

**Evidência:** requisito dominante = padronização/gestão de ambientes de desenvolvimento.

**Causa:** escolha incorreta de serviço.

## 7. Corrigir

Escolha **Cloud Workstations** quando o requisito corresponder.

## 8. Questões ACE

1. Ambiente de desenvolvimento gerenciado → **Cloud Workstations**.
2. Runtime gerenciado para agentes → **Agent Runtime**.
3. Notebook interativo → **Workbench/notebook**.

## 9. Cleanup

Nenhum recurso caro foi criado.

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
