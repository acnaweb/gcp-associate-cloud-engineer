# Aula 2 — Cloud Run Services, Revisions e Scaling

> Semana 5 — Aula 2. **Pré-requisito:** Aula 1, com a image `ace-web:v1` publicada no Artifact Registry. Não exclua o repositório da Aula 1 antes de terminar esta aula.

## Objetivos

Ao final, você deverá:

- Explicar o modelo serverless e distinguir **Service**, **Revision**, **Instance** e **Request**;
- Implantar, listar, descrever e testar um serviço Cloud Run usando uma image do Artifact Registry;
- Diferenciar acesso público e autenticado sem depender de `allUsers`;
- Criar uma segunda image e uma nova revisão, inspecionando ambas;
- Fazer rollout canary 90/10, promover 100% e executar rollback;
- Explicar e configurar autoscaling, scale-to-zero, mínimo/máximo de instâncias e concurrency;
- Relacionar concurrency, instâncias, latência, custos e capacidade de sistemas downstream;
- Provocar e diagnosticar uma falha determinística de porta e corrigir a configuração;
- Inspecionar logs e limpar recursos sem apagar artefatos compartilhados.

> [!IMPORTANT]
> ## Pré-requisito — Aula 1
>
> O laboratório desta aula é uma continuação da **Aula 1 — Containers e Artifact Registry**.
>
> Antes de iniciar, você deve ter concluído a aula anterior e possuir:
>
> - o repositório Docker criado no Artifact Registry;
> - a container image `ace-web:v1` publicada nesse repositório;
> - a autenticação do Docker configurada para o Artifact Registry;
> - as variáveis `PROJECT_ID`, `REGION`, `HOST` e `REPO` configuradas novamente nesta sessão.
>
> **Não execute o cleanup da Aula 1 antes de concluir esta aula**, pois a image publicada no Artifact Registry será utilizada para criar o Cloud Run Service.
>
> Se você já executou o cleanup da Aula 1, recrie o repositório e publique novamente a image antes de continuar.

## 1. Conceitos e arquitetura

Cloud Run Services executa containers que recebem requisições HTTP/HTTPS sem administrar servidores. Uma **revision** é um snapshot imutável de image e configurações de execução; um **service** roteia tráfego para uma ou mais revisões; cada revisão pode ter várias **instances**; cada instância pode atender múltiplas **requests** simultâneas.

```text
Artifact Registry (ace-web:v1 / ace-web:v2)
                 |
                 v
          Cloud Run Service
             ace-web
                 |
            HTTPS URL
                 |
        +--------+--------+
        |                 |
       90%               10%
        |                 |
    Revision v1       Revision v2
        |                 |
    Instances          Instances
     0 .. N             0 .. N
```

| Recurso | Função | Alteração típica |
|---|---|---|
| Service | URL, acesso e distribuição de tráfego | `services describe`, `update-traffic` |
| Revision | Versão imutável de image/configuração | Novo deploy/update cria revisão |
| Instance | Processo container que recebe requests | Autoscaler aumenta/diminui |
| Request | Chamada HTTP individual | Roteada para revisão/instância |

**Quando usar:** APIs, microsserviços HTTP, web apps e serviços stateless. Compare com Compute Engine (controle da VM) e GKE (orquestração Kubernetes) nas aulas posteriores. **Limite:** armazenamento local da instância não é persistência compartilhada.

## 2. Preparação, custos e IAM

A Aula 1 usa Nginx na porta **80**, não 8080. Cloud Run deve receber `--port=80` neste exemplo. Cloud Run fornece a variável `PORT`, mas este Nginx não foi configurado para interpretá-la dinamicamente: por isso o laboratório fixa a porta correta explicitamente.

Mínimo de instâncias acima de zero gera custo mesmo sem requisições. Acesso à image requer permissão de leitura no Artifact Registry para a identidade responsável pelo pull. Para deploy, o operador precisa de permissões Cloud Run e `iam.serviceAccounts.actAs` sobre a identidade de runtime quando aplicável. Não conceda papéis amplos automaticamente.

