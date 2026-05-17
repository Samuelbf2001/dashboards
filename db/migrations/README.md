# Convención de Migraciones — GHL Analytics Platform

## Principio general

Los scripts en `db/init/` son la definición canónica del schema v1.0.0. Solo se ejecutan al **primer arranque** del contenedor PostgreSQL (volumen vacío). Cualquier cambio posterior al schema en un entorno ya desplegado requiere una migración explícita en este directorio.

---

## Numeración y formato de archivos

```
db/migrations/
├── README.md
├── V1.0.1__add_contact_score_index.sql
├── V1.0.2__add_ctwa_ad_id_column.sql
└── V1.1.0__new_dim_appointments.sql
```

Formato del nombre:

```
V<MAJOR>.<MINOR>.<PATCH>__<descripcion_en_snake_case>.sql
```

- `MAJOR`: cambio que rompe compatibilidad hacia atrás (añadir tabla requerida, eliminar columna).
- `MINOR`: cambio compatible hacia adelante (añadir columna nullable, nuevo índice).
- `PATCH`: corrección de datos o ajuste sin impacto en schema.
- La descripción debe ser breve e imperativa: `add_index`, `rename_column`, `backfill_utm`.

---

## Estructura de cada archivo de migración

```sql
-- ─── Migración V1.0.1 ─────────────────────────────────────────────────────
-- Fecha: 2026-05-16
-- Autor: nombre o alias
-- Descripción: Breve descripción del cambio y la motivación.
-- Rollback: instrucción de rollback al final del archivo.
-- ─────────────────────────────────────────────────────────────────────────────

BEGIN;

-- ─── UP (aplicar) ──────────────────────────────────────────────────────────
-- (SQL de la migración)

COMMIT;

-- ─── ROLLBACK (revertir) ───────────────────────────────────────────────────
-- Instrucción SQL para deshacer el cambio si la migración falla o se revierte.
-- ROLLBACK no se ejecuta automáticamente — es documentación para el operador.
-- Ejemplo:
--   DROP INDEX IF EXISTS idx_nuevo;
--   ALTER TABLE dim_contacts DROP COLUMN IF EXISTS nueva_columna;
```

---

## Reglas de escritura

1. **Siempre usar `IF NOT EXISTS` / `IF EXISTS`** en CREATE/DROP para hacer las migraciones idempotentes.
2. **Nunca eliminar columnas de dimensiones SCD2** sin antes garantizar que ningún workflow o dashboard depende de ellas.
3. **Añadir columnas siempre como nullable** (`DEFAULT NULL`) para no bloquear tablas grandes.
4. **Los índices sobre tablas grandes** deben crearse con `CREATE INDEX CONCURRENTLY` para no bloquear escrituras.
5. **Documentar el rollback** al final de cada archivo aunque no se use de forma automática.

---

## Ejecución de migraciones

Las migraciones **no se aplican automáticamente** — deben ejecutarse manualmente por el operador o con una herramienta como Flyway o Liquibase.

```bash
# Aplicar una migración manualmente:
psql -h localhost -U sixteam_admin -d ghl_analytics \
  -f db/migrations/V1.0.1__add_contact_score_index.sql

# Verificar que la migración se aplicó:
# (mantener una tabla migration_log manualmente o usar herramienta)
psql -h localhost -U sixteam_admin -d ghl_analytics \
  -c "SELECT * FROM migration_log ORDER BY applied_at DESC LIMIT 5;"
```

---

## Tabla de registro (recomendado)

Crear esta tabla para llevar un log de migraciones aplicadas:

```sql
CREATE TABLE IF NOT EXISTS migration_log (
  version     VARCHAR(20)  PRIMARY KEY,
  description TEXT,
  applied_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  applied_by  TEXT
);
```

Insertar al final de cada migración:

```sql
INSERT INTO migration_log (version, description, applied_by)
VALUES ('V1.0.1', 'Add contact score index', 'operator_name');
```

---

## Compatibilidad con Agente 2 (n8n) y Agente 3 (Metabase)

- Cualquier **renombrado de columna** requiere actualizar:
  - Los workflows JSON en `n8n/workflows/` (Agente 2)
  - Los SQL de queries en `metabase/queries/` (Agente 3)
- Cualquier **nueva tabla** requiere:
  - ENABLE ROW LEVEL SECURITY + políticas en todas las filas existentes de `client_provision_template.sql`
  - GRANT SELECT al rol `client_loc_<slug>` de todos los clientes activos
- Los cambios al contrato de `mv_unified_attribution` deben coordinarse con Agente 3 (dashboards que la consumen).
