# Aula 3 — Simulado 2

## Instruções

Faça sem consultar o gabarito. Para cada resposta, escreva em uma frase por que as outras opções não atendem ao requisito.

## Questão 1

Uma VM sem IP externo precisa baixar atualizações da internet.

A. VPC Peering
B. Cloud Armor
C. Cloud NAT
D. Cloud DNS

## Questão 2

Uma aplicação containerizada HTTP stateless precisa escalar a zero.

A. Bigtable
B. GKE Standard
C. Cloud Run
D. Compute Engine

## Questão 3

Uma SA precisa apenas ler objetos de um bucket.

A. roles/editor
B. roles/storage.objectViewer
C. roles/storage.admin
D. roles/owner

## Questão 4

Duas subnets em regiões diferentes pertencem à mesma VPC.

A. Podem comunicar via VPC global, sujeito a firewall/rotas
B. Precisam VPN
C. Precisam Interconnect
D. Precisam Peering

## Questão 5

Banco relacional global horizontalmente escalável.

A. Firestore
B. Bigtable
C. Cloud SQL
D. Spanner

## Questão 6

Warehouse analítico serverless.

A. Memorystore
B. BigQuery
C. Cloud SQL
D. Firestore

## Questão 7

MIG precisa adicionar VMs por CPU.

A. Autohealing
B. Autoscaler
C. Health check
D. Snapshot

## Questão 8

Cloud Run retorna 403, serviço está Ready.

A. Verificar invoker IAM
B. Criar route
C. Trocar region
D. Aumentar max instances

## Questão 9

Qual recurso troca rotas dinamicamente com BGP?

A. Cloud DNS
B. URL Map
C. Cloud Router
D. Cloud NAT

## Questão 10

Budget atingiu 100%.

A. VMs são apagadas
B. Projeto desliga
C. Por padrão é mecanismo de alerta/acompanhamento
D. Quota zera

## Questão 11

Terraform mostra mudanças antes de executar.

A. apply
B. plan
C. destroy
D. state rm

## Questão 12

Kubernetes Service sem endpoints.

A. Crie snapshot
B. Aumente quota BigQuery
C. Troque billing
D. Compare selectors e labels

## Questão 13

Cloud SQL retorna database does not exist.

A. Criar Cloud NAT
B. Mudar machine type
C. Verificar databases da instância
D. Abrir firewall

## Questão 14

GitHub precisa autenticar no GCP sem chave longa.

A. Cloud DNS
B. WIF
C. Owner key JSON
D. Static IP

## Questão 15

Pod mostra ImagePullBackOff.

A. Ver image/tag/registry
B. Ver BigQuery slots
C. Ver Cloud Router
D. Ver budget

# Gabarito comentado

**1. C — Cloud NAT**

Cloud NAT fornece saída para internet a recursos sem IP externo.

**2. C — Cloud Run**

Cloud Run é serverless para containers request-driven.

**3. B — roles/storage.objectViewer**

Object Viewer atende leitura com menor privilégio.

**4. A — Podem comunicar via VPC global, sujeito a firewall/rotas**

VPC é global e subnets são regionais.

**5. D — Spanner**

Spanner é relacional distribuído/global.

**6. B — BigQuery**

BigQuery é serviço analítico.

**7. B — Autoscaler**

Autoscaler altera capacidade.

**8. A — Verificar invoker IAM**

403 com serviço saudável aponta para autorização.

**9. C — Cloud Router**

Cloud Router gerencia BGP.

**10. C — Por padrão é mecanismo de alerta/acompanhamento**

Budget não é quota/bloqueio automático.

**11. B — plan**

`terraform plan`.

**12. D — Compare selectors e labels**

Service seleciona Pods por labels.

**13. C — Verificar databases da instância**

O erro nomeia o objeto lógico inexistente.

**14. B — WIF**

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
