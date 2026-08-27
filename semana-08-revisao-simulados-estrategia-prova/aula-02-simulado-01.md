# Aula 2 — Simulado 1

## Instruções

- Faça sem consultar o gabarito.
- Marque o motivo de cada escolha.
- Depois classifique seus erros por domínio.

## Questão 1

Uma VM privada precisa acessar pacotes na internet sem IP externo. Melhor serviço?

A. Cloud NAT
B. VPC Peering
C. Cloud DNS
D. Cloud Armor

## Questão 2

Uma aplicação HTTP containerizada stateless precisa escalar a zero sem cluster.

A. GKE Standard
B. Cloud Run
C. Compute Engine sole-tenant
D. Bigtable

## Questão 3

Usuário precisa apenas ler objetos de um bucket.

A. Owner
B. Storage Object Viewer
C. Editor
D. Storage Admin

## Questão 4

Duas subnets em regiões diferentes estão na mesma VPC. Precisam peering?

A. Sim
B. Não
C. Só se CIDR /24
D. Só com Cloud Router

## Questão 5

Banco relacional global com escala horizontal.

A. Cloud SQL
B. Firestore
C. Spanner
D. Bigtable

## Questão 6

Consultas analíticas sobre TB/PB.

A. BigQuery
B. Cloud SQL
C. Firestore
D. Memorystore

## Questão 7

MIG deve aumentar VMs por CPU.

A. Health check
B. Autoscaler
C. Cloud NAT
D. URL map

## Questão 8

Backend HTTP morreu mas VM existe. LB deve parar de enviar tráfego.

A. Health check
B. Snapshot
C. Route
D. Budget

## Questão 9

Quem troca rotas dinamicamente com BGP no GCP?

A. Cloud DNS
B. Cloud Router
C. Cloud NAT
D. Cloud Scheduler

## Questão 10

Budget atingiu 100%. O que ocorre automaticamente por padrão?

A. Projeto desliga
B. Gasto bloqueia
C. Somente alertas configurados podem ocorrer
D. VMs param

## Questão 11

Terraform: comando para visualizar mudanças previstas?

A. apply
B. init
C. plan
D. destroy

## Questão 12

Kubernetes: objeto que mantém quantidade desejada de Pods?

A. Service
B. Deployment
C. ConfigMap
D. Ingress only

## Questão 13

Cloud Storage: apagar automaticamente objetos antigos.

A. Lifecycle rule
B. Snapshot schedule
C. Cloud Router
D. Quota

## Questão 14

External CI/CD sem chave JSON longa.

A. Basic role Owner
B. Workload Identity Federation
C. Static external IP
D. Cloud NAT

## Questão 15

403 ao acessar recurso indica primeiro investigar:

A. IAM/autorização
B. CPU
C. CIDR sempre
D. disk type

# Gabarito comentado

**1. A — Cloud NAT**

**2. B — Cloud Run**

**3. B — Storage Object Viewer**

**4. B — Não**

**5. C — Spanner**

**6. A — BigQuery**

**7. B — Autoscaler**

**8. A — Health check**

**9. B — Cloud Router**

**10. C — Somente alertas configurados podem ocorrer**

**11. C — plan**

**12. B — Deployment**

**13. A — Lifecycle rule**

**14. B — Workload Identity Federation**

**15. A — IAM/autorização**

## Análise pós-simulado

Para cada erro, registre:

```text
Questão:
Domínio:
Conceito que faltou:
Por que minha opção estava errada:
Comando/lab que vou repetir:
```
