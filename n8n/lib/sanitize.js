/**
 * sanitize.js — Libreria de sanitizacion de inputs para n8n Code nodes
 * Referencia: GHL_Platform.txt seccion 5.4
 *
 * IMPORTANTE: Este archivo se versiona en el repositorio pero su contenido
 * debe pegarse directamente dentro del Code node en n8n (no hay require() en n8n sandbox).
 * Copiar las funciones necesarias al inicio del Code node antes de usarlas.
 */

// ============================================================
// Constantes de validacion
// ============================================================

const REGEX_GHL_ID       = /^[a-zA-Z0-9_-]{8,50}$/;
const REGEX_LOCATION_ID  = /^[a-zA-Z0-9]{10,30}$/;
const REGEX_EMAIL        = /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$/;

const MAX_TAGS           = 200;
const MAX_CUSTOM_FIELDS  = 200;

// ============================================================
// Utilidades basicas
// ============================================================

/**
 * Trunca y limpia un string. Devuelve null si el resultado es vacio.
 * @param {*} val    - valor a limpiar
 * @param {number} maxLen - longitud maxima
 * @returns {string|null}
 */
function cleanStr(val, maxLen) {
  if (val === null || val === undefined) return null;
  const s = String(val).trim().substring(0, maxLen);
  return s.length > 0 ? s : null;
}

/**
 * Normaliza un numero de telefono a formato E.164.
 * Asume Colombia (+57) como pais por defecto si el numero tiene 10 digitos y empieza en 3.
 * Adaptar segun necesidades del cliente.
 * @param {*} raw - telefono en cualquier formato
 * @returns {string|null}
 */
function normalizeE164(raw) {
  if (!raw) return null;
  // Eliminar todo excepto digitos y el signo +
  let digits = String(raw).replace(/[^\d+]/g, '');
  // Ya tiene codigo de pais
  if (digits.startsWith('+')) {
    const clean = '+' + digits.slice(1).replace(/\D/g, '');
    if (clean.length >= 8 && clean.length <= 16) return clean;
    return null;
  }
  // Colombia: 10 digitos empezando en 3 => +57
  if (/^3\d{9}$/.test(digits)) return '+57' + digits;
  // 12 digitos empezando en 57 => Colombia con codigo
  if (/^57\d{10}$/.test(digits)) return '+' + digits;
  // Devolver con + si tiene suficiente longitud
  if (digits.length >= 7 && digits.length <= 15) return '+' + digits;
  return null;
}

/**
 * Valida y normaliza un email segun RFC-5321.
 * @param {*} val
 * @returns {string|null}
 */
function validateEmail(val) {
  if (!val) return null;
  const normalized = String(val).toLowerCase().trim().substring(0, 255);
  return REGEX_EMAIL.test(normalized) ? normalized : null;
}

/**
 * Valida el formato de un ID de GHL.
 * @param {*} val
 * @returns {string|null}
 */
function validateGHLId(val) {
  if (!val) return null;
  const s = String(val).trim();
  return REGEX_GHL_ID.test(s) ? s : null;
}

/**
 * Valida el formato de un location_id de GHL.
 * @param {*} val
 * @returns {string|null}
 */
function validateLocationId(val) {
  if (!val) return null;
  const s = String(val).trim();
  return REGEX_LOCATION_ID.test(s) ? s : null;
}

/**
 * Parsea un timestamp ISO. Devuelve null si no es valido.
 * @param {*} val
 * @returns {string|null}
 */
function parseISODate(val) {
  if (!val) return null;
  const ts = Date.parse(String(val));
  if (isNaN(ts)) return null;
  return new Date(ts).toISOString();
}

/**
 * Parsea un numero flotante con fallback null.
 * @param {*} val
 * @returns {number|null}
 */
function parseFloatSafe(val) {
  if (val === null || val === undefined || val === '') return null;
  const n = parseFloat(val);
  return isNaN(n) ? null : n;
}

/**
 * Parsea un entero con fallback null.
 * @param {*} val
 * @returns {number|null}
 */
function parseIntSafe(val) {
  if (val === null || val === undefined || val === '') return null;
  const n = parseInt(val, 10);
  return isNaN(n) ? null : n;
}

/**
 * Limpia un array de strings. Limita a maxItems elementos.
 * @param {*} val
 * @param {number} maxItems
 * @returns {string[]|null}
 */
