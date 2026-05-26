# ─────────────────────────────────────────────────────────────────────────────
# Traefik — Middleware CORS estricto
# Referencia: GHL_Platform.txt sección 5.2
# Se aplica a todos los routers que listen "cors-strict@file"
# ─────────────────────────────────────────────────────────────────────────────

http:
  middlewares:
    cors-strict:
      headers:
        # Métodos HTTP permitidos (OPTIONS necesario para preflight)
        accessControlAllowMethods:
          - GET
          - POST
          - OPTIONS

        # Headers permitidos en peticiones
        accessControlAllowHeaders:
          - Content-Type
          - Authorization
          - X-Requested-With
          - X-GHL-Signature   # Firma HMAC de webhooks de GHL

        # Orígenes permitidos
        # IMPORTANTE: ajustar a los subdominios reales del cliente
        # Los endpoints de webhook de n8n reciben de GHL/Meta directamente;
        # la validación de origen se complementa con la firma HMAC del payload.
        accessControlAllowOriginList:
          - "https://app.${DOMAIN}"
          - "https://analytics.${DOMAIN}"
          - "https://n8n.${DOMAIN}"

        # Cache de preflight: 1 hora (3600 segundos)
        accessControlMaxAge: 3600

        # Incluir header Vary: Origin para caches intermedias
        addVaryHeader: true
