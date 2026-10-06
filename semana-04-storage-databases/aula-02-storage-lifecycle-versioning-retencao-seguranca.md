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

Esta aula trabalha quatro mecanismos diferentes:

```text
Versioning
→ preserva gerações anteriores de objetos

Lifecycle
→ executa ações automaticamente quando condições são atendidas

Retention Policy
→ impede exclusão/substituição antes de um período mínimo

IAM
→ controla quem pode executar operações
```

## Arquitetura mental

```text
Bucket
 ├─ versioning → generations
 ├─ lifecycle → condition + action
 ├─ retention → período mínimo de retenção
 └─ IAM → autorização
```

Esses mecanismos resolvem problemas diferentes.

---

# 2. Criar bucket e habilitar Versioning

Defina as variáveis:

```bash
# Define o Project ID ativo.
export PROJECT_ID="$(gcloud config get-value project)"

# Define um nome globalmente único para o bucket.
export BUCKET="gs://$PROJECT_ID-ace-lifecycle-$RANDOM"
```

Crie o bucket:

```bash
# Cria o bucket em us-central1.
gcloud storage buckets create "$BUCKET" \
  --location=us-central1
```

Habilite Object Versioning:

```bash
# Habilita Object Versioning no bucket.
gcloud storage buckets update "$BUCKET" \
  --versioning
```

Inspecione:

```bash
# Exibe as propriedades do bucket.
gcloud storage buckets describe "$BUCKET"
```

Procure a configuração de versioning habilitada.

---

# 3. Criar duas gerações do mesmo objeto

## 3.1 Criar a primeira geração

```bash
# Cria o conteúdo da versão inicial.
echo "v1" > dado.txt

# Faz upload de dado.txt.
gcloud storage cp dado.txt "$BUCKET/dado.txt"
```

Capture a generation da versão `v1`:

```bash
# Lê o número da generation atualmente ativa.
export GEN_V1="$(gcloud storage objects describe "$BUCKET/dado.txt" \
  --format='value(generation)')"

echo "$GEN_V1"
```

Modelo:

```text
dado.txt
generation = GEN_V1
content = v1
```

---

## 3.2 Criar a segunda geração

Sobrescreva o mesmo nome de objeto:

```bash
# Substitui o arquivo local pelo conteúdo v2.
echo "v2" > dado.txt

# Faz novo upload para o mesmo nome de objeto.
gcloud storage cp dado.txt "$BUCKET/dado.txt"
```

Capture a nova generation:

```bash
# Captura a generation atual, agora correspondente a v2.
export GEN_V2="$(gcloud storage objects describe "$BUCKET/dado.txt" \
  --format='value(generation)')"

echo "$GEN_V2"
```

Agora:

```text
dado.txt
├─ GEN_V1 → v1 → noncurrent
└─ GEN_V2 → v2 → current
```

---

# 4. Inspecionar as generations

Liste todas as versões do objeto:

```bash
# Lista a versão atual e as versões não atuais.
gcloud storage ls \
  --all-versions \
  "$BUCKET/dado.txt"
```

Você deve identificar mais de uma generation.

Leia a versão atual:

```bash
# Sem #generation, acessamos o objeto atual.
gcloud storage cat "$BUCKET/dado.txt"
```

Resultado esperado:

```text
v2
```

Leia explicitamente a geração anterior:

```bash
# O sufixo #GENERATION seleciona uma versão específica.
gcloud storage cat "$BUCKET/dado.txt#$GEN_V1"
```

Resultado esperado:

```text
v1
```

Isso prova que Versioning preservou o conteúdo anterior.

---

# 5. Recuperar uma geração anterior

Listar versões não é suficiente. Vamos efetivamente **restaurar `v1`**.

Use a generation antiga como origem e o nome original como destino:

```bash
# Copia a geração antiga para o nome ativo do objeto.
# Isso cria uma nova generation cujo conteúdo volta a ser v1.
gcloud storage cp \
  "$BUCKET/dado.txt#$GEN_V1" \
  "$BUCKET/dado.txt"
```

Valide a recuperação:

```bash
# Lê o objeto corrente após a restauração.
gcloud storage cat "$BUCKET/dado.txt"
```

