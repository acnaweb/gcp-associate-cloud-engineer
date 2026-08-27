# Aula 4 — Instance Templates e Managed Instance Groups

## Objetivos

Ao final desta aula, você deverá:

- Criar Instance Template;
- Criar MIG zonal e entender regional;
- Redimensionar MIG;
- Atualizar template conceitualmente;

---

# 1. Modelo mental

```text
Instance Template
      │
      v
Managed Instance Group
   ├─ VM
   ├─ VM
   └─ VM
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
  --image-family=debian-12 --image-project=debian-cloud

gcloud compute instance-groups managed create ace-mig \
  --zone=us-central1-a \
  --template=ace-template-v1 \
  --size=2

gcloud compute instance-groups managed list-instances ace-mig \
  --zone=us-central1-a

gcloud compute instance-groups managed resize ace-mig \
  --zone=us-central1-a --size=3
```

---

# 4. Testes e falhas propositais

- Delete manualmente uma VM do MIG e observe o grupo recriá-la.
- Instance Template é imutável: para mudanças, crie nova versão/template e faça update do MIG.
- MIG regional distribui instâncias entre zonas e melhora disponibilidade.

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

- MIG gerencia instâncias; unmanaged group não oferece os mesmos recursos.
- Template define 'como criar'. MIG define 'grupo desejado'.
- Regional MIG é preferível quando requisito é resiliência zonal.

---

# 7. Questões estilo ACE

- Uma VM do grupo foi apagada. O que o MIG faz? → reconcilia com tamanho desejado.
- Precisa mudar machine type de todas? → novo template + update.

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

