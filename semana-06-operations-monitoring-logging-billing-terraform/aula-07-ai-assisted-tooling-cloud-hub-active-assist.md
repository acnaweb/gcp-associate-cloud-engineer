# Aula 7 — AI-assisted Tooling, Active Assist e Cloud Hub

## Método da aula

```text
Conceito → Criar/Configurar → Inspecionar → Testar → Quebrar → Troubleshooting → Corrigir → Questões → Cleanup
```

> O troubleshooting usa apenas conceitos apresentados antes na própria aula.

## 1. Conceito

O exam guide atual inclui ferramentas de assistência por IA e operação:

- Gemini CLI;
- Google Antigravity;
- Gemini Cloud Assist;
- Application Design Center;
- Active Assist;
- Cloud Hub.

## 2. Criar / configurar

Nem todas exigem ou permitem um lab uniforme em conta pessoal. Faça laboratório de descoberta no Console e documentação oficial.

Para Gemini Cloud Assist, identifique os pontos de entrada disponíveis no Console atual.

## 3. Inspecionar

Registre a função:

```text
Gemini CLI / Cloud Assist → assistência para tarefas cloud
Application Design Center → planejamento/design de aplicações compatíveis
Active Assist             → recomendações de otimização
Cloud Hub                 → eventos ativos e saúde agregada
```

## 4. Testar

Pegue uma recomendação gerada por ferramenta de IA e valide manualmente:

```text
recurso existe?
comando sugerido é atual?
IAM permite?
impacto/custo?
cleanup?
```

## 5. Quebrar propositalmente

Falha de processo:

> executar uma sugestão gerada por IA sem `describe`, `plan` ou revisão.

## 6. Troubleshooting

**Sintoma:** mudança inesperada/erro de permissão.

**Hipótese:** sugestão não foi validada no contexto real.

**Evidência:** contexto/permissions diferem do assumido.

**Causa:** ferramenta assistiva foi tratada como autoridade operacional.

## 7. Corrigir

Sempre valide com documentação, `describe`, IAM e `plan` quando aplicável.

## 8. Questões ACE

1. Recomendações de rightsizing/otimização → **Active Assist**.
2. Visão de eventos e saúde → **Cloud Hub**.
3. Assistência por IA substitui revisão? **Não**.

## 9. Cleanup

Nenhum recurso foi criado.
