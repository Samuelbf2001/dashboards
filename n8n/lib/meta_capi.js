/**
 * meta_capi.js — Envio de conversion events a Meta Conversions API (CAPI)
 * Referencia: GHL_Database.txt fact_ctwa_clicks (capi_sent_at, capi_event_id, capi_payload)
 *
 * IMPORTANTE: Este archivo se versiona en el repositorio pero su contenido
 * debe pegarse directamente dentro del Code node en n8n.
 *
 * Meta CAPI endpoint: POST https://graph.facebook.com/v18.0/{pixel_id}/events
 *
 * El event_id es deterministico (hash de ctwa_clid + event_name) para que Meta
 * deduplique si el evento llega dos veces (ej: browser pixel + server CAPI).
 */

const crypto = require('crypto');

// ============================================================
// sendConversionToMeta
// ============================================================

/**
 * Envia un evento de conversion a Meta Conversions API.
 *
 * @param {object} params
 * @param {string}  params.pixelId       - ID del pixel de Meta (META_PIXEL_ID)
 * @param {string}  params.accessToken   - Token de acceso META_CLOUD_API_TOKEN
 * @param {string}  params.ctwa_clid     - Click ID de CTWA — requerido para atribucion
 * @param {string}  params.phone         - Telefono del usuario en E.164 (para match con Meta)
 * @param {number}  params.value         - Valor monetario de la conversion
 * @param {string}  params.currency      - Moneda ISO 4217 (ej: 'COP', 'USD')
 * @param {number}  params.event_time    - Unix timestamp del evento (segundos)
 * @param {string}  [params.event_name]  - Nombre del evento (default: 'Purchase')
 * @param {string}  [params.email]       - Email del usuario (hashed con SHA256 por Meta)
 *
 * @returns {Promise<{event_id: string, response: object, payload: object}>}
 */
async function sendConversionToMeta({
  pixelId,
  accessToken,
  ctwa_clid,
  phone,
  value,
  currency,
  event_time,
  event_name = 'Purchase',
  email = null
}) {
  if (!pixelId)     throw new Error('meta_capi: pixelId requerido');
  if (!accessToken) throw new Error('meta_capi: accessToken requerido');
  if (!ctwa_clid)   throw new Error('meta_capi: ctwa_clid requerido para atribucion CTWA');

  // Event ID deterministico: SHA256 de ctwa_clid + event_name
  // Esto permite deduplicacion en Meta si el evento se envia dos veces
  const event_id = crypto
    .createHash('sha256')
    .update(ctwa_clid + event_name)
    .digest('hex');

  // Hash PII con SHA256 (requerido por Meta CAPI)
  const hashPhone = phone
    ? crypto.createHash('sha256').update(phone.replace(/\s/g, '')).digest('hex')
    : undefined;
  const hashEmail = email
    ? crypto.createHash('sha256').update(email.toLowerCase().trim()).digest('hex')
    : undefined;

  // Construir objeto user_data
  const user_data = {
    ctwa_clid  // campo principal para atribucion CTWA
  };
  if (hashPhone) user_data.ph = [hashPhone];
  if (hashEmail) user_data.em = [hashEmail];

  // Payload CAPI
  const payload = {
    data: [
      {
        event_name,
        event_time: event_time || Math.floor(Date.now() / 1000),
        event_id,
        action_source: 'business_messaging',
        messaging_channel: 'whatsapp',
        user_data,
        custom_data: {
          value: value || 0,
          currency: currency || 'COP'
        }
      }
    ]
  };

  // Llamada HTTP a Meta Graph API v18.0
  const url = `https://graph.facebook.com/v18.0/${pixelId}/events?access_token=${encodeURIComponent(accessToken)}`;

  let response;
  try {
    const httpResponse = await fetch(url, {
      method:  'POST',
      headers: { 'Content-Type': 'application/json' },
      body:    JSON.stringify(payload)
    });
    response = await httpResponse.json();

    if (!httpResponse.ok) {
      throw new Error('Meta CAPI error HTTP ' + httpResponse.status + ': ' + JSON.stringify(response));
    }
  } catch (err) {
    throw new Error('meta_capi: fallo al llamar Meta CAPI — ' + err.message);
  }

  return {
    event_id,
    response,
    payload
  };
}

// ============================================================
// Exportar
// ============================================================
module.exports = {
  sendConversionToMeta
};
