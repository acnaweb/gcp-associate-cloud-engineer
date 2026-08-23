# Aula 1 — VPC, Subnets, CIDR e IPs

## Objetivos

Ao final desta aula, você deverá:

- Entender o que é uma VPC;
- Saber que VPC é global e subnet é regional;
- Diferenciar auto mode e custom mode;
- Entender CIDR;
- Diferenciar IP interno e externo;
- Criar uma VPC customizada e suas subnets.

---

# 1. O que é uma VPC?

Uma Virtual Private Cloud é a rede virtual na qual recursos do Google Cloud se comunicam.

```text
VPC
 │
 ├── Subnet A
 │     └── VMs
 │
 └── Subnet B
       └── VMs
```

Uma VPC pode conter recursos em várias regiões.

---

# 2. Escopo da VPC

Ponto fundamental para o ACE:

```text
VPC     → Global
Subnet  → Regional
VM      → Zonal
```

Exemplo:

```text
VPC: corp-vpc
   │
   ├── subnet-sp
   │     region: southamerica-east1
   │
   └── subnet-us
         region: us-central1
```

---

# 3. Auto Mode x Custom Mode

## Auto Mode

Ao criar uma VPC auto mode, o Google cria automaticamente uma subnet em cada região suportada.

```text
Auto Mode VPC
   ├── subnet region A
   ├── subnet region B
   ├── subnet region C
   └── ...
```

Bom para:

- Laboratórios;
- Cenários simples;
- Primeiros testes.

## Custom Mode

Você cria as subnets explicitamente.

```text
Custom VPC
   ├── subnet-app
   └── subnet-data
```

Melhor para ambientes corporativos e produção.

---

# 4. CIDR

CIDR define o range de endereços IP.

Exemplo:

```text
10.10.0.0/24
```

Um `/24` possui 256 endereços no espaço teórico.

Exemplos:

```text
10.10.0.0/24
10.20.0.0/24
192.168.10.0/24
```

Evite ranges sobrepostos quando houver necessidade de conectividade entre redes.

---

# 5. Subnets

Cada subnet possui um range primário.

Exemplo:

```text
subnet-app
region: southamerica-east1
range: 10.10.0.0/24
```

Você pode ter mais de uma subnet na mesma região.

---

# 6. IP Interno

Usado para comunicação dentro da rede.

```text
VM1 10.10.0.2
      │
      ▼
VPC
      │
      ▼
VM2 10.10.0.3
```

---

# 7. IP Externo

Permite comunicação direta com a internet, sujeito às regras de firewall e demais controles.

```text
Internet
   │
External IP
   ▼
  VM
```

Nem toda VM precisa de IP externo.

---

# 8. Laboratório — Criar VPC Customizada

```bash
gcloud compute networks create ace-vpc \
  --subnet-mode=custom
```

Listar:

```bash
gcloud compute networks list
```

---

# 9. Criar Subnet

```bash
gcloud compute networks subnets create ace-subnet-sp \
  --network=ace-vpc \
  --region=southamerica-east1 \
  --range=10.10.0.0/24
```

Criar outra:

```bash
gcloud compute networks subnets create ace-subnet-us \
  --network=ace-vpc \
  --region=us-central1 \
  --range=10.20.0.0/24
```

---

# 10. Listar Subnets

```bash
gcloud compute networks subnets list \
  --network=ace-vpc
```

---

# 11. Criar VM na Subnet

```bash
gcloud compute instances create ace-net-vm-01 \
  --zone=southamerica-east1-a \
  --machine-type=e2-micro \
  --network=ace-vpc \
  --subnet=ace-subnet-sp
```

---

# 12. VPC com múltiplas regiões

```text
            ace-vpc
               │
       ┌───────┴────────┐
       ▼                ▼
southamerica-east1   us-central1
  10.10.0.0/24       10.20.0.0/24
       │                │
      VM               VM
```

A VPC continua sendo um recurso global.

---

# 13. Pegadinhas ACE

- VPC não é regional.
- Subnet não é zonal.
- Uma subnet pertence a uma única região.
- Uma VPC pode ter várias subnets na mesma região.
- Custom mode dá maior controle sobre endereçamento.
- Evite CIDRs sobrepostos em redes que precisarão se conectar.

---

# 14. Questões Estilo ACE

## Questão 1

Uma subnet foi criada em `southamerica-east1`.

Qual seu escopo?

**Resposta:** regional.

## Questão 2

Uma VPC possui subnets em São Paulo e Iowa.

Isso é válido?

**Resposta:** sim, pois VPC é global.

## Questão 3

Você precisa controlar cuidadosamente os ranges usados por cada ambiente.

**Resposta:** Custom Mode VPC.

---

# 15. Checklist

- [ ] Entendo VPC
- [ ] Sei que VPC é global
- [ ] Sei que subnet é regional
- [ ] Entendo auto mode e custom mode
- [ ] Entendo CIDR em nível básico
- [ ] Sei criar VPC customizada
- [ ] Sei criar subnet
- [ ] Entendo IP interno e externo
