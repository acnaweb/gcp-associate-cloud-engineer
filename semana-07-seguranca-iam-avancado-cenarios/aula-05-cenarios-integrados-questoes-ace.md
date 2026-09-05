# Aula 5 — Cenários Integrados e Questões ACE

## Objetivos

Ao final, você deverá:
- combinar identidade, escopo e role;
- distinguir falha IAM de rede;
- resolver cenários sem provisionar recursos desnecessários;
- justificar resposta.


---

# 1. Conceito

No ACE, a melhor resposta costuma ser a opção que atende requisito com serviço nativo, menor privilégio e menor complexidade operacional. A chave é separar as camadas.

## Arquitetura mental

```text
Requirement
 ↓
Identity
 ↓
Scope
 ↓
Role
 ↓
Network path (se necessário)
 ↓
Operation
```

---

# 2. Criar

Crie uma tabela de decisão:

```text
Cenário | Principal | Recurso | Role mínima | Rede necessária? | Evidência
```

Preencha:
1. VM lê bucket.
2. Usuário consulta BigQuery.
3. GitHub faz deploy no Cloud Run.
4. Cloud Run acessa Storage.
5. Usuário recebe 403.


---

# 3. Inspecionar

Antes de provocar qualquer erro, confirme a configuração criada. O troubleshooting desta aula usará **somente elementos que você já observou aqui**.

Use comandos já aprendidos:

```bash
# Explicação: Lista as identidades autenticadas e mostra qual conta está ativa no `gcloud`.
gcloud auth list
# Explicação: Exibe a política IAM do projeto para inspecionar principals, roles e bindings.
gcloud projects get-iam-policy "$(gcloud config get-value project)"
# Explicação: Lista Service Accounts para confirmar que a identidade foi criada.
gcloud iam service-accounts list
# Explicação: Exibe detalhes da role IAM, incluindo permissões e estágio, para entender exatamente o acesso concedido.
gcloud iam roles describe roles/storage.objectViewer
# Explicação: Consulta entradas do Cloud Logging usando o filtro informado para coletar evidências.
gcloud logging read 'protoPayload.status.code=7' --limit=10
```

---

# 4. Testar

Escolha um cenário e prove cada camada com comandos, sem alterar recursos:
- principal;
- role;
- scope;
- mensagem de erro/log.

---

# 5. Quebrar propositalmente

Falha proposital de raciocínio:

> “A aplicação recebe 403 do Cloud Storage; vou abrir firewall tcp:443.”

Explique por que essa correção não ataca a evidência observada.

---

# 6. Troubleshooting

Agora o erro já foi produzido e os componentes envolvidos já foram apresentados.

**Sintoma:** HTTP 403 / `PERMISSION_DENIED`.

**Hipótese correta:** autorização.

**Evidência:** resposta chegou à API e foi explicitamente negada.

**Causa provável:** role/binding/condition/principal incorreto.

**Por que firewall é hipótese fraca:** firewall de VPC costuma produzir conectividade/timeout, não decisão IAM explícita da API.

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

A correção deve atuar em:
```text
principal correto
+
role mínima
+
scope correto
+
condition correta (se houver)
```

---

# 8. Questões estilo ACE

1. 403 do Storage: **IAM**.
2. Timeout para IP privado: **rede/rota/firewall/serviço**.
3. CI externo sem key: **WIF**.
4. Workload precisa ler bucket: **runtime SA + objectViewer no bucket**.

---

# 9. Cleanup

Nenhum recurso obrigatório é criado nesta aula; ela reutiliza conhecimento das anteriores.

---

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
