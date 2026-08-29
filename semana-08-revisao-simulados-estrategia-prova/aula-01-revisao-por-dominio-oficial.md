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
gcloud config list
gcloud auth list
gcloud compute instances list
gcloud compute networks list
gcloud compute firewall-rules list
gcloud compute routes list
gcloud storage buckets list
gcloud run services list --region=us-central1
gcloud container clusters list
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