function cleanArray(val, maxItems) {
  if (!Array.isArray(val)) return null;
  return val.slice(0, maxItems).map(i => String(i).trim().substring(0, 200)).filter(Boolean);
}

// ============================================================
// sanitizeContact
// ============================================================

/**
 * Sanitiza el payload de un contacto de GHL.
 * Lanza Error si faltan campos obligatorios (contact_id, location_id).
 * @param {object} raw - payload crudo del webhook o API
 * @returns {object} - contacto limpio listo para SCD2/upsert
 */
function sanitizeContact(raw) {
  if (!raw || typeof raw !== 'object') {
    throw new Error('sanitizeContact: payload nulo o no es objeto');
  }

  const contact_id  = validateGHLId(raw.id || raw.contactId || raw.contact_id);
  const location_id = validateLocationId(raw.locationId || raw.location_id);

  if (!contact_id)  throw new Error('sanitizeContact: contact_id invalido: ' + (raw.id || raw.contactId));
  if (!location_id) throw new Error('sanitizeContact: location_id invalido: ' + (raw.locationId || raw.location_id));

  // Atribucion UTM — puede venir en attributionSource o en campos planos
  const attrFirst = raw.attributionSource || raw.attribution || {};
  const attrLast  = raw.lastAttributionSource || {};

  return {
    contact_id,
    location_id,
    email:               validateEmail(raw.email),
    phone:               normalizeE164(raw.phone),
    first_name:          cleanStr(raw.firstName  || raw.first_name,  100),
    last_name:           cleanStr(raw.lastName   || raw.last_name,   100),
    source:              cleanStr(raw.source,                        100),
    tags:                cleanArray(raw.tags, MAX_TAGS),
    contact_type:        cleanStr(raw.contactType || raw.type,        50),
    dnd:                 raw.dnd === true || raw.dnd === 'true' ? true : false,
    custom_fields:       raw.customFields && typeof raw.customFields === 'object'
                           ? raw.customFields : null,
    // UTM primer toque
    utm_source_first:    cleanStr(attrFirst.utmSource   || raw.utm_source_first,   200),
    utm_medium_first:    cleanStr(attrFirst.utmMedium   || raw.utm_medium_first,   200),
    utm_campaign_first:  cleanStr(attrFirst.utmCampaign || raw.utm_campaign_first, 200),
    utm_content_first:   cleanStr(attrFirst.utmContent  || raw.utm_content_first,  200),
    utm_term_first:      cleanStr(attrFirst.utmTerm     || raw.utm_term_first,     200),
    landing_url_first:   cleanStr(attrFirst.url         || raw.landing_url_first,  2048),
    referrer_first:      cleanStr(attrFirst.referrer    || raw.referrer_first,     2048),
    gclid_first:         cleanStr(attrFirst.gclid       || raw.gclid_first,        200),
    fbclid_first:        cleanStr(attrFirst.fbclid      || raw.fbclid_first,       200),
    campaign_id_first:   cleanStr(attrFirst.campaignId  || raw.campaign_id_first,  100),
    // UTM ultimo toque
    utm_source_last:     cleanStr(attrLast.utmSource    || raw.utm_source_last,    200),
    utm_medium_last:     cleanStr(attrLast.utmMedium    || raw.utm_medium_last,    200),
    utm_campaign_last:   cleanStr(attrLast.utmCampaign  || raw.utm_campaign_last,  200),
    utm_content_last:    cleanStr(attrLast.utmContent   || raw.utm_content_last,   200),
    landing_url_last:    cleanStr(attrLast.url          || raw.landing_url_last,   2048),
    ghl_created_at:      parseISODate(raw.dateAdded     || raw.createdAt || raw.ghl_created_at),
    ghl_updated_at:      parseISODate(raw.dateUpdated   || raw.updatedAt || raw.ghl_updated_at),
    synced_at:           new Date().toISOString()
  };
}

// ============================================================
// sanitizeOpportunity
// ============================================================

/**
 * Sanitiza el payload de una oportunidad de GHL.
 * @param {object} raw
 * @returns {object}
 */