```bash
# Recupera o projeto atual e define os nomes do laboratório.
export PROJECT_ID="$(gcloud config get-value project)"
export REGION="southamerica-east1"
export REPO="ace-containers-lab"
export SERVICE="ace-web"
export HOST="${REGION}-docker.pkg.dev"
export IMAGE_V1="${HOST}/${PROJECT_ID}/${REPO}/ace-web:v1"
export IMAGE_V2="${HOST}/${PROJECT_ID}/${REPO}/ace-web:v2"
# Confere a conta e o projeto antes de criar recursos cobrados.
gcloud auth list --filter="status:ACTIVE"
gcloud config get-value project
# Confere se a image da Aula 1 ainda está no registry.
gcloud artifacts docker images list "${HOST}/${PROJECT_ID}/${REPO}" --include-tags
# Habilita a API Cloud Run.
gcloud services enable run.googleapis.com --project="$PROJECT_ID"
```

**Esperado:** a image `ace-web:v1` existe. Se a Aula 1 foi limpa, repita seu build/push antes de continuar. Execute em projeto de laboratório; não use nomes de serviço de produção.

## 3. Deploy da v1 e inspeção

O deploy abaixo **não abre acesso público**. O serviço permanece protegido por IAM, independentemente de a organização permitir ou bloquear `allUsers`.

```bash
# Cria o serviço usando a image publicada e a porta real do Nginx.
gcloud run deploy "$SERVICE" \
  --image="$IMAGE_V1" \
  --region="$REGION" \
  --port=80 \
  --no-allow-unauthenticated \
  --min=0 \
  --max=3 \
  --concurrency=10
# Lista os serviços da região.
gcloud run services list --region="$REGION"
# Inspeciona URL, image, porta, scaling e tráfego.
gcloud run services describe "$SERVICE" --region="$REGION" --format=yaml
# Guarda a URL e o nome da primeira revisão.
export SERVICE_URL="$(gcloud run services describe "$SERVICE" --region="$REGION" --format='value(status.url)')"
export REV1="$(gcloud run services describe "$SERVICE" --region="$REGION" --format='value(status.latestCreatedRevisionName)')"
# Confere os valores antes de prosseguir.
printf 'URL=%s\nREV1=%s\n' "$SERVICE_URL" "$REV1"
```

**Esperado:** revisão Ready, URL HTTPS e tráfego 100% para v1. Se o deploy falhar, inspecione a mensagem e a revisão; não libere acesso público como tentativa de correção.

## 4. Teste HTTP autenticado

O invocador precisa de `roles/run.invoker` no serviço ou em escopo superior. Para usuário humano com permissão, o comando abaixo pode emitir um **identity token**; o token não é uma access token genérica. Caso sua identidade não consiga gerar um token válido para o serviço, consulte o administrador ou use uma identidade de teste autorizada, sem expor o serviço.

```bash
# Obtém um identity token da identidade gcloud ativa.
export ID_TOKEN="$(gcloud auth print-identity-token)"
# Faz chamada HTTPS autenticada ao serviço.
curl -i -H "Authorization: Bearer ${ID_TOKEN}" "$SERVICE_URL"
# Confere o HTML esperado da primeira image.
curl -fsS -H "Authorization: Bearer ${ID_TOKEN}" "$SERVICE_URL" | grep 'ACE Containers v1'
```

**Esperado:** `HTTP 200` e `ACE Containers v1`. Se retornar **403**, confira `roles/run.invoker`; se retornar **401**, confira validade/audience do identity token. Acesso público é **opcional** e depende de política organizacional: não altere `allUsers` para fazer o laboratório funcionar.

## IAM e `roles/run.invoker`

Cloud Run separa **autenticação** de **autorização**. Um identity token comprova quem está fazendo a chamada; o IAM decide se esse principal pode invocar o serviço.

```text
Request
   |
   +--> Autenticação: quem é você?
   |       Identity Token
   |
   v
Principal identificado
   |
   +--> Autorização: pode invocar?
           IAM
           roles/run.invoker
   |
   v
Cloud Run Service
```

O papel predefinido `roles/run.invoker` é destinado à **invocação** de serviços e jobs do Cloud Run. Ele não transforma o principal em administrador do serviço.

| Papel | Uso nesta aula |
|---|---|
| `roles/run.invoker` | Invocar o Cloud Run Service |
| `roles/run.admin` | Administrar recursos do Cloud Run; não deve ser concedido apenas para permitir uma chamada HTTP |

### Inspecionar a política IAM

```bash
# Exibe a política IAM aplicada ao serviço.
gcloud run services get-iam-policy "$SERVICE" \
  --region="$REGION"
# Mostra a conta gcloud atualmente ativa.
gcloud auth list --filter="status:ACTIVE"
```

