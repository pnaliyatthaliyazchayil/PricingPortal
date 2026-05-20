# ── PricePortal — Streamlit portal Docker image ──────────────────────────────
# Builds a self-contained image that runs the Streamlit app on port 8501.
# Data files are baked in from the repo's data/ folder (populated by
# the sync_zenodo GitHub Actions workflow).
#
# Usage:
#   docker build -t priceportal .
#   docker run -p 8501:8501 priceportal
#   open http://localhost:8501

FROM python:3.11-slim

# ── System dependencies ───────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        curl \
    && rm -rf /var/lib/apt/lists/*

# ── Working directory ─────────────────────────────────────────────────────────
WORKDIR /app

# ── Python dependencies ───────────────────────────────────────────────────────
# Copy requirements first so Docker caches this layer
COPY requirements.txt .
RUN pip install --no-cache-dir \
        "streamlit>=1.32" \
        "duckdb>=0.10" \
        "pandas>=2.2,<2.3" \
        "plotly>=5.18" \
        "pyarrow" \
        "pydeck"

# ── Application code ──────────────────────────────────────────────────────────
COPY app.py .
COPY views/ views/
COPY data/ data/

# ── Streamlit config ──────────────────────────────────────────────────────────
RUN mkdir -p /app/.streamlit
RUN echo '\
[server]\n\
headless = true\n\
port = 8501\n\
address = "0.0.0.0"\n\
enableCORS = false\n\
enableXsrfProtection = false\n\
\n\
[browser]\n\
gatherUsageStats = false\n\
' > /app/.streamlit/config.toml

# ── Expose port ───────────────────────────────────────────────────────────────
EXPOSE 8501

# ── Health check ─────────────────────────────────────────────────────────────
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8501/_stcore/health || exit 1

# ── Entrypoint ────────────────────────────────────────────────────────────────
CMD ["streamlit", "run", "app.py", "--server.port=8501", "--server.address=0.0.0.0"]
