# RELATORIO-COMPATIBILIDADE-GUIA-ANEXO.md

## Resultado

A matriz da versão anterior **não estava plenamente compatível com o guia oficial anexado como fonte de verdade**.

### Problemas encontrados

1. A auditoria anterior possuía **4 seções**; o anexo possui **5**.
2. Os pesos estavam diferentes:
   - anterior: 20 / 30 / 30 / 20;
   - anexo: 20 / 17,5 / 25 / 20 / 17,5.
3. A matriz anterior misturava requisitos do exame com conteúdos complementares.
4. Alguns termos explícitos do anexo não estavam suficientemente destacados:
   - Cloud Run for Anthos;
   - GKE Enterprise;
   - Cloud Foundation Toolkit;
   - export de logs para sistemas externos/on-premises;
   - Cloud diagnostics;
   - status do Google Cloud.
5. Alguns conteúdos adicionais estavam marcados como se fossem obrigatórios, embora não apareçam explicitamente no anexo.

## Correções realizadas

- Matriz reconstruída somente a partir do PDF anexado.
- Auditoria reconstruída nas 5 seções oficiais.
- Conteúdo complementar separado do obrigatório.
- Aula de Cloud Functions/Eventarc ampliada com decisão:
  - Cloud Run totalmente gerenciado;
  - Cloud Run for Anthos;
  - Cloud Functions.
- Aula GKE ampliada com GKE Enterprise.
- Aula de Logging/Observability ampliada com:
  - export externo/on-prem;
  - BigQuery;
  - Log Router;
  - detalhes de mensagens;
  - cloud diagnostics;
  - Google Cloud status;
  - Audit Logs.
- Aula IaC corrigida para usar Cloud Foundation Toolkit como item oficial.
- Tópicos fora do anexo marcados como complementares.

## Critério daqui em diante

A fonte de verdade para esta baseline é o **PDF oficial anexado**.

Conteúdo adicional pode permanecer, mas deve ser classificado como:

```text
Complementar
```

e nunca substituir ou ocultar os tópicos explicitamente cobrados pelo guia.
