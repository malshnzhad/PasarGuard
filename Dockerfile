ARG PYTHON_VERSION=3.14

FROM ghcr.io/astral-sh/uv:python$PYTHON_VERSION-bookworm-slim AS builder
ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    python3-dev \
    libc6-dev \
    && rm -rf /var/lib/apt/lists/*

ENV UV_PYTHON_DOWNLOADS=0

WORKDIR /build
RUN COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-install-project --no-dev
ADD . /build
RUN RUN uv sync --frozen --no-dev

FROM python:$PYTHON_VERSION-slim-bookworm

COPY --from=builder /build /code
WORKDIR /code

ENV PATH="/code/.venv/bin:$PATH"

# Install curl for health checks
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY cli_wrapper.sh /usr/bin/pasarguard-cli
RUN chmod +x /usr/bin/pasarguard-cli

COPY tui_wrapper.sh /usr/bin/pasarguard-tui
RUN chmod +x /usr/bin/pasarguard-tui

# Copy healthcheck script
COPY healthcheck.sh /code/healthcheck.sh
RUN chmod +x /code/healthcheck.sh

RUN chmod +x /code/start.sh

ENTRYPOINT ["/code/start.sh"]
RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

COPY start-railway.sh /start-railway.sh
RUN chmod +x /start-railway.sh /code/start.sh

# این خط به Railway می‌گوید پنل روی کدام پورت گوش می‌دهد تا موقع ساخت
# دامنه، پورت درست را خودش به‌صورت خودکار تشخیص دهد.
EXPOSE 8000

ENTRYPOINT ["/start-railway.sh"]
