# Patch: idle-timeout 500s -> 7200s

## Repositório e versão
- Origem: https://github.com/tdlib/telegram-bot-api (clone em 2026-10-31)
- Commit base: `e3e9dd8e5b3d7ab8537cd5a10dc31d5ffa8f82d1` ("Fix RichBlockDocument.")
- Versão declarada no código: Bot API **10.3**
  - `telegram-bot-api/telegram-bot-api.cpp:168`: `parameters->version_ = "10.3";`
  - `CMakeLists.txt`: `project(TelegramBotApi VERSION 10.3 ...)`
  - Confere com a versão que a vault reporta hoje (`--version` => Bot API 10.3).
- O repositório upstream **não tem tags** e **não tem `.github/workflows`**;
  o workflow deste trabalho foi criado do zero (ver `BUILD.md`).

## Patch aplicado (1 linha)
- Arquivo: `telegram-bot-api/HttpServer.h`
- Linha: **47**
- Antes: `static constexpr td::int32 IDLE_TIMEOUT = 500;`
- Depois: `static constexpr td::int32 IDLE_TIMEOUT = 7200;`
- Uso: linha 71 do mesmo arquivo passa `IDLE_TIMEOUT` para
  `td::HttpInboundConnection` (classe do submódulo `td`/TDLib, que é onde a
  conexão HTTP fica ociosa esperando a resposta do upload). É esse valor que
  fecha a conexão HTTP após 500s sem tráfego de resposta, gerando no CBR o
  `HTTP 0 / code 52`, mesmo com o upload MTProto continuando em background.

```diff
-  static constexpr td::int32 IDLE_TIMEOUT = 500;
+  static constexpr td::int32 IDLE_TIMEOUT = 7200;
```

## Por que 7200, e não 3600
- O curl do CBR tem timeout próprio de 3600s por arquivo.
- Um arquivo de 1,95 GB a 0,5 MB/s leva ~4000s; a 6,5 MB/s leva ~300s.
- 7200s cobre os dois casos (upload lento antigo e timeout do CBR) sem
  deixar a conexão aberta indefinidamente (não usamos 0/infinito).

## Outros timeouts verificados e NÃO alterados
- `Client.h:1732` `LONG_POLL_MAX_TIMEOUT = 50` — é de `getUpdates`, não de upload.
- `WebhookActor.h` `WEBHOOK_MAX_RESEND_TIMEOUT = 60`, `WEBHOOK_DROP_TIMEOUT`
  — são de webhook, não de `sendVideo`.
- `ClientManager.h:81` `WATCHDOG_TIMEOUT = 0.25`, `ClientManager.cpp:380`
  `set_timeout_in(600.0)` — é o watchdog interno, não o timeout HTTP.
- Alterar qualquer um desses mudaria comportamento fora do problema; por
  isso o patch é só o `IDLE_TIMEOUT`.

## O que NÃO está neste trabalho
- Nenhum token, `api_id`, `api_hash` ou segredo em nenhum arquivo aqui.
  Grep de verificação está em `BUILD.md`.
- Nenhum acesso à vault, nenhuma troca de container, nenhum envio de arquivo.
- O submódulo `td/` **não** foi baixado localmente (está vazio neste clone);
  ele é buscado pelo GitHub Actions no build (`submodules: recursive`).
  Sem ele, nem a compilação de teste local é possível — o que reforça que o
  build deve rodar no Actions, não na VM do Muse.