function sanitizeOpportunity(raw) {
  if (!raw || typeof raw !== 'object') {
    throw new Error('sanitizeOpportunity: payload nulo o no es objeto');
  }

  const opportunity_id = validateGHLId(raw.id || raw.opportunityId || raw.opportunity_id);
  const contact_id     = validateGHLId(raw.contactId || raw.contact_id);
  const location_id    = validateLocationId(raw.locationId || raw.location_id);

  if (!opportunity_id) throw new Error('sanitizeOpportunity: opportunity_id invalido');
  if (!contact_id)     throw new Error('sanitizeOpportunity: contact_id invalido');
  if (!location_id)    throw new Error('sanitizeOpportunity: location_id invalido');

  const monetary_value = parseFloatSafe(raw.monetaryValue || raw.monetary_value);
  const status = cleanStr(raw.status, 20);
  const validStatuses = ['open', 'won', 'lost', 'abandoned'];
  const safe_status = validStatuses.includes(status) ? status : null;

  return {
    opportunity_id,
    contact_id,
    location_id,
    pipeline_id:         validateGHLId(raw.pipelineId        || raw.pipeline_id),
    pipeline_name:       cleanStr(raw.pipelineName           || raw.pipeline_name,    200),
    pipeline_stage_id:   validateGHLId(raw.pipelineStageId   || raw.pipeline_stage_id),
    stage_name:          cleanStr(raw.stageName              || raw.stage_name,       200),
    status:              safe_status,
    monetary_value:      monetary_value !== null ? monetary_value : 0,
    currency:            cleanStr(raw.currency, 3) || 'COP',
    assigned_to_user_id: validateGHLId(raw.assignedTo        || raw.assigned_to_user_id),
    assigned_to_name:    cleanStr(raw.assignedToName         || raw.assigned_to_name, 200),
    custom_fields:       raw.customFields && typeof raw.customFields === 'object'
                           ? raw.customFields : null,
    close_date:          parseISODate(raw.closeDate          || raw.close_date),
    ghl_created_at:      parseISODate(raw.dateAdded          || raw.createdAt || raw.ghl_created_at),
    ghl_updated_at:      parseISODate(raw.dateUpdated        || raw.updatedAt || raw.ghl_updated_at),
    synced_at:           new Date().toISOString()
  };
}

// ============================================================
// sanitizeConversation
// ============================================================

/**
 * Sanitiza el payload de una conversacion de GHL.
 * @param {object} raw
 * @returns {object}
 */
function sanitizeConversation(raw) {
  if (!raw || typeof raw !== 'object') {
    throw new Error('sanitizeConversation: payload nulo o no es objeto');
  }

  const conversation_id = validateGHLId(raw.id || raw.conversationId || raw.conversation_id);
  const contact_id      = validateGHLId(raw.contactId || raw.contact_id);
  const location_id     = validateLocationId(raw.locationId || raw.location_id);

  if (!conversation_id) throw new Error('sanitizeConversation: conversation_id invalido');
  if (!contact_id)      throw new Error('sanitizeConversation: contact_id invalido');
  if (!location_id)     throw new Error('sanitizeConversation: location_id invalido');

  const validChannels = ['WHATSAPP', 'SMS', 'EMAIL', 'FB_MESSENGER', 'INSTAGRAM', 'CALL'];
  const channel_type  = cleanStr(raw.type || raw.channelType || raw.channel_type, 30);

  return {
    conversation_id,
    contact_id,
    location_id,
    channel_type:       validChannels.includes(channel_type) ? channel_type : cleanStr(channel_type, 30),
    inbox_id:           validateGHLId(raw.inboxId          || raw.inbox_id),
    inbox_name:         cleanStr(raw.inboxName             || raw.inbox_name,            200),
    assigned_user_id:   validateGHLId(raw.userId           || raw.assigned_user_id),
    assigned_user_name: cleanStr(raw.userName              || raw.assigned_user_name,    200),
    status:             cleanStr(raw.status, 20),
    unread_count:       parseIntSafe(raw.unreadCount        || raw.unread_count) || 0,
    last_message_at:    parseISODate(raw.lastMessageDate    || raw.last_message_at),
    ghl_created_at:     parseISODate(raw.dateAdded          || raw.createdAt || raw.ghl_created_at),
    synced_at:          new Date().toISOString()
  };
}

// ============================================================
// sanitizeMessage
// ============================================================

/**
 * Sanitiza el payload de un mensaje individual de GHL.
 * @param {object} raw
 * @returns {object}
 */
