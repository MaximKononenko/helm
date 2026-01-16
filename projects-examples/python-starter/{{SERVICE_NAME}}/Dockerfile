# {{PROJECT_NAME}} - Python {{PYTHON_VERSION}}
#
# Multi-stage build for production
# Stage 1: Build dependencies
# Stage 2: Production image

# Build stage
FROM catalina.azurecr.io/python:{{PYTHON_VERSION}}-slim as builder

WORKDIR /build

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Create virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Production stage
FROM catalina.azurecr.io/python:{{PYTHON_VERSION}}-slim as production

# Labels
LABEL maintainer="{{OWNER}}"
LABEL service="{{PROJECT_NAME}}"
LABEL version="1.0.0"

WORKDIR /app

# Copy virtual environment from builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy application code
COPY src/ ./

# Create non-root user
RUN useradd -m -u 1000 -s /bin/bash appuser && \
    chown -R appuser:appuser /app

USER appuser

# Expose port
EXPOSE {{PORT}}

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:{{PORT}}/health')" || exit 1

# Run with uvicorn
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "{{PORT}}"]
