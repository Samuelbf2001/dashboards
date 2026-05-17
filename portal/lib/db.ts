import { Pool } from 'pg'

let pool: Pool | null = null

function getPool(): Pool {
  if (!pool) {
    pool = new Pool({
      host: process.env.POSTGRES_HOST || 'postgres',
      port: Number(process.env.POSTGRES_PORT) || 5432,
      database: process.env.POSTGRES_DB || 'ghl_analytics',
      user: process.env.POSTGRES_USER || 'ghl_user',
      password: process.env.POSTGRES_PASSWORD,
      max: 5,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 5000,
    })
  }
  return pool
}

export async function query<T = Record<string, unknown>>(
  sql: string,
  params?: unknown[]
): Promise<T[]> {
  const client = await getPool().connect()
  try {
    const res = await client.query(sql, params)
    return res.rows as T[]
  } finally {
    client.release()
  }
}

export async function queryOne<T = Record<string, unknown>>(
  sql: string,
  params?: unknown[]
): Promise<T | null> {
  const rows = await query<T>(sql, params)
  return rows[0] ?? null
}

// Safe wrapper — returns default on error so pages don't crash if DB is unreachable
export async function safeQuery<T>(
  sql: string,
  params: unknown[],
  fallback: T
): Promise<T> {
  try {
    const rows = await query<Record<string, unknown>>(sql, params)
    return (rows[0] as T) ?? fallback
  } catch {
    return fallback
  }
}

export async function safeQueryAll<T>(
  sql: string,
  params: unknown[] = [],
  fallback: T[] = []
): Promise<T[]> {
  try {
    return await query<T>(sql, params)
  } catch {
    return fallback
  }
}