Para um serviço que exige autenticação, o principal que realiza a chamada precisa estar autorizado a invocá-lo. Em um laboratório individual, conceda o papel somente se necessário e apenas ao principal que fará o teste.

```bash
# Obtém o e-mail da conta ativa.
export ACTIVE_ACCOUNT="$(gcloud auth list --filter='status:ACTIVE' --format='value(account)')"
# Concede ao usuário ativo somente a capacidade de invocar este serviço.
gcloud run services add-iam-policy-binding "$SERVICE" \
  --region="$REGION" \
  --member="user:$ACTIVE_ACCOUNT" \
  --role="roles/run.invoker"
# Confirma a política resultante.
gcloud run services get-iam-policy "$SERVICE" \
  --region="$REGION"
```

> Em ambientes corporativos, a concessão pode ser bloqueada por Organization Policy ou o principal pode receber o papel por grupo/projeto. Não adicione bindings redundantes se o acesso já estiver sendo herdado ou administrado centralmente.

### Testar com identity token

```bash
# Recupera a URL do serviço.
export SERVICE_URL="$(gcloud run services describe "$SERVICE" \
  --region="$REGION" \
  --format='value(status.url)')"
# Gera um identity token e o envia no cabeçalho Authorization.
curl -i \
  -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  "$SERVICE_URL"
```

O ponto importante é:

```text
Identity Token válido
        !=
autorização automática

Identity Token
      +
roles/run.invoker
      =
chamada autenticada e autorizada
```

### Serviço público

Quando a política da organização permite acesso público, uma configuração possível é conceder `roles/run.invoker` a `allUsers`.

```text
allUsers
   +
roles/run.invoker
   |
   v
invocação sem autenticação do usuário
```

```bash
# EXEMPLO CONDICIONAL: torna o serviço público somente se a política da organização permitir.
gcloud run services add-iam-policy-binding "$SERVICE" \
  --region="$REGION" \
  --member="allUsers" \
  --role="roles/run.invoker"
```

Este comando **não é requisito do laboratório**. Prefira o teste autenticado quando o ambiente não deve expor o serviço publicamente.

### Troubleshooting de acesso

| Sintoma | Hipótese | Evidência | Correção |
|---|---|---|---|
| `401` | Chamada sem credencial válida | Verificar cabeçalho/token | Gerar e enviar identity token adequado |
| `403` | Principal autenticado sem autorização suficiente | `get-iam-policy` + conta ativa | Conceder/solicitar `roles/run.invoker` no escopo correto |
| `allUsers` bloqueado | Restrição organizacional | Erro ao alterar IAM/policy | Manter serviço autenticado; não contornar a policy |

**Regra de troubleshooting:** não conceda `roles/run.admin` para corrigir um `403` de invocação. Primeiro identifique o principal e verifique se ele precisa apenas de `roles/run.invoker`.


## 5. Criar image v2 e publicar no mesmo repositório

A Aula 1 ensinou build/tag/push; aqui repetimos somente o necessário para produzir uma resposta HTTP distinta e observável no canary. Use a pasta criada naquela aula ou recrie seus arquivos.

```bash
# Recria uma pasta isolada caso a Aula 1 já tenha sido limpa localmente.
mkdir -p "$HOME/ace-cloud-run-v2"
cd "$HOME/ace-cloud-run-v2"
# Produz conteúdo identificável na segunda revisão.
printf '<h1>ACE Containers v2</h1>\n' > index.html
# Usa a mesma base e porta da Aula 1.
printf 'FROM nginx:alpine\nCOPY index.html /usr/share/nginx/html/index.html\nEXPOSE 80\n' > Dockerfile
# Constrói, publica e verifica a segunda image.
docker build -t "$IMAGE_V2" .
docker push "$IMAGE_V2"
gcloud artifacts docker images list "${HOST}/${PROJECT_ID}/${REPO}" --include-tags
```

**Esperado:** tag `v2` disponível no mesmo repositório. Se `docker push` falhar, volte ao diagnóstico de autenticação/IAM da Aula 1.

## 6. Criar revisão v2 sem enviar tráfego

