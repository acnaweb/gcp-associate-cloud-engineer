# Aula 3 — Metadata e Startup Scripts

## Objetivos

Ao final desta aula, você deverá:

- Usar metadata;
- Automatizar bootstrap com startup script;
- Inspecionar serial port/logs;
- Corrigir script quebrado;

---

# 1. Modelo mental

```text
Instance metadata
      │
      v
Startup script
      │
      v
VM configurada automaticamente
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

Crie:
```bash
cat > startup.sh <<'EOF'
#!/bin/bash
apt-get update
apt-get install -y nginx
echo "ACE startup $(hostname)" > /var/www/html/index.html
systemctl restart nginx
EOF
```

```bash
gcloud compute instances create ace-startup-vm \
  --zone=us-central1-a \
  --machine-type=e2-micro \
  --tags=http-server \
  --metadata=ambiente=lab \
  --metadata-from-file=startup-script=startup.sh \
  --image-family=debian-12 \
  --image-project=debian-cloud
```

Leia metadata:
```bash
gcloud compute instances describe ace-startup-vm \
  --zone=us-central1-a \
  --format="yaml(metadata)"
```

Logs do startup:
```bash
gcloud compute instances get-serial-port-output ace-startup-vm \
  --zone=us-central1-a | tail -50
```

---

# 4. Testes e falhas propositais

- Troque `nginx` por um pacote inexistente e recrie a VM para observar falha.
- Startup scripts precisam ser idempotentes quando há reexecução/recriação.
- Metadata não deve armazenar segredo em texto puro.

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

- Metadata é configuração, não segredo.
- Startup script executa no boot e é útil para bootstrap.
- Instance template + startup script é combinação comum em MIG.

---

# 7. Questões estilo ACE

- Quer instalar agente em toda nova VM de um MIG? → startup script no template.
- Script falhou: onde começar? → serial port output / logs.

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

