import { Building2, Users, TrendingUp, RefreshCw } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { safeQueryAll } from '@/lib/db'
import { formatRelative, formatNumber } from '@/lib/utils'

interface ClientRow {
  location_id: string
  contacts: string
  active_opps: string
  messages: string
  last_sync_at: string | null
  sync_status: string
}

async function getClients(): Promise<ClientRow[]> {
  return safeQueryAll<ClientRow>(
    `SELECT
       s.location_id,
       COALESCE(c.cnt, 0)::text          AS contacts,
       COALESCE(o.cnt, 0)::text          AS active_opps,
       COALESCE(m.cnt, 0)::text          AS messages,
       s.last_sync_at,
       s.sync_status
     FROM ghl_sync_state s
     LEFT JOIN (
       SELECT location_id, COUNT(*) AS cnt FROM dim_contacts WHERE is_current = true GROUP BY 1
     ) c USING (location_id)
     LEFT JOIN (
       SELECT location_id, COUNT(*) AS cnt FROM dim_opportunities
       WHERE is_current = true AND stage_name NOT IN ('Closed Won','Closed Lost') GROUP BY 1
     ) o USING (location_id)
     LEFT JOIN (
       SELECT location_id, COUNT(*) AS cnt FROM fact_messages GROUP BY 1
     ) m USING (location_id)
     ORDER BY s.location_id`
  )
}

export default async function ClientsPage() {
  const clients = await getClients()

  const statusVariant = (s: string): 'success' | 'error' | 'teal' | 'warning' =>
    s === 'ok' ? 'success' : s === 'error' ? 'error' : s === 'running' ? 'teal' : 'warning'

  return (
    <div className="p-8 space-y-6 max-w-7xl">
      <div className="flex items-start justify-between">
        <div>
          <h1 className="font-poppins font-bold text-2xl text-navy">Clients</h1>
          <p className="text-sm font-lato text-warm mt-1">{clients.length} location{clients.length !== 1 ? 's' : ''} onboarded</p>
        </div>
      </div>

      <div className="bg-white rounded-xl border border-cream-dark shadow-card overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-cream-dark bg-cream-light">
              <th className="text-left px-6 py-3 font-poppins font-semibold text-navy text-xs uppercase tracking-wider">
                <div className="flex items-center gap-2"><Building2 size={13} /> Location</div>
              </th>
              <th className="text-right px-4 py-3 font-poppins font-semibold text-navy text-xs uppercase tracking-wider">
                <div className="flex items-center justify-end gap-1"><Users size={13} /> Contacts</div>
              </th>
              <th className="text-right px-4 py-3 font-poppins font-semibold text-navy text-xs uppercase tracking-wider">
                <div className="flex items-center justify-end gap-1"><TrendingUp size={13} /> Open Opps</div>
              </th>
              <th className="text-right px-4 py-3 font-poppins font-semibold text-navy text-xs uppercase tracking-wider">
                Messages
              </th>
              <th className="text-right px-6 py-3 font-poppins font-semibold text-navy text-xs uppercase tracking-wider">
                <div className="flex items-center justify-end gap-1"><RefreshCw size={13} /> Last Sync</div>
              </th>
              <th className="text-center px-4 py-3 font-poppins font-semibold text-navy text-xs uppercase tracking-wider">
                Status
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-cream-dark">
            {clients.length === 0 ? (
              <tr>
                <td colSpan={6} className="px-6 py-12 text-center text-warm font-lato text-sm">
                  No clients onboarded yet. Run the provisioning script to add locations.
                </td>
              </tr>
            ) : (
              clients.map(c => (
                <tr key={c.location_id} className="hover:bg-cream/50 transition-colors">
                  <td className="px-6 py-3 font-medium text-navy font-lato">{c.location_id}</td>
                  <td className="px-4 py-3 text-right text-warm font-lato">{formatNumber(Number(c.contacts))}</td>
                  <td className="px-4 py-3 text-right text-warm font-lato">{formatNumber(Number(c.active_opps))}</td>
                  <td className="px-4 py-3 text-right text-warm font-lato">{formatNumber(Number(c.messages))}</td>
                  <td className="px-6 py-3 text-right text-xs text-warm font-lato">{formatRelative(c.last_sync_at)}</td>
                  <td className="px-4 py-3 text-center">
                    <Badge variant={statusVariant(c.sync_status)}>{c.sync_status}</Badge>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}