```bash
# Implanta a nova image sem alterar o tráfego da v1.
gcloud run deploy "$SERVICE" \
  --image="$IMAGE_V2" \
  --region="$REGION" \
  --port=80 \
  --no-traffic
# Guarda o nome da revisão criada.
export REV2="$(gcloud run services describe "$SERVICE" --region="$REGION" --format='value(status.latestCreatedRevisionName)')"
# Lista todas as revisões do serviço.
gcloud run revisions list --service="$SERVICE" --region="$REGION"
# Inspeciona especificamente a revisão v2.
gcloud run revisions describe "$REV2" --region="$REGION" --format=yaml
# Confirma que a revisão anterior ainda recebe todo o tráfego.
gcloud run services describe "$SERVICE" --region="$REGION" --format='yaml(status.traffic)'
```

**Esperado:** duas revisões distintas; v2 Ready com **0%** e v1 com **100%**. Uma revisão não é alterada in-place: novas mudanças de configuração de revisão produzem uma nova revisão.

## 7. Canary 90/10, promoção e rollback

```bash
# Direciona 90% do tráfego para v1 e 10% para v2.
gcloud run services update-traffic "$SERVICE" \
  --region="$REGION" \
  --to-revisions="${REV1}=90,${REV2}=10"
# Inspeciona a divisão configurada (evidência principal).
gcloud run services describe "$SERVICE" --region="$REGION" --format='yaml(status.traffic)'
# Recolhe respostas HTTP para observar ambas as versões.
for i in $(seq 1 60); do curl -fsS -H "Authorization: Bearer $(gcloud auth print-identity-token)" "$SERVICE_URL" | grep -o 'ACE Containers v[12]' || true; done | sort | uniq -c
```

**Esperado:** configuração 90/10; a contagem é **aproximada e não determinística**, especialmente com poucas requisições. Um 90/10 não garante exatamente 54 e 6 respostas em 60 chamadas.

```bash
# Promove v2 para 100% do tráfego.
gcloud run services update-traffic "$SERVICE" \
  --region="$REGION" \
  --to-revisions="${REV2}=100"
# Verifica a resposta da nova versão.
curl -fsS -H "Authorization: Bearer $(gcloud auth print-identity-token)" "$SERVICE_URL" | grep 'ACE Containers v2'
# Simula decisão de rollback, voltando 100% para a revisão anterior.
gcloud run services update-traffic "$SERVICE" \
  --region="$REGION" \
  --to-revisions="${REV1}=100"
# Verifica que o rollback restaurou v1.
curl -fsS -H "Authorization: Bearer $(gcloud auth print-identity-token)" "$SERVICE_URL" | grep 'ACE Containers v1'
# Confere a configuração final de tráfego.
gcloud run services describe "$SERVICE" --region="$REGION" --format='yaml(status.traffic)'
```

**Rollback de tráfego** não exclui revisões. Revisions com 0% podem continuar existindo para novas decisões de rollout.

## 8. Autoscaling, mínimo/máximo e concurrency

O autoscaler considera sinais como concorrência e CPU. **Concurrency** limita o número de requisições simultâneas por instância, mas não é fórmula exata de capacidade: uma aplicação CPU-bound pode precisar de mais instâncias mesmo com concurrency alta. Mínimo no **nível de serviço** pode manter instâncias aquecidas, com custo; máximo no **nível de serviço** limita capacidade, mas pode ser excedido temporariamente em situações documentadas. Máximo não é garantia rígida de conexões ao banco.

```text
Requests + CPU
      |
      v
Autoscaling por revisão
      |
      +--> concurrency por instância
      +--> service min/max instances
      +--> CPU, latência, quotas e downstreams
```

| Configuração | Benefício | Trade-off |
|---|---|---|
| `min=0` | Permite scale-to-zero | Possível cold start |
| `min=1` | Reduz cold start | Custo de instância ociosa |
| `max=3` | Limita crescimento e custo | Pode gerar fila/429/503 sob carga |
| `concurrency=1` | Isola requests pesadas | Mais instâncias potenciais |
| `concurrency=20` | Melhor compartilhamento de instância | Mais disputa por CPU/memória |

**Nota importante:** configurações de **scaling no nível de serviço** podem ser aplicadas sem criar revisão. Configurações como **concurrency** fazem parte da revisão e geram nova revisão. Não trate toda alteração do Cloud Run como criação obrigatória de revision.

