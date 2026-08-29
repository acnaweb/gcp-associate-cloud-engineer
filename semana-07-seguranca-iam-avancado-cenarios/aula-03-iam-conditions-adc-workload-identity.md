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
gcloud auth list
gcloud auth application-default login
gcloud auth application-default print-access-token | head -c 20
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
gcloud auth list
gcloud config get-value account
gcloud auth application-default print-access-token | head -c 20
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
gcloud auth application-default revoke
```

Depois:

```bash
gcloud auth application-default print-access-token
```

---

# 6. Troubleshooting

Agora o erro já foi produzido e os componentes envolvidos já foram apresentados.

**Sintoma:** ADC não consegue produzir token.

**Hipótese:** credencial ADC foi revogada/ausente.

**Evidência:**
```bash
gcloud auth list
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
gcloud auth application-default login
gcloud auth application-default print-access-token | head -c 20
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
