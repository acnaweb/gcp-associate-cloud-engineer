# Aula 3 — Simulado 2

## Instruções

Este simulado usa mais cenários integrados.

---

# Questões

## 1

Uma empresa quer alta disponibilidade para um frontend em Compute Engine, tolerando falha de uma zone.

A. Duas VMs na mesma zone  
B. Regional MIG + Load Balancer  
C. Uma VM maior  
D. Spot VM única

## 2

Uma nova versão do Cloud Run deve receber 5% do tráfego.

A. Snapshot  
B. Traffic splitting entre revisions  
C. Regional disk  
D. Firewall route

## 3

Uma aplicação no Cloud Run recebe `403` ao consultar BigQuery.

Primeiro verifique:

A. Storage Class  
B. Runtime Service Account e IAM  
C. Cloud NAT obrigatoriamente  
D. Snapshot

## 4

Uma VM não consegue alcançar outro host e recebe timeout.

A. Adicionar Owner  
B. Verificar rota, firewall e DNS  
C. Criar Service Account key  
D. Trocar para Archive

## 5

Equipe quer centralizar VPC e compartilhar subnets entre projetos.

A. VPC Peering  
B. Shared VPC  
C. Cloud NAT  
D. Cloud DNS

## 6

Datacenter precisa de conectividade dedicada de alta capacidade.

A. Cloud Interconnect  
B. Signed URL  
C. Cloud Run Job  
D. Firestore

## 7

Workload PostgreSQL enterprise exige alta performance.

A. AlloyDB  
B. Bigtable  
C. Firestore  
D. Archive

## 8

Aplicação de BI consulta dezenas de TB com SQL.

A. Cloud SQL  
B. BigQuery  
C. Firestore  
D. Cloud Run

## 9

Usuário deve ter acesso somente até determinada data.

A. Owner  
B. IAM Condition  
C. Static Key  
D. Editor

## 10

Você quer reduzir cold start no Cloud Run.

A. Maximum instances = 0  
B. Minimum instances > 0  
C. Archive Storage  
D. Cloud VPN

## 11

Pods precisam aumentar quando CPU sobe.

A. Cluster Autoscaler  
B. HPA  
C. MIG Autohealing  
D. Cloud NAT

## 12

Nodes precisam aumentar porque não há capacidade para novos Pods.

A. HPA  
B. Cluster Autoscaler  
C. Signed URL  
D. Bucket Lifecycle

## 13

Você quer identificar erro exato às 14:31.

A. Cloud Logging  
B. Budget  
C. IAM Condition  
D. Snapshot Schedule

## 14

Você quer reproduzir uma VPC em dev/hml/prod.

A. Terraform  
B. Manual Console  
C. Screenshot  
D. DNS only

## 15

Qual comando mostra mudanças Terraform antes da aplicação?

A. terraform init  
B. terraform plan  
C. terraform destroy  
D. terraform state rm

## 16

Uma aplicação precisa baixar arquivo por URL temporária sem tornar bucket público.

A. Signed URL  
B. Owner  
C. VPC Peering  
D. Archive

## 17

Um objeto deve migrar automaticamente para Coldline após 90 dias.

A. Lifecycle Management  
B. Snapshot  
C. IAM Condition  
D. MIG

## 18

Duas VPCs independentes precisam comunicação privada e direta.

A. VPC Network Peering  
B. Cloud Storage  
C. Budget Alert  
D. GKE HPA

## 19

Peering A↔B e B↔C implica A↔C?

A. Sempre  
B. Não, peering não é transitivo  
C. Apenas com Archive  
D. Apenas com Cloud Run

## 20

Qual abordagem é geralmente preferível para autenticação de workload?

A. JSON key persistente  
B. Managed identity / federation / impersonation  
C. Shared admin account  
D. Owner

---

# Gabarito

1. B  
2. B  
3. B  
4. B  
5. B  
6. A  
7. A  
8. B  
9. B  
10. B  
11. B  
12. B  
13. A  
14. A  
15. B  
16. A  
17. A  
18. A  
19. B  
20. B

---

# Revisão após o simulado

Para cada erro, registre:

```text
Questão:
Resposta marcada:
Resposta correta:
Tema:
Motivo do erro:
Regra correta:
```

Exemplo:

```text
Tema: GKE
Erro: confundi HPA com Cluster Autoscaler
Regra:
HPA → Pods
Cluster Autoscaler → Nodes
```