```bash
# Define min/max no nível do serviço e observa a configuração.
gcloud run services update "$SERVICE" --region="$REGION" --min=1 --max=3
# Inspeciona o scaling do serviço.
gcloud run services describe "$SERVICE" --region="$REGION" --format=yaml
# Altera a concurrency, gerando nova revisão.
gcloud run services update "$SERVICE" --region="$REGION" --concurrency=20
# Inspeciona as revisões e o valor efetivo da nova configuração.
gcloud run revisions list --service="$SERVICE" --region="$REGION"
gcloud run services describe "$SERVICE" --region="$REGION" --format=yaml
# Garante que v1 continue como revisão estável antes da falha controlada.
gcloud run services update-traffic "$SERVICE" --region="$REGION" --to-revisions="${REV1}=100"
# Retorna o mínimo a zero para evitar cobrança ociosa.
gcloud run services update "$SERVICE" --region="$REGION" --min=0 --max=3
```

**Observação:** o serviço pode criar uma **REV3** ao mudar concurrency. O rollback da seção anterior foi feito antes disso, para preservar a comparação inequívoca entre v1/v2. O ajuste de min=1 deve ser breve: há cobrança enquanto instâncias ficam aquecidas.

## 9. Falha controlada: porta incompatível

O Nginx da image escuta na porta **80**. Alterar somente a porta configurada do Cloud Run para **9999** provoca uma nova revisão incapaz de atender ao health/startup check esperado. Essa falha é realizada **sem tráfego para a revisão defeituosa**; mantenha v1 saudável atendendo o serviço.

```bash
# Tenta implantar a image v2 com porta incorreta e sem tráfego.
# A operação pode terminar com erro porque a revisão não fica Ready.
gcloud run deploy "$SERVICE" \
  --image="$IMAGE_V2" \
  --region="$REGION" \
  --port=9999 \
  --no-traffic || true
# Inspeciona a revisão mais recente e suas condições.
gcloud run services describe "$SERVICE" --region="$REGION" --format=yaml
# Lista revisões para identificar a que falhou.
gcloud run revisions list --service="$SERVICE" --region="$REGION"
# Consulta logs recentes do serviço para evidências de startup.
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=${SERVICE}" \
  --project="$PROJECT_ID" \
  --limit=20 \
  --format='table(timestamp,severity,textPayload)'
```

**Sintoma:** nova revisão não Ready. **Hipótese:** porta incompatível. **Evidência:** `--port=9999` e Nginx ouvindo 80, condições da revisão e logs. **Causa:** Cloud Run encaminha requisições/health check para porta 9999, enquanto o processo escuta em 80. **Correção:** restaurar a porta 80 em uma nova revisão.

```bash
# Corrige exclusivamente a porta e cria uma revisão válida sem tráfego.
gcloud run deploy "$SERVICE" \
  --image="$IMAGE_V2" \
  --region="$REGION" \
  --port=80 \
  --no-traffic
# Inspeciona a revisão corrigida.
gcloud run revisions list --service="$SERVICE" --region="$REGION"
# Confirma que a URL principal continua atendendo a revisão estável.
curl -fsS -H "Authorization: Bearer $(gcloud auth print-identity-token)" "$SERVICE_URL" | grep 'ACE Containers v1'
```

Se o deploy defeituoso não produzir revisão visível, use a saída de erro do próprio comando como evidência. **Não** conceda `allUsers` nem papéis IAM aleatórios para corrigir falha de porta.

## 10. Variáveis de ambiente e novas revisões

```bash
# Atualiza uma variável de ambiente; isto cria uma nova revisão.
gcloud run services update "$SERVICE" \
  --region="$REGION" \
  --update-env-vars="ENVIRONMENT=dev"
# Confere o novo histórico de revisões.
gcloud run revisions list --service="$SERVICE" --region="$REGION"
```

A variável **não altera o HTML estático** servido por Nginx; ela demonstra alteração de configuração. Para observar mudança na resposta, usamos images v1/v2 nas seções 5–7.

## 11. Troubleshooting adicional

| Sintoma | Evidência | Primeira investigação |
|---|---|---|
| `401` | HTTP não autenticado/token inválido | Identity token e audience |
| `403` | Identidade reconhecida sem invocação | `roles/run.invoker` e política |
| Revision não Ready | Condições e logs | Porta, processo, startup, recursos |
| `404`/resposta inesperada | URL e tráfego | Service URL, revisão e roteamento |
| `Permission denied` no deploy | Conta ativa e IAM | Cloud Run Developer/Admin e `actAs` |
| Image não encontrada | Nome completo no deploy | Artifact Registry, região, tag e IAM de pull |
| Latência/custo elevados | Métricas, min/max/concurrency | Dimensionamento e dependências |

