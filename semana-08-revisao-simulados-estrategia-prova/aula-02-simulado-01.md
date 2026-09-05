# Aula 2 — Simulado 1

## Instruções

Faça sem consultar o gabarito. Para cada resposta, escreva em uma frase por que as outras opções não atendem ao requisito.

## Questão 1

Uma VM sem IP externo precisa baixar atualizações da internet.

A. Cloud NAT
B. Cloud DNS
C. VPC Peering
D. Cloud Armor

## Questão 2

Uma aplicação containerizada HTTP stateless precisa escalar a zero.

A. GKE Standard
B. Cloud Run
C. Compute Engine
D. Bigtable

## Questão 3

Uma SA precisa apenas ler objetos de um bucket.

A. roles/editor
B. roles/storage.objectViewer
C. roles/storage.admin
D. roles/owner

## Questão 4

Duas subnets em regiões diferentes pertencem à mesma VPC.

A. Precisam Peering
B. Podem comunicar via VPC global, sujeito a firewall/rotas
C. Precisam VPN
D. Precisam Interconnect

## Questão 5

Banco relacional global horizontalmente escalável.

A. Cloud SQL
B. Spanner
C. Firestore
D. Bigtable

## Questão 6

Warehouse analítico serverless.

A. BigQuery
B. Cloud SQL
C. Firestore
D. Memorystore

## Questão 7

MIG precisa adicionar VMs por CPU.

A. Autohealing
B. Autoscaler
C. Health check
D. Snapshot

## Questão 8

Cloud Run retorna 403, serviço está Ready.

A. Aumentar max instances
B. Verificar invoker IAM
C. Criar route
D. Trocar region

## Questão 9

Qual recurso troca rotas dinamicamente com BGP?

A. Cloud Router
B. Cloud NAT
C. Cloud DNS
D. URL Map

## Questão 10

Budget atingiu 100%.

A. Projeto desliga
B. Por padrão é mecanismo de alerta/acompanhamento
C. Quota zera
D. VMs são apagadas

## Questão 11

Terraform mostra mudanças antes de executar.

A. apply
B. plan
C. destroy
D. state rm

## Questão 12

Kubernetes Service sem endpoints.

A. Compare selectors e labels
B. Crie snapshot
C. Aumente quota BigQuery
D. Troque billing

## Questão 13

Cloud SQL retorna database does not exist.

A. Verificar databases da instância
B. Abrir firewall
C. Criar Cloud NAT
D. Mudar machine type

## Questão 14

GitHub precisa autenticar no GCP sem chave longa.

A. WIF
B. Owner key JSON
C. Static IP
D. Cloud DNS

## Questão 15

Pod mostra ImagePullBackOff.

A. Ver image/tag/registry
B. Ver BigQuery slots
C. Ver Cloud Router
D. Ver budget

# Gabarito comentado

**1. A — Cloud NAT**

Cloud NAT fornece saída para internet a recursos sem IP externo.

**2. B — Cloud Run**

Cloud Run é serverless para containers request-driven.

**3. B — roles/storage.objectViewer**

Object Viewer atende leitura com menor privilégio.

**4. B — Podem comunicar via VPC global, sujeito a firewall/rotas**

VPC é global e subnets são regionais.

**5. B — Spanner**

Spanner é relacional distribuído/global.

**6. A — BigQuery**

BigQuery é serviço analítico.

**7. B — Autoscaler**

Autoscaler altera capacidade.

**8. B — Verificar invoker IAM**

403 com serviço saudável aponta para autorização.

**9. A — Cloud Router**

Cloud Router gerencia BGP.

**10. B — Por padrão é mecanismo de alerta/acompanhamento**

Budget não é quota/bloqueio automático.

**11. B — plan**

`terraform plan`.

**12. A — Compare selectors e labels**

Service seleciona Pods por labels.

**13. A — Verificar databases da instância**

O erro nomeia o objeto lógico inexistente.

**14. A — WIF**

WIF fornece federação/credenciais curtas.

**15. A — Ver image/tag/registry**

Eventos do Pod apontam pull de imagem.

# Análise pós-simulado

```text
Questão:
Domínio:
Minha resposta:
Resposta correta:
Qual requisito eu ignorei?
Qual laboratório devo repetir?
```
