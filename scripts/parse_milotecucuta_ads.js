// Script: parsea CSV de Meta Ads Manager (Milotecucuta) y genera SQL para dim_ads.
// Uso: node scripts/parse_milotecucuta_ads.js [location_id]

const fs   = require('fs');
const path = require('path');

// ── Fix mojibake (UTF-8 mal leido como Latin-1) ──────────────────────────────
// El CSV tiene texto en UTF-8 donde chars acentuados se ven como "Ã±", "Ã©", etc.
// Tecnica: tratar cada char Unicode como su byte Latin-1 equivalente y
// reinterpretar el buffer resultante como UTF-8.
// Los bytes "silenciados" (rango 0x80-0x9F) dejan secuencias invalidas que
// Node.js convierte en U+FFFD; los resolvemos con patrones contextuales.

const FFFD = '�'; // caracter de reemplazo de Unicode

function fixEncoding(str) {
  if (!str) return str;

  // Paso 1: recodificar via Buffer
  let out;
  try {
    // Buffer.from(str, 'latin1') toma los 8 bits bajos de cada char Unicode
    // como un byte — exactamente lo que necesitamos para deshacer el mojibake.
    out = Buffer.from(str, 'latin1').toString('utf8');
  } catch (_) {
    out = str;
  }

  // Paso 2: reparar secuencias invalidas (donde el 2do byte UTF-8 fue silenciado)
  // out puede contener FFFD en lugar de la vocal/consonante acentuada.

  // -CION / -cion (Ó = byte 0x93 silenciado)
  out = out.replace(new RegExp(`CI${FFFD}([NnRr])`, 'g'), (_, c) => 'CIÓ' + c);
  out = out.replace(new RegExp(`ci${FFFD}([nr])`,   'g'), (_, c) => 'ció' + c);

  // PÚBLICO / Público (Ú = byte 0x9A silenciado)
  out = out.replace(new RegExp(`P${FFFD}BL`, 'g'), 'PÚBL');
  out = out.replace(new RegExp(`p${FFFD}bl`, 'g'), 'públ');

  // TRÁFICO (Á = byte 0x81 silenciado)
  out = out.replace(new RegExp(`TR${FFFD}F`, 'g'), 'TRÁF');
  out = out.replace(new RegExp(`Tr${FFFD}f`, 'g'), 'Tráf');

  // FÁCIL (Á)
  out = out.replace(new RegExp(`F${FFFD}CI`, 'g'), 'FÁCI');

  // CÚCUTA (Ú = byte 0x9A)
  out = out.replace(new RegExp(`C${FFFD}C`, 'g'), 'CÚC');
  // Cucuta minuscula: "CÚcuta" — byte 0xBA visible, ya resuelto por Buffer

  // SEÑAL (Ñ = byte 0x91 silenciado)
  out = out.replace(new RegExp(`SE${FFFD}AL`, 'g'), 'SEÑAL');
  out = out.replace(new RegExp(`se${FFFD}al`, 'g'), 'señal');

  // ASÍ (Í = byte 0x8D silenciado)
  out = out.replace(new RegExp(`AS${FFFD}`, 'g'), 'ASÍ');
  out = out.replace(new RegExp(`as${FFFD}`, 'g'), 'así');
  out = out.replace(new RegExp(`As${FFFD}`, 'g'), 'Así');

  // ANIMACIÓN (Ó en -CIÓN ya cubierto arriba)
  // INTERACCIÓN (Ó en -CIÓN ya cubierto)

  // Paso 3: limpiar FFFD residuales (casos no identificados)
  out = out.replace(new RegExp(FFFD, 'g'), '');

  return out;
}

// ── Parser CSV respetando comillas ──────────────────────────────────────────
function parseCSVLine(line) {
  const result = [];
  let current  = '';
  let inQuotes = false;

  for (let i = 0; i < line.length; i++) {
    const ch = line[i];
    if (ch === '"') {
      if (inQuotes && line[i + 1] === '"') { current += '"'; i++; }
      else inQuotes = !inQuotes;
    } else if (ch === ',' && !inQuotes) {
      result.push(current.trim());
      current = '';
    } else {
      current += ch;
    }
  }
  result.push(current.trim());
  return result;
}

