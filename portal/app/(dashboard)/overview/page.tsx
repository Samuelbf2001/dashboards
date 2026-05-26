import { Users, TrendingUp, MessageSquare, RefreshCw, CalendarCheck } from 'lucide-react'
import { StatCard } from '@/components/stat-card'
import { Badge } from '@/components/ui/badge'
import { safeQuery, safeQueryAll } from '@/lib/db'
import { formatRelative } from '@/lib/utils'

interface OverviewStats {
  total_locations: string
  total_contacts: string
  active_opportunities: string
  messages_today: string
  appointments_today: string
}

interface SyncRow {
  location_id: string
  last_sync_at: string | null
  sync_status: string
}

async function getStats(): Promise<OverviewStats> {
  return safeQuery<OverviewStats>(
    `SELECT
      (SELECT COUNT(DISTINCT location_id) FROM ghl_sync_state)::text            AS total_locations,
      (SELECT COUNT(*) FROM dim_contacts    WHERE is_current = true)::text      AS total_contacts,
      (SELECT COUNT(*) FROM dim_opportunities WHERE is_current = true
         AND stage_name NOT IN ('Closed Won','Closed Lost'))::text              AS active_opportunities,
      (SELECT COUNT(*) FROM fact_messages
         WHERE created_at >= CURRENT_DATE)::text                                AS messages_today,
      (SELECT COUNT(*) FROM ghl_appointments
         WHERE start_time >= CURRENT_DATE AND start_time < CURRENT_DATE + interval '1 day')::text AS appointments_today`,
    [],
    {
      total_locations: '0', total_contacts: '0',
      active_opportunities: '0', messages_today: '0', appointments_today: '0',
    }
  )
}

async function getRecentSync(): Promise<SyncRow[]> {
  return safeQueryAll<SyncRow>(
    `SELECT
       location_id,
       last_synced_at AS last_sync_at,
       CASE
         WHEN last_error IS NOT NULL THEN 'error'
         WHEN last_synced_at IS NOT NULL THEN 'ok'
         ELSE 'pending'
       END AS sync_status
     FROM ghl_sync_state
     ORDER BY last_synced_at DESC NULLS LAST
     LIMIT 10`,
    []
  )
}

export default async function OverviewPage() {
  const [stats, syncs] = await Promise.all([getStats(), getRecentSync()])

  const statusVariant = (s: string) =>
    s === 'ok' ? 'success' : s === 'running' ? 'teal' : s === 'error' ? 'error' : 'warning'

  return (
    <div className="p-8 space-y-8 max-w-7xl">
      {/* Header */}
      <div>
        <h1 className="font-poppins font-bold text-2xl text-navy">Overview</h1>
        <p className="text-sm font-lato text-warm mt-1">Platform health at a glance</p>
      </div>

      {/* KPI grid */}
      <div className="grid grid-cols-2 xl:grid-cols-5 gap-4">
        <StatCard title="Active Clients" value={Number(stats.total_locations)} icon={Users} accent="navy" />
        <StatCard title="Total Contacts" value={Number(stats.total_contacts)} icon={Users} accent="teal" />
        <StatCard title="Open Opportunities" value={Number(stats.active_opportunities)} icon={TrendingUp} accent="teal" />
        <StatCard title="Messages Today" value={Number(stats.messages_today)} icon={MessageSquare} accent="warm" />
        <StatCard title="Appts Today" value={Number(stats.appointments_today)} icon={CalendarCheck} accent="teal" />
      </div>

      {/* Recent sync */}
      <div className="bg-white rounded-xl border border-cream-dark shadow-card">
        <div className="flex items-center gap-3 px-6 py-4 border-b border-cream-dark">
          <RefreshCw size={16} className="text-teal" />
          <h2 className="font-poppins font-semibold text-navy text-sm">Recent Sync Activity</h2>
        </div>
        <div className="divide-y divide-cream-dark">
          {syncs.length === 0 ? (
            <p className="px-6 py-8 text-sm text-warm text-center font-lato">No sync data yet.</p>
          ) : (
            syncs.map(row => (
              <div key={row.location_id} className="flex items-center justify-between px-6 py-3">
                <div>
                  <p className="text-sm font-medium text-navy font-lato">{row.location_id}</p>
                  <p className="text-xs text-warm font-lato">{formatRelative(row.last_sync_at)}</p>
                </div>
                <Badge variant={statusVariant(row.sync_status) as 'success' | 'teal' | 'error' | 'warning'}>
                  {row.sync_status}
                </Badge>
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  )
}
