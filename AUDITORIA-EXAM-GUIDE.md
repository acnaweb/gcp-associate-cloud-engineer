# AUDITORIA-EXAM-GUIDE.md

Fonte de verdade: **Associate Cloud Engineer — Guia do exame de certificação**, PDF oficial anexado pelo usuário.

## Pesos do guia anexado

- Seção 1 — Configurar um ambiente de solução de nuvem: **~20%**
- Seção 2 — Planejar e configurar uma solução de nuvem: **~17,5%**
- Seção 3 — Implantar e implementar uma solução de nuvem: **~25%**
- Seção 4 — Garantir a operação bem-sucedida de uma solução de nuvem: **~20%**
- Seção 5 — Configurar acesso e segurança: **~17,5%**

---

## Rastreabilidade

| Item oficial | Cobertura no roadmap | Status |
|---|---|---|
| 1.1 Hierarquia de recursos | S1 A1 | ✅ |
| 1.1 Organization Policies | S1 A1 | ✅ |
| 1.1 Conceder IAM roles no projeto | S1 A2 | ✅ |
| 1.1 Cloud Identity users/groups | S1 A3 | ✅ |
| 1.1 Ativar APIs | S1 A1 | ✅ |
| 1.1 Google Cloud Observability | S1 A3 + S6 | ✅ |
| 1.1 Quotas / aumento | S1 A3 + S6 A3 | ✅ |
| 1.2 Billing Accounts | S1 A3 | ✅ |
| 1.2 Vincular projeto ao billing | S1 A3 | ✅ |
| 1.2 Budgets/alerts | S1 A3 + S6 A3 | ✅ |
| 1.2 Billing export | S1 A3 + S6 A3 | ✅ |
| 2.1 CE/GKE/Cloud Run/Cloud Functions | S2 A1 + S5 | ✅ |
| 2.1 Spot VM | S2 A1/A5 | ✅ |
| 2.1 Custom Machine Type | S2 A1 | ✅ |
| 2.2 Cloud SQL/BQ/Firestore/Spanner/Bigtable | S4 | ✅ |
| 2.2 Zonal/Regional PD | S2 A2 | ✅ |
| 2.2 Standard/Nearline/Coldline/Archive | S4 A1 | ✅ |
| 2.3 Load Balancing | S3 A4 | ✅ |
| 2.3 Resource location availability | S1 A1 + S3 A1/A4 | ✅ |
| 2.3 Network Service Tiers | S3 A1/A4 | ✅ |
| 3.1 VM + disk + availability policy + SSH keys | S2 A1/A2/A3/A6 | ✅ |
| 3.1 MIG + autoscaling + template | S2 A4/A5 | ✅ |
| 3.1 OS Login | S2 A6 | ✅ |
| 3.1 VM Manager | S2 A6 | ✅ |
| 3.2 kubectl | S5 A4 | ✅ |
| 3.2 Autopilot/regional/private/GKE Enterprise | S5 A5/A7 | ✅ |
| 3.2 Deploy container no GKE | S5 A4 | ✅ |
| 3.3 Deploy Cloud Run | S5 A2 | ✅ |
| 3.3 Deploy Cloud Functions | S5 A6 | ✅ |
| 3.3 Pub/Sub/Storage events/Eventarc | S5 A6 | ✅ |
| 3.3 Cloud Run managed / Cloud Run for Anthos / Functions | S5 A6 | ✅ |
| 3.4 Cloud SQL/Firestore/BQ/Spanner/PubSub/Dataflow/Storage/AlloyDB | S4 | ✅ |
| 3.4 Upload CLI / GCS load / Storage Transfer | S4 A1/A5/A6 | ✅ |
| 3.5 Custom VPC / Shared VPC | S3 A1/A5 | ✅ |
| 3.5 Firewall ingress/egress/ranges/tags/SAs | S3 A2 | ✅ |
| 3.5 VPC Peering / Cloud VPN | S3 A5 | ✅ |
| 3.6 Cloud Foundation Toolkit | S6 A4 | ✅ |
| 3.6 Config Connector | S6 A4 | ✅ |
| 3.6 Terraform | S6 A4 | ✅ |
| 3.6 Helm | S6 A4 | ✅ |
| 4.1 Remote access VM | S2 A1/A6 | ✅ |
| 4.1 Inventory/details VM | S2 A1 | ✅ |
| 4.1 Snapshots/schedules | S2 A2 | ✅ |
| 4.1 Images | S2 A2 | ✅ |
| 4.2 GKE inventory | S5 A4/A7 | ✅ |
| 4.2 GKE + Artifact Registry | S5 A4/A7 | ✅ |
| 4.2 Node pools | S5 A7 | ✅ |
| 4.2 Pods/Services/StatefulSets | S5 A4/A7 | ✅ |
| 4.2 HPA/VPA | S5 A5/A7 | ✅ |
| 4.3 Cloud Run versions/revisions | S5 A2 | ✅ |
| 4.3 Traffic splitting | S5 A2 | ✅ |
| 4.3 Autoscaling | S5 A2 | ✅ |
| 4.4 Cloud Storage objects/security | S4 A1/A2 | ✅ |
| 4.4 Lifecycle | S4 A2 | ✅ |
| 4.4 Queries SQL/BQ/Spanner/Firestore/AlloyDB | S4 A3-A5 | ✅ |
| 4.4 Storage cost estimation | S4 A1/A5 | ✅ |
| 4.4 Backup/restore Cloud SQL | S4 A3 | ✅ |
| 4.4 Backup/restore Firestore | S4 A4 | ✅ |
| 4.4 Dataflow/BigQuery job status | S4 A5/A6 | ✅ |
| 4.5 Add/expand subnet | S3 A1 | ✅ |
| 4.5 Static internal/external IP | S3 A1 | ✅ |
| 4.5 Cloud DNS/NAT | S3 A3 | ✅ |
| 4.6 Monitoring alerts | S6 A1 | ✅ |
| 4.6 Custom metrics | S6 A1 | ✅ |
| 4.6 Export logs external/on-prem/BigQuery | S6 A6 | ✅ |
| 4.6 Log buckets/router/analytics | S6 A6 | ✅ |
| 4.6 View/filter/details logs | S6 A2 | ✅ |
| 4.6 Cloud diagnostics | S6 A6 | ✅ |
| 4.6 Google Cloud status | S6 A6 | ✅ |
| 4.6 Ops Agent | S6 A6 | ✅ |
| 4.6 Managed Prometheus | S6 A6 | ✅ |
| 4.6 Audit Logs | S6 A2/A6 | ✅ |
| 5.1 View/create IAM policies | S1 A2 + S7 A1 | ✅ |
| 5.1 Basic/predefined/custom roles | S1 A2 + S7 A1 | ✅ |
| 5.2 Create Service Accounts | S1 A2/S7 A2 | ✅ |
| 5.2 Least privilege SA | S1 A2/S7 | ✅ |
| 5.2 Assign SA to resource | S7 A2 | ✅ |
| 5.2 Manage IAM on SA | S7 A2 | ✅ |
| 5.2 Temporary SA identity / impersonation | S7 A2 | ✅ |
| 5.2 Short-lived credentials | S7 A2 | ✅ |

---

# Diferenças encontradas em relação à auditoria anterior

A auditoria anterior **não era compatível com o PDF anexado como fonte de verdade**, principalmente porque:

1. usava **4 seções**, enquanto o anexo possui **5**;
2. usava pesos **20/30/30/20**, enquanto o anexo usa **20/17,5/25/20/17,5**;
3. incluía tópicos não presentes explicitamente no anexo;
4. utilizava terminologia diferente em alguns pontos, como `Fabric FAST` no lugar de **Cloud Foundation Toolkit**;
5. não destacava de maneira suficientemente explícita **Cloud Run for Anthos**, **GKE Enterprise**, **export de logs para sistemas externos/on-prem** e alguns itens operacionais textuais do guia.

Esses pontos foram corrigidos nesta versão.
