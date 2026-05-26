import type { NextConfig } from 'next'

const nextConfig: NextConfig = {
  output: 'standalone',
  serverExternalPackages: ['pg'],
  optimizeFonts: false,
  async headers() {
    return [
      {
        // Permite que GHL (y app.gohighlevel.com) embeba cualquier página del portal en un iframe
        source: '/(.*)',
        headers: [
          {
            key: 'Content-Security-Policy',
            value: "frame-ancestors 'self' https://*.gohighlevel.com https://*.leadconnectorhq.com https://*.msgsndr.com",
          },
          // X-Frame-Options sólo soporta SAMEORIGIN/DENY — para dominios externos
          // usamos CSP frame-ancestors arriba y omitimos este header para no bloquearlo
        ],
      },
    ]
  },
}

export default nextConfig