Resultado esperado:

```text
v1
```

Capture a generation criada pela restauração:

```bash
export GEN_RESTORED="$(gcloud storage objects describe "$BUCKET/dado.txt" \
  --format='value(generation)')"

echo "$GEN_RESTORED"
```

Agora temos conceitualmente:

```text
GEN_V1       → v1 → noncurrent
GEN_V2       → v2 → noncurrent
GEN_RESTORED → v1 → current
```

Liste novamente:

```bash
gcloud storage ls \
  --all-versions \
  "$BUCKET/dado.txt"
```

## Modelo mental

```text
Versioning
não "volta no tempo" apagando histórico

Restaurar uma generation antiga
→ cria uma nova generation atual
→ mantém as anteriores no histórico
```

---

# 6. Configurar Lifecycle

Lifecycle Management usa regras com duas partes:

```text
condition
→ quando a regra se aplica

action
→ o que o Cloud Storage deve fazer
```

Neste laboratório:

```text
condition
→ age = 30 dias

action
→ Delete
```

Ou seja:

```text
objeto atende age >= 30
        ↓
Lifecycle rule
        ↓
Delete
```

Crie o arquivo:

```bash
cat > lifecycle.json <<'EOF'
{
  "rule": [{
    "action": {
      "type": "Delete"
    },
    "condition": {
      "age": 30
    }
  }]
}
EOF
```

Leia antes de aplicar:

```bash
cat lifecycle.json
```

Aplique:

```bash
# Configura Object Lifecycle Management usando o JSON criado.
gcloud storage buckets update "$BUCKET" \
  --lifecycle-file=lifecycle.json
```

## 6.1 Inspecionar a regra aplicada

```bash
# Exibe a configuração do bucket após aplicar a regra.
gcloud storage buckets describe "$BUCKET"
```

Procure pela configuração de lifecycle contendo, conceitualmente:

```text
condition
  age: 30

action
  type: Delete
```

## 6.2 Comportamento esperado

O objeto do laboratório tem poucos segundos/minutos de idade.

Portanto:

```text
age < 30 dias
→ condição FALSE
→ Delete não executado
```

Confirme que o objeto continua existindo:

```bash
gcloud storage ls "$BUCKET/dado.txt"
```

> Alterações de Lifecycle não devem ser usadas como mecanismo de exclusão imediata. A avaliação e execução das regras é assíncrona.

---

# 7. Retention Policy

Uma Retention Policy define um **período mínimo** durante o qual objetos do bucket não podem ser excluídos ou substituídos.

Modelo:

```text
objeto criado
    |
    | retention period
    v
objeto protegido
    |
    | período cumprido
    v
pode ser excluído/substituído
```

Configure um período curto para laboratório:

```bash
# Define 60 segundos como período mínimo de retenção.
gcloud storage buckets update "$BUCKET" \
  --retention-period=60s
```

Inspecione:

```bash
gcloud storage buckets describe "$BUCKET"
```

Procure a política de retenção e confirme:

```text
retention period
→ 60 segundos

lock
→ não aplicado neste laboratório
```

---

# 8. Retention Policy x Retention Lock

Esses conceitos não são equivalentes.

| Recurso | Efeito |
|---|---|
| Retention Policy | estabelece o período mínimo de retenção |
| Retention Lock | torna a política permanentemente não removível/não redutível |

Modelo:

```text
Retention Policy desbloqueada
→ pode ser administrada/removida conforme permissões

Retention Policy bloqueada
→ não pode ser removida
→ período não pode ser reduzido
→ ação irreversível
```

> **Não aplique Retention Lock neste laboratório.**

A razão é operacional:

```text
lock
→ ação permanente
→ pode impedir limpeza do laboratório
→ inadequado para ambiente didático descartável
```

Para a ACE, reconheça:

```text
"reter por no mínimo X dias"
→ Retention Policy

"tornar a política imutável para compliance"
→ Retention Lock / Bucket Lock
```

---

# 9. Quebrar propositalmente — exclusão bloqueada

Logo após configurar a retenção, tente excluir o objeto atual:

