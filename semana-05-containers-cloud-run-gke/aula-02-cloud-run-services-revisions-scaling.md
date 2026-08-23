# Aula 2 — Cloud Run Services, Revisions e Scaling

## Objetivos

Ao final desta aula, você deverá:

- Entender Cloud Run Services;
- Implantar um container;
- Entender revisions;
- Entender traffic splitting;
- Entender autoscaling;
- Configurar minimum e maximum instances;
- Entender concurrency.

---

# 1. Cloud Run

Cloud Run executa containers com infraestrutura gerenciada.

```text
Container Image
      │
      ▼
 Cloud Run Service
      │
      ├── HTTPS
      ├── Scaling
      ├── Revisions
      └── IAM
```

---

# 2. Quando usar

Bom para:

- APIs;
- Microsserviços;
- Web apps;
- Backends HTTP;
- Event-driven workloads;
- Containers stateless.

---

# 3. Deploy

```bash
PROJECT_ID=$(gcloud config get-value project)

gcloud run deploy ace-web \
  --image=southamerica-east1-docker.pkg.dev/$PROJECT_ID/ace-containers/ace-web:v1 \
  --region=southamerica-east1
```

---

# 4. Público x autenticado

Por padrão, acesso pode exigir autenticação.

Para serviço público, conforme política:

```bash
gcloud run services add-iam-policy-binding ace-web \
  --region=southamerica-east1 \
  --member="allUsers" \
  --role="roles/run.invoker"
```

Em ambientes corporativos, prefira autenticação quando possível.

---

# 5. Revisions

Cada deploy ou alteração de configuração cria uma revisão imutável.

```text
Service: ace-web
   │
   ├── Revision v1
   ├── Revision v2
   └── Revision v3
```

Uma revisão não é editada depois de criada.

---

# 6. Traffic Splitting

Você pode dividir tráfego entre revisões.

Exemplo:

```text
100% traffic
     │
     ├── 90% → revision-v2
     └── 10% → revision-v3
```

Útil para:

- Canary;
- Gradual rollout;
- Testes controlados.

---

# 7. Listar revisões

```bash
gcloud run revisions list \
  --service=ace-web \
  --region=southamerica-east1
```

---

# 8. Autoscaling

Cloud Run escala automaticamente por padrão.

Modelo:

```text
Requests ↑
    │
    ▼
More instances
```

Quando não há tráfego, pode escalar para zero, salvo configurações como minimum instances.

---

# 9. Minimum Instances

Use para manter instâncias aquecidas.

```text
min-instances = 1
```

Benefício:

- Redução de cold start.

Trade-off:

- Custo maior.

---

# 10. Maximum Instances

Limita escalabilidade.

Bom para:

- Controlar custo;
- Proteger banco downstream;
- Evitar excesso de conexões.

---

# 11. Configurar scaling

```bash
gcloud run services update ace-web \
  --region=southamerica-east1 \
  --min=1 \
  --max=10
```

---

# 12. Concurrency

Concurrency define quantas requisições uma instância pode processar simultaneamente.

```text
Instance
  ├── Request 1
  ├── Request 2
  ├── Request 3
  └── ...
```

---

# 13. Environment Variables

```bash
gcloud run services update ace-web \
  --region=southamerica-east1 \
  --set-env-vars=ENVIRONMENT=dev
```

Alterar configuração gera nova revision.

---

# 14. Rollback

Como revisões anteriores existem, você pode redirecionar tráfego novamente.

Modelo:

```text
revision-v3 problematic
       ↓
traffic → revision-v2
```

---

# 15. Questões Estilo ACE

## Questão 1

Você quer executar API containerizada sem administrar servidores.

**Resposta:** Cloud Run.

## Questão 2

Uma versão nova deve receber apenas 10% do tráfego.

**Resposta:** traffic splitting entre revisions.

## Questão 3

Você quer reduzir cold start.

**Resposta:** minimum instances.

## Questão 4

Você quer proteger o banco contra quantidade excessiva de instâncias.

**Resposta:** maximum instances.

---

# 16. Checklist

- [ ] Entendo Cloud Run Service
- [ ] Sei fazer deploy
- [ ] Entendo revisions
- [ ] Entendo traffic splitting
- [ ] Entendo min/max instances
- [ ] Entendo concurrency
