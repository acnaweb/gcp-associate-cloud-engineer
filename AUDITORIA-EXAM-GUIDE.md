# AUDITORIA-EXAM-GUIDE.md

Fonte de verdade: **Associate Cloud Engineer Certification Exam Guide oficial vigente**, consultado em 29/08/2026.

## Pesos atuais

- Section 1 — Setting up a cloud solution environment: **~20%**
- Section 2 — Planning and implementing a cloud solution: **~30%**
- Section 3 — Ensuring successful operation: **~30%**
- Section 4 — Configuring access and security: **~20%**

## Rastreabilidade granular

| Seção | Tópico oficial | Cobertura | Status |
|---|---|---|---|
| 1.1 | Creating a resource hierarchy | S1 A1 | ✅ |
| 1.1 | Applying organizational policies | S1 A1 | ✅ |
| 1.1 | Granting IAM roles within a project | S1 A2 | ✅ |
| 1.1 | Managing users and groups in Cloud Identity | S1 A3 | ✅ |
| 1.1 | Enabling APIs | S1 A1 | ✅ |
| 1.1 | Setting up Google Cloud Observability | S1 A3 / S6 | ✅ |
| 1.1 | Assessing quotas/requesting increases | S1 A3 / S6 A3 | ✅ |
| 1.1 | Standalone organizations | S1 A1 | ✅ |
| 1.1 | Setting up cloud networking | S3 | ✅ |
| 1.1 | Regions/zones product availability | S1 A1 | ✅ |
| 1.1 | Cloud Asset Inventory + Gemini Cloud Assist | S1 A1 | ✅ |
| 1.1 | Workforce Identity Federation | S1 A1 | ✅ |
| 1.2 | Billing accounts | S1 A3 | ✅ |
| 1.2 | Linking projects to billing | S1 A3 | ✅ |
| 1.2 | Budgets and alerts | S1 A3 / S6 A3 | ✅ |
| 1.2 | Billing exports | S1 A3 / S6 A3 | ✅ |
| 2.1 | Compute choice: CE/GKE/Run/functions/Agent Runtime | S2 A1 / S2 A7 / S5 | ✅ |
| 2.1 | Launch compute instance / availability / SSH | S2 A1 / S2 A6 | ✅ |
| 2.1 | CE storage: zonal/regional PD/Hyperdisk | S2 A2 | ✅ |
| 2.1 | Autoscaled MIG using template | S2 A4-A5 | ✅ |
| 2.1 | OS Login | S2 A6 | ✅ |
| 2.1 | VM Manager | S2 A6 | ✅ |
| 2.1 | Spot VMs/custom machine types | S2 A1/A5 | ✅ |
| 2.1 | kubectl | S5 A4 | ✅ |
| 2.1 | GKE Autopilot/regional/private | S5 A5/A7 | ✅ |
| 2.1 | Deploy container to GKE | S5 A4 | ✅ |
| 2.1 | Serverless events / PubSub / Storage / Eventarc | S5 A6 | ✅ |
| 2.1 | GPU/TPU choice | S2 A1 | ✅ |
| 2.2 | Data products SQL/BQ/Firestore/Spanner/Bigtable/AlloyDB/Dataflow/PubSub/Kafka/Memorystore | S4 A3-A7 | ✅ |
| 2.2 | Storage products Storage/Filestore/NetApp/Lustre + classes | S4 A1/A7 | ✅ |
| 2.2 | Load data / CLI / GCS / Storage Transfer | S4 A1/A2/A6 | ✅ |
| 2.2 | Multi-region redundancy data solutions | S4 A1/A3-A7 | ✅ |
| 2.3 | VPC/custom/shared/peering | S3 A1/A5 | ✅ |
| 2.3 | VPC firewall + Cloud NGFW | S3 A2 | ✅ |
| 2.3 | Secure Tags + service accounts in NGFW | S3 A2 | ✅ |
| 2.3 | VPN/Peering/Interconnect | S3 A5 | ✅ |
| 2.3 | Choose/deploy load balancers | S3 A4 | ✅ |
| 2.3 | Network Service Tiers | S3 A1/A4 | ✅ |
| 2.4 | Fabric FAST/Config Connector/Terraform/Helm | S6 A4 | ✅ |
| 2.4 | Gemini CLI/Antigravity/Cloud Assist/Application Design Center | S6 A7 | ✅ |
| 3.1 | Remote connect Compute Engine | S2 A1/A6 | ✅ |
| 3.1 | View running CE instances | S2 A1 | ✅ |
| 3.1 | Snapshots/images + schedule | S2 A2 | ✅ |
| 3.1 | GKE inventory | S5 A4/A7 | ✅ |
| 3.1 | GKE access Artifact Registry | S5 A1/A7 | ✅ |
| 3.1 | Node pools + autoscaling | S5 A7 | ✅ |
| 3.1 | Pods/Services/StatefulSets | S5 A4/A7 | ✅ |
| 3.1 | HPA/VPA | S5 A5/A7 | ✅ |
| 3.1 | Autopilot resource requests | S5 A7 | ✅ |
| 3.1 | Cloud Run new versions | S5 A2 | ✅ |
| 3.1 | Traffic splitting Run/functions/GKE | S5 A2/A6/A7 | ✅ |
| 3.1 | Cloud Run autoscaling | S5 A2 | ✅ |
| 3.1 | Attach GPUs/TPUs | S2 A1 | ✅ |
| 3.1 | Agent Runtime | S2 A7 | ✅ |
| 3.1 | Workbench/notebooks | S2 A7 | ✅ |
| 3.1 | Cloud Workstations | S2 A7 | ✅ |
| 3.2 | Secure Cloud Storage objects | S4 A1/A2 | ✅ |
| 3.2 | Object lifecycle policies | S4 A2 | ✅ |
| 3.2 | Execute data queries | S4 A3-A5 | ✅ |
| 3.2 | Estimate storage costs | S4 A1/A7 | ✅ |
| 3.2 | Backup/restore databases | S4 A3/A4 | ✅ |
| 3.2 | Dataflow/BigQuery job status | S4 A5/A6 | ✅ |
| 3.2 | Database Center | S4 A3 | ✅ |
| 3.2 | CMEK | S4 A2 | ✅ |
| 3.3 | Resize subnet IPv4 range | S3 A1 | ✅ |
| 3.3 | Static external/internal IP | S3 A1 | ✅ |
| 3.3 | Custom static routes | S3 A2 | ✅ |
| 3.3 | Cloud DNS/NAT | S3 A3 | ✅ |
| 3.3 | Firewall + NGFW management | S3 A2 | ✅ |
| 3.4 | Monitoring alerts | S6 A1 | ✅ |
| 3.4 | Custom metrics | S6 A1 | ✅ |
| 3.4 | VPC flow/audit/firewall logs | S6 A2 | ✅ |
| 3.4 | Export logs | S6 A6 | ✅ |
| 3.4 | Log buckets/analytics/router | S6 A6 | ✅ |
| 3.4 | View/filter logs | S6 A2 | ✅ |
| 3.4 | Log message details | S6 A2 | ✅ |
| 3.4 | Trace/Profiler/Query Insights/index advisor | S6 A6 | ✅ |
| 3.4 | Personalized Service Health | S6 A6 | ✅ |
| 3.4 | Ops Agent | S6 A6 | ✅ |
| 3.4 | Managed Prometheus | S6 A6 | ✅ |
| 3.4 | Gemini Cloud Assist Monitoring | S6 A1/A7 | ✅ |
| 3.4 | Active Assist | S6 A1/A7 | ✅ |
| 3.4 | Cloud Hub | S6 A7 | ✅ |
| 4.1 | View/create IAM policies | S1 A2 / S7 A1 | ✅ |
| 4.1 | Roles + inheritance | S7 A1 | ✅ |
| 4.1 | Role types + custom IAM roles | S1 A2 / S7 A1 | ✅ |
| 4.2 | Create service accounts incl Google-managed | S1 A2 / S7 A2 | ✅ |
| 4.2 | SA minimum permissions | S1 A2 / S7 | ✅ |
| 4.2 | Assign SA to resources | S7 A2 | ✅ |
| 4.2 | Manage IAM permissions of SA | S7 A2 | ✅ |
| 4.2 | SA impersonation | S7 A2 | ✅ |
| 4.2 | Short-lived SA credentials | S7 A2 | ✅ |
| 4.2 | Google SA with GKE app | S5 A7 / S7 A3 | ✅ |
| 4.2 | Workload Identity Federation | S7 A3 | ✅ |

## Regra de regressão

Uma nova versão do roadmap não pode remover um tópico marcado acima sem que o exam guide oficial também tenha removido o requisito.

## Regra de troubleshooting

A hipótese e a evidência de troubleshooting devem usar apenas conceitos apresentados e inspecionados anteriormente na aula ou explicitamente retomados de aula anterior.