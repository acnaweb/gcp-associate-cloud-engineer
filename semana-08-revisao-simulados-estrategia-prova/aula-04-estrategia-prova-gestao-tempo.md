# Aula 4 — Estratégia de Prova e Gestão do Tempo

## Objetivos

Ao final desta aula, você deverá:

- Aplicar estratégia de leitura;
- Gerenciar tempo;
- Eliminar alternativas;
- Lidar com múltipla seleção;

---

# 1. Modelo mental

```text
Questão
  ↓ requisito dominante
  ↓ restrições
  ↓ eliminar opções
  ↓ escolher ação mínima/correta
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

### Simulação cronometrada
Pegue 20 questões dos simulados e estabeleça uma janela.

Para cada questão:
1. Leia primeiro a última frase/pergunta.
2. Identifique o verbo: `create`, `configure`, `troubleshoot`, `minimize`, `secure`.
3. Marque requisitos duros: managed, global, private, least privilege, low ops.
4. Elimine opções que violam um requisito.
5. Se travar, marque e avance.
6. Volte no fim.

### Folha de erros
```text
Erro de conhecimento
Erro de leitura
Erro de pressa
Duas opções pareciam corretas
Não reconheci produto
Esqueci comando/escopo
```

### Técnica para “most appropriate”
Prefira:
- serviço gerenciado quando requisito pede baixa operação;
- predefined role mínima em vez de basic role ampla;
- recurso no escopo correto;
- ação nativa em vez de workaround manual.

---

# 4. Testes e falhas propositais

- Não gaste vários minutos numa única questão.
- Multiple select exige todas as opções corretas.
- Cuidado com palavras como MOST, LEAST, MINIMIZE, REQUIRED.

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

- Questões ACE frequentemente têm duas respostas tecnicamente possíveis; uma atende melhor custo/operação/segurança.
- Conhecer escopos global/regional/zonal elimina alternativas rápido.

---

# 7. Questões estilo ACE

- Se duas opções funcionam, qual reduz operação mantendo requisito? Essa costuma ser a direção da resposta.
- Se pergunta pede least privilege, descarte Owner/Editor quando há role específica.

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

