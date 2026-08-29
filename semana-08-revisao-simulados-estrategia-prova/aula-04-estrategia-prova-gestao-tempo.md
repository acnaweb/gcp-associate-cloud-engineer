# Aula 4 — Estratégia de Prova e Gestão do Tempo

## Objetivos

Ao final, você deverá:
- identificar requisito dominante;
- eliminar alternativas;
- gerenciar tempo;
- separar erro de conhecimento de erro de leitura.


---

# 1. Conceito

Questões de cenário oferecem informações úteis e distrações. A melhor resposta atende requisitos obrigatórios com menor complexidade, escopo correto e least privilege.

## Arquitetura mental

```text
Questão
 ↓
verbo/requisito
 ↓
restrições
 ↓
eliminar opções
 ↓
responder / marcar e seguir
```

---

# 2. Criar

Selecione 20 questões dos simulados e faça uma sessão cronometrada. Não consulte material durante a primeira passagem.

---

# 3. Inspecionar

Antes de provocar qualquer erro, confirme a configuração criada. O troubleshooting desta aula usará **somente elementos que você já observou aqui**.

Para cada questão, marque:
```text
verbo:
requisito dominante:
restrições:
duas opções eliminadas:
```

---

# 4. Testar

Na segunda passagem, explique por que a correta é melhor, não apenas possível.

---

# 5. Quebrar propositalmente

Escolha deliberadamente uma alternativa “tecnicamente possível, mas mais complexa” e explique qual requisito ela viola (custo, operação, segurança, escopo).

---

# 6. Troubleshooting

Agora o erro já foi produzido e os componentes envolvidos já foram apresentados.

**Sintoma:** duas opções parecem corretas.

**Hipótese:** uma delas viola uma restrição implícita/explicita como “mínima operação” ou “least privilege”.

**Evidência:** releia a última frase e palavras como `MOST`, `LEAST`, `MINIMIZE`, `REQUIRED`.

**Causa comum:** responder pelo produto conhecido, não pelo requisito.

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

Reescreva a questão em uma linha:
```text
Preciso de X, com restrição Y; portanto escolho Z.
```

---

# 8. Questões estilo ACE

1. Duas opções funcionam, mas uma exige cluster sem necessidade: escolha a **mais simples/gerenciada**.
2. Least privilege elimina **Owner/Editor** quando role específica atende.
3. Não sabe uma questão após tempo razoável: **marque e avance**.

---

# 9. Cleanup

Nenhum recurso é criado.

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
