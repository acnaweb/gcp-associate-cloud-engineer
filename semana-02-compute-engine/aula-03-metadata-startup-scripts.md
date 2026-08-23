# Aula 3 — Metadata e Startup Scripts

## Objetivos

Ao final desta aula, você deverá:

- Entender metadata de instância;
- Entender startup scripts;
- Automatizar configuração inicial de VMs;
- Diferenciar custom image de startup script;
- Criar VMs já configuradas.

---

# 1. Metadata

Metadata armazena pares chave/valor associados a uma VM ou projeto.

Exemplo:

```text
environment = dev
team        = platform
startup-script = ...
```

Metadata pode ser usada por aplicações e pelo próprio sistema de inicialização.

---

# 2. Startup Script

Um startup script é executado automaticamente quando a VM inicializa.

Exemplo:

```text
Create VM
   ↓
Boot
   ↓
Startup Script
   ↓
Install packages
   ↓
Start application
```

---

# 3. Exemplo simples

Crie `startup.sh`:

```bash
#!/bin/bash

apt-get update
apt-get install -y nginx

echo "ACE Compute Engine Lab" \
  > /var/www/html/index.html

systemctl enable nginx
systemctl restart nginx
```

---

# 4. Criar VM com startup script

```bash
gcloud compute instances create ace-web-01 \
  --zone=southamerica-east1-a \
  --machine-type=e2-medium \
  --metadata-from-file startup-script=startup.sh
```

---

# 5. Startup script inline

```bash
gcloud compute instances create ace-web-02 \
  --zone=southamerica-east1-a \
  --machine-type=e2-medium \
  --metadata startup-script='#!/bin/bash
apt-get update
apt-get install -y nginx'
```

Para scripts maiores, prefira arquivo.

---

# 6. Custom Metadata

```bash
gcloud compute instances add-metadata ace-vm-01 \
  --zone=southamerica-east1-a \
  --metadata environment=dev,team=platform
```

---

# 7. Consultar metadata configurada

```bash
gcloud compute instances describe ace-vm-01 \
  --zone=southamerica-east1-a \
  --format="yaml(metadata)"
```

---

# 8. Startup Script x Custom Image

## Startup Script

Bom para:

- Instalação dinâmica;
- Configuração na inicialização;
- Pequenas variações por ambiente.

## Custom Image

Bom para:

- SO e software pré-configurados;
- Inicialização mais previsível;
- Padronização de muitas VMs.

Tabela:

| Necessidade | Melhor opção |
|---|---|
| Configuração dinâmica | Startup Script |
| Golden image padronizada | Custom Image |
| Pequenos parâmetros | Metadata |
| Muitas VMs idênticas | Image + Instance Template |

---

# 9. Idempotência

Um startup script pode rodar mais de uma vez.

Idealmente ele deve ser idempotente:

```text
Executar 1 vez  → estado correto
Executar 2 vezes → mesmo estado correto
```

Evite scripts que quebram quando repetidos.

---

# 10. Logs e troubleshooting

Quando um startup script falha:

- Verifique serial console;
- Logs do sistema;
- Sintaxe do script;
- Permissões;
- Acesso à internet;
- APIs e repositórios.

Comando útil:

```bash
gcloud compute instances get-serial-port-output ace-web-01 \
  --zone=southamerica-east1-a
```

---

# 11. Laboratório

Crie `startup.sh`:

```bash
cat > startup.sh <<'EOF'
#!/bin/bash
apt-get update
apt-get install -y nginx
echo "Google Cloud ACE - Semana 2" > /var/www/html/index.html
systemctl enable nginx
systemctl restart nginx
EOF
```

Crie a VM:

```bash
gcloud compute instances create ace-web-01 \
  --zone=southamerica-east1-a \
  --machine-type=e2-medium \
  --metadata-from-file startup-script=startup.sh
```

Descreva:

```bash
gcloud compute instances describe ace-web-01 \
  --zone=southamerica-east1-a
```

---

# 12. Pegadinhas ACE

- Metadata não é substituto para Secret Manager.
- Startup script automatiza bootstrap.
- Para padronização pesada e previsível, custom image pode ser melhor.
- Scripts devem ser idempotentes.
- Problemas de inicialização podem ser investigados via serial output.

---

# 13. Questões Estilo ACE

## Questão 1

Você precisa instalar automaticamente NGINX em cada VM no primeiro boot.

**Resposta:** startup script.

## Questão 2

Você precisa armazenar um parâmetro simples `environment=dev`.

**Resposta:** metadata.

## Questão 3

Você precisa de centenas de VMs com o mesmo SO já preparado.

**Resposta:** custom image + instance template.

---

# 14. Checklist

- [ ] Entendo metadata
- [ ] Sei criar startup script
- [ ] Sei anexar startup script à VM
- [ ] Entendo startup script x custom image
- [ ] Entendo idempotência
- [ ] Sei usar serial output para troubleshooting