```bash
# Tenta excluir o objeto durante o período de retenção.
gcloud storage rm "$BUCKET/dado.txt"
```

Resultado esperado:

```text
operação negada
```

porque o objeto ainda não cumpriu o período mínimo.

> Como Versioning está habilitado, lembre-se de que exclusões e gerações exigem atenção adicional. O ponto deste teste é observar o bloqueio causado pela Retention Policy.

---

# 10. Troubleshooting

## Sintoma

```text
não consigo excluir dado.txt
```

## Hipótese

O objeto ainda está protegido pela Retention Policy.

## Evidência 1 — bucket

```bash
# Inspeciona a Retention Policy configurada.
gcloud storage buckets describe "$BUCKET"
```

Confirme:

```text
retention period
→ 60s
```

## Evidência 2 — objeto

```bash
# Inspeciona os metadados do objeto atual.
gcloud storage objects describe "$BUCKET/dado.txt"
```

## Evidência 3 — IAM não é a primeira hipótese

A configuração foi criada deliberadamente antes do erro.

Portanto:

```text
PERMISSION_DENIED por IAM
≠ hipótese principal

Retention Policy
→ evidência direta do bloqueio
```

## Causa

```text
idade do objeto
<
retention period
```

A exclusão foi bloqueada pela política de retenção.

---

# 11. Corrigir

Neste laboratório, a correção não é aumentar privilégio nem aplicar lock.

Aguarde o período curto configurado:

```text
60 segundos
```

Depois tente novamente:

```bash
gcloud storage rm "$BUCKET/dado.txt"
```

Se necessário, liste todas as generations:

```bash
gcloud storage ls \
  --all-versions \
  "$BUCKET/dado.txt"
```

A lógica é:

```text
retenção ainda válida
→ aguardar

retenção cumprida
→ operação pode prosseguir

NÃO:
→ conceder role mais ampla
→ aplicar Retention Lock
```

---

# 12. Questões estilo ACE

1. Você precisa recuperar conteúdo anterior após sobrescrever um objeto.  
   **Resposta:** Object Versioning e uma generation anterior.

2. Objetos com mais de 90 dias devem ser removidos automaticamente.  
   **Resposta:** Object Lifecycle Management com `condition=age` e `action=Delete`.

3. Um objeto não pode ser excluído antes de cumprir um prazo mínimo.  
   **Resposta:** Retention Policy.

4. Uma política de retenção precisa se tornar permanentemente imutável para compliance.  
   **Resposta:** Retention Lock / Bucket Lock.

5. Você está em um laboratório temporário e precisa testar retenção. Deve ativar lock?  
   **Resposta:** não. Use uma política curta e desbloqueada.

---

# 13. Cleanup

> Execute o cleanup somente depois que a Retention Policy permitir a remoção dos objetos.

Liste todas as generations:

```bash
gcloud storage ls \
  --all-versions \
  "$BUCKET"
```

Remova os objetos/versions do laboratório:

```bash
# Remove os objetos do bucket após o período mínimo de retenção.
gcloud storage rm "$BUCKET/**" 2>/dev/null || true
```

Exclua o bucket:

```bash
gcloud storage buckets delete "$BUCKET" \
  --quiet
```

Remova arquivos locais:

```bash
rm -f dado.txt lifecycle.json
```

---

# 14. Checklist

- [ ] Habilitei Object Versioning;
- [ ] Criei duas generations do mesmo objeto;
- [ ] Capturei `GEN_V1` e `GEN_V2`;
- [ ] Li explicitamente uma generation antiga;
- [ ] Restaurei uma generation anterior;
- [ ] Entendi que restaurar cria uma nova generation atual;
- [ ] Configurei Lifecycle;
- [ ] Sei diferenciar `condition` e `action`;
- [ ] Inspecionei a regra de Lifecycle aplicada;
- [ ] Entendi Retention Policy;
- [ ] Sei diferenciar Retention Policy e Retention Lock;
- [ ] Não apliquei lock irreversível;
- [ ] Provoquei uma exclusão bloqueada;
- [ ] Diagnostiquei a causa usando evidências;
- [ ] Corrigi sem ampliar privilégios;
- [ ] Executei o cleanup.

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
