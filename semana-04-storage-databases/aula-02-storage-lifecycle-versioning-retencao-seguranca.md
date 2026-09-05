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
# Explicação: Define `PROJECT_ID` com o ID do projeto Google Cloud usado pelos comandos seguintes.
export PROJECT_ID=$(gcloud config get-value project)
# Explicação: Define `BUCKET` com o nome do bucket usado no laboratório.
export BUCKET="gs://$PROJECT_ID-ace-lifecycle-$RANDOM"

# Explicação: Cria um bucket Cloud Storage com localização e opções informadas.
gcloud storage buckets create "$BUCKET" --location=us-central1
# Explicação: Atualiza configurações do bucket, como versioning, lifecycle, retention ou outras opções informadas.
gcloud storage buckets update "$BUCKET" --versioning

# Explicação: Exibe ou grava o valor/texto informado, normalmente para validar variável ou criar conteúdo de teste.
echo v1 > dado.txt
# Explicação: Copia arquivo(s) entre o ambiente local e Cloud Storage, ou entre localizações no Cloud Storage.
gcloud storage cp dado.txt "$BUCKET/dado.txt"
# Explicação: Exibe ou grava o valor/texto informado, normalmente para validar variável ou criar conteúdo de teste.
echo v2 > dado.txt
# Explicação: Copia arquivo(s) entre o ambiente local e Cloud Storage, ou entre localizações no Cloud Storage.
gcloud storage cp dado.txt "$BUCKET/dado.txt"

# Explicação: Exibe conteúdo de arquivo ou cria conteúdo via redirecionamento/heredoc, conforme a sintaxe usada.
cat > lifecycle.json <<'EOF'
{
  "rule": [{
    "action": {"type": "Delete"},
    "condition": {"age": 30}
  }]
}
EOF

# Explicação: Atualiza configurações do bucket, como versioning, lifecycle, retention ou outras opções informadas.
gcloud storage buckets update "$BUCKET" \
  --lifecycle-file=lifecycle.json

# Explicação: Atualiza configurações do bucket, como versioning, lifecycle, retention ou outras opções informadas.
gcloud storage buckets update "$BUCKET" \
  --retention-period=60s
```

---

# 3. Inspecionar

Antes de provocar qualquer erro, confirme a configuração criada. O troubleshooting desta aula usará **somente elementos que você já observou aqui**.

```bash
# Explicação: Lista buckets/objetos; flags podem incluir versões antigas e detalhes adicionais.
gcloud storage ls --all-versions "$BUCKET"
# Explicação: Exibe propriedades do bucket, como localização, storage class, versioning e políticas.
gcloud storage buckets describe "$BUCKET"
```

---

# 4. Testar

Anote as generations:

```bash
# Explicação: Lista buckets/objetos; flags podem incluir versões antigas e detalhes adicionais.
gcloud storage ls --all-versions "$BUCKET/dado.txt"
```

Confirme que existem versões e que a retention policy está configurada.

---

# 5. Quebrar propositalmente

Logo após configurar retenção, tente apagar:

```bash
# Explicação: Remove objeto(s) do Cloud Storage conforme o caminho/padrão informado.
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
# Explicação: Exibe propriedades do bucket, como localização, storage class, versioning e políticas.
gcloud storage buckets describe "$BUCKET"
# Explicação: Exibe metadados de um objeto Cloud Storage, como geração, tamanho e storage class.
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
# Explicação: Remove objeto(s) do Cloud Storage conforme o caminho/padrão informado.
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
# Explicação: Remove objeto(s) do Cloud Storage conforme o caminho/padrão informado.
gcloud storage rm "$BUCKET/**" 2>/dev/null || true
# Explicação: Exclui o bucket; ele precisa estar vazio ou ser removido recursivamente conforme o comando.
gcloud storage buckets delete "$BUCKET" --quiet
# Explicação: Remove o arquivo/diretório temporário indicado durante correção ou cleanup.
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
# Explicação: Lista jobs do Storage Transfer Service para acompanhar transferências configuradas.
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

---

<!-- MEP-ACCEPTANCE-V8 -->
# Critério de aceite M/E/P desta aula

> Esta seção não substitui o conteúdo acima; ela explicita o critério usado na auditoria da baseline v8.

Para um tópico ser classificado como `P` nesta baseline, não basta existir um comando. A aula precisa apresentar:

```text
conceito operacional
   ↓
configuração/comando
   ↓
inspeção
   ↓
teste ou comportamento observável
```

Quando a execução depender de Organization, privilégio administrativo, custo relevante ou infraestrutura especial, use `P*`.

## Tópicos do guia mapeados para esta aula

| Seção | Tópico | Esperado | Nível da matriz |
|---|---|---:|---:|
| 4.4 | Lifecycle policies | `P` | `P` |
