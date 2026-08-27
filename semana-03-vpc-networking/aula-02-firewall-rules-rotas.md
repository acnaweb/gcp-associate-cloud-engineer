# Aula 2 — Firewall Rules e Rotas

## Objetivos

Ao final desta aula, você deverá:

- Entender regras de firewall;
- Diferenciar ingress e egress;
- Entender prioridade;
- Trabalhar com network tags;
- Entender rotas;
- Diagnosticar problemas básicos de conectividade.

---

# 1. Regras de Firewall

Regras de firewall controlam tráfego de entrada e saída das VMs.

```text
Source
  │
  ▼
Firewall Rule
  │
  ▼
Target VM
```

---

# 2. Ingress x Egress

## Ingress

Tráfego chegando ao recurso.

```text
Client → VM
```

## Egress

Tráfego saindo do recurso.

```text
VM → Destination
```

---

# 3. Elementos de uma regra

Uma regra pode considerar:

- Direção;
- Prioridade;
- Ação allow/deny;
- Protocolo;
- Porta;
- Source range;
- Destination range;
- Target tag;
- Target service account.

---

# 4. Prioridade

Quanto menor o número, maior a prioridade.

```text
priority 100
   ↓
avaliada antes de
priority 1000
```

No ACE, sempre observe conflitos entre regras.

---

# 5. Network Tags

Uma regra pode ser aplicada a VMs com uma tag.

```text
Firewall Rule
 target-tag=web
      │
      ├── VM1 tag=web
      └── VM2 tag=web
```

---

# 6. Criar regra HTTP

```bash
gcloud compute firewall-rules create ace-allow-http \
  --network=ace-vpc \
  --direction=INGRESS \
  --priority=1000 \
  --action=ALLOW \
  --rules=tcp:80 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=web
```

* Exemplo: permitir tráfego da subnet 10.10.0.0/24 para instâncias da mesma VPC na porta 8080

```bash
gcloud compute firewall-rules create allow-subnet-sp-to-us-8080 \
  --network=vpc-producao \
  --direction=INGRESS \
  --priority=1000 \
  --action=ALLOW \
  --rules=tcp:8080 \
  --source-ranges=10.10.0.0/24
```

---

# 7. Aplicar tag à VM

```bash
gcloud compute instances add-tags ace-net-vm-01 \
  --zone=southamerica-east1-a \
  --tags=web
```

---

# 8. Listar regras

```bash
gcloud compute firewall-rules list
```

Filtrar rede:

```bash
gcloud compute firewall-rules list \
  --filter="network:ace-vpc"
```

---

# 9. Rotas

Rotas determinam para onde o tráfego deve ser encaminhado.

```text
Destination
    │
    ▼
Route
    │
    ▼
Next Hop
```

Exemplo conceitual:

```text
10.20.0.0/24
    ↓
local VPC route
    ↓
subnet-us
```

---

# 10. Rotas de Subnet

O Google cria rotas para ranges de subnet.

Isso permite comunicação interna dentro da VPC, desde que firewall permita.

---

# 11. Default Route

Uma VPC pode possuir uma rota default como:

```text
0.0.0.0/0
```

Essa rota aponta tráfego não conhecido para o gateway de internet padrão, dependendo da configuração.

Ter uma rota não significa automaticamente ter acesso.

Você também precisa considerar:

- IP externo ou Cloud NAT;
- Firewall;
- Configuração do recurso.

---

# 12. Listar rotas

```bash
gcloud compute routes list
```

Filtrar:

```bash
gcloud compute routes list \
  --filter="network:ace-vpc"
```

---

# 13. Rota x Firewall

Não confunda:

```text
Route
 = onde enviar
```

```text
Firewall
 = permitir ou negar
```

Você normalmente precisa dos dois aspectos funcionando.

---

# 14. Troubleshooting básico

Se VM A não alcança VM B:

```text
1. IP correto?
2. Mesma VPC ou conectividade entre redes?
3. Route existe?
4. Firewall permite?
5. Aplicação está escutando?
6. Porta correta?
```

---

# 15. Laboratório

```bash
# Criar regra SSH restrita ao range interno
gcloud compute firewall-rules create ace-allow-internal-ssh \
  --network=ace-vpc \
  --direction=INGRESS \
  --action=ALLOW \
  --rules=tcp:22 \
  --source-ranges=10.10.0.0/24

# Listar firewall
gcloud compute firewall-rules list \
  --filter="network:ace-vpc"

# Listar rotas
gcloud compute routes list \
  --filter="network:ace-vpc"
```

---

# 16. Pegadinhas ACE

- Rota e firewall têm funções diferentes.
- Menor número de prioridade significa maior prioridade.
- Tag pode ser usada para selecionar targets.
- A rota pode existir e o tráfego ainda ser bloqueado pelo firewall.
- Permitir `0.0.0.0/0` é amplo e deve ser usado com cautela.

---

# 17. Questões Estilo ACE

## Questão 1

Uma rota existe, mas a VM não aceita conexões TCP/80.

O que verificar?

**Resposta:** firewall e aplicação.

## Questão 2

Duas regras conflitam: prioridade 100 e 1000.

Qual é avaliada primeiro?

**Resposta:** prioridade 100.

## Questão 3

Você quer liberar HTTP apenas para VMs web.

**Resposta:** regra de firewall com target apropriado, como network tag ou service account.

---

# 18. Checklist

- [ ] Entendo ingress e egress
- [ ] Entendo prioridade
- [ ] Sei criar firewall rule
- [ ] Entendo network tags
- [ ] Entendo rotas
- [ ] Sei diferenciar rota e firewall
- [ ] Sei seguir troubleshooting básico
