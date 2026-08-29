# Aula 2 — Lifecycle, Versioning, Retenção e Segurança

## Objetivos

Ao final, você deverá:
- habilitar Object Versioning;
- criar duas gerações do mesmo objeto;
- recuperar geração anterior;
- configurar lifecycle;
- entender retention policy;
- diagnosticar exclusão bloqueada por retenção sem ativar lock irreversível.


---

# 1. Conceito

Versioning mantém gerações anteriores. Lifecycle automatiza ações por condições. Retention policy impede exclusão antes de determinado período. IAM controla acesso. São mecanismos diferentes.

## Arquitetura mental

```text
Bucket
 ├─ versioning → generations
 ├─ lifecycle → ações automáticas
 ├─ retention → mínimo de retenção
 └─ IAM → autorização
```

---

# 2. Criar

```bash
export PROJECT_ID=$(gcloud config get-value project)
export BUCKET="gs://$PROJECT_ID-ace-lifecycle-$RANDOM"

gcloud storage buckets create "$BUCKET" --location=us-central1
gcloud storage buckets update "$BUCKET" --versioning

echo v1 > dado.txt
gcloud storage cp dado.txt "$BUCKET/dado.txt"
echo v2 > dado.txt
gcloud storage cp dado.txt "$BUCKET/dado.txt"

cat > lifecycle.json <<'EOF'
{
  "rule": [{
    "action": {"type": "Delete"},
    "condition": {"age": 30}
  }]
}
EOF

gcloud storage buckets update "$BUCKET" \
  --lifecycle-file=lifecycle.json

gcloud storage buckets update "$BUCKET" \
  --retention-period=60s
```

---

# 3. Inspecionar

Antes de provocar qualquer erro, confirme a configuração criada. O troubleshooting desta aula usará **somente elementos que você já observou aqui**.

```bash
gcloud storage ls --all-versions "$BUCKET"
gcloud storage buckets describe "$BUCKET"
```

---

# 4. Testar

Anote as generations:

```bash
gcloud storage ls --all-versions "$BUCKET/dado.txt"
```

Confirme que existem versões e que a retention policy está configurada.

---

# 5. Quebrar propositalmente

Logo após configurar retenção, tente apagar:

```bash
gcloud storage rm "$BUCKET/dado.txt"
```

A operação pode ser bloqueada enquanto o objeto estiver dentro do período de retenção.

---

# 6. Troubleshooting

Agora o erro já foi produzido e os componentes envolvidos já foram apresentados.

**Sintoma:** exclusão negada por retenção.

**Hipótese:** o objeto ainda não cumpriu `retention-period`.

**Evidências:**
```bash
gcloud storage buckets describe "$BUCKET"
gcloud storage objects describe "$BUCKET/dado.txt"
```

**Causa:** a retention policy foi configurada deliberadamente antes do teste.

Isso é diferente de IAM: o erro está associado à política de retenção do objeto/bucket.

Use sempre:

```text
Sintoma
   ↓
Hipótese
   ↓
Evidência
   ↓
Causa
   ↓
Correção
```

---

# 7. Corrigir

Aguarde o período curto de laboratório e tente novamente. Não aplique retention lock neste laboratório.

Depois:
```bash
gcloud storage rm "$BUCKET/dado.txt"
```

---

# 8. Questões estilo ACE

1. Quer recuperar conteúdo anterior sobrescrito? **Versioning**.
2. Quer apagar automaticamente objetos com 90 dias? **Lifecycle**.
3. Quer impedir deleção antes de prazo mínimo? **Retention policy**.

---

# 9. Cleanup

```bash
# Após a retenção mínima expirar:
gcloud storage rm "$BUCKET/**" 2>/dev/null || true
gcloud storage buckets delete "$BUCKET" --quiet
rm -f dado.txt lifecycle.json
```

---


---

# Cobertura ACE ampliada — segurança, CMEK e Storage Transfer Service

## CMEK

Por padrão, Google Cloud oferece criptografia gerenciada. **Customer-managed encryption keys (CMEK)** usa chaves do Cloud KMS controladas pelo cliente em recursos compatíveis.

Modelo:

```text
Cloud KMS key
   ↓ permission + config
Cloud Storage / Database / outro recurso compatível
```

Para ACE, saiba quando um requisito pede controle explícito de ciclo de vida/rotação/permissões da chave.

## Storage Transfer Service

Para mover dados para Cloud Storage ou entre storages em cenários suportados, avalie Storage Transfer Service em vez de scripts manuais de cópia em larga escala.

```text
Fonte externa / outro bucket
       ↓
Storage Transfer Service
       ↓
Cloud Storage
```

Laboratório de inspeção:

```bash
gcloud transfer jobs list 2>/dev/null || true
```

> A criação de transfer jobs depende da origem/destino e credenciais; não crie integração fictícia.

# 10. Checklist

- [ ] Entendi os conceitos usados no laboratório;
- [ ] Criei o recurso;
- [ ] Inspecionei estado e configuração;
- [ ] Testei o comportamento esperado;
- [ ] Provoquei a falha descrita;
- [ ] Diagnostiquei usando evidências;
- [ ] Corrigi sem aumentar privilégios ou alterar componentes desnecessários;
- [ ] Consigo relacionar o cenário a uma questão ACE;
- [ ] Executei o cleanup.
