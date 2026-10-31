#!/bin/sh
# Entrypoint compatível com aiogram/telegram-bot-api.
# Variáveis lidas SOMENTE do ambiente de runtime (docker run -e ...).
# Nenhum valor padrão de api_id/api_hash/token existe neste arquivo.
set -e
ARGS="--http-port=${TELEGRAM_HTTP_PORT:-8081}"
if [ -n "$TELEGRAM_WORK_DIR" ]; then
  ARGS="$ARGS --dir=$TELEGRAM_WORK_DIR"
fi
if [ -n "$TELEGRAM_TEMP_DIR" ]; then
  ARGS="$ARGS --temp-dir=$TELEGRAM_TEMP_DIR"
fi
if [ "$TELEGRAM_LOCAL" = "1" ]; then
  ARGS="$ARGS --local"
fi
if [ -n "$TELEGRAM_API_ID" ]; then
  ARGS="$ARGS --api-id=$TELEGRAM_API_ID"
fi
if [ -n "$TELEGRAM_API_HASH" ]; then
  ARGS="$ARGS --api-hash=$TELEGRAM_API_HASH"
fi
# shellcheck disable=SC2086
exec /usr/local/bin/telegram-bot-api $ARGS
