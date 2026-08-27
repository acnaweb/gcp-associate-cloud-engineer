# Aula 1 — Cloud Storage: Buckets, Objetos e Classes

## Objetivos

Ao final desta aula, você deverá:

- Criar buckets e objetos;
- Entender localização e classes;
- Copiar/listar/remover objetos;
- Escolher classe por padrão de acesso;

---

# 1. Modelo mental

```text
Cloud Storage
  └─ Bucket (location)
      ├─ objeto A
      └─ objeto B
           └─ storage class
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

```bash
export PROJECT_ID=$(gcloud config get-value project)
export BUCKET=gs://$PROJECT_ID-ace-storage-$RANDOM

gcloud storage buckets create $BUCKET \
  --location=us-central1 \
  --default-storage-class=STANDARD

echo "ACE Storage Lab" > exemplo.txt
gcloud storage cp exemplo.txt $BUCKET/
gcloud storage ls -L $BUCKET
gcloud storage cat $BUCKET/exemplo.txt
```

Mude classe de um objeto:
```bash
gcloud storage objects update $BUCKET/exemplo.txt \
  --storage-class=NEARLINE
gcloud storage ls -L $BUCKET/exemplo.txt
```

Compare conceitualmente:
- Standard: acesso frequente
- Nearline/Coldline/Archive: acesso progressivamente menos frequente, com regras/custos associados

---

# 4. Testes e falhas propositais

- Tente criar outro bucket com o mesmo nome global para entender namespace global.
- Remova localmente o arquivo e prove que o objeto permanece no bucket.
- Classe não define autorização: IAM é separado.

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

- Bucket name é globalmente único.
- Bucket location e storage class são decisões diferentes.
- Cloud Storage é object storage, não filesystem POSIX tradicional.

---

# 7. Questões estilo ACE

- Objeto acessado várias vezes ao dia? → Standard.
- Backup raramente acessado? → classe fria conforme requisito de retenção/acesso.

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

