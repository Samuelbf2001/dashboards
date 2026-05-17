import { cn, formatNumber } from '@/lib/utils'
import type { LucideIcon } from 'lucide-react'

interface StatCardProps {
  title: string
  value: number | string
  subtitle?: string
  icon: LucideIcon
  trend?: { value: number; label: string }
  accent?: 'teal' | 'navy' | 'warm'
  className?: string
}

export function StatCard({ title, value, subtitle, icon: Icon, trend, accent = 'teal', className }: StatCardProps) {
  const accentMap = {
    teal: 'bg-teal/10 text-teal',
    navy: 'bg-navy/10 text-navy',
    warm: 'bg-warm/10 text-warm',
  }

  const displayValue = typeof value === 'number' ? formatNumber(value) : value

  return (
    <div className={cn('rounded-xl bg-white border border-cream-dark shadow-card p-6 flex flex-col gap-4', className)}>
      <div className="flex items-start justify-between">
        <p className="text-sm font-medium font-lato text-warm">{title}</p>
        <div className={cn('rounded-lg p-2', accentMap[accent])}>
          <Icon size={18} />
        </div>
      </div>
      <div>
        <p className="text-3xl font-poppins font-bold text-navy">{displayValue}</p>
        {subtitle && <p className="text-xs font-lato text-warm mt-1">{subtitle}</p>}
      </div>
      {trend && (
        <div className="flex items-center gap-1 text-xs font-lato">
          <span className={cn('font-medium', trend.value >= 0 ? 'text-teal' : 'text-red-500')}>
            {trend.value >= 0 ? '+' : ''}{trend.value}%
          </span>
          <span className="text-warm">{trend.label}</span>
        </div>
      )}
    </div>
  )
}
