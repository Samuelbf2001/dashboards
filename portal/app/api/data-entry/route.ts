import { NextRequest, NextResponse } from 'next/server'
import { query } from '@/lib/db'

export async function POST(req: NextRequest) {
  try {
    const body = await req.json()
    const { type, locationId, recordId, field, value, reason } = body

    if (!locationId) {
      return NextResponse.json({ error: 'locationId is required' }, { status: 400 })
    }

    if (type === 'sync_reset') {
      await query(
        `UPDATE ghl_sync_state
         SET last_synced_at = NULL, last_cursor = NULL, last_error = NULL, updated_at = NOW()
         WHERE location_id = $1`,
        [locationId]
      )
      return NextResponse.json({ ok: true, message: `Sync reset for ${locationId}` })
    }

    // Log override to an audit table (created on first use)
    await query(
      `CREATE TABLE IF NOT EXISTS portal_overrides (
         id          BIGSERIAL PRIMARY KEY,
         created_at  TIMESTAMPTZ DEFAULT NOW(),
         type        TEXT NOT NULL,
         location_id TEXT NOT NULL,
         record_id   TEXT,
         field       TEXT,
         value       TEXT,
         reason      TEXT
       )`,
      []
    )

    await query(
      `INSERT INTO portal_overrides (type, location_id, record_id, field, value, reason)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [type, locationId, recordId || null, field || null, value || null, reason || null]
    )

    return NextResponse.json({ ok: true })
  } catch (err) {
    console.error('data-entry error:', err)
    return NextResponse.json({ error: 'Database error' }, { status: 500 })
  }
}
