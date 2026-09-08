# Aula 4 — Instance Templates e Managed Instance Groups

## Objetivos

Ao final, você deverá:
- criar Instance Template;
- criar MIG;
- redimensionar;
- deletar uma VM e observar reconciliação;
- entender template imutável e update.


> **Custos:** MIG mantém múltiplas VMs; faça cleanup obrigatório.

---

# 1. Conceito

Instance Template descreve como criar VMs. MIG mantém um estado desejado de instâncias homogêneas e pode recriar membros ausentes.

## Arquitetura mental

```text
Instance Template
       ↓
MIG (desired size)
 ├─ VM
 └─ VM
```

---

# 2. Criar

```bash
# Explicação: Exibe conteúdo de arquivo ou cria conteúdo via redirecionamento/heredoc, conforme a sintaxe usada.
cat > startup.sh <<'EOF'
#!/bin/bash
apt-get update
apt-get install -y nginx
echo "$(hostname)" > /var/www/html/index.html
EOF

# Explicação: Cria um Instance Template reutilizável para padronizar as VMs de um Managed Instance Group.
gcloud compute instance-templates create ace-template-v1 \
  --machine-type=e2-micro \
  --metadata-from-file=startup-script=startup.sh \
  --image-family=debian-12 \
  --image-project=debian-cloud

# Explicação: Cria um Managed Instance Group baseado no template informado.
gcloud compute instance-groups managed create ace-mig \
  --zone=us-central1-a \
  --template=ace-template-v1 \
  --size=2
```

---

# 3. Inspecionar

Antes de provocar qualquer erro, confirme a configuração criada. O troubleshooting desta aula usará **somente elementos que você já observou aqui**.

```bash
# Explicação: Exibe a configuração imutável do Instance Template.
gcloud compute instance-templates describe ace-template-v1
# Explicação: Exibe configuração, target size, políticas e estado do Managed Instance Group.
gcloud compute instance-groups managed describe ace-mig \
  --zone=us-central1-a
# Explicação: Lista as VMs pertencentes ao Managed Instance Group e seus estados.
gcloud compute instance-groups managed list-instances ace-mig \
  --zone=us-central1-a
```

---

# 4. Testar

```bash
# Explicação: Executa `gcloud compute instance-groups managed resize ace-mig --zone=us-central1-a --size=3` nesta etapa para aplicar ou inspecionar a configuração indicada.
gcloud compute instance-groups managed resize ace-mig \
  --zone=us-central1-a --size=3

# Explicação: Lista as VMs pertencentes ao Managed Instance Group e seus estados.
gcloud compute instance-groups managed list-instances ace-mig \
  --zone=us-central1-a
```

---

# 5. Quebrar propositalmente

Pegue uma VM do grupo e apague manualmente:

```bash
# Explicação: Define `VM` com o nome da VM usada no laboratório.
VM=$(gcloud compute instance-groups managed list-instances ace-mig \
  --zone=us-central1-a \
  --format="value(instance.basename())" | head -1)

# Explicação: Exclui a VM indicada e libera os recursos associados que não foram preservados.
gcloud compute instances delete "$VM" \
  --zone=us-central1-a --quiet
```

Aguarde e liste novamente.

---

# 6. Troubleshooting

Agora o erro já foi produzido e os componentes envolvidos já foram apresentados.

**Sintoma:** a VM apagada reaparece com outro nome.

**Hipótese:** o MIG está reconciliando o tamanho desejado.

**Evidências:**
```bash
# Explicação: Exibe configuração, target size, políticas e estado do Managed Instance Group.
gcloud compute instance-groups managed describe ace-mig \
  --zone=us-central1-a \
  --format="yaml(targetSize,currentActions)"
# Explicação: Lista as VMs pertencentes ao Managed Instance Group e seus estados.
gcloud compute instance-groups managed list-instances ace-mig \
  --zone=us-central1-a
```

**Causa:** o grupo foi configurado com `size=3`; uma exclusão manual cria diferença entre estado real e desejado.

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

