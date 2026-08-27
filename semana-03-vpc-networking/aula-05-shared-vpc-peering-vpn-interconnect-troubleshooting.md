# Aula 5 — Shared VPC, Peering, VPN, Interconnect e Troubleshooting

## Objetivos

Ao final desta aula, você deverá:

- Entender Shared VPC;
- Diferenciar Host Project e Service Project;
- Entender VPC Network Peering;
- Entender Cloud VPN;
- Entender Cloud Interconnect;
- Diferenciar conectividade privada entre ambientes;
- Seguir um fluxo de troubleshooting.

---

# 1. Shared VPC

Shared VPC permite centralizar uma VPC em um projeto e compartilhar subnets com outros projetos da mesma organização.

```text
Host Project
   │
   └── Shared VPC
         │
    ┌────┴────┐
    ▼         ▼
Service     Service
Project A   Project B
```

---

# 2. Host Project

Contém a Shared VPC e seus componentes de rede.

---

# 3. Service Project

Projetos associados podem criar recursos usando subnets compartilhadas, conforme IAM.

Isso ajuda a separar:

```text
Network administration
        +
Application ownership
```

---

# 4. VPC Network Peering

Conecta duas VPCs permitindo comunicação privada entre elas.

```text
VPC A
  │
Peering
  │
VPC B
```

Pode envolver projetos ou organizações diferentes, conforme configuração e políticas aplicáveis.

---

# 5. Peering não é transitivo

Modelo importante:

```text
VPC A ↔ VPC B ↔ VPC C
```

Não significa automaticamente:

```text
VPC A ↔ VPC C
```

Não assuma transitividade.

---

# 6. Cloud VPN

Usado para conectividade criptografada através da internet.

```text
On-Premises
     │
     ▼
Internet
     │
Encrypted Tunnel
     │
     ▼
Cloud VPN
     │
     ▼
VPC
```

Boa opção para:

- Conectividade híbrida;
- Implementação rápida;
- Tráfego criptografado;
- Backup de conectividade.

---

# 7. HA VPN

HA VPN oferece arquitetura de alta disponibilidade para VPN.

Para o ACE, reconheça que é a opção moderna/recomendada quando alta disponibilidade é requisito.

---

# 8. Cloud Interconnect

Fornece conectividade dedicada entre rede on-premises e Google Cloud.

```text
On-Premises
     │
Dedicated / Partner connectivity
     │
     ▼
Google Cloud
```

Tipos principais:

- Dedicated Interconnect;
- Partner Interconnect.

---

# 9. VPN x Interconnect

| Requisito | Solução típica |
|---|---|
| Rápido e criptografado pela internet | Cloud VPN |
| Conectividade dedicada / alta capacidade | Cloud Interconnect |
| Não possui presença compatível para Dedicated | Partner Interconnect |
| Alta disponibilidade via VPN | HA VPN |

---

# 10. Cloud Router e BGP (Border Gateway Protocol)

Cloud Router troca rotas dinamicamente usando BGP em cenários como:

- HA VPN;
- Cloud Interconnect.

```text
On-Prem Router
      │
      │ BGP
      ▼
Cloud Router
      │
      ▼
VPC
```

---

# 11. Shared VPC x Peering

## Shared VPC

```text
Mesma organização
Centralização de rede
Host + Service Projects
```

## Peering

```text
Conecta VPCs independentes
Comunicação privada
Sem transformar uma rede na outra
```

---

# 12. Fluxo de Troubleshooting

Quando uma conexão falha:

```text
1. DNS resolve?
       ↓
2. IP correto?
       ↓
3. VPC/subnet correta?
       ↓
4. Route existe?
       ↓
5. Firewall permite?
       ↓
6. NAT/VPN/Peering está correto?
       ↓
7. Serviço está escutando?
       ↓
8. IAM interfere no plano de controle?
```

---

# 13. Troubleshooting de VPN

Verifique:

- Tunnel status;
- Peer IP;
- Shared secret/configuração;
- BGP session;
- Cloud Router;
- Rotas aprendidas/anunciadas;
- Firewall.

---

# 14. Troubleshooting de Peering

Verifique:

- Peering ativo dos dois lados;
- Ranges sem conflito;
- Rotas importadas/exportadas conforme necessário;
- Firewall;
- Ausência de expectativa de transitividade.

---

# 15. Comandos úteis

Listar peerings:

```bash
gcloud compute networks peerings list
```

Listar VPN tunnels:

```bash
gcloud compute vpn-tunnels list
```

Listar routers:

```bash
gcloud compute routers list
```

Listar rotas:

```bash
gcloud compute routes list
```

---

# 16. Arquitetura Enterprise

```text
                    On-Premises
                         │
                 VPN / Interconnect
                         │
                         ▼
                    Host Project
                         │
                    Shared VPC
                 ┌───────┼───────┐
                 ▼       ▼       ▼
             Project A Project B Project C
```

---

# 17. Pegadinhas ACE

- Shared VPC centraliza rede em Host Project.
- Service Projects consomem subnets compartilhadas.
- Peering não é transitivo.
- VPN usa internet com túnel criptografado.
- Interconnect oferece conectividade dedicada.
- Cloud Router/BGP aparece em conectividade dinâmica.
- Antes de culpar IAM, verifique rede, rota, firewall e serviço.

---

# 18. Questões Estilo ACE

## Questão 1

A empresa quer centralizar administração da rede e permitir que vários projetos usem as mesmas subnets.

**Resposta:** Shared VPC.

## Questão 2

Duas VPCs independentes precisam se comunicar via IP privado.

**Resposta:** VPC Network Peering, se os requisitos forem compatíveis.

## Questão 3

Datacenter precisa de conexão dedicada de alta capacidade.

**Resposta:** Cloud Interconnect.

## Questão 4

Conectividade híbrida precisa ser estabelecida rapidamente usando internet e criptografia.

**Resposta:** Cloud VPN / HA VPN conforme disponibilidade exigida.

---

# 19. Checklist

- [ ] Entendo Shared VPC
- [ ] Sei diferenciar Host e Service Project
- [ ] Entendo VPC Peering
- [ ] Sei que Peering não é transitivo
- [ ] Entendo Cloud VPN
- [ ] Entendo HA VPN
- [ ] Entendo Cloud Interconnect
- [ ] Entendo Cloud Router/BGP
- [ ] Sei seguir fluxo de troubleshooting
