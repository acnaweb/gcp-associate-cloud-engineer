# Aula 3 — Cloud NAT, Private Google Access e Cloud DNS

## Objetivos

Ao final desta aula, você deverá:

- Entender Cloud NAT;
- Saber quando uma VM privada precisa de NAT;
- Entender Private Google Access;
- Diferenciar acesso à internet de acesso a APIs Google;
- Entender Cloud DNS em nível ACE.

---

# 1. VM sem IP externo

Uma VM pode ter apenas IP interno.

```text
Private VM
   │
Internal IP
   ▼
  VPC
```

Isso reduz exposição direta à internet.

---

# 2. Problema: saída para internet

Uma VM sem IP externo pode precisar baixar atualizações ou acessar APIs externas.

```text
Private VM
    │
    ▼
Cloud NAT
    │
    ▼
Internet
```

---

# 3. Cloud NAT

Cloud NAT fornece tradução de endereços para tráfego de saída.

Características importantes:

- Não exige IP externo na VM;
- Não cria caminho de entrada iniciado pela internet;
- É usado para saída;
- Trabalha em conjunto com Cloud Router.

---

# 4. Cloud Router

Cloud NAT é configurado usando um Cloud Router.

```text
Private VM
   │
   ▼
Subnet
   │
   ▼
Cloud NAT
   │
Cloud Router
   │
   ▼
Internet
```

Cloud Router também é importante em conectividade dinâmica com VPN/Interconnect usando BGP.

---

# 5. Laboratório — Cloud Router

```bash
gcloud compute routers create ace-router \
  --network=ace-vpc \
  --region=southamerica-east1
```

---

# 6. Criar Cloud NAT

```bash
gcloud compute routers nats create ace-nat \
  --router=ace-router \
  --region=southamerica-east1 \
  --nat-all-subnet-ip-ranges \
  --auto-allocate-nat-external-ips
```

---

# 7. Private Google Access

Private Google Access permite que VMs sem IP externo acessem APIs e serviços Google compatíveis usando endereços internos/rotas específicas.

Modelo:

```text
VM sem IP externo
      │
      ▼
Private Google Access
      │
      ▼
Google APIs
```

---

# 8. Habilitar na subnet

```bash
gcloud compute networks subnets update ace-subnet-sp \
  --region=southamerica-east1 \
  --enable-private-ip-google-access
```

---

# 9. Cloud NAT x Private Google Access

| Necessidade | Recurso |
|---|---|
| Acessar internet geral sem IP externo | Cloud NAT |
| Acessar APIs Google sem IP externo | Private Google Access |
| Receber conexão direta da internet | Não é função do Cloud NAT |

---

# 10. Cloud DNS

Cloud DNS é o serviço gerenciado de DNS do Google Cloud.

```text
app.exemplo.com
      │
      ▼
Cloud DNS
      │
      ▼
IP / Resource
```

Pode trabalhar com zonas:

- Públicas;
- Privadas.

---

# 11. Public Zone x Private Zone

## Public Zone

Resolução na internet.

## Private Zone

Resolução dentro de redes VPC autorizadas.

---

# 12. Laboratório conceitual

Listar zonas:

```bash
gcloud dns managed-zones list
```

Criar zona privada:

```bash
gcloud dns managed-zones create ace-private-zone \
  --dns-name=ace.internal. \
  --description="ACE private DNS zone" \
  --visibility=private \
  --networks=ace-vpc
```

---

# 13. Pegadinhas ACE

- Cloud NAT é para saída, não entrada.
- Cloud NAT não exige IP externo individual nas VMs.
- Private Google Access é diferente de acesso geral à internet.
- Cloud DNS resolve nomes; não substitui firewall ou rotas.
- Zonas privadas podem ser vinculadas a VPCs.

---

# 14. Questões Estilo ACE

## Questão 1

VM privada precisa instalar pacotes da internet sem receber IP externo.

**Resposta:** Cloud NAT.

## Questão 2

VM privada precisa acessar APIs Google suportadas sem IP externo.

**Resposta:** Private Google Access.

## Questão 3

Aplicações internas precisam resolver `db.ace.internal`.

**Resposta:** Cloud DNS private zone.

---

# 15. Checklist

- [ ] Entendo Cloud NAT
- [ ] Entendo Cloud Router
- [ ] Entendo Private Google Access
- [ ] Sei diferenciar NAT e acesso privado a APIs Google
- [ ] Entendo Cloud DNS
- [ ] Sei diferenciar zona pública e privada
