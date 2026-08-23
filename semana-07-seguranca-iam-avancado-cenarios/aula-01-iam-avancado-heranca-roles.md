# Aula 1 — IAM Avançado, Herança e Roles

## Objetivos

Ao final desta aula, você deverá:

- Entender herança de IAM;
- Entender políticas cumulativas;
- Diferenciar roles básicas, predefinidas e customizadas;
- Entender escopo;
- Aplicar least privilege.

---

# 1. Hierarquia

```text
Organization
    ↓
Folder
    ↓
Project
    ↓
Resource
```

Uma política concedida em nível superior pode ser herdada pelos recursos abaixo.

---

# 2. Exemplo de Herança

```text
Organization
  roles/viewer → grupo-a
       │
       ▼
Folder
       │
       ▼
Project
       │
       ▼
VM
```

O grupo pode herdar acesso de visualização aos recursos abaixo.

---

# 3. IAM é cumulativo

Modelo mental:

```text
Access from Organization
        +
Access from Folder
        +
Access from Project
        +
Access from Resource
        =
Effective Permissions
```

---

# 4. Basic Roles

```text
roles/viewer
roles/editor
roles/owner
```

São amplas.

Para a prova:

> Evite basic roles quando uma predefined role mais específica atender.

---

# 5. Predefined Roles

Exemplos:

```text
roles/storage.objectViewer
roles/bigquery.dataViewer
roles/compute.instanceAdmin.v1
roles/run.invoker
```

São mantidas pelo Google e normalmente preferíveis.

---

# 6. Custom Roles

Use quando nenhuma predefined role atende exatamente.

```text
Custom Role
   ├── permission A
   ├── permission B
   └── permission C
```

Trade-offs:

- Mais controle;
- Mais manutenção;
- Necessidade de governança.

---

# 7. Least Privilege

Exemplo ruim:

```text
Application needs read-only Storage
        ↓
roles/editor
```

Melhor:

```text
roles/storage.objectViewer
```

---

# 8. Escopo do Binding

Pense sempre em:

```text
WHO
 +
ROLE
 +
WHERE
```

Exemplo:

```text
serviceAccount:app@...
+
roles/storage.objectViewer
+
bucket específico
```

Melhor que conceder no projeto inteiro quando o requisito é restrito.

---

# 9. Questões Estilo ACE

## Questão 1

Usuário precisa apenas iniciar/parar VMs, sem administrar todo o projeto.

**Resposta:** role predefinida apropriada, evitando Editor/Owner.

## Questão 2

Nenhuma role pronta possui exatamente as permissões necessárias.

**Resposta:** considerar Custom Role.

## Questão 3

Um role binding foi feito no Folder.

Projetos abaixo podem herdar?

**Resposta:** sim.

---

# 10. Checklist

- [ ] Entendo herança
- [ ] Entendo permissões efetivas
- [ ] Sei diferenciar tipos de role
- [ ] Entendo escopo
- [ ] Aplico least privilege