function sanitizeMessage(raw) {
  if (!raw || typeof raw !== 'object') {
    throw new Error('sanitizeMessage: payload nulo o no es objeto');
  }

  const message_id      = validateGHLId(raw.id || raw.messageId || raw.message_id);
  const conversation_id = validateGHLId(raw.conversationId || raw.conversation_id);
  const contact_id      = validateGHLId(raw.contactId      || raw.contact_id);
  const location_id     = validateLocationId(raw.locationId || raw.location_id);

  if (!message_id)      throw new Error('sanitizeMessage: message_id invalido');
  if (!conversation_id) throw new Error('sanitizeMessage: conversation_id invalido');
  if (!contact_id)      throw new Error('sanitizeMessage: contact_id invalido');
  if (!location_id)     throw new Error('sanitizeMessage: location_id invalido');

  const direction = cleanStr(raw.direction || raw.messageDirection, 10);
  if (!['inbound', 'outbound'].includes(direction)) {
    throw new Error('sanitizeMessage: direction invalido: ' + direction);
  }

  return {
    message_id,
    conversation_id,
    contact_id,
    location_id,
    message_type:      cleanStr(raw.messageType || raw.type || raw.message_type, 30),
    direction,
    body:              raw.body ? String(raw.body).substring(0, 65535) : null,
    subject:           cleanStr(raw.subject, 500),
    from_email:        validateEmail(raw.from || raw.fromEmail),
    to_email:          validateEmail(raw.to   || raw.toEmail),
    email_message_id:  cleanStr(raw.emailMessageId   || raw.email_message_id, 200),
    call_duration_sec: parseIntSafe(raw.callDuration  || raw.call_duration_sec),
    call_status:       cleanStr(raw.callStatus        || raw.call_status,      30),
    wa_message_id:     cleanStr(raw.waMessageId       || raw.wa_message_id,   200),
    wa_status:         cleanStr(raw.waStatus          || raw.wa_status,         20),
    user_id:           validateGHLId(raw.userId       || raw.user_id),
    user_name:         cleanStr(raw.userName          || raw.user_name,        200),
    sent_at:           parseISODate(raw.dateAdded     || raw.createdAt || raw.sent_at) || new Date().toISOString()
  };
}

// ============================================================
// sanitizeAppointment
// ============================================================

/**
 * Sanitiza el payload de una cita de GHL.
 * @param {object} raw
 * @returns {object}
 */
function sanitizeAppointment(raw) {
  if (!raw || typeof raw !== 'object') {
    throw new Error('sanitizeAppointment: payload nulo o no es objeto');
  }

  const appointment_id = validateGHLId(raw.id || raw.appointmentId || raw.appointment_id);
  const contact_id     = validateGHLId(raw.contactId || raw.contact_id);
  const location_id    = validateLocationId(raw.locationId || raw.location_id);

  if (!appointment_id) throw new Error('sanitizeAppointment: appointment_id invalido');
  if (!contact_id)     throw new Error('sanitizeAppointment: contact_id invalido');
  if (!location_id)    throw new Error('sanitizeAppointment: location_id invalido');

  return {
    appointment_id,
    contact_id,
    location_id,
    calendar_id:      validateGHLId(raw.calendarId    || raw.calendar_id),
    title:            cleanStr(raw.title, 500),
    status:           cleanStr(raw.appointmentStatus  || raw.status, 30),
    start_time:       parseISODate(raw.startTime      || raw.start_time),
    end_time:         parseISODate(raw.endTime        || raw.end_time),
    assigned_user_id: validateGHLId(raw.assignedUserId || raw.userId || raw.assigned_user_id),
    notes:            raw.notes ? String(raw.notes).substring(0, 5000) : null,
    address:          cleanStr(raw.address, 500),
    ghl_created_at:   parseISODate(raw.dateAdded      || raw.createdAt || raw.ghl_created_at),
    ghl_updated_at:   parseISODate(raw.dateUpdated    || raw.updatedAt || raw.ghl_updated_at),
    synced_at:        new Date().toISOString()
  };
}

// ============================================================
// Exportar (para referencia — en n8n no se usa require)
// ============================================================
module.exports = {
  sanitizeContact,
  sanitizeOpportunity,
  sanitizeConversation,
  sanitizeMessage,
  sanitizeAppointment,
  normalizeE164,
  validateEmail,
  validateGHLId,
  validateLocationId,
  parseISODate,
  parseFloatSafe,
  parseIntSafe,
  cleanStr,
  cleanArray
};
