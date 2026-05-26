import { SignJWT } from 'jose'

const METABASE_URL = process.env.METABASE_SITE_URL || 'https://analytics.sixteam.pro'
const EMBED_SECRET = process.env.MB_EMBEDDING_SECRET_KEY || ''

export async function GET(
  _req: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params
  const dashboardId = parseInt(id, 10)

  if (!EMBED_SECRET) {
    return new Response('MB_EMBEDDING_SECRET_KEY not configured', { status: 500 })
  }
  if (isNaN(dashboardId)) {
    return new Response('Invalid dashboard id', { status: 400 })
  }

  const secret = new TextEncoder().encode(EMBED_SECRET)
  const token = await new SignJWT({ resource: { dashboard: dashboardId }, params: {} })
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime('1h')
    .sign(secret)

  const html = `<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Dashboard ${dashboardId}</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { background: #ffffff; width: 100%; height: 100vh; overflow: hidden; }
    metabase-dashboard { display: block; width: 100%; height: 100vh; }
  </style>
  <script>
    function defineMetabaseConfig(config) { window.metabaseConfig = config; }
  </script>
  <script>
    defineMetabaseConfig({
      "theme": { "preset": "light" },
      "isGuest": true,
      "instanceUrl": "${METABASE_URL}"
    });
  </script>
  <script defer src="${METABASE_URL}/app/embed.js"></script>
</head>
<body>
  <metabase-dashboard
    token="${token}"
    with-title="false"
    with-downloads="true">
  </metabase-dashboard>
</body>
</html>`

  return new Response(html, {
    headers: {
      'Content-Type': 'text/html; charset=utf-8',
      'Content-Security-Policy':
        "frame-ancestors 'self' https://*.gohighlevel.com https://*.leadconnectorhq.com https://*.msgsndr.com",
      // Sin X-Frame-Options para que CSP frame-ancestors tome el control
      'Cache-Control': 'no-store',
    },
  })
}