## 12. Questões estilo ACE

1. É preciso executar um backend HTTP sem administrar VMs. **Cloud Run Services** é uma opção apropriada.
2. É necessário testar 10% de tráfego em nova versão. **Criar revisão e aplicar traffic splitting 90/10.**
3. Uma revisão nova apresentou erros. **Redirecionar 100% para revisão anterior**, sem reconstruir image.
4. É necessário reduzir cold starts. **Mínimo de instâncias maior que zero**, aceitando custo.
5. É preciso proteger um banco de excesso de conexões. **Combinar limites de instâncias/concurrency e controle de conexões**; max não é garantia absoluta.
6. Uma revisão falha no startup após configurar porta 9999, mas Nginx escuta 80. **Corrigir porta configurada**, não IAM.
7. A organização bloqueia `allUsers`. **Manter serviço autenticado e testar com identity token**.
8. Alterar `concurrency` ou variável de ambiente implica **nova revisão**; mudar mínimo no nível de serviço não necessariamente.

## 13. Cleanup e custos

**Importante:** a exclusão abaixo remove **somente o serviço Cloud Run deste laboratório**. Não apague o Artifact Registry se a Aula 1 ou outras aulas ainda precisarem das images.

```bash
# Inspeciona o serviço antes da exclusão.
gcloud run services describe "$SERVICE" --region="$REGION" --format='value(metadata.name)'
# Remove o serviço e suas revisões.
gcloud run services delete "$SERVICE" --region="$REGION" --quiet
# Confere que não está mais listado.
gcloud run services list --region="$REGION" --filter="metadata.name:$SERVICE"
# Remove apenas a pasta de build v2 criada nesta aula.
cd "$HOME"
rm -rf "$HOME/ace-cloud-run-v2"
# Opcional: remover a image v2 do Artifact Registry apenas após confirmar que não é usada.
# Preserve v1/v2 se continuar as próximas aulas.
```

## 14. Checklist

- [ ] Image v1 da Aula 1 disponível;
- [ ] Serviço implantado, listado, descrito e testado com token;
- [ ] Distingo Service, Revision, Instance e Request;
- [ ] Image v2 publicada e revisão v2 criada sem tráfego;
- [ ] Traffic split 90/10 inspecionado;
- [ ] Promoção 100% v2 e rollback 100% v1 testados;
- [ ] Min/max/concurrency configurados e inspecionados;
- [ ] Entendo custos de min=1 e limitações de max;
- [ ] Falha de porta diagnosticada e corrigida;
- [ ] Serviço excluído e cleanup verificado.

## 15. Matriz M/E/P

`M` mencionado; `E` explicado; `P` praticado com inspeção e teste; `P*` guiado/condicional.

| Conteúdo | Nível | Evidência |
|---|---|---|
| Modelo Cloud Run Service/Revision/Instance | E | Arquitetura e tabela |
| Deploy/describe/HTTP autenticado | P* | Teste depende de permissão invoker e emissão de token |
| Revisões v1/v2 | P | Deploy, list, describe, inspeção de tráfego |
| Canary/promoção/rollback | P* | CLI e HTTP; teste depende de invoker |
| Scaling min/max | P | Update + describe |
| Concurrency | P | Update + revisions list/describe |
| Falha de porta | P* | Depende da revisão defeituosa ser criada/visível |
| IAM e acesso público | E | Conceito, política e troubleshooting |
| Cleanup | P | Delete/list |

## 16. Referências oficiais

- [Implantar serviços](https://cloud.google.com/run/docs/deploying)
- [Gerenciar revisões](https://cloud.google.com/run/docs/managing/revisions)
- [Rollouts e rollback](https://cloud.google.com/run/docs/rollouts-rollbacks-traffic-migration)
- [Instâncias mínimas](https://cloud.google.com/run/docs/configuring/min-instances)
- [Instâncias máximas](https://cloud.google.com/run/docs/configuring/max-instances)
- [Concurrency](https://cloud.google.com/run/docs/about-concurrency)
- [Autenticação de desenvolvedores](https://cloud.google.com/run/docs/authenticating/developers)

**Commit sugerido:** `git commit -m "feat(cloud-run): adiciona revisoes canary rollback e scaling praticos"`
