import { SignJWT, jwtVerify } from 'jose'
import { cookies } from 'next/headers'

const COOKIE = 'portal_session'
const TTL = 60 * 60 * 8 // 8 hours

function secret() {
  return new TextEncoder().encode(
    process.env.PORTAL_ADMIN_PASSWORD || 'fallback-secret'
  )
}

export async function createSession(username: string): Promise<string> {
  return new SignJWT({ sub: username })
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime(`${TTL}s`)
    .sign(secret())
}

export async function getSession(): Promise<{ sub: string } | null> {
  const token = (await cookies()).get(COOKIE)?.value
  if (!token) return null
  try {
    const { payload } = await jwtVerify(token, secret())
    return payload as { sub: string }
  } catch {
    return null
  }
}

export function validateCredentials(user: string, pass: string): boolean {
  const adminUser = process.env.PORTAL_ADMIN_USER || 'admin'
  const adminPass = process.env.PORTAL_ADMIN_PASSWORD || ''
  return user === adminUser && pass === adminPass
}

export const COOKIE_NAME = COOKIE
export const COOKIE_TTL = TTL
