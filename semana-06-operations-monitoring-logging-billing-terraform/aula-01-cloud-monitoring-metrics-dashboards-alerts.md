# Aula 1 — Cloud Monitoring, Metrics, Dashboards e Alerts

## Nível de cobertura M/E/P

```text
Alerts/resource metrics/custom log-based metric: P
```


## Objetivos

Ao final, você deverá:
- entender metric, resource, time series e alert policy;
- observar CPU de uma VM;
- criar dashboard/alert no Console;
- provocar condição de indisponibilidade simples;
- distinguir métrica de log.


---

# 1. Conceito

Monitoring trabalha com séries temporais. Uma métrica associada a um recurso gera pontos ao longo do tempo. Alert policy avalia condição; notification channel envia notificação.

## Arquitetura mental

```text
Resource → metric → time series
                    ├─ dashboard
                    └─ alert policy → incident
```

---

# 2. Criar

```bash
# Explicação: Cria uma VM do Compute Engine com as opções de máquina, rede, disco e identidade informadas.
gcloud compute instances create ace-monitor-vm \
  --zone=us-central1-a \
  --machine-type=e2-micro \
  --image-family=debian-12 \
  --image-project=debian-cloud
```

No Console:
1. Monitoring → Metrics Explorer.
2. Resource: VM Instance.
3. Metric: CPU utilization.
4. Salve o gráfico em um dashboard.
5. Crie uma alert policy simples com limiar baixo o suficiente para laboratório, ou apenas configure sem esperar o disparo se não quiser gerar carga artificial.

---

# 3. Inspecionar

Antes de provocar qualquer erro, confirme a configuração criada. O troubleshooting desta aula usará **somente elementos que você já observou aqui**.

```bash
# Explicação: Exibe a configuração e o estado detalhado da VM para inspeção/troubleshooting.
gcloud compute instances describe ace-monitor-vm \
  --zone=us-central1-a \
  --format="value(status)"
```

No Metrics Explorer, identifique explicitamente:
- monitored resource;
- metric;
- aggregation;
- time range.

---

# 4. Testar

Gere CPU por curto período:

```bash
# Explicação: Abre uma sessão SSH na VM indicada; flags adicionais podem executar um comando remotamente.
gcloud compute ssh ace-monitor-vm \
  --zone=us-central1-a \
  --command="timeout 30s yes > /dev/null || true"
```

Observe a série após alguns minutos.

---

# 5. Quebrar propositalmente

Pare a VM:

```bash
# Explicação: Interrompe a VM sem excluir seus discos persistentes.
gcloud compute instances stop ace-monitor-vm \
  --zone=us-central1-a
```

Agora você já conhece o estado da VM e a série temporal; observe a diferença de dados/availability.

---

# 6. Troubleshooting

Agora o erro já foi produzido e os componentes envolvidos já foram apresentados.

**Sintoma:** a VM está parada e novas métricas de CPU deixam de representar workload em execução.

**Hipótese:** mudança no estado do recurso, não falha do dashboard.

**Evidência:**
```bash
# Explicação: Exibe a configuração e o estado detalhado da VM para inspeção/troubleshooting.
gcloud compute instances describe ace-monitor-vm \
  --zone=us-central1-a \
  --format="value(status)"
```

**Causa:** `stop` deliberado.

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
# Explicação: Inicia uma VM que está parada.
gcloud compute instances start ace-monitor-vm \
  --zone=us-central1-a
```

Confirme status `RUNNING` e aguarde novas métricas.

---

# 8. Questões estilo ACE

1. CPU ao longo do tempo é **métrica/time series**.
2. Alert policy corrige automaticamente a VM? **Não**.
3. Dashboard é visualização, não mecanismo de autorização.

---

# 9. Cleanup

```bash
# Explicação: Exclui a VM indicada e libera os recursos associados que não foram preservados.
gcloud compute instances delete ace-monitor-vm \
  --zone=us-central1-a --quiet
# Remova dashboard/alert policy criados no Console.
```

---


---

# Cobertura ACE ampliada — custom metrics, Cloud Assist e Active Assist

## Custom metrics

Além de métricas nativas, aplicações podem publicar métricas customizadas. Conceito:

```text
Application
   ↓ custom metric
Cloud Monitoring
   ↓
Alert / Dashboard
```

Para laboratório, não é necessário desenvolver um agente complexo: saiba identificar o metric type e consultar no Metrics Explorer.

## Gemini Cloud Assist for Monitoring

Pode auxiliar investigação e interpretação de sinais no contexto suportado. Sempre valide recomendações contra métricas/logs/configuração real.

## Active Assist

Active Assist fornece recomendações para otimização de recursos, custo, performance e segurança em áreas suportadas.

Não confunda:

```text
Monitoring alert → detecta condição operacional
Active Assist    → recomenda otimização
```

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

# Cobertura adicional — Custom Metrics

Além de métricas nativas, o exam guide inclui criar/enviar métricas personalizadas.

Modelo mental:

```text
Application
   ↓ produz medida
Custom Metric
   ↓
Cloud Monitoring
   ↓
Dashboard / Alert
```

Para prova, entenda que métricas também podem ser derivadas de logs (log-based metrics), mas **log entry e metric time series são objetos diferentes**.

No Console:

```text
Monitoring → Metrics Management / Metrics Explorer
Logging → Log-based Metrics
```

Uma falha comum é criar alerta sobre uma métrica que não recebe pontos. Antes de mudar o threshold, valide se há dados no Metrics Explorer.


---

## Laboratório — criar e ingerir métrica personalizada a partir de logs

O guia cita métricas personalizadas provenientes de **aplicações ou registros**. Um laboratório seguro é criar uma **log-based metric**.

### 1. Gere entradas de log

```bash
# Explicação: Grava uma entrada de log de teste no Cloud Logging.
gcloud logging write ace-app-log 'ACE_OK' --severity=INFO
# Explicação: Grava uma entrada de log de teste no Cloud Logging.
gcloud logging write ace-app-log 'ACE_ERROR' --severity=ERROR
```

### 2. Crie métrica baseada no log

```bash
# Explicação: Cria uma log-based metric a partir do filtro de logs informado.
gcloud logging metrics create ace_error_count \
  --description='Contagem de erros ACE' \
  --log-filter='logName:"ace-app-log" AND severity>=ERROR'
```

### 3. Inspecione

```bash
# Explicação: Exibe a configuração da log-based metric.
gcloud logging metrics describe ace_error_count
```

### 4. Ingira novos pontos

```bash
# Explicação: Grava uma entrada de log de teste no Cloud Logging.
gcloud logging write ace-app-log 'ACE_ERROR_2' --severity=ERROR
```

Após a ingestão, procure no Metrics Explorer a métrica de logging correspondente.

### 5. Falha proposital

Altere temporariamente o filtro para uma condição que nunca corresponde ou simplesmente gere apenas `INFO` e observe ausência de novos pontos.

### Troubleshooting

```text
Sintoma: alerta/métrica não recebe pontos
Hipótese: filtro não corresponde às entradas geradas
Evidência: Logs Explorer + definição da log-based metric
Causa: mismatch no filtro/severity/logName
Correção: alinhar filtro ao log real
```

### Cleanup

```bash
# Explicação: Exclui a log-based metric criada no laboratório.
gcloud logging metrics delete ace_error_count --quiet
```

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

## Tópicos do guia mapeados para esta aula

| Seção | Tópico | Esperado | Nível da matriz |
|---|---|---:|---:|
| 4.6 | Monitoring alerts por resource metric | `P` | `P` |
| 4.6 | Custom metrics | `P` | `P` |
