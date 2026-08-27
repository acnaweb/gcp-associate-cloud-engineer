# Aula 2 — Cloud Run Services, Revisions e Scaling

## Objetivos

Ao final desta aula, você deverá:

- Deploy Cloud Run;
- Criar revisions;
- Dividir tráfego;
- Testar scaling e auth;

---

# 1. Modelo mental

```text
Artifact Registry ──> Cloud Run Service
                       ├─ revision v1
                       ├─ revision v2
                       └─ traffic split
```

O objetivo desta aula não é apenas reconhecer nomes de serviços. Você deve conseguir **criar, inspecionar, testar e explicar** o comportamento dos recursos.

---

# 2. Regra de estudo da aula

Use sempre este ciclo:

```text
Conceito
   ↓
Criar
   ↓
Inspecionar
   ↓
Testar
   ↓
Quebrar propositalmente
   ↓
Diagnosticar
   ↓
Corrigir
   ↓
Remover
```

---

# 3. Laboratório principal

Use uma imagem pública simples:
```bash
export REGION=us-central1
gcloud services enable run.googleapis.com

gcloud run deploy ace-web \
  --image=us-docker.pkg.dev/cloudrun/container/hello \
  --region=$REGION \
  --allow-unauthenticated

gcloud run services describe ace-web --region=$REGION
gcloud run revisions list --service=ace-web --region=$REGION
```

Nova revision alterando env:
```bash
gcloud run services update ace-web \
  --region=$REGION \
  --set-env-vars=VERSAO=v2
```

Scaling:
```bash
gcloud run services update ace-web \
  --region=$REGION \
  --min=0 --max=3
```

Inspecione URL e revisions.

---

# 4. Testes e falhas propositais

- Remova `--allow-unauthenticated` em um serviço de teste e observe 403 sem identidade.
- Revision é imutável; mudança de configuração gera nova revision.
- Min instances pode gerar custo mesmo sem tráfego.

Para cada falha, não corrija imediatamente. Primeiro registre:

```text
Sintoma:
Hipótese:
Comando/evidência:
Causa:
Correção:
```

---

# 5. Troubleshooting

Use este fluxo:

```text
1. O recurso existe e está no estado esperado?
2. O escopo (project/region/zone) está correto?
3. A identidade/principal está correta?
4. IAM permite a operação?
5. Rede/rota/firewall permitem comunicação, quando aplicável?
6. A aplicação/serviço está saudável?
7. Há quota/capacidade suficiente?
8. Logs e métricas confirmam a hipótese?
```

Comandos-base:

```bash
gcloud config list
gcloud auth list
gcloud projects describe $(gcloud config get-value project)
gcloud logging read 'severity>=ERROR' --limit=10
```

---

# 6. Pegadinhas ACE

- Cloud Run Service é request-driven.
- Revision guarda snapshot de código+configuração.
- Traffic splitting permite rollout/canary.
- Scaling to zero é característica importante.

---

# 7. Questões estilo ACE

- API HTTP containerizada sem gerenciar cluster? → Cloud Run.
- Precisa execução batch sem endpoint? → Cloud Run Job.

---

# 8. Checklist

- [ ] Consigo explicar o modelo mental da aula;
- [ ] Executei o laboratório;
- [ ] Inspecionei os recursos com `describe/list`;
- [ ] Provoquei ao menos uma falha;
- [ ] Diagnostiquei antes de corrigir;
- [ ] Consigo justificar a escolha do serviço;
- [ ] Consigo explicar as pegadinhas ACE;
- [ ] Fiz o cleanup.

---

# 9. O que memorizar

Não memorize apenas comandos. Memorize a relação:

```text
Requisito
   ↓
Serviço/recurso correto
   ↓
Escopo correto
   ↓
Permissão correta
   ↓
Operação correta
   ↓
Troubleshooting com evidência
```

Essa é a forma de raciocínio mais útil para o Associate Cloud Engineer.

