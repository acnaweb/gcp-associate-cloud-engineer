# Aula 4 — Instance Templates e Managed Instance Groups

## Objetivos

Ao final desta aula, você deverá:

- Entender Instance Templates;
- Criar templates reutilizáveis;
- Entender Managed Instance Groups;
- Diferenciar MIG zonal e regional;
- Entender alta disponibilidade com MIG;
- Reconhecer MIG stateless e stateful.

---

# 1. Instance Template

Um Instance Template guarda uma configuração reutilizável de VM.

Exemplo:

```text
Instance Template
      │
      ├── Machine Type
      ├── Boot Image
      ├── Network
      ├── Metadata
      ├── Startup Script
      └── Service Account
```

É a base para criar VMs consistentes e para Managed Instance Groups.

---

# 2. Por que usar?

Sem template:

```text
VM1 → configuração manual
VM2 → configuração manual
VM3 → configuração manual
```

Com template:

```text
Instance Template
      │
  ┌───┼───┐
  ▼   ▼   ▼
 VM1 VM2 VM3
```

Resultado:

- Consistência;
- Reprodutibilidade;
- Escala;
- Atualizações mais controladas.

---

# 3. Criar Instance Template

```bash
gcloud compute instance-templates create ace-web-template-v1 \
  --machine-type=e2-medium \
  --metadata-from-file startup-script=startup.sh
```

Listar:

```bash
gcloud compute instance-templates list
```

---

# 4. Managed Instance Group

Um MIG administra um conjunto de instâncias criadas a partir de um template.

```text
Instance Template
       │
       ▼
Managed Instance Group
       │
   ┌───┼───┐
   ▼   ▼   ▼
  VM1 VM2 VM3
```

---

# 5. Benefícios do MIG

- Criação/recriação de VMs;
- Autoscaling;
- Autohealing;
- Atualizações controladas;
- Integração com Load Balancer;
- Distribuição entre zones em MIG regional.

---

# 6. MIG Zonal

```text
Zone A
  │
  └── MIG
      ├── VM1
      ├── VM2
      └── VM3
```

Se a zone falhar, o grupo pode ser afetado.

---

# 7. MIG Regional

```text
Region
  │
  ├── Zone A → VM1
  ├── Zone B → VM2
  └── Zone C → VM3
```

Melhor opção para alta disponibilidade contra falha zonal.

---

# 8. Criar MIG

Exemplo zonal:

```bash
gcloud compute instance-groups managed create ace-web-mig \
  --base-instance-name=ace-web \
  --template=ace-web-template-v1 \
  --size=2 \
  --zone=southamerica-east1-a
```

Listar:

```bash
gcloud compute instance-groups managed list
```

---

# 9. Redimensionar manualmente

```bash
gcloud compute instance-groups managed resize ace-web-mig \
  --size=3 \
  --zone=southamerica-east1-a
```

---

# 10. Stateless x Stateful MIG

## Stateless

As instâncias podem ser recriadas livremente.

Bom para:

- Web;
- APIs;
- workers;
- frontends.

## Stateful

Preserva estado específico como discos e metadata em cenários compatíveis.

Bom para workloads que precisam manter determinados dados/identidade.

Para o ACE, o mais importante é saber:

> O MIG stateless é o padrão mental para escalabilidade horizontal.

---

# 11. Atualizações

Você pode criar nova versão do template:

```text
ace-web-template-v1
        ↓
ace-web-template-v2
```

e atualizar o MIG gradualmente.

Isso permite:

- rolling updates;
- canary;
- menor indisponibilidade.

---

# 12. MIG + Load Balancer

Arquitetura típica:

```text
Internet
   │
   ▼
Load Balancer
   │
   ▼
Regional MIG
   │
 ┌─┼─┐
 ▼ ▼ ▼
VM VM VM
```

---

# 13. Laboratório

```bash
# Criar template
gcloud compute instance-templates create ace-web-template-v1 \
  --machine-type=e2-medium \
  --metadata-from-file startup-script=startup.sh

# Criar MIG zonal
gcloud compute instance-groups managed create ace-web-mig \
  --base-instance-name=ace-web \
  --template=ace-web-template-v1 \
  --size=2 \
  --zone=southamerica-east1-a

# Listar
gcloud compute instance-groups managed list

# Redimensionar
gcloud compute instance-groups managed resize ace-web-mig \
  --size=3 \
  --zone=southamerica-east1-a
```

---

# 14. Pegadinhas ACE

- MIG usa Instance Template.
- MIG regional distribui instâncias entre zones.
- MIG regional é preferível para maior disponibilidade.
- Stateless MIG é adequado para workloads horizontalmente escaláveis.
- Stateful MIG existe, mas exige configuração específica.

---

# 15. Questões Estilo ACE

## Questão 1

Você precisa criar 20 VMs com a mesma configuração.

**Resposta:** Instance Template + MIG.

## Questão 2

Você precisa tolerar falha de uma zone.

**Resposta:** Regional MIG.

## Questão 3

Você quer atualizar VMs gradualmente.

**Resposta:** nova versão de template + rolling update no MIG.

---

# 16. Checklist

- [ ] Entendo Instance Template
- [ ] Sei criar template
- [ ] Entendo MIG
- [ ] Sei criar MIG
- [ ] Sei diferenciar zonal e regional MIG
- [ ] Entendo stateless e stateful MIG
- [ ] Entendo MIG + Load Balancer
