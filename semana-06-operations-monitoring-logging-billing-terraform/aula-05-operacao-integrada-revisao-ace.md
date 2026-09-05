# Aula 5 — Operação Integrada e Revisão ACE

## Objetivos

Ao final, você deverá:
- classificar sintomas por camada;
- usar uma sequência de diagnóstico;
- evitar mudanças aleatórias;
- executar mini-incidente envolvendo VM e nginx.


---

# 1. Conceito

Troubleshooting eficaz reduz espaço de busca. Primeiro confirme recurso/estado, depois configuração e camada específica. Mensagens 403, timeout, `RESOURCE_EXHAUSTED` e serviço parado apontam caminhos diferentes.

## Arquitetura mental

```text
Sintoma
 ↓
Estado do recurso
 ↓
Configuração
 ↓
IAM / Rede / Quota / Aplicação
 ↓
Logs/Metrics
 ↓
Correção mínima
```

---

# 2. Criar

Crie VM com nginx:

```bash
# Explicação: Exibe conteúdo de arquivo ou cria conteúdo via redirecionamento/heredoc, conforme a sintaxe usada.
cat > startup.sh <<'EOF'
#!/bin/bash
apt-get update
apt-get install -y nginx
systemctl enable --now nginx
EOF

# Explicação: Cria uma VM do Compute Engine com as opções de máquina, rede, disco e identidade informadas.
gcloud compute instances create ace-ops-vm \
  --zone=us-central1-a \
  --machine-type=e2-micro \
  --metadata-from-file=startup-script=startup.sh \
  --image-family=debian-12 \
  --image-project=debian-cloud
```

---

# 3. Inspecionar

Antes de provocar qualquer erro, confirme a configuração criada. O troubleshooting desta aula usará **somente elementos que você já observou aqui**.

```bash
# Explicação: Exibe a configuração e o estado detalhado da VM para inspeção/troubleshooting.
gcloud compute instances describe ace-ops-vm \
  --zone=us-central1-a
# Explicação: Abre uma sessão SSH na VM indicada; flags adicionais podem executar um comando remotamente.
gcloud compute ssh ace-ops-vm \
  --zone=us-central1-a \
  --command="systemctl is-active nginx; curl -s localhost | head"
```

---

# 4. Testar

Valide primeiro o estado saudável. Registre:
```text
VM = RUNNING
nginx = active
localhost:80 = responde
```

---

# 5. Quebrar propositalmente

Pare apenas nginx:

```bash
# Explicação: Abre uma sessão SSH na VM indicada; flags adicionais podem executar um comando remotamente.
gcloud compute ssh ace-ops-vm \
  --zone=us-central1-a \
  --command="sudo systemctl stop nginx"
```

Não altere VM, firewall ou IAM.

---

# 6. Troubleshooting

Agora o erro já foi produzido e os componentes envolvidos já foram apresentados.

**Sintoma:** aplicação local deixou de responder.

**Hipótese:** nginx parado.

**Evidências:**
```bash
# Explicação: Exibe a configuração e o estado detalhado da VM para inspeção/troubleshooting.
gcloud compute instances describe ace-ops-vm \
  --zone=us-central1-a \
  --format="value(status)"

# Explicação: Abre uma sessão SSH na VM indicada; flags adicionais podem executar um comando remotamente.
gcloud compute ssh ace-ops-vm \
  --zone=us-central1-a \
  --command="systemctl is-active nginx || true; sudo ss -lntp | grep :80 || true"
```

**Causa:** serviço parado.

A VM está `RUNNING`, então não é necessário reiniciar compute nem mexer em quota.

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
# Explicação: Abre uma sessão SSH na VM indicada; flags adicionais podem executar um comando remotamente.
gcloud compute ssh ace-ops-vm \
  --zone=us-central1-a \
  --command="sudo systemctl start nginx; curl -s localhost | head"
```

---

# 8. Questões estilo ACE

1. VM `RUNNING`, porta 80 sem listener: investigar **aplicação**.
2. 403 de API Google: investigar **IAM**, antes de firewall.
3. `RESOURCE_EXHAUSTED`: investigar **quota/capacidade**.

---

# 9. Cleanup

```bash
# Explicação: Exclui a VM indicada e libera os recursos associados que não foram preservados.
gcloud compute instances delete ace-ops-vm \
  --zone=us-central1-a --quiet
# Explicação: Remove o arquivo/diretório temporário indicado durante correção ou cleanup.
rm -f startup.sh
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
