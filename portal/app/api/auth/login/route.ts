import { NextRequest, NextResponse } from 'next/server'
import { createSession, validateCredentials, COOKIE_NAME, COOKIE_TTL } from '@/lib/auth'

export async function POST(req: NextRequest) {
  try {
    const { username, password } = await req.json()

    if (!username || !password) {
      return NextResponse.json({ error: 'Username and password required' }, { status: 400 })
    }

    if (!validateCredentials(username, password)) {
      return NextResponse.json({ error: 'Invalid credentials' }, { status: 401 })
    }

    const token = await createSession(username)

    const res = NextResponse.json({ ok: true })
    res.cookies.set(COOKIE_NAME, token, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax',
      maxAge: COOKIE_TTL,
      path: '/',
    })
    return res
  } catch {
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
