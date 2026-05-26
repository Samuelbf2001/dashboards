import { NextRequest, NextResponse } from 'next/server'
import { query } from '@/lib/db'

// POST /api/import-ads
// Carga filas de dim_ads desde un JSON array (parseado de CSV de Meta Ads Manager).
// Cada fila debe tener: ad_id, location_id (obligatorios).
// Opcionales: ad_name, adset_id, adset_name, campaign_id, campaign_name,
//             account_id, objective, status, daily_budget, start_date, end_date.
//
// Columnas del export de Meta Ads Manager que mapean a este endpoint:
//   "Ad ID"         → ad_id
//   "Ad name"       → ad_name
//   "Ad set ID"     → adset_id
//   "Ad set name"   → adset_name
//   "Campaign ID"   → campaign_id
//   "Campaign name" → campaign_name
//   "Account ID"    → account_id
//   "Objective"     → objective (opcional)
//   "Delivery"      → status (ACTIVE / PAUSED / etc.)
//   "Daily budget"  → daily_budget (opcional)
//   "Start date"    → start_date (YYYY-MM-DD, opcional)
//   "End date"      → end_date   (YYYY-MM-DD, opcional)

interface AdRow {
  ad_id: string
  location_id: string
  ad_name?: string
  adset_id?: string
  adset_name?: string
  campaign_id?: string
  campaign_name?: string
  account_id?: string
  objective?: string
  status?: string
  daily_budget?: number | string | null
  start_date?: string | null
  end_date?: string | null
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json()

    // Aceptar array directo o { rows: [...] }
    const rows: AdRow[] = Array.isArray(body) ? body : body?.rows

    if (!Array.isArray(rows) || rows.length === 0) {
      return NextResponse.json(
        { error: 'Se esperaba un array de filas en el body (o { rows: [...] })' },
        { status: 400 }
      )
    }

    // Validar que cada fila tenga ad_id y location_id
    const invalid = rows.filter(r => !r.ad_id || !r.location_id)
    if (invalid.length > 0) {
      return NextResponse.json(
        { error: `${invalid.length} fila(s) sin ad_id o location_id`, sample: invalid[0] },
        { status: 400 }
      )
    }

    let upserted = 0
    let skipped = 0

    for (const row of rows) {
      const budget = row.daily_budget != null && row.daily_budget !== ''
        ? Number(row.daily_budget)
        : null

      const result = await query(
        `INSERT INTO dim_ads (
           ad_id, ad_name,
           adset_id, adset_name,
           campaign_id, campaign_name,
           account_id, location_id,
           objective, status,
           daily_budget, start_date, end_date,
           synced_at
         ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13, NOW())
         ON CONFLICT (ad_id) DO UPDATE SET
           ad_name      = EXCLUDED.ad_name,
           adset_id     = EXCLUDED.adset_id,
           adset_name   = EXCLUDED.adset_name,
           campaign_id  = EXCLUDED.campaign_id,
           campaign_name= EXCLUDED.campaign_name,
           account_id   = EXCLUDED.account_id,
           objective    = EXCLUDED.objective,
           status       = EXCLUDED.status,
           daily_budget = EXCLUDED.daily_budget,
           start_date   = EXCLUDED.start_date,
           end_date     = EXCLUDED.end_date,
           synced_at    = NOW()`,
        [
          row.ad_id,
          row.ad_name   ?? null,
          row.adset_id  ?? null,
          row.adset_name ?? null,
          row.campaign_id ?? null,
          row.campaign_name ?? null,
          row.account_id ?? null,
          row.location_id,
          row.objective ?? null,
          row.status    ?? null,
          budget,
          row.start_date ?? null,
          row.end_date   ?? null,
        ]
      )

      if ((result as any).rowCount > 0) upserted++
      else skipped++
    }

    return NextResponse.json({ ok: true, upserted, skipped, total: rows.length })
  } catch (err) {
    console.error('import-ads error:', err)
    return NextResponse.json({ error: 'Database error' }, { status: 500 })
  }
}
