/**
 * hmac_validator.js — Validacion HMAC para webhooks de GHL y Meta
 * Referencia: GHL_Platform.txt seccion 5 (SEC-05)
 *
 * IMPORTANTE: Este archivo se versiona en el repositorio pero su contenido
 * debe pegarse directamente dentro del Code node en n8n (no hay require()).
 *
 * GHL firma los payloads con HMAC-SHA256 usando WEBHOOK_SECRET.
 * El header es: X-GHL-Signature: sha256=<hex>
 *
 * Meta firma los payloads con HMAC-SHA256 usando META_APP_SECRET (si configurado).
 * El header es: X-Hub-Signature-256: sha256=<hex>
 */

const crypto = require('crypto');

// ============================================================
// validateGHLSignature
// ============================================================

/**
 * Valida la firma HMAC-SHA256 del webhook de GHL.
 * Usa comparacion timing-safe para prevenir timing attacks.
 *
 * @param {string|Buffer} rawBody         - Cuerpo crudo de la solicitud (sin parsear)
 * @param {string}        signatureHeader - Valor del header X-GHL-Signature (ej: "sha256=abc123...")
 * @param {string}        secret          - WEBHOOK_SECRET configurado en EasyPanel
 * @returns {boolean} - TRUE si la firma es valida
 */
function validateGHLSignature(rawBody, signatureHeader, secret) {
  if (!rawBody || !signatureHeader || !secret) {
    return false;
  }

  // El header puede venir como "sha256=<hex>" o solo "<hex>"
  const receivedHex = signatureHeader.startsWith('sha256=')
    ? signatureHeader.slice(7)
    : signatureHeader;

  let receivedBuf;
  try {
    receivedBuf = Buffer.from(receivedHex, 'hex');
  } catch (e) {
    return false;
  }

  // Calcular HMAC esperado
  const hmac = crypto.createHmac('sha256', secret);
  hmac.update(typeof rawBody === 'string' ? rawBody : rawBody.toString('utf8'));
  const expectedBuf = Buffer.from(hmac.digest('hex'), 'hex');

  // Comparacion timing-safe
  if (receivedBuf.length !== expectedBuf.length) {
    return false;
  }

  try {
    return crypto.timingSafeEqual(receivedBuf, expectedBuf);
  } catch (e) {
    return false;
  }
}

// ============================================================
// validateMetaSignature
// ============================================================

/**
 * Valida la firma HMAC-SHA256 del webhook de Meta Cloud API.
 * Header: X-Hub-Signature-256: sha256=<hex>
 *
 * @param {string|Buffer} rawBody         - Cuerpo crudo
 * @param {string}        signatureHeader - Valor del header X-Hub-Signature-256
 * @param {string}        appSecret       - META_APP_SECRET (si configurado; puede ser META_CLOUD_API_TOKEN)
 * @returns {boolean}
 */
function validateMetaSignature(rawBody, signatureHeader, appSecret) {
  // Reutiliza la misma logica — mismo patron HMAC-SHA256
  return validateGHLSignature(rawBody, signatureHeader, appSecret);
}

// ============================================================
// Exportar
// ============================================================
module.exports = {
  validateGHLSignature,
  validateMetaSignature
};
