'use client'

import { useState } from 'react'
import { ClipboardEdit, CheckCircle, AlertCircle, ChevronDown } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Badge } from '@/components/ui/badge'

type EntryType = 'contact' | 'opportunity' | 'sync_reset'

const ENTRY_TYPES: { id: EntryType; label: string; desc: string }[] = [
  { id: 'contact',     label: 'Override Contact Tag',    desc: 'Manually set tags or notes on a contact' },
  { id: 'opportunity', label: 'Override Opportunity',    desc: 'Correct stage, value, or assigned user' },
  { id: 'sync_reset',  label: 'Reset Sync State',        desc: 'Force a full re-sync for a location' },
]

export default function DataEntryPage() {
  const [type, setType] = useState<EntryType>('contact')
  const [status, setStatus] = useState<'idle' | 'loading' | 'success' | 'error'>('idle')
  const [message, setMessage] = useState('')

  const [fields, setFields] = useState({
    locationId: '', recordId: '', field: '', value: '', reason: '',
  })

  function set(key: keyof typeof fields, val: string) {
    setFields(f => ({ ...f, [key]: val }))
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setStatus('loading')
    try {
      const res = await fetch('/api/data-entry', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ type, ...fields }),
      })
      if (res.ok) {
        setStatus('success')
        setMessage('Entry recorded successfully.')
        setFields({ locationId: '', recordId: '', field: '', value: '', reason: '' })
      } else {
        const d = await res.json()
        setStatus('error')
        setMessage(d.error || 'Failed to submit entry.')
      }
    } catch {
      setStatus('error')
      setMessage('Network error.')
    }
  }

  return (
    <div className="p-8 space-y-6 max-w-2xl">
      <div>
        <h1 className="font-poppins font-bold text-2xl text-navy">Data Entry</h1>
        <p className="text-sm font-lato text-warm mt-1">Manual overrides and corrections</p>
      </div>

      {/* Type selector */}
      <div className="grid grid-cols-3 gap-3">
        {ENTRY_TYPES.map(t => (
          <button
            key={t.id}
            onClick={() => { setType(t.id); setStatus('idle') }}
            className={`rounded-xl border p-4 text-left transition-all ${
              type === t.id
                ? 'border-teal bg-teal/5 shadow-card'
                : 'border-cream-dark bg-white hover:border-warm-lighter'
            }`}
          >
            <p className={`text-sm font-poppins font-semibold ${type === t.id ? 'text-teal-dark' : 'text-navy'}`}>
              {t.label}
            </p>
            <p className="text-xs font-lato text-warm mt-1">{t.desc}</p>
          </button>
        ))}
      </div>

      {/* Form */}
      <form onSubmit={handleSubmit} className="bg-white rounded-xl border border-cream-dark shadow-card p-6 space-y-4">
        <div className="flex items-center gap-2 mb-2">
          <ClipboardEdit size={16} className="text-teal" />
          <h2 className="font-poppins font-semibold text-navy">
            {ENTRY_TYPES.find(t => t.id === type)?.label}
          </h2>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div className="space-y-1.5">
            <Label htmlFor="locationId">Location ID</Label>
            <Input id="locationId" placeholder="loc_xxx" value={fields.locationId}
              onChange={e => set('locationId', e.target.value)} required />
          </div>
          {type !== 'sync_reset' && (
            <div className="space-y-1.5">
              <Label htmlFor="recordId">Record ID</Label>
              <Input id="recordId" placeholder="contact_id / opp_id" value={fields.recordId}
                onChange={e => set('recordId', e.target.value)} required />
            </div>
          )}
        </div>

        {type !== 'sync_reset' && (
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-1.5">
              <Label htmlFor="field">Field</Label>
              <Input id="field" placeholder="e.g. tags, stage_name" value={fields.field}
                onChange={e => set('field', e.target.value)} required />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="value">New Value</Label>
              <Input id="value" placeholder="new value" value={fields.value}
                onChange={e => set('value', e.target.value)} required />
            </div>
          </div>
        )}

        <div className="space-y-1.5">
          <Label htmlFor="reason">Reason / Notes</Label>
          <Input id="reason" placeholder="Why is this change needed?" value={fields.reason}
            onChange={e => set('reason', e.target.value)} />
        </div>

        {status !== 'idle' && (
          <div className={`flex items-center gap-2 text-sm rounded-lg px-3 py-2 ${
            status === 'success' ? 'bg-teal/10 text-teal-dark' :
            status === 'error'   ? 'bg-red-50 text-red-600' :
            'bg-cream text-warm'
          }`}>
            {status === 'success' && <CheckCircle size={14} />}
            {status === 'error'   && <AlertCircle size={14} />}
            <span className="font-lato">{status === 'loading' ? 'Submitting…' : message}</span>
          </div>
        )}

        <Button type="submit" variant="primary" disabled={status === 'loading'} className="w-full">
          Submit Entry
        </Button>
      </form>
    </div>
  )
}