Não há “correção” de falha: o comportamento é desejado. Para reduzir instâncias, use o próprio MIG:

```bash
# Explicação: Executa `gcloud compute instance-groups managed resize ace-mig --zone=us-central1-a --size=2` nesta etapa para aplicar ou inspecionar a configuração indicada.
gcloud compute instance-groups managed resize ace-mig \
  --zone=us-central1-a --size=2
```

---

# 8. Questões estilo ACE

1. Quem define como uma nova VM do grupo é criada? **Instance Template**.
2. Quem mantém a quantidade desejada? **MIG**.
3. Deletar uma VM manualmente reduz permanentemente o MIG? **Não**.

---

# 9. Cleanup

```bash
# Explicação: Exclui o Managed Instance Group e as instâncias gerenciadas por ele.
gcloud compute instance-groups managed delete ace-mig \
  --zone=us-central1-a --quiet
# Explicação: Exclui o Instance Template após remover os recursos que dependem dele.
gcloud compute instance-templates delete ace-template-v1 --quiet
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

## Tópicos do guia mapeados para esta aula

| Seção | Tópico | Esperado | Nível da matriz |
|---|---|---:|---:|
| 3.1 | MIG + autoscaling + instance template | `P` | `P` |


# 11. Refinamento prático — Rolling Update de MIG

## Laboratório — Rolling Update de um MIG

Um Managed Instance Group usa Instance Templates imutáveis. Para mudar a configuração das VMs, crie **um novo template** e faça rollout.

### Modelo mental

```text
Template v1
   ↓
MIG
   ↓
cria Template v2
   ↓
rolling update
   ↓
substituição gradual das VMs
```

### 1. Crie o novo template

```bash
# Explicação: Cria um segundo template com startup-script diferente para podermos identificar a nova versão.
gcloud compute instance-templates create ace-mig-template-v2 \
  --machine-type=e2-micro \
  --metadata=startup-script='#!/bin/bash
apt-get update
apt-get install -y nginx
echo "versao-v2" > /var/www/html/index.html'
```

### 2. Inicie o rolling update

```bash
# Explicação: Atualiza gradualmente o MIG para o novo template.
# --max-surge=1 permite uma VM adicional durante a substituição.
# --max-unavailable=0 tenta manter todas as instâncias alvo disponíveis durante o rollout.
gcloud compute instance-groups managed rolling-action start-update ace-mig \
  --zone=us-central1-a \
  --version=template=ace-mig-template-v2 \
  --max-surge=1 \
  --max-unavailable=0
```

### 3. Acompanhe o rollout

```bash
# Explicação: Lista as VMs do MIG e mostra template/ação/estado durante a atualização.
gcloud compute instance-groups managed list-instances ace-mig \
  --zone=us-central1-a

# Explicação: Aguarda até que o MIG termine as ações atuais e atinja estabilidade.
gcloud compute instance-groups managed wait-until ace-mig \
  --zone=us-central1-a \
  --stable
```

### 4. Teste

```bash
# Explicação: Obtém IPs externos das VMs do MIG para validar a versão servida.
gcloud compute instances list \
  --filter='name~ace-mig' \
  --format='table(name,networkInterfaces[0].accessConfigs[0].natIP)'
```

Acesse os IPs e procure `versao-v2`.

### Falha proposital

Crie um template com startup-script inválido ou aplicação que não sobe, aplique-o em laboratório e observe a atualização/health state. Não introduza outra falha ao mesmo tempo.

### Rollback

Não existe um comando especial chamado `rollback`: faça **um novo rolling update** apontando para o template anterior.

```bash
# Explicação: Reaplica o template anterior como nova atualização, efetivamente fazendo rollback.
gcloud compute instance-groups managed rolling-action start-update ace-mig \
  --zone=us-central1-a \
  --version=template=ace-mig-template \
  --max-surge=1 \
  --max-unavailable=0
```

### Cleanup adicional

```bash
# Explicação: Exclua o template v2 somente depois que nenhum MIG depender dele.
gcloud compute instance-templates delete ace-mig-template-v2 --quiet
```
