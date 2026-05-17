import * as React from 'react'
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils'

const badgeVariants = cva(
  'inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium font-lato transition-colors',
  {
    variants: {
      variant: {
        default: 'bg-navy/10 text-navy',
        success: 'bg-teal/15 text-teal-dark',
        warning: 'bg-amber-100 text-amber-800',
        error: 'bg-red-100 text-red-700',
        outline: 'border border-warm-lighter text-warm',
        teal: 'bg-teal text-white',
        navy: 'bg-navy text-white',
      },
    },
    defaultVariants: { variant: 'default' },
  }
)

export interface BadgeProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof badgeVariants> {}

function Badge({ className, variant, ...props }: BadgeProps) {
  return <div className={cn(badgeVariants({ variant }), className)} {...props} />
}

export { Badge, badgeVariants }
