# Como disparar o build (e o que falta para testar)

## Por que o build NÃO foi feito localmente
- VM do Muse em 2026-10-31: 7,7 GB de RAM total, ~225 MB livres,
  ~455 MB disponíveis, 4 CPUs, sem swap. O build do TDLib + bot-api
  precisa de vários GB por job de compilação e costuma estourar 8 GB com
  `-j$(nproc)`. Tentar aqui arriscaria OOM e interrupção de outro trabalho.
- Conclusão: build local **inviável nesta VM**; o caminho é o GitHub Actions,
  pronto em `.github/workflows/build-botapi.yml`.

## Passo 1 — Publicar este conteúdo num fork
1. Criar um fork de `tdlib/telegram-bot-api` no GitHub (conta do usuário).
2. Subir este diretório para o fork, incluindo:
   - `telegram-bot-api/HttpServer.h` patchado (7200)
   - `.github/workflows/build-botapi.yml`
   - `Dockerfile` e `docker-entrypoint.sh`
   - `PATCH_NOTES.md` e este `BUILD.md`
3. Conferir no GitHub que o arquivo `telegram-bot-api/HttpServer.h` do fork
   contém `IDLE_TIMEOUT = 7200` (o próprio workflow faz esse grep e falha
   se o patch não estiver lá).

## Passo 2 — Disparar o Actions
1. No fork, abrir Actions > "Build telegram-bot-api (idle-timeout 7200s)".
2. Clicar em "Run workflow" (é `workflow_dispatch`, manual — nada roda
   sozinho em push, e nada é publicado em registry público).
3. Aguardar os dois jobs:
   - `build-binary`: produz o artefato `telegram-bot-api-idle7200-binary`
     (binário Linux x86_64, Release).
   - `build-docker-image`: produz o artefato
     `telegram-bot-api-idle7200-image` (tarball `telegram-bot-api-idle7200.tar`).
4. Baixar os artefatos na máquina que vai testar (a vault, na hora do teste).

## Passo 3 — Teste isolado na vault (AINDA NÃO FEITO, precisa de aprovação)
Pré-requisitos antes de qualquer teste (não executados neste trabalho):
- Uploads de produção pausados e nenhum upload em voo (janela já existe
  hoje, mas deve ser reconfirmada na hora).
- Container de produção (`telegram-bot-api-oraclevm`) **mantido intacto**,
  sem parar nem substituir.
- Teste em **outra porta** (ex.: 8082, que já é exposta pelo container
  atual mas não usada pelo CBR), com **diretório de trabalho separado**
  (ex.: `~/projects/telegram-bot-api-test`, vazio) e **sem montar a mídia
  de produção** para leitura de teste — ou, se o teste for com arquivo
  real, com um arquivo de teste próprio, nunca um arquivo da fila, para
  não duplicar envio.
- **Não usar os mesmos tokens de produção ao mesmo tempo que a produção.**
  Duas instâncias bot-api com o mesmo token e sessões diferentes podem
  conflitar. Opções, a decidir com o usuário na hora do teste:
  (a) testar só `--version` e resposta HTTP 404 na porta de teste, sem
      nenhum token (prova que o binário novo sobe, sem risco de sessão);
  (b) teste com `sendVideo` real usando um bot/token de teste separado,
      nunca os 6 bots de produção;
  (c) só após a fila de produção zerar e os bots de produção serem
      pausados, trocar temporariamente a porta 8081 para o container novo
      e medir um upload real — com rollback imediato para o container
      antigo, que está preservado parado.
- Verificação do teste: `--version` deve continuar reportando Bot API 10.3,
  e um upload lento simulado (ou real, no caso (c)) deve passar de 500s
  sem `code 52`.

## Artefatos finais
- Binário: `telegram-bot-api` (a partir do artefato `telegram-bot-api-idle7200-binary`)
- Imagem: `telegram-bot-api-idle7200:latest` (a partir do tarball,
  carregada com `docker load -i telegram-bot-api-idle7200.tar`)

## Verificação de segredos (executada localmente)
- Grep por padrões de token/bot e por `TELEGRAM_API_ID=` / `TELEGRAM_API_HASH=`
  com valor em todos os arquivos novos: nenhum valor encontrado — os
  arquivos citam apenas os NOMES das variáveis, nunca valores.
- O `docker-entrypoint.sh` lê as variáveis do ambiente de runtime e não
  define nenhum padrão com valor.
