# SoftEther Manager — Railway ready
# Multi-stage: build Next.js frontend, then run Python backend

FROM node:20-alpine AS web-builder
WORKDIR /web

# Copy package files first for better layer caching
COPY app/web/package.json ./
COPY app/web/package-lock.json* ./
RUN npm install

# Copy source and build
COPY app/web/ ./
RUN npm run build

# ── Final image ────────────────────────────────────────────────────────────
FROM python:3.12-slim
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code (explicit paths are more reliable on Railway)
COPY app ./app
COPY Library ./Library
COPY run.py .
COPY requirements.txt .

# Put the pre-built static files in the correct place
COPY --from=web-builder /web/out ./app/web/out

ENV SEM_DATA_DIR=/data
ENV SEM_BIND_HOST=0.0.0.0
ENV PYTHONUNBUFFERED=1

RUN mkdir -p /data && chmod 777 /data

EXPOSE 8000

CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
