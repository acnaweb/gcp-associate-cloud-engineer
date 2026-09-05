# Aula 3 — Metadata e Startup Scripts

## Objetivos

Ao final, você deverá:
- criar metadata de instância;
- usar startup script para instalar nginx;
- consultar serial port output;
- provocar erro de bootstrap e identificar a linha problemática.


> **Custos:** São criadas duas VMs pequenas. Remova no final.

---

# 1. Conceito

Metadata guarda pares chave/valor associados à instância/projeto. Startup scripts podem automatizar bootstrap no boot. Não use metadata comum para armazenar segredos.

## Arquitetura mental

```text
VM metadata
   └─ startup-script
        └─ configura SO/aplicação
```

---

# 2. Criar

```bash
# Explicação: Exibe conteúdo de arquivo ou cria conteúdo via redirecionamento/heredoc, conforme a sintaxe usada.
cat > startup-ok.sh <<'EOF'
#!/bin/bash
apt-get update
apt-get install -y nginx
echo "ACE $(hostname)" > /var/www/html/index.html
systemctl enable --now nginx
EOF

# Explicação: Cria uma VM do Compute Engine com as opções de máquina, rede, disco e identidade informadas.
gcloud compute instances create ace-startup \
  --zone=us-central1-a \
  --machine-type=e2-micro \
  --metadata=ambiente=lab \
  --metadata-from-file=startup-script=startup-ok.sh \
  --image-family=debian-12 \
  --image-project=debian-cloud
```

---

# 3. Inspecionar

Antes de provocar qualquer erro, confirme a configuração criada. O troubleshooting desta aula usará **somente elementos que você já observou aqui**.

```bash
# Explicação: Exibe a configuração e o estado detalhado da VM para inspeção/troubleshooting.
gcloud compute instances describe ace-startup \
  --zone=us-central1-a \
  --format="yaml(metadata)"

# Explicação: Lê a saída da porta serial da VM, útil quando o sistema não inicializa ou o SSH não funciona.
gcloud compute instances get-serial-port-output ace-startup \
  --zone=us-central1-a | tail -80
```

---

# 4. Testar

```bash
# Explicação: Abre uma sessão SSH na VM indicada; flags adicionais podem executar um comando remotamente.
gcloud compute ssh ace-startup --zone=us-central1-a \
  --command="curl -s localhost; systemctl is-active nginx"
```

---

# 5. Quebrar propositalmente

Crie uma segunda VM com pacote inválido:

```bash
# Explicação: Exibe conteúdo de arquivo ou cria conteúdo via redirecionamento/heredoc, conforme a sintaxe usada.
cat > startup-fail.sh <<'EOF'
#!/bin/bash
apt-get update
apt-get install -y pacote-que-nao-existe-ace
EOF

# Explicação: Cria uma VM do Compute Engine com as opções de máquina, rede, disco e identidade informadas.
gcloud compute instances create ace-startup-fail \
  --zone=us-central1-a \
  --machine-type=e2-micro \
  --metadata-from-file=startup-script=startup-fail.sh \
  --image-family=debian-12 \
  --image-project=debian-cloud
```

---

# 6. Troubleshooting

Agora o erro já foi produzido e os componentes envolvidos já foram apresentados.

**Sintoma:** bootstrap não entrega o software esperado.

**Hipótese:** startup script falhou.

**Evidência ensinada nesta aula:**
```bash
# Explicação: Lê a saída da porta serial da VM, útil quando o sistema não inicializa ou o SSH não funciona.
gcloud compute instances get-serial-port-output ace-startup-fail \
  --zone=us-central1-a | tail -100
```

Procure a mensagem do `apt-get`.

**Causa:** pacote deliberadamente inexistente.

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

Atualize metadata com script válido ou recrie a VM.

```bash
# Explicação: Executa `gcloud compute instances add-metadata ace-startup-fail --zone=us-central1-a --metada…` nesta etapa para aplicar ou inspecionar a configuração indicada.
gcloud compute instances add-metadata ace-startup-fail \
  --zone=us-central1-a \
  --metadata-from-file=startup-script=startup-ok.sh

# Explicação: Reinicializa a VM de forma semelhante a um reset de hardware, sem desligamento gracioso do sistema operacional.
gcloud compute instances reset ace-startup-fail --zone=us-central1-a
```

Depois confira serial output novamente.

---

# 8. Questões estilo ACE

1. Quer instalar agente automaticamente em novas VMs? **Startup script**.
2. Onde começar se o startup falhar? **Serial port output/logs**.
3. Deve guardar senha em metadata simples? **Não**.

---

# 9. Cleanup

```bash
# Explicação: Exclui a VM indicada e libera os recursos associados que não foram preservados.
gcloud compute instances delete ace-startup ace-startup-fail \
  --zone=us-central1-a --quiet
# Explicação: Remove o arquivo/diretório temporário indicado durante correção ou cleanup.
rm -f startup-ok.sh startup-fail.sh
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

# Cobertura adicional — SSH, OS Login e Metadata

A prova menciona explicitamente conexão remota e configuração de OS Login.

## SSH tradicional x OS Login

```text
Metadata SSH keys
→ chaves mantidas em metadata de projeto/instância

OS Login
→ acesso SSH integrado a IAM/identidade Google
```

Verifique metadata:

```bash
# Explicação: Exibe metadados/configurações do Compute Engine no projeto.
gcloud compute project-info describe --format='yaml(commonInstanceMetadata)'
# Explicação: Exibe a configuração e o estado detalhado da VM para inspeção/troubleshooting.
gcloud compute instances describe INSTANCE --zone=ZONE --format='yaml(metadata)'
```

Habilitar OS Login por metadata de projeto em laboratório controlado:

```bash
# Explicação: Adiciona metadata em nível de projeto, tornando o valor disponível às VMs conforme as regras do Compute Engine.
gcloud compute project-info add-metadata \
  --metadata enable-oslogin=TRUE
```

Roles relacionadas ao acesso do SO incluem `roles/compute.osLogin` e, para acesso administrativo, `roles/compute.osAdminLogin`.

Não confunda:

```text
IAM permite usar OS Login
≠
Firewall permite chegar à porta 22
```

São duas camadas distintas.
