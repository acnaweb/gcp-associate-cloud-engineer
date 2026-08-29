# MATRIZ-MEP-ACE.md

Fonte: guia oficial anexado pelo usuário.

## Legenda

| Código | Significado |
|---|---|
| `M` | Mencionado: aparece no material, mas sem explicação suficiente |
| `E` | Explicado: conceito, uso e decisão são ensinados |
| `P` | Praticado: há laboratório/inspeção/teste executável |
| `P*` | Prática guiada/condicional por depender de Organization, billing, custo, edição ou infraestrutura externa |

### Regra de aceite

```text
Guia diz “selecionar / escolher” → E é aceitável
Guia diz “criar / configurar / implantar / gerenciar / trabalhar com” → P ou P* esperado
```

`P*` não deve ser confundido com `P`: ele indica que existe um roteiro de prática, mas a execução pode depender de pré-requisitos que não devem ser forçados apenas para estudo.

## Auditoria

| Seção | Item | Esperado | Onde | Nível final | Evidência/observação |
|---|---|---:|---|---:|---|

| 1.1 | Hierarquia de recursos | `P` | S1 A1 | `P` | Criar/inspecionar contexto e hierarquia; Organization condicional |
| 1.1 | Aplicar políticas organizacionais | `P` | S1 A1 | `P*` | Prática guiada requer Organization/permissão |
| 1.1 | Conceder IAM roles em projeto | `P` | S1 A2 | `P` | Bindings criados/removidos/testados |
| 1.1 | Cloud Identity usuários/grupos manual/automático | `P` | S1 A3 | `P*` | Admin Console/Organization necessária |
| 1.1 | Ativar APIs | `P` | S1 A1 | `P` | gcloud services enable/list |
| 1.1 | Provisionar/configurar Observability | `P` | S1 A3 + S6 | `P` | APIs + Monitoring/Logging labs |
| 1.1 | Avaliar quotas | `P` | S1 A3/S6 A3 | `P` | Inspeção via CLI |
| 1.1 | Pedir aumento de quota | `P` | S1 A3 | `P*` | Fluxo guiado sem enviar pedido desnecessário |
| 1.2 | Criar Billing Account | `P` | S1 A3 | `P*` | Requer privilégio financeiro; prática guiada |
| 1.2 | Vincular projeto ao billing | `P` | S1 A3 | `P*` | Inspeção + fluxo guiado |
| 1.2 | Budgets e alerts | `P` | S1 A3/S6 A3 | `P*` | Criação condicional no Console |
| 1.2 | Billing export | `P` | S1 A3/S6 A3 | `P*` | Configuração guiada para BigQuery |
| 2.1 | Escolher CE/GKE/Cloud Run/Cloud Functions | `E` | S2 A1 + S5 | `E` | Matrizes e cenários |
| 2.1 | Spot VMs | `E` | S2 A1/A5 | `P` | VM Spot criada/inspecionada |
| 2.1 | Custom machine types | `E` | S2 A1 | `P` | VM custom criada/inspecionada |
| 2.2 | Escolher Cloud SQL/BigQuery/Firestore/Spanner/Bigtable | `E` | S4 | `E` | Matriz de decisão |
| 2.2 | Zonal vs Regional Persistent Disk | `E` | S2 A2 | `E` | Comparação + zonal lab |
| 2.2 | Standard/Nearline/Coldline/Archive | `E` | S4 A1 | `E/P` | Classes explicadas; mudança de class praticada |
| 2.3 | Load Balancing | `E` | S3 A4 | `P` | LB completo |
| 2.3 | Localização/disponibilidade de recursos em rede | `E` | S3 A1/A4 | `E` | Global/regional/zonal e arquitetura |
| 2.3 | Network Service Tiers | `E` | S3 A1/A4 | `E` | Premium vs Standard |
| 3.1 | Inicializar VM + discos + availability policy + SSH keys | `P` | S2 A1/A2/A6 | `P` | Criação/inspeção/SSH/scheduling |
| 3.1 | MIG + autoscaling + instance template | `P` | S2 A4/A5 | `P` | Hands-on completo |
| 3.1 | OS Login | `P` | S2 A6 | `P` | Habilitar/testar/troubleshoot |
| 3.1 | VM Manager | `P` | S2 A6 | `P` | API/metadata/Console/inventário |
| 3.2 | kubectl | `P` | S5 A4 | `P` | Configuração e uso |
| 3.2 | Autopilot | `P` | S5 A4/A7 | `P` | Cluster create-auto |
| 3.2 | Regional cluster | `P` | S5 A7 | `P` | Comando de criação |
| 3.2 | Private cluster | `P` | S5 A7 | `P*` | Prática guiada por custo/rede |
| 3.2 | GKE Enterprise | `P` | S5 A7 | `P*` | Explicado + prática condicional |
| 3.2 | Deploy app containerizada no GKE | `P` | S5 A4 | `P` | Deployment + Service |
| 3.3 | Deploy Cloud Run | `P` | S5 A2 | `P` | Service real |
| 3.3 | Deploy Cloud Functions | `P` | S5 A6 | `P` | Gen2 function Pub/Sub |
| 3.3 | Evento Pub/Sub | `P` | S5 A6 | `P` | Publish + function logs |
| 3.3 | Evento de objeto Cloud Storage | `P` | S5 A6 | `P*` | Arquitetura + trigger guiado |
| 3.3 | Eventarc | `P` | S5 A6 | `P/P*` | Trigger inspecionado; event source guiado |
| 3.3 | Decidir Cloud Run managed / Cloud Run for Anthos / Functions | `E` | S5 A6 | `E` | Comparação explícita do guia |
| 3.4 | Deploy produtos de dados | `P` | S4 | `P/P*` | Cloud SQL/BQ/Firestore hands-on; caros guiados |
| 3.4 | Pub/Sub | `P` | S4 A6 | `P` | Topic/subscription/publish/pull |
| 3.4 | Dataflow | `P` | S4 A6 | `P` | Template job + status |
| 3.4 | Cloud Storage | `P` | S4 A1 | `P` | Bucket/objects |
| 3.4 | AlloyDB | `P` | S4 A3 | `E/P*` | Decisão; provisionamento não obrigatório por custo |
| 3.4 | Upload CLI / carga de GCS | `P` | S4 A1/A5 | `P` | gcloud storage + bq load |
| 3.4 | Storage Transfer Service | `P` | S4 A6 | `P*` | Transfer pequeno guiado |
| 3.5 | Custom VPC + subnets | `P` | S3 A1 | `P` | Hands-on |
| 3.5 | Shared VPC | `P` | S3 A5 | `P*` | Comandos condicionais à Organization |
| 3.5 | Firewall ingress/egress/ranges/tags/SAs | `P` | S3 A2 | `P` | Lab de regras/prioridade |
| 3.5 | VPC Peering | `P` | S3 A5 | `P` | Hands-on |
| 3.5 | Cloud VPN | `P` | S3 A5 | `E/P*` | Gateway/router inspecionados; peer real condicional |
| 3.6 | Cloud Foundation Toolkit | `E` | S6 A4 | `E` | Conceito/uso |
| 3.6 | Config Connector | `E` | S6 A4 | `E` | Conceito/arquitetura |
| 3.6 | Terraform | `P` | S6 A4 | `P` | init/plan/apply/drift/destroy |
| 3.6 | Helm | `E` | S6 A4 | `E` | Conceito/comandos básicos |
| 4.1 | Conectar remotamente à VM | `P` | S2 A1/A6 | `P` | SSH |
| 4.1 | Inventário/IDs/detalhes de VMs | `P` | S2 A1 | `P` | list/describe |
| 4.1 | Snapshots: view/delete/schedule/create | `P` | S2 A2 | `P` | snapshot + schedule |
| 4.1 | Images: create/view/delete | `P` | S2 A2 | `P` | custom image hands-on |
| 4.2 | Inventário clusters/nodes/pods/services | `P` | S5 A4/A7 | `P` | kubectl/gcloud |
| 4.2 | GKE acesso Artifact Registry | `P` | S5 A1/A7 | `E/P*` | Imagem/registry + IAM troubleshooting |
| 4.2 | Node pools add/edit/remove | `P` | S5 A7 | `P` | commands completos |
| 4.2 | Pods/Services/StatefulSets | `P` | S5 A4/A7 | `P` | recursos criados |
| 4.2 | HPA | `P` | S5 A5/A7 | `P` | autoscale deployment |
| 4.2 | VPA | `P` | S5 A7 | `P/P*` | manifest + describe quando API disponível |
| 4.3 | Novas revisions do Cloud Run | `P` | S5 A2 | `P` | update/revisions |
| 4.3 | Traffic splitting | `P` | S5 A2 | `P` | update-traffic + inspect |
| 4.3 | Cloud Run autoscaling parameters | `P` | S5 A2 | `P` | min/max/concurrency + load/troubleshoot |
| 4.4 | Gerenciar/proteger objetos Storage | `P` | S4 A1/A2 | `P` | objects/IAM/versioning/retention |
| 4.4 | Lifecycle policies | `P` | S4 A2 | `P` | lifecycle JSON aplicado |
| 4.4 | Queries Cloud SQL | `P` | S4 A3 | `P` | psql |
| 4.4 | Queries BigQuery | `P` | S4 A5 | `P` | bq query |
| 4.4 | Queries Spanner | `P` | S4 A4 | `E/P*` | Provisionamento caro; cenário/inspeção |
| 4.4 | Queries Firestore | `P` | S4 A4 | `P*` | Console documents/query |
| 4.4 | Queries AlloyDB | `P` | S4 A3 | `E/P*` | Não provisionado por custo |
| 4.4 | Estimar custo de storage | `P` | S4 A1/A5 | `E/P*` | Trade-offs; calculadora/estimativa guiada |
| 4.4 | Backup/restore Cloud SQL | `P` | S4 A3 | `P/P*` | backup real; restore guiado por impacto |
| 4.4 | Backup/restore Firestore | `P` | S4 A4 | `P*` | fluxo guiado condicional |
| 4.4 | Status Dataflow jobs | `P` | S4 A6 | `P` | job real + describe |
| 4.4 | Status BigQuery jobs | `P` | S4 A5/A6 | `P` | bq job list/status |
| 4.5 | Adicionar subnet | `P` | S3 A1 | `P` | subnets create |
| 4.5 | Expandir subnet | `P` | S3 A1 | `P` | expand-ip-range |
| 4.5 | IP estático interno | `P` | S3 A1 | `P` | addresses create internal |
| 4.5 | IP estático externo | `P` | S3 A1 | `P` | addresses create/use |
| 4.5 | Cloud DNS | `P` | S3 A3 | `P` | private zone/records/test |
| 4.5 | Cloud NAT | `P` | S3 A3 | `P` | router/NAT/test |
| 4.6 | Monitoring alerts por resource metric | `P` | S6 A1 | `P` | policy via Console + workload |
| 4.6 | Custom metrics | `P` | S6 A1 | `P` | log-based metric create/ingest |
| 4.6 | Export logs externo/on-prem/BigQuery | `P` | S6 A6 | `P/P*` | BigQuery sink hands-on; external architecture |
| 4.6 | Log buckets/router/analytics | `P` | S6 A6 | `P/P*` | sink/bucket inspect; analytics guided |
| 4.6 | View/filter/details logs | `P` | S6 A2/A6 | `P` | gcloud + Logs Explorer |
| 4.6 | Cloud diagnostics | `P` | S6 A6 | `E/P*` | diagnostic flow guided |
| 4.6 | Google Cloud status | `P` | S6 A6 | `P*` | status check guided |
| 4.6 | Ops Agent | `P` | S6 A6 | `P` | install/stop/test flow |
| 4.6 | Managed Service for Prometheus | `P` | S6 A6 | `P*` | GKE-dependent guided practice |
| 4.6 | Audit Logs | `P` | S6 A2/A6 | `P` | query/audit evidence |
| 5.1 | View/create IAM policies | `P` | S1 A2/S7 A1 | `P` | get/add/remove policy binding |
| 5.1 | Basic/predefined/custom roles | `P` | S1 A2/S7 A1 | `P` | list/describe/create custom |
| 5.2 | Criar Service Accounts | `P` | S1 A2/S7 A2 | `P` | create |
| 5.2 | Least privilege SA in IAM | `P` | S1 A2/S7 | `P` | role mínima em recurso |
| 5.2 | Atribuir SA a recursos | `P` | S7 A2 | `P` | VM com SA |
| 5.2 | Gerenciar IAM da SA | `P` | S7 A2 | `P` | get/add/remove SA policy |
| 5.2 | Identidade temporária SA | `P` | S7 A2 | `P` | impersonation |
| 5.2 | Credenciais de curta duração | `P` | S7 A2 | `P` | access/id token via impersonation |
