/**
 * scd2.js — Logica SCD Tipo 2 para dim_contacts y dim_opportunities
 * Referencia: GHL_Database.txt seccion "Logica SCD Tipo 2 — Code node de n8n"
 *
 * IMPORTANTE: Este archivo se versiona en el repositorio pero su contenido
 * debe pegarse directamente dentro del Code node en n8n.
 * La funcion recibe un pgClient del nodo PostgreSQL configurado en n8n.
 *
 * Patron:
 *   1. Buscar version activa por (entity_id, is_current=TRUE)
 *   2. Si no existe → INSERT nueva version (primera vez)
 *   3. Si existe y cambia campo rastreado → SCD_UPDATE: cerrar version anterior + INSERT nueva
 *   4. Si existe sin cambios en campos rastreados → UPDATE_MINOR: actualizar solo synced_at y no-rastreados
 */

// ============================================================
// Configuracion de campos rastreados por tabla
// ============================================================

const TRACKED_FIELDS_CONTACTS = [
  'email', 'phone', 'source',
  'utm_source_first', 'utm_campaign_first'
];

const TRACKED_FIELDS_OPPORTUNITIES = [
  'pipeline_stage_id', 'status', 'monetary_value',
  'assigned_to_user_id', 'pipeline_id'
];

// ============================================================
// applySCD2
// ============================================================

/**
 * Aplica la logica SCD Tipo 2 para una entidad.
 *
 * @param {object} params
 * @param {string}   params.table         - Nombre de la tabla (dim_contacts | dim_opportunities)
 * @param {string}   params.idColumn      - Nombre de la columna ID natural (contact_id | opportunity_id)
 * @param {string[]} params.trackedFields - Campos que disparan nueva version
 * @param {object}   params.incoming      - Registro sanitizado entrante
 * @param {object}   params.pgClient      - Referencia al nodo PostgreSQL de n8n (usa $node["Postgres"].executeQuery)
 *
 * @returns {Promise<{action: string, result: object}>}
 *   action: 'INSERT' | 'SCD_UPDATE' | 'UPDATE_MINOR'
 */
async function applySCD2({ table, idColumn, trackedFields, incoming, pgClient }) {
  const now = new Date().toISOString();
  const entityId = incoming[idColumn];

  if (!entityId) {
    throw new Error('applySCD2: ' + idColumn + ' no puede ser nulo');
  }

  // --- Paso 1: Buscar version activa ---
  const selectSQL = `
    SELECT * FROM ${table}
    WHERE ${idColumn} = $1 AND is_current = TRUE
    LIMIT 1
  `;
  const existing = await pgClient.executeQuery(selectSQL, [entityId]);
  const prev = existing.rows && existing.rows.length > 0 ? existing.rows[0] : null;

  // --- Paso 2: Primera vez → INSERT ---
  if (!prev) {
    const record = Object.assign({}, incoming, {
      valid_from: now,
      valid_to:   null,
      is_current: true,
      change_reason: 'initial_insert',
      synced_at: now
    });
    await insertRecord(table, record, pgClient);
    return { action: 'INSERT', record };
  }

  // --- Paso 3: Detectar cambios en campos rastreados ---
  const changedFields = trackedFields.filter(f => {
    const prevVal     = prev[f] === undefined ? null : prev[f];
    const incomingVal = incoming[f] === undefined ? null : incoming[f];
    // Comparacion de strings con null-safety
    return String(prevVal) !== String(incomingVal);
  });

  if (changedFields.length > 0) {
    // --- SCD_UPDATE: cerrar version anterior y abrir nueva ---
    const change_reason = changedFields.map(f => f + '_change').join(', ');

    // Cerrar version anterior
    const closeSQL = `
      UPDATE ${table}
      SET valid_to    = $1,
          is_current  = FALSE
      WHERE surrogate_key = $2
    `;
    await pgClient.executeQuery(closeSQL, [now, prev.surrogate_key]);

    // Insertar nueva version
    const newRecord = Object.assign({}, incoming, {
      valid_from:    now,
      valid_to:      null,
      is_current:    true,
      change_reason,
      synced_at:     now
    });
    await insertRecord(table, newRecord, pgClient);

    return { action: 'SCD_UPDATE', changedFields, record: newRecord };
  }

  // --- Paso 4: Sin cambios en rastreados → UPDATE_MINOR ---
  // Actualizar solo synced_at y campos no rastreados (tags, custom_fields, etc.)
  const minorUpdateSQL = `
    UPDATE ${table}
    SET synced_at       = $1,
        ghl_updated_at  = $2,
        tags            = $3,
        custom_fields   = $4
    WHERE surrogate_key = $5
  `;
  await pgClient.executeQuery(minorUpdateSQL, [
    now,
    incoming.ghl_updated_at || now,
    incoming.tags        || prev.tags,
    incoming.custom_fields ? JSON.stringify(incoming.custom_fields) : prev.custom_fields,
    prev.surrogate_key
  ]);

  return { action: 'UPDATE_MINOR', surrogate_key: prev.surrogate_key };
}

// ============================================================
// Helpers internos
// ============================================================

/**
 * Construye y ejecuta un INSERT dinamico para la tabla indicada.
 * SIEMPRE usa queries parametrizadas — sin interpolacion de strings en valores.
 * Los nombres de columnas se derivan del objeto record (que ya paso por sanitize).
 */
async function insertRecord(table, record, pgClient) {
  // Filtrar columnas: excluir surrogate_key (BIGSERIAL auto)
  const columns = Object.keys(record).filter(k => k !== 'surrogate_key');
  const values  = columns.map(k => record[k]);
  const placeholders = columns.map((_, i) => '$' + (i + 1)).join(', ');
  const colList = columns.join(', ');

  // Tabla y columnas son literales controlados por codigo, no por input externo
  const insertSQL = `INSERT INTO ${table} (${colList}) VALUES (${placeholders})`;
  await pgClient.executeQuery(insertSQL, values);
}

// ============================================================
// Wrappers de conveniencia por entidad
// ============================================================

/**
 * Aplica SCD2 a dim_contacts.
 * @param {object} incoming - contacto sanitizado
 * @param {object} pgClient
 */
async function applySCD2Contact(incoming, pgClient) {
  return applySCD2({
    table:         'dim_contacts',
    idColumn:      'contact_id',
    trackedFields: TRACKED_FIELDS_CONTACTS,
    incoming,
    pgClient
  });
}

/**
 * Aplica SCD2 a dim_opportunities.
 * @param {object} incoming - oportunidad sanitizada
 * @param {object} pgClient
 */
async function applySCD2Opportunity(incoming, pgClient) {
  return applySCD2({
    table:         'dim_opportunities',
    idColumn:      'opportunity_id',
    trackedFields: TRACKED_FIELDS_OPPORTUNITIES,
    incoming,
    pgClient
  });
}

// ============================================================
// Exportar
// ============================================================
module.exports = {
  applySCD2,
  applySCD2Contact,
  applySCD2Opportunity,
  TRACKED_FIELDS_CONTACTS,
  TRACKED_FIELDS_OPPORTUNITIES
};
