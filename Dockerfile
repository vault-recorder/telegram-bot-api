# Dockerfile para o telegram-bot-api oficial com IDLE_TIMEOUT = 7200s.
# Uso: apenas pelo workflow do GitHub Actions (build-botapi.yml) ou por
# `docker build -t telegram-bot-api-idle7200:latest .` numa máquina com RAM
# suficiente. NÃO contém api_id, api_hash ou token: essas variáveis são
# passadas em runtime, no `docker run` da vault, exatamente como hoje.
# O entrypoint reproduz o comportamento do aiogram/telegram-bot-api:
# lê TELEGRAM_API_ID, TELEGRAM_API_HASH, TELEGRAM_LOCAL, TELEGRAM_WORK_DIR
# e TELEGRAM_TEMP_DIR do ambiente e os repassa como argumentos.

FROM ubuntu:24.04 AS builder
RUN apt-get update && apt-get install -y \
    make git zlib1g-dev libssl-dev gperf cmake g++ \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /src
COPY . /src
RUN mkdir build && cd build \
    && cmake -DCMAKE_BUILD_TYPE=Release .. \
    && cmake --build . --target telegram-bot-api -j"$(nproc)"

FROM ubuntu:24.04
RUN apt-get update && apt-get install -y libssl3 zlib1g ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m -s /bin/false telegram-bot-api || true
COPY --from=builder /src/build/telegram-bot-api /usr/local/bin/telegram-bot-api
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
EXPOSE 8081 8082
ENTRYPOINT ["/docker-entrypoint.sh"]
