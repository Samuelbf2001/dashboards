import { Settings, Database, Clock, HardDrive, CheckCircle, AlertTriangle, XCircle } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { safeQueryAll, safeQuery } from '@/lib/db'
import { formatDate } from '@/lib/utils'

interface CronJob {
  jobid: string
  jobname: string
  schedule: string
  active: boolean
  database: string
}

interface CronRun {
  jobid: string
  status: string
  start_time: string
  end_time: string | null
  return_message: string | null
}

interface DbStats {
  db_name: string
  size: string
  connections: string
}

async function getCronJobs(): Promise<CronJob[]> {
  return safeQueryAll<CronJob>(
    `SELECT jobid::text, jobname, schedule, active, database FROM cron.job ORDER BY jobname`
  )
}

async function getCronRuns(): Promise<CronRun[]> {
  return safeQueryAll<CronRun>(
    `SELECT jobid::text, status, start_time::text, end_time::text, return_message
     FROM cron.job_run_details
     ORDER BY start_time DESC
     LIMIT 20`
  )
}

async function getDbStats(): Promise<DbStats[]> {
  return safeQueryAll<DbStats>(
    `SELECT datname AS db_name,
            pg_size_pretty(pg_database_size(datname)) AS size,
            (SELECT count(*) FROM pg_stat_activity WHERE datname = pg_database.datname)::text AS connections
     FROM pg_database
     WHERE datname NOT IN ('postgres','template0','template1')
     ORDER BY pg_database_size(datname) DESC`
  )
}

async function getTableCount(): Promise<{ count: string }> {
  return safeQuery<{ count: string }>(
    `SELECT COUNT(*)::text AS count FROM information_schema.tables
     WHERE table_schema = 'public' AND table_type = 'BASE TABLE'`,
    [],
    { count: '0' }
  )
}

export default async function SystemPage() {
  const [jobs, runs, dbs, tableCount] = await Promise.all([
    getCronJobs(), getCronRuns(), getDbStats(), getTableCount()
  ])

  const runVariant = (s: string): 'success' | 'error' | 'teal' | 'warning' =>
    s === 'succeeded' ? 'success' : s === 'failed' ? 'error' : s === 'running' ? 'teal' : 'warning'

  const statusIcon = (s: string) =>
    s === 'succeeded' ? <CheckCircle size={14} className="text-teal" /> :
    s === 'failed'    ? <XCircle size={14} className="text-red-500" /> :
    <AlertTriangle size={14} className="text-amber-500" />

  return (
    <div className="p-8 space-y-8 max-w-5xl">
      <div>
        <h1 className="font-poppins font-bold text-2xl text-navy">System</h1>
        <p className="text-sm font-lato text-warm mt-1">Database, cron jobs, and platform health</p>
      </div>

      {/* DB stats */}
      <div>
        <h2 className="font-poppins font-semibold text-navy mb-3 flex items-center gap-2 text-sm">
          <Database size={15} className="text-teal" /> Databases · {tableCount.count} tables in ghl_analytics
        </h2>
        <div className="bg-white rounded-xl border border-cream-dark shadow-card overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-cream-dark bg-cream-light">
                {['Database', 'Size', 'Connections'].map(h => (
                  <th key={h} className="text-left px-6 py-3 text-xs font-poppins font-semibold text-navy uppercase tracking-wider">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-cream-dark">
              {dbs.length === 0 ? (
                <tr><td colSpan={3} className="px-6 py-8 text-center text-warm font-lato text-sm">No database data available.</td></tr>
              ) : dbs.map(db => (
                <tr key={db.db_name} className="hover:bg-cream/50">
                  <td className="px-6 py-3 font-medium text-navy font-lato">{db.db_name}</td>
                  <td className="px-6 py-3 text-warm font-lato">{db.size}</td>
                  <td className="px-6 py-3 text-warm font-lato">{db.connections}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* pg_cron jobs */}
      <div>
        <h2 className="font-poppins font-semibold text-navy mb-3 flex items-center gap-2 text-sm">
          <Clock size={15} className="text-teal" /> Scheduled Jobs ({jobs.length})
        </h2>
        <div className="bg-white rounded-xl border border-cream-dark shadow-card overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-cream-dark bg-cream-light">
                {['Job', 'Schedule', 'Database', 'Active'].map(h => (
                  <th key={h} className="text-left px-6 py-3 text-xs font-poppins font-semibold text-navy uppercase tracking-wider">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-cream-dark">
              {jobs.length === 0 ? (
                <tr><td colSpan={4} className="px-6 py-8 text-center text-warm font-lato text-sm">No cron jobs configured.</td></tr>
              ) : jobs.map(j => (
                <tr key={j.jobid} className="hover:bg-cream/50">
                  <td className="px-6 py-3 font-medium text-navy font-lato">{j.jobname}</td>
                  <td className="px-6 py-3 text-warm font-lato font-mono text-xs">{j.schedule}</td>
                  <td className="px-6 py-3 text-warm font-lato">{j.database}</td>
                  <td className="px-6 py-3">
                    <Badge variant={j.active ? 'success' : 'outline'}>{j.active ? 'active' : 'disabled'}</Badge>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Recent cron runs */}
      <div>
        <h2 className="font-poppins font-semibold text-navy mb-3 flex items-center gap-2 text-sm">
          <HardDrive size={15} className="text-teal" /> Recent Job Runs
        </h2>
        <div className="bg-white rounded-xl border border-cream-dark shadow-card overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-cream-dark bg-cream-light">
                {['Job ID', 'Status', 'Started', 'Message'].map(h => (
                  <th key={h} className="text-left px-6 py-3 text-xs font-poppins font-semibold text-navy uppercase tracking-wider">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-cream-dark">
              {runs.length === 0 ? (
                <tr><td colSpan={4} className="px-6 py-8 text-center text-warm font-lato text-sm">No recent job runs.</td></tr>
              ) : runs.map((r, i) => (
                <tr key={i} className="hover:bg-cream/50">
                  <td className="px-6 py-3 text-warm font-lato font-mono text-xs">{r.jobid}</td>
                  <td className="px-6 py-3">
                    <div className="flex items-center gap-1.5">
                      {statusIcon(r.status)}
                      <Badge variant={runVariant(r.status)} className="text-xs">{r.status}</Badge>
                    </div>
                  </td>
                  <td className="px-6 py-3 text-warm font-lato text-xs">{formatDate(r.start_time)}</td>
                  <td className="px-6 py-3 text-warm font-lato text-xs truncate max-w-xs" title={r.return_message || ''}>
                    {r.return_message || '—'}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}
