# syntax=docker/dockerfile:1
# ---------------------------------------------------------------------------
# Hybrid Recommendation Engine — backend image
#
# Build:
#   docker build -t hybrid-recsys-backend .
#   # Smaller image without PyTorch (no deep learning models):
#   docker build -t hybrid-recsys-backend --build-arg REQUIREMENTS_FILE=requirements-minimal.txt .
#
# Run:
#   docker run -p 8000:8000 hybrid-recsys-backend
# ---------------------------------------------------------------------------
FROM python:3.11-slim AS base

ARG REQUIREMENTS_FILE=requirements.txt
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

# System deps needed for scientific Python wheels + healthcheck curl
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential curl \
    && rm -rf /var/lib/apt/lists/*

COPY ${REQUIREMENTS_FILE} requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Create a non-root user
RUN useradd --create-home --shell /bin/bash appuser

COPY recsys/ recsys/
COPY backend/ backend/
COPY scripts/ scripts/
COPY data/raw/.gitkeep data/raw/.gitkeep

RUN chown -R appuser:appuser /app
USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

CMD ["uvicorn", "backend.app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]
