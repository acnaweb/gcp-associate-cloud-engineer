# Aula 4 — Estratégia de Prova e Gestão do Tempo

## Objetivos

Ao final desta aula, você deverá:

- Entender como administrar as 2 horas;
- Saber lidar com múltipla seleção;
- Evitar armadilhas;
- Priorizar requisitos;
- Usar eliminação de alternativas.

---

# 1. Formato

O exame padrão possui:

```text
50–60 questões
2 horas
múltipla escolha
múltipla seleção
```

Tempo médio aproximado:

```text
120 minutos / 60
≈ 2 minutos por questão
```

---

# 2. Não gaste 5 minutos em uma questão

Estratégia:

```text
Leu
 ↓
Entendeu
 ↓
Responde
```

Se travar:

```text
Marque mentalmente
 ↓
Escolha melhor opção possível
 ↓
Siga
```

---

# 3. Leia o requisito, não a tecnologia

Exemplo:

> A empresa quer minimizar administração operacional.

Isso já sugere:

```text
Managed service
```

antes mesmo de olhar alternativas.

---

# 4. Palavras-chave

## Menor custo

Procure:

- managed;
- autoscaling;
- right sizing;
- storage class;
- Spot, quando tolerável.

## Alta disponibilidade

Procure:

- regional;
- multi-zone;
- load balancer;
- HA;
- health checks.

## Menor privilégio

Procure:

- specific predefined role;
- specific resource scope;
- managed identity.

## Menor administração

Procure:

- serverless;
- managed service;
- Autopilot;
- Cloud Run.

---

# 5. Evite respostas amplas

Exemplo:

```text
Need read access
```

Evite:

```text
Owner
Editor
```

Prefira role específica.

---

# 6. Eliminação

Se a pergunta é sobre banco relacional:

Elimine:

```text
Cloud Storage
Cloud DNS
Cloud NAT
```

Depois compare os bancos.

---

# 7. Múltipla seleção

Quando a pergunta diz:

```text
Choose two
```

você precisa marcar exatamente a quantidade solicitada.

Verifique cada alternativa independentemente.

---

# 8. Não invente requisito

Se a pergunta não fala em:

```text
global scale
```

não escolha Spanner automaticamente.

Se não fala em:

```text
Kubernetes
```

não escolha GKE só porque é poderoso.

---

# 9. Prefira solução simples

O ACE tende a valorizar:

```text
Correct
+
Managed
+
Least privilege
+
Operationally simple
```

---

# 10. Regra de decisão

Quando duas alternativas parecem corretas, pergunte:

```text
Qual exige menos administração?
Qual aplica menor privilégio?
Qual atende exatamente o requisito?
Qual é serviço gerenciado apropriado?
```

---

# 11. Checklist durante prova

```text
Requirement
↓
Constraint
↓
Service
↓
Security
↓
Operations
↓
Cost
```

---

# 12. Tempo

Sugestão:

```text
Primeiros 90 min
→ responder tudo

Últimos 30 min
→ revisar questões difíceis
```

Não dependa de lembrar cada detalhe perfeito.

Use modelos mentais.

---

# 13. Questões com comando

Você não precisa decorar cada flag.

Mas reconheça:

```text
gcloud compute
gcloud storage
gcloud run
gcloud container
gcloud iam
kubectl
terraform
```

E o propósito dos comandos.

---

# 14. No dia

- Documento válido;
- Ambiente compatível se remoto;
- Internet estável;
- Chegar/conectar antes;
- Sem material não permitido;
- Ler regras da plataforma de exame.

---

# 15. Checklist

- [ ] Sei administrar tempo
- [ ] Sei lidar com múltipla seleção
- [ ] Sei eliminar alternativas
- [ ] Procuro least privilege
- [ ] Procuro managed services
- [ ] Não escolho serviço mais complexo sem requisito
