# =============================================================================
# AI Agent Code Modernizer — Multi-stage Docker build with uv
# Optimized for Azure Container Apps deployment
# =============================================================================

# ---------------------------------------------------------------------------
# Stage 1: Builder — install dependencies and prepare the virtualenv
# ---------------------------------------------------------------------------
FROM python:3.13-slim AS builder

COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy

WORKDIR /app

# Copy dependency manifests first to leverage Docker layer cache
COPY pyproject.toml uv.lock ./

# Install production dependencies only (no dev extras)
RUN uv sync --frozen --no-dev --no-install-project

# Copy the application source code
COPY . .

# Sync again to install the project itself
RUN uv sync --frozen --no-dev

# ---------------------------------------------------------------------------
# Stage 2: Runtime — minimal image for production
# ---------------------------------------------------------------------------
FROM python:3.13-slim AS runtime

# Install curl for healthcheck
RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

WORKDIR /app

# Copy the virtualenv and source from builder
COPY --from=builder /app /app

# Create non-root user for security
RUN groupadd --gid 1000 appuser \
    && useradd --uid 1000 --gid appuser --shell /bin/bash --create-home appuser \
    && chown -R appuser:appuser /app

USER appuser

# Runtime environment
ENV PYTHONUNBUFFERED=1 \
    AGENT_SERVER_PORT=8088 \
    PATH="/app/.venv/bin:$PATH"

EXPOSE 8088

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl --fail http://localhost:8088/liveness || exit 1

# Labels (OCI)
LABEL org.opencontainers.image.title="AI Agent Code Modernizer" \
      org.opencontainers.image.description="Modernizes Semantic Kernel and AutoGen code to Microsoft Agent Framework" \
      org.opencontainers.image.source="https://github.com/jesussan/tech-connect-2026-sk-modernizer"

# Start in HTTP server mode (default) on port 8088
CMD ["uv", "run", "python", "main.py", "--port", "8088"]
