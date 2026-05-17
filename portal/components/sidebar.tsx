'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import {
  LayoutDashboard,
  Users,
  ClipboardEdit,
  BarChart3,
  Settings,
  LogOut,
  Activity,
  ChevronRight,
} from 'lucide-react'
import { cn } from '@/lib/utils'

const NAV_ITEMS = [
  { href: '/overview',    label: 'Overview',    icon: LayoutDashboard },
  { href: '/clients',     label: 'Clients',     icon: Users },
  { href: '/data-entry',  label: 'Data Entry',  icon: ClipboardEdit },
  { href: '/dashboards',  label: 'Dashboards',  icon: BarChart3 },
  { href: '/system',      label: 'System',      icon: Settings },
]

export function Sidebar() {
  const path = usePathname()

  return (
    <aside className="flex h-screen w-60 flex-col bg-navy text-white select-none">
      {/* Logo */}
      <div className="flex items-center gap-3 px-6 py-6 border-b border-navy-light">
        <div className="w-8 h-8 rounded-lg bg-teal flex items-center justify-center shrink-0">
          <Activity size={16} className="text-white" />
        </div>
        <div>
          <p className="font-poppins font-semibold text-sm leading-tight">GHL Analytics</p>
          <p className="text-xs text-navy-lighter font-lato">Boutique Intelligence</p>
        </div>
      </div>

      {/* Nav */}
      <nav className="flex-1 px-3 py-4 space-y-1">
        {NAV_ITEMS.map(({ href, label, icon: Icon }) => {
          const active = path === href || path.startsWith(href + '/')
          return (
            <Link
              key={href}
              href={href}
              className={cn(
                'flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-lato transition-all group',
                active
                  ? 'bg-teal text-white font-medium'
                  : 'text-navy-lighter hover:bg-navy-light hover:text-white'
              )}
            >
              <Icon size={17} className="shrink-0" />
              <span className="flex-1">{label}</span>
              {active && <ChevronRight size={14} className="opacity-60" />}
            </Link>
          )
        })}
      </nav>

      {/* Footer */}
      <div className="px-3 py-4 border-t border-navy-light">
        <form action="/api/auth/logout" method="POST">
          <button
            type="submit"
            className="w-full flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-lato text-navy-lighter hover:bg-navy-light hover:text-white transition-all"
          >
            <LogOut size={17} className="shrink-0" />
            <span>Sign out</span>
          </button>
        </form>
      </div>
    </aside>
  )
}
