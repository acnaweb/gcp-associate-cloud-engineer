# Aula 5 — Checklist Final e Plano Pré-Prova

## Objetivos

Ao final, você deverá:
- avaliar prontidão;
- priorizar lacunas;
- montar plano final;
- decidir quando parar de expandir escopo.


---

# 1. Conceito

Prontidão não é “terminei de ler”. É conseguir executar, explicar, diagnosticar e escolher.

## Arquitetura mental

```text
Simulado
 ↓
erros
 ↓
labs dirigidos
 ↓
novo simulado
 ↓
prontidão
```

---

# 2. Criar

Checklist mínimo:
```text
[ ] gcloud configurations / projects / APIs
[ ] IAM + SA + impersonation
[ ] VM + disk + snapshot + startup script
[ ] MIG + autoscaling + autohealing
[ ] VPC + subnet + firewall + route
[ ] NAT + PGA + DNS
[ ] LB + health check
[ ] Storage + lifecycle/versioning/retention
[ ] Cloud SQL + database/user/troubleshooting
[ ] BigQuery + escolha de banco
[ ] Artifact Registry + Cloud Run
[ ] GKE básico + troubleshooting
[ ] Monitoring + Logging
[ ] Billing + budget + quota
[ ] Terraform
```

---

# 3. Inspecionar

Antes de provocar qualquer erro, confirme a configuração criada. O troubleshooting desta aula usará **somente elementos que você já observou aqui**.

Para cada item marque:
```text
0 = não sei
1 = explico
2 = executo
3 = executo e diagnostico
```

Priorize itens com 0/1.

---

# 4. Testar

Faça um último simulado e compare não só a nota, mas categorias de erro.

---

# 5. Quebrar propositalmente

Falha proposital de estudo:
> “Vou aprender um serviço novo na véspera porque apareceu em um blog.”

Pergunte se ele está no guia/roadmap e se resolve uma lacuna real.

---

# 6. Troubleshooting

Agora o erro já foi produzido e os componentes envolvidos já foram apresentados.

**Sintoma:** revisão final está ficando cada vez maior.

**Hipótese:** expansão de escopo em vez de consolidação.

**Evidência:** novos tópicos não vieram de erros de simulado/labs.

**Causa:** ansiedade de cobertura.

**Correção:** voltar às lacunas demonstradas.

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

Plano sugerido:
- D-7 a D-4: labs fracos;
- D-3: simulado;
- D-2: erros + IAM/networking;
- D-1: revisão leve;
- prova: leitura cuidadosa.

---

# 8. Questões estilo ACE

1. Melhor métrica de prontidão: **acerto consistente + justificativa + hands-on**.
2. Erro repetido de IAM: faça **lab IAM**, não leia produto novo.
3. Último dia: **consolidar**, não expandir.

---

# 9. Cleanup

Nenhum recurso é criado.

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
