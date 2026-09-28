# =========================
# Stage 1: Build dependencies
# =========================
FROM python:3.9-slim AS builder

WORKDIR /app

COPY requirements.txt .

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       gcc \
       default-libmysqlclient-dev \
       pkg-config \
    && rm -rf /var/lib/apt/lists/* \
    && pip install --no-cache-dir --prefix=/install mysqlclient \
    && pip install --no-cache-dir --prefix=/install -r requirements.txt


# =========================
# Stage 2: Runtime
# =========================
FROM python:3.9-slim

WORKDIR /app/backend

RUN apt-get update \
    && apt-get install -y --no-install-recommends default-libmysqlclient-dev \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /install /usr/local

COPY . /app/backend

EXPOSE 8000

CMD ["python3", "manage.py", "runserver", "0.0.0.0:8000"]
