import { SignJWT } from 'jose'
import { BarChart3, ExternalLink } from 'lucide-react'

const METABASE_URL = process.env.METABASE_SITE_URL || 'https://analytics.sixteam.pro'
const EMBED_SECRET = process.env.MB_EMBEDDING_SECRET_KEY || ''

// Dashboard IDs to embed (update these once you create them in Metabase UI)
const DASHBOARDS = [
  { id: 1, title: 'Pipeline Overview',     description: 'Opportunity stages across all locations' },
  { id: 2, title: 'Contacts & Leads',      description: 'Contact acquisition and qualification' },
  { id: 3, title: 'Conversations',         description: 'Messaging activity and response times' },
  { id: 4, title: 'Ad Attribution (CTWA)', description: 'Click-to-WhatsApp attribution funnels' },
  { id: 5, title: 'Appointments',          description: 'Booking rates and appointment outcomes' },
  { id: 6, title: 'Executive Summary',     description: 'High-level KPIs across all clients' },
]

async function embedUrl(dashboardId: number): Promise<string> {
  if (!EMBED_SECRET) return ''
  const secret = new TextEncoder().encode(EMBED_SECRET)
  const token = await new SignJWT({ resource: { dashboard: dashboardId }, params: {} })
    .setProtectedHeader({ alg: 'HS256' })
    .sign(secret)
  return `${METABASE_URL}/embed/dashboard/${token}#bordered=false&titled=false&theme=transparent`
}

export default async function DashboardsPage() {
  const urls = await Promise.all(DASHBOARDS.map(d => embedUrl(d.id)))

  return (
    <div className="p-8 space-y-6 max-w-7xl">
      <div className="flex items-start justify-between">
        <div>
          <h1 className="font-poppins font-bold text-2xl text-navy">Dashboards</h1>
          <p className="text-sm font-lato text-warm mt-1">Embedded Metabase analytics</p>
        </div>
        <a
          href={METABASE_URL}
          target="_blank"
          rel="noopener noreferrer"
          className="flex items-center gap-2 text-sm font-lato text-teal hover:text-teal-dark transition-colors"
        >
          <ExternalLink size={14} />
          Open in Metabase
        </a>
      </div>

      {!EMBED_SECRET ? (
        <div className="bg-amber-50 border border-amber-200 rounded-xl p-6 text-sm font-lato text-amber-800">
          <strong className="font-poppins">MB_EMBEDDING_SECRET_KEY not configured.</strong>{' '}
          Set this env var and restart the container to enable embedded dashboards.
        </div>
      ) : (
        <div className="space-y-8">
          {DASHBOARDS.map((d, i) => (
            <div key={d.id} className="bg-white rounded-xl border border-cream-dark shadow-card overflow-hidden">
              <div className="flex items-center gap-3 px-6 py-4 border-b border-cream-dark">
                <BarChart3 size={16} className="text-teal" />
                <div>
                  <h2 className="font-poppins font-semibold text-navy text-sm">{d.title}</h2>
                  <p className="text-xs font-lato text-warm">{d.description}</p>
                </div>
              </div>
              <iframe
                src={urls[i]}
                className="w-full border-0"
                style={{ height: 480 }}
                title={d.title}
                allowFullScreen
              />
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
