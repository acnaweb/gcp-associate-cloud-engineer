# Aula 3 — Cloud Run Jobs, IAM e Operação

## Objetivos

Ao final, você deverá:
- criar Cloud Run Job;
- executar;
- inspecionar executions;
- configurar runtime SA;
- provocar exit code 1;
- diagnosticar falha pela execution/logs.


---

# 1. Conceito

Cloud Run Job executa tarefas que terminam; não oferece endpoint HTTP contínuo. Job define configuração; Execution representa uma execução concreta; Task é unidade executada.

## Arquitetura mental

```text
Job
 ↓ execute
Execution
 └─ Task(s)
      └─ exit code/logs
```

---

# 2. Criar

```bash
# Explicação: Define `REGION` com o valor da região padrão usada pelos recursos do laboratório.
export REGION=us-central1
# Explicação: Cria um Cloud Run Job para executar uma tarefa finita sem servir requisições HTTP continuamente.
gcloud run jobs create ace-job \
  --image=alpine \
  --region="$REGION" \
  --command=sh \
  --args=-c,'echo ACE Job; date'
```

---

# 3. Inspecionar

Antes de provocar qualquer erro, confirme a configuração criada. O troubleshooting desta aula usará **somente elementos que você já observou aqui**.

```bash
# Explicação: Executa `gcloud run jobs describe ace-job --region="$REGION"` nesta etapa para aplicar ou inspecionar a configuração indicada.
gcloud run jobs describe ace-job --region="$REGION"
# Explicação: Lista ou descreve execuções do Cloud Run Job para verificar resultado e troubleshooting.
gcloud run jobs executions list --job=ace-job --region="$REGION"
```

---

# 4. Testar

```bash
# Explicação: Dispara uma execução do Cloud Run Job e, opcionalmente, aguarda sua conclusão.
gcloud run jobs execute ace-job --region="$REGION" --wait
# Explicação: Lista ou descreve execuções do Cloud Run Job para verificar resultado e troubleshooting.
gcloud run jobs executions list --job=ace-job --region="$REGION"
```

---

# 5. Quebrar propositalmente

Atualize o job para terminar com erro:

```bash
# Explicação: Atualiza configuração, imagem ou parâmetros do Cloud Run Job.
gcloud run jobs update ace-job \
  --region="$REGION" \
  --command=sh \
  --args=-c,'echo falha proposital; exit 1'

# Explicação: Dispara uma execução do Cloud Run Job e, opcionalmente, aguarda sua conclusão.
gcloud run jobs execute ace-job \
  --region="$REGION" \
  --wait || true
```

---

# 6. Troubleshooting

Agora o erro já foi produzido e os componentes envolvidos já foram apresentados.

**Sintoma:** execution termina `FAILED`.

**Hipótese:** o processo no container retornou código diferente de zero.

**Evidências:**
```bash
# Explicação: Lista ou descreve execuções do Cloud Run Job para verificar resultado e troubleshooting.
gcloud run jobs executions list --job=ace-job --region="$REGION"
# Explicação: Consulta entradas do Cloud Logging usando o filtro informado para coletar evidências.
gcloud logging read \
 'resource.type="cloud_run_job" AND resource.labels.job_name="ace-job"' \
 --limit=20
```

**Causa:** adicionamos `exit 1` deliberadamente.

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

Restaure comando:

```bash
# Explicação: Atualiza configuração, imagem ou parâmetros do Cloud Run Job.
gcloud run jobs update ace-job \
  --region="$REGION" \
  --command=sh \
  --args=-c,'echo corrigido; exit 0'

# Explicação: Dispara uma execução do Cloud Run Job e, opcionalmente, aguarda sua conclusão.
gcloud run jobs execute ace-job --region="$REGION" --wait
```

---

# 8. Questões estilo ACE

1. Processo batch sem endpoint? **Cloud Run Job**.
2. Onde ver execução concreta? **Executions**.
3. Exit code 1 aponta primeiro para quê? **Processo/aplicação do job**, antes de IAM/rede.

---

# 9. Cleanup

```bash
# Explicação: Exclui o Cloud Run Job criado no laboratório.
gcloud run jobs delete ace-job --region="$REGION" --quiet
```

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
