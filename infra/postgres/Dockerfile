# PostgreSQL 16 + pgvector + pg_cron
# Base oficial Debian Bookworm (la imagen de postgres ya trae el repo pgdg configurado)
FROM postgres:16

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      postgresql-16-cron \
      postgresql-16-pgvector \
 && rm -rf /var/lib/apt/lists/*
