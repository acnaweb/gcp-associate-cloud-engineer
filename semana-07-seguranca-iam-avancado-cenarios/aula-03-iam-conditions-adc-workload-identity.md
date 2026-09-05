# Aula 3 — IAM Conditions, ADC e Workload Identity Federation

## Objetivos

Ao final, você deverá:
- entender IAM Conditions;
- distinguir `gcloud auth` de ADC;
- gerar ADC local;
- entender WIF sem key persistente;
- diagnosticar aplicação usando credencial errada.


---

# 1. Conceito

IAM Condition adiciona expressão contextual a binding. ADC é ordem de descoberta de credenciais usada por bibliotecas. Workload Identity Federation troca identidade externa por credenciais Google de curta duração.

## Arquitetura mental

```text
CLI credentials ≠ ADC
External IdP ── WIF ──> short-lived Google credentials
```

---

# 2. Criar

### ADC

```bash
# Explicação: Lista as identidades autenticadas e mostra qual conta está ativa no `gcloud`.
gcloud auth list
# Explicação: Cria credenciais Application Default Credentials para aplicações locais usarem APIs do Google Cloud.
gcloud auth application-default login
# Explicação: Gera/exibe um access token das Application Default Credentials para testar a identidade efetiva.
gcloud auth application-default print-access-token | head -c 20
# Explicação: Exibe ou grava o valor/texto informado, normalmente para validar variável ou criar conteúdo de teste.
echo
```

### IAM Condition — exemplo de laboratório
Use apenas identidade controlada e data futura:

```text
binding:
  member
  role
  condition:
    request.time < timestamp(...)
```

### WIF — laboratório de arquitetura
Desenhe:

```text
GitHub/AWS/Azure/OIDC
       ↓
Workload Identity Provider
       ↓
STS / credencial curta
       ↓
Google API
```

---

# 3. Inspecionar

Antes de provocar qualquer erro, confirme a configuração criada. O troubleshooting desta aula usará **somente elementos que você já observou aqui**.

```bash
# Explicação: Lista as identidades autenticadas e mostra qual conta está ativa no `gcloud`.
gcloud auth list
# Explicação: Executa `gcloud config get-value account` nesta etapa para aplicar ou inspecionar a configuração indicada.
gcloud config get-value account
# Explicação: Gera/exibe um access token das Application Default Credentials para testar a identidade efetiva.
gcloud auth application-default print-access-token | head -c 20
# Explicação: Exibe ou grava o valor/texto informado, normalmente para validar variável ou criar conteúdo de teste.
echo
```

Explique:
- `gcloud auth list` → identidades do CLI;
- ADC → usado por client libraries compatíveis.

---

# 4. Testar

Se tiver Python com `google-auth`, execute uma pequena aplicação que use ADC ou apenas valide o token via comando acima.

---

# 5. Quebrar propositalmente

Revogue ADC local:

```bash
# Explicação: Executa `gcloud auth application-default revoke` nesta etapa para aplicar ou inspecionar a configuração indicada.
gcloud auth application-default revoke
```

Depois:

```bash
# Explicação: Gera/exibe um access token das Application Default Credentials para testar a identidade efetiva.
gcloud auth application-default print-access-token
```

---

# 6. Troubleshooting

Agora o erro já foi produzido e os componentes envolvidos já foram apresentados.

**Sintoma:** ADC não consegue produzir token.

**Hipótese:** credencial ADC foi revogada/ausente.

**Evidência:**
```bash
# Explicação: Lista as identidades autenticadas e mostra qual conta está ativa no `gcloud`.
gcloud auth list
# Explicação: Gera/exibe um access token das Application Default Credentials para testar a identidade efetiva.
gcloud auth application-default print-access-token
```

Pode ocorrer de o CLI ainda estar autenticado enquanto ADC falha. Isso prova que são contextos distintos.

**Causa:** revogamos ADC propositalmente.

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

```bash
# Explicação: Cria credenciais Application Default Credentials para aplicações locais usarem APIs do Google Cloud.
gcloud auth application-default login
# Explicação: Gera/exibe um access token das Application Default Credentials para testar a identidade efetiva.
gcloud auth application-default print-access-token | head -c 20
# Explicação: Exibe ou grava o valor/texto informado, normalmente para validar variável ou criar conteúdo de teste.
echo
```

---

# 8. Questões estilo ACE

1. Biblioteca local procura credencial padrão? **ADC**.
2. GitHub Actions sem JSON key? **Workload Identity Federation**.
3. `gcloud auth login` e ADC são exatamente a mesma credencial? **Não necessariamente**.

---

# 9. Cleanup

Opcional: `gcloud auth application-default revoke` ao final, se não precisar manter ADC no ambiente.

---


---

# Cobertura ACE ampliada — Workload Identity Federation

## Workload Identity Federation

Fluxo:

```text
External workload identity
(AWS / Azure / OIDC / CI)
        ↓
Workload Identity Pool + Provider
        ↓ token exchange
Google short-lived credential
        ↓
Google Cloud resource
```

Use quando workloads externos precisam acessar GCP sem distribuir service account keys.

Não confunda com **Workforce Identity Federation**, voltada a usuários/workforce.

## GKE application identity

Em GKE, Workload Identity Federation for GKE associa identidades Kubernetes a identidades Google de forma controlada, evitando armazenar JSON keys em Pods.

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

<!-- MEP-ACCEPTANCE-V9 -->
# Critério de aceite M/E/P desta aula

> Esta seção não substitui o conteúdo acima; ela explicita o critério usado na auditoria da baseline v9.

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
