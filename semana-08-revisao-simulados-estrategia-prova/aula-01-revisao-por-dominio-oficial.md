# Aula 1 — Revisão por Domínio Oficial

## Objetivos

Ao final, você deverá:
- revisar configuração de ambiente;
- implementação;
- operação;
- acesso e segurança;
- identificar lacunas por execução, não por releitura.


---

# 1. Conceito

A revisão final deve reproduzir as capacidades que a certificação exige: configurar ambiente, planejar/implementar, operar e configurar acesso/segurança.

## Arquitetura mental

```text
Configurar ambiente
 ↓
Implementar
 ↓
Operar
 ↓
Acesso e segurança
 ↓
Troubleshooting
```

---

# 2. Criar

Circuito:

```bash
# Explicação: Exibe as propriedades da configuração `gcloud` ativa para conferência.
gcloud config list
# Explicação: Lista as identidades autenticadas e mostra qual conta está ativa no `gcloud`.
gcloud auth list
# Explicação: Lista VMs do projeto para verificar inventário, zona, IPs e estado.
gcloud compute instances list
# Explicação: Lista VPCs existentes no projeto.
gcloud compute networks list
# Explicação: Lista regras de firewall para inspecionar a política efetiva da VPC.
gcloud compute firewall-rules list
# Explicação: Lista rotas efetivas/estáticas visíveis no projeto para análise de caminho de rede.
gcloud compute routes list
# Explicação: Lista buckets visíveis no projeto.
gcloud storage buckets list
# Explicação: Lista serviços Cloud Run existentes na região/projeto.
gcloud run services list --region=us-central1
# Explicação: Lista clusters GKE existentes e seus estados/localizações.
gcloud container clusters list
# Explicação: Consulta entradas do Cloud Logging usando o filtro informado para coletar evidências.
gcloud logging read 'severity>=ERROR' --limit=5
```

---

# 3. Inspecionar

Antes de provocar qualquer erro, confirme a configuração criada. O troubleshooting desta aula usará **somente elementos que você já observou aqui**.

Crie uma planilha/markdown com:
```text
Comando/ação
Consigo executar sem consultar?
Consigo explicar escopo?
Consigo diagnosticar falha?
```

---

# 4. Testar

Escolha 5 operações e execute `describe/list` até conseguir explicar cada campo relevante.

---

# 5. Quebrar propositalmente

Marque uma lacuna real, por exemplo:
> “Não consigo explicar diferença entre Health Check e Autohealing.”

Esse é o “erro” a corrigir: lacuna detectada por revisão ativa.

---

# 6. Troubleshooting

Agora o erro já foi produzido e os componentes envolvidos já foram apresentados.

Use a aula específica:
- reproduza arquitetura;
- repita lab;
- refaça falha;
- responda questões.

Não tente compensar lacuna lendo 20 serviços novos.

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

Registre a regra corrigida em uma frase e um comando-chave.

---

# 8. Questões estilo ACE

1. Revisão passiva é suficiente? **Não**.
2. Quais domínios merecem prática? **Todos os domínios operacionais do guia**.
3. Erro deve gerar qual ação? **Repetir laboratório correspondente**.

---

# 9. Cleanup

Sem cleanup obrigatório; use apenas comandos de inspeção, salvo se optar por recriar labs.

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
