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
cat > startup.sh <<'EOF'
#!/bin/bash
apt-get update
apt-get install -y nginx
echo "$(hostname)" > /var/www/html/index.html
EOF

gcloud compute instance-templates create ace-template-v1 \
  --machine-type=e2-micro \
  --metadata-from-file=startup-script=startup.sh \
  --image-family=debian-12 \
  --image-project=debian-cloud

gcloud compute instance-groups managed create ace-mig \
  --zone=us-central1-a \
  --template=ace-template-v1 \
  --size=2
```

---

# 3. Inspecionar

Antes de provocar qualquer erro, confirme a configuração criada. O troubleshooting desta aula usará **somente elementos que você já observou aqui**.

```bash
gcloud compute instance-templates describe ace-template-v1
gcloud compute instance-groups managed describe ace-mig \
  --zone=us-central1-a
gcloud compute instance-groups managed list-instances ace-mig \
  --zone=us-central1-a
```

---

# 4. Testar

```bash
gcloud compute instance-groups managed resize ace-mig \
  --zone=us-central1-a --size=3

gcloud compute instance-groups managed list-instances ace-mig \
  --zone=us-central1-a
```

---

# 5. Quebrar propositalmente

Pegue uma VM do grupo e apague manualmente:

```bash
VM=$(gcloud compute instance-groups managed list-instances ace-mig \
  --zone=us-central1-a \
  --format="value(instance.basename())" | head -1)

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
gcloud compute instance-groups managed describe ace-mig \
  --zone=us-central1-a \
  --format="yaml(targetSize,currentActions)"
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
gcloud compute instance-groups managed delete ace-mig \
  --zone=us-central1-a --quiet
gcloud compute instance-templates delete ace-template-v1 --quiet
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
