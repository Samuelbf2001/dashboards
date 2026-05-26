# GHL Analytics Platform

Plataforma self-hosted de inteligencia de datos para Sixteam. Centraliza GoHighLevel,
Meta CTWA y ESP en un warehouse PostgreSQL con dashboards Metabase, desplegada en
EasyPanel sobre VPS Hostinger.

Para el plan de implementacion completo ver: [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md)

---

## Quick Start (5 pasos)

```bash
# 1. Copiar y editar variables de entorno (rellenar todos los valores reales)
cp .env.example .env
nano .env   # o el editor de tu preferencia

# 2. Validar .env y generar cors.yml con dominios reales (REQUERIDO antes del deploy)
bash setup.sh

# 3. Levantar el stack completo
docker compose up -d

# 4. Importar los 14 workflows a n8n (con el stack levantado)
bash scripts/import_n8n_workflows.sh

# 5. Validar que todo esta funcionando
bash tests/run_all.sh --skip-non-blocking
```

`setup.sh` valida que todas las variables requeridas estén configuradas y genera
`infra/traefik/dynamic/cors.yml` con los dominios reales (Traefik no interpola
variables de entorno en archivos de configuración dinámica).

Tiempo estimado para el stack completo: 5-10 minutos (Metabase tarda en inicializar).

---

## Stack tecnologico

| Componente | Version | Puerto |
|---|---|---|
| PostgreSQL | 16-alpine | 5432 (interno) |
| n8n | 1.x | https://n8n.DOMAIN |
| Metabase OSS | 0.51.x | https://analytics.DOMAIN |
| Traefik | 3.x | 80/443 |
| Uptime Kuma | latest | https://kuma.DOMAIN |

---

## Documentacion operativa

| Documento | Descripcion |
|---|---|
| [docs/DEPLOYMENT_RUNBOOK.md](docs/DEPLOYMENT_RUNBOOK.md) | Despliegue desde cero hasta go-live |
| [docs/OPERATIONS_GUIDE.md](docs/OPERATIONS_GUIDE.md) | Operacion dia a dia, logs, backups, escalado |
| [docs/CLIENT_ONBOARDING.md](docs/CLIENT_ONBOARDING.md) | Agregar un nuevo cliente a la plataforma |
| [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Diagnostico de problemas comunes |

---

## Estructura del repositorio

```
ghl-analytics-platform/
├── README.md
├── IMPLEMENTATION_PLAN.md
├── .env.example
├── infra/              # Docker compose, Traefik config
├── db/                 # Schema SQL, RLS, indices, vista materializada
├── n8n/                # 12 workflows JSON versionados
├── metabase/           # Definiciones de 6 dashboards + SQL de KPIs
├── tests/              # Suite de QA ejecutable (30 tests)
└── docs/               # Documentacion operativa
```

---

## Tests de aceptacion

```bash
# Correr todos los tests
cd tests && ./run_all.sh

# Solo tests bloqueantes
./run_all.sh --skip-non-blocking

# Por categoria
./run_all.sh infra
./run_all.sh security
./run_all.sh etl
```

El sistema esta listo para produccion cuando todos los tests BLOQUEANTES pasan.
Ver [tests/README.md](tests/README.md) para configuracion detallada.

---

## Seguridad

- Row Level Security (RLS) en PostgreSQL: cada cliente ve solo sus datos
- Webhooks validados via HMAC SHA-256
- CORS estricto via Traefik middleware
- Rate limiting: 500 req/10s (webhooks), 120 req/min (Metabase)
- Embeddings firmados con JWT para portales de cliente
- Variables sensibles en EasyPanel Secret Manager (nunca en codigo)
