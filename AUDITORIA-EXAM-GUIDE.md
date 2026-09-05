# AUDITORIA-EXAM-GUIDE.md

Fonte de verdade: **Associate Cloud Engineer — Guia do exame de certificação**, PDF oficial anexado pelo usuário.

A auditoria desta versão não usa mais apenas `✅`. Cada item informa o nível real de cobertura.

## Pesos do guia anexado

- Seção 1: **~20%**
- Seção 2: **~17,5%**
- Seção 3: **~25%**
- Seção 4: **~20%**
- Seção 5: **~17,5%**

## Legenda

`M` mencionado · `E` explicado · `P` praticado · `P*` prática condicional/guiada.

| Seção | Item oficial | Semana/Aula | Esperado | Nível final |
|---|---|---|---:|---:|

| 1.1 | Hierarquia de recursos | S1 A1 | `P` | `P` |
| 1.1 | Aplicar políticas organizacionais | S1 A1 | `P` | `P*` |
| 1.1 | Conceder IAM roles em projeto | S1 A2 | `P` | `P` |
| 1.1 | Cloud Identity usuários/grupos manual/automático | S1 A3 | `P` | `P*` |
| 1.1 | Ativar APIs | S1 A1 | `P` | `P` |
| 1.1 | Provisionar/configurar Observability | S1 A3 + S6 | `P` | `P` |
| 1.1 | Avaliar quotas | S1 A3/S6 A3 | `P` | `P` |
| 1.1 | Pedir aumento de quota | S1 A3 | `P` | `P*` |
| 1.2 | Criar Billing Account | S1 A3 | `P` | `P*` |
| 1.2 | Vincular projeto ao billing | S1 A3 | `P` | `P*` |
| 1.2 | Budgets e alerts | S1 A3/S6 A3 | `P` | `P*` |
| 1.2 | Billing export | S1 A3/S6 A3 | `P` | `P*` |
| 2.1 | Escolher CE/GKE/Cloud Run/Cloud Functions | S2 A1 + S5 | `E` | `E` |
| 2.1 | Spot VMs | S2 A1/A5 | `E` | `P` |
| 2.1 | Custom machine types | S2 A1 | `E` | `P` |
| 2.2 | Escolher Cloud SQL/BigQuery/Firestore/Spanner/Bigtable | S4 | `E` | `E` |
| 2.2 | Zonal vs Regional Persistent Disk | S2 A2 | `E` | `E` |
| 2.2 | Standard/Nearline/Coldline/Archive | S4 A1 | `E` | `E/P` |
| 2.3 | Load Balancing | S3 A4 | `E` | `P` |
| 2.3 | Localização/disponibilidade de recursos em rede | S3 A1/A4 | `E` | `E` |
| 2.3 | Network Service Tiers | S3 A1/A4 | `E` | `E` |
| 3.1 | Inicializar VM + discos + availability policy + SSH keys | S2 A1/A2/A6 | `P` | `P` |
| 3.1 | MIG + autoscaling + instance template | S2 A4/A5 | `P` | `P` |
| 3.1 | OS Login | S2 A6 | `P` | `P` |
| 3.1 | VM Manager | S2 A6 | `P` | `P` |
| 3.2 | kubectl | S5 A4 | `P` | `P` |
| 3.2 | Autopilot | S5 A4/A7 | `P` | `P` |
| 3.2 | Regional cluster | S5 A7 | `P` | `P` |
| 3.2 | Private cluster | S5 A7 | `P` | `P*` |
| 3.2 | GKE Enterprise | S5 A7 | `P` | `P*` |
| 3.2 | Deploy app containerizada no GKE | S5 A4 | `P` | `P` |
| 3.3 | Deploy Cloud Run | S5 A2 | `P` | `P` |
| 3.3 | Deploy Cloud Functions | S5 A6 | `P` | `P` |
| 3.3 | Evento Pub/Sub | S5 A6 | `P` | `P` |
| 3.3 | Evento de objeto Cloud Storage | S5 A6 | `P` | `P*` |
| 3.3 | Eventarc | S5 A6 | `P` | `P/P*` |
| 3.3 | Decidir Cloud Run managed / Cloud Run for Anthos / Functions | S5 A6 | `E` | `E` |
| 3.4 | Deploy produtos de dados | S4 | `P` | `P/P*` |
| 3.4 | Pub/Sub | S4 A6 | `P` | `P` |
| 3.4 | Dataflow | S4 A6 | `P` | `P` |
| 3.4 | Cloud Storage | S4 A1 | `P` | `P` |
| 3.4 | AlloyDB | S4 A3 | `P` | `E/P*` |
| 3.4 | Upload CLI / carga de GCS | S4 A1/A5 | `P` | `P` |
| 3.4 | Storage Transfer Service | S4 A6 | `P` | `P*` |
| 3.5 | Custom VPC + subnets | S3 A1 | `P` | `P` |
| 3.5 | Shared VPC | S3 A5 | `P` | `P*` |
| 3.5 | Firewall ingress/egress/ranges/tags/SAs | S3 A2 | `P` | `P` |
| 3.5 | VPC Peering | S3 A5 | `P` | `P` |
| 3.5 | Cloud VPN | S3 A5 | `P` | `E/P*` |
| 3.6 | Cloud Foundation Toolkit | S6 A4 | `E` | `E` |
| 3.6 | Config Connector | S6 A4 | `E` | `E` |
| 3.6 | Terraform | S6 A4 | `P` | `P` |
| 3.6 | Helm | S6 A4 | `E` | `E` |
| 4.1 | Conectar remotamente à VM | S2 A1/A6 | `P` | `P` |
| 4.1 | Inventário/IDs/detalhes de VMs | S2 A1 | `P` | `P` |
| 4.1 | Snapshots: view/delete/schedule/create | S2 A2 | `P` | `P` |
| 4.1 | Images: create/view/delete | S2 A2 | `P` | `P` |
| 4.2 | Inventário clusters/nodes/pods/services | S5 A4/A7 | `P` | `P` |
| 4.2 | GKE acesso Artifact Registry | S5 A1/A7 | `P` | `E/P*` |
| 4.2 | Node pools add/edit/remove | S5 A7 | `P` | `P` |
| 4.2 | Pods/Services/StatefulSets | S5 A4/A7 | `P` | `P` |
| 4.2 | HPA | S5 A5/A7 | `P` | `P` |
| 4.2 | VPA | S5 A7 | `P` | `P/P*` |
| 4.3 | Novas revisions do Cloud Run | S5 A2 | `P` | `P` |
| 4.3 | Traffic splitting | S5 A2 | `P` | `P` |
| 4.3 | Cloud Run autoscaling parameters | S5 A2 | `P` | `P` |
| 4.4 | Gerenciar/proteger objetos Storage | S4 A1/A2 | `P` | `P` |
| 4.4 | Lifecycle policies | S4 A2 | `P` | `P` |
| 4.4 | Queries Cloud SQL | S4 A3 | `P` | `P` |
| 4.4 | Queries BigQuery | S4 A5 | `P` | `P` |
| 4.4 | Queries Spanner | S4 A4 | `P` | `E/P*` |
| 4.4 | Queries Firestore | S4 A4 | `P` | `P*` |
| 4.4 | Queries AlloyDB | S4 A3 | `P` | `E/P*` |
| 4.4 | Estimar custo de storage | S4 A1/A5 | `P` | `E/P*` |
| 4.4 | Backup/restore Cloud SQL | S4 A3 | `P` | `P/P*` |
| 4.4 | Backup/restore Firestore | S4 A4 | `P` | `P*` |
| 4.4 | Status Dataflow jobs | S4 A6 | `P` | `P` |
| 4.4 | Status BigQuery jobs | S4 A5/A6 | `P` | `P` |
| 4.5 | Adicionar subnet | S3 A1 | `P` | `P` |
| 4.5 | Expandir subnet | S3 A1 | `P` | `P` |
| 4.5 | IP estático interno | S3 A1 | `P` | `P` |
| 4.5 | IP estático externo | S3 A1 | `P` | `P` |
| 4.5 | Cloud DNS | S3 A3 | `P` | `P` |
| 4.5 | Cloud NAT | S3 A3 | `P` | `P` |
| 4.6 | Monitoring alerts por resource metric | S6 A1 | `P` | `P` |
| 4.6 | Custom metrics | S6 A1 | `P` | `P` |
| 4.6 | Export logs externo/on-prem/BigQuery | S6 A6 | `P` | `P/P*` |
| 4.6 | Log buckets/router/analytics | S6 A6 | `P` | `P/P*` |
| 4.6 | View/filter/details logs | S6 A2/A6 | `P` | `P` |
| 4.6 | Cloud diagnostics | S6 A6 | `P` | `E/P*` |
| 4.6 | Google Cloud status | S6 A6 | `P` | `P*` |
| 4.6 | Ops Agent | S6 A6 | `P` | `P` |
| 4.6 | Managed Service for Prometheus | S6 A6 | `P` | `P*` |
| 4.6 | Audit Logs | S6 A2/A6 | `P` | `P/P*` |
| 5.1 | View/create IAM policies | S1 A2/S7 A1 | `P` | `P` |
| 5.1 | Basic/predefined/custom roles | S1 A2/S7 A1 | `P` | `P` |
| 5.2 | Criar Service Accounts | S1 A2/S7 A2 | `P` | `P` |
| 5.2 | Least privilege SA in IAM | S1 A2/S7 | `P` | `P` |
| 5.2 | Atribuir SA a recursos | S7 A2 | `P` | `P` |
| 5.2 | Gerenciar IAM da SA | S7 A2 | `P` | `P` |
| 5.2 | Identidade temporária SA | S7 A2 | `P` | `P` |
| 5.2 | Credenciais de curta duração | S7 A2 | `P` | `P` |