function sq(val) {
  if (val === null || val === undefined || val === '') return 'NULL';
  return "'" + String(val).replace(/'/g, "''") + "'";
}

function num(val) {
  const n = parseFloat(String(val).replace(/,/g, '.'));
  return isNaN(n) ? 'NULL' : String(n);
}

// ── Main ─────────────────────────────────────────────────────────────────────
const locationId = process.argv[2] || 'REEMPLAZAR_CON_LOCATION_ID_DE_GHL';

const csvPath = path.join(__dirname, 'milotecucuta_ads.csv');
if (!fs.existsSync(csvPath)) {
  console.error('ERROR: Falta scripts/milotecucuta_ads.csv');
  process.exit(1);
}

// Leer como UTF-8 (el archivo fue guardado en UTF-8 con mojibake dentro)
const raw   = fs.readFileSync(csvPath, 'utf8');
const lines = raw.split(/\r?\n/).filter(l => l.trim());

// Detectar columnas aplicando fixEncoding al header para encontrar por nombre
const rawHeader    = parseCSVLine(lines[0]);
const decodedHeader = rawHeader.map(h => fixEncoding(h));

console.error('Columnas detectadas:', decodedHeader.length);

function findCol(headers, ...candidates) {
  for (const c of candidates) {
    const idx = headers.findIndex(h => h.toLowerCase().includes(c.toLowerCase()));
    if (idx >= 0) return idx;
  }
  return -1;
}

const COL = {
  ad_name:       findCol(decodedHeader, 'nombre del anuncio'),
  objective:     findCol(decodedHeader, 'objetivo'),
  budget:        findCol(decodedHeader, 'presupuesto del conjunto'),
  campaign_id:   findCol(decodedHeader, 'identificador de la campa'),
  account_id:    findCol(decodedHeader, 'identificador de la cuenta'),
  ad_id:         findCol(decodedHeader, 'identificador del anuncio'),
  adset_id:      findCol(decodedHeader, 'identificador del conjunto'),
  adset_name:    findCol(decodedHeader, 'nombre del conjunto'),
  campaign_name: findCol(decodedHeader, 'nombre de la campa'),
};

console.error('Mapa de columnas:', COL);

const seen = new Map();

for (let i = 1; i < lines.length; i++) {
  const cols = parseCSVLine(lines[i]);
  if (cols.length < 10) continue;

  const adId = cols[COL.ad_id]?.trim();
  if (!adId || seen.has(adId)) continue;

  const budgetRaw = cols[COL.budget]?.trim() || '';
  const budget    = /^\d/.test(budgetRaw) ? budgetRaw : null;

  seen.set(adId, {
    ad_id:         adId,
    ad_name:       fixEncoding(cols[COL.ad_name]?.trim() || null),
    adset_id:      cols[COL.adset_id]?.trim() || null,
    adset_name:    fixEncoding(cols[COL.adset_name]?.trim() || null),
    campaign_id:   cols[COL.campaign_id]?.trim() || null,
    campaign_name: fixEncoding(cols[COL.campaign_name]?.trim() || null),
    account_id:    cols[COL.account_id]?.trim() || null,
    objective:     fixEncoding(cols[COL.objective]?.trim() || null),
    daily_budget:  budget,
  });
}

const rows    = [...seen.values()];
const outPath = path.join(__dirname, 'V1.0.3__seed_dim_ads_milotecucuta.sql');
const out     = [];

out.push(`-- ────────────────────────────────────────────────────────────────────────`);
out.push(`-- V1.0.3 — Seed dim_ads: Milotecucuta (Meta Ads Manager export)`);
out.push(`-- Generado: ${new Date().toISOString()}`);
out.push(`-- ${rows.length} anuncios unicos | account_id: 1177096264190146`);
out.push(`--`);
out.push(`-- Antes de ejecutar, obtener location_id real con:`);
out.push(`--   SELECT DISTINCT location_id FROM dim_contacts LIMIT 5;`);
out.push(`-- Reemplazar REEMPLAZAR_CON_LOCATION_ID_DE_GHL con ese valor.`);
out.push(`-- ────────────────────────────────────────────────────────────────────────`);
out.push('');
out.push(`DO $$`);
out.push(`DECLARE loc TEXT := ${sq(locationId)};`);
out.push(`BEGIN`);

for (const r of rows) {
  out.push(`
  INSERT INTO dim_ads (ad_id, ad_name, adset_id, adset_name, campaign_id, campaign_name, account_id, location_id, objective, daily_budget, status, synced_at)
  VALUES (${sq(r.ad_id)}, ${sq(r.ad_name)}, ${sq(r.adset_id)}, ${sq(r.adset_name)}, ${sq(r.campaign_id)}, ${sq(r.campaign_name)}, ${sq(r.account_id)}, loc, ${sq(r.objective)}, ${num(r.daily_budget)}, 'ACTIVE', NOW())
  ON CONFLICT (ad_id) DO UPDATE SET
    ad_name=EXCLUDED.ad_name, adset_id=EXCLUDED.adset_id, adset_name=EXCLUDED.adset_name,
    campaign_id=EXCLUDED.campaign_id, campaign_name=EXCLUDED.campaign_name,
    account_id=EXCLUDED.account_id, location_id=EXCLUDED.location_id,
    objective=EXCLUDED.objective, daily_budget=EXCLUDED.daily_budget, synced_at=NOW();`);
}

out.push(`END $$;`);
out.push('');
out.push(`-- Verificacion post-carga:`);
out.push(`-- SELECT COUNT(*), location_id FROM dim_ads GROUP BY location_id;`);
out.push(`-- SELECT ad_id, ad_name, adset_name, campaign_name FROM dim_ads ORDER BY synced_at DESC LIMIT 10;`);
out.push(`-- REFRESH MATERIALIZED VIEW CONCURRENTLY mv_unified_attribution;`);

fs.writeFileSync(outPath, out.join('\n'), 'utf8');
console.error(`\nSQL generado: ${outPath}`);
console.error(`${rows.length} anuncios unicos`);

console.error('\nPrimeros 8 nombres (verificar encoding):');
rows.slice(0, 8).forEach(r =>
  console.error(` ad_name: "${r.ad_name}"  |  campaign: "${r.campaign_name}"`));
