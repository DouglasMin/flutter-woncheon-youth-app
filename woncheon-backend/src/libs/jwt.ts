import jwt from 'jsonwebtoken';
import { requireEnv } from './env.js';

const JWT_SECRET = requireEnv('JWT_SECRET');
const JWT_REFRESH_SECRET = requireEnv('JWT_REFRESH_SECRET');

export interface TokenPayload {
  memberId: string;
  name: string;
}

function validatePayload(decoded: unknown): TokenPayload {
  if (
    typeof decoded !== 'object' ||
    decoded === null ||
    !('memberId' in decoded) ||
    !('name' in decoded) ||
    typeof (decoded as Record<string, unknown>).memberId !== 'string' ||
    typeof (decoded as Record<string, unknown>).name !== 'string' ||
    ((decoded as Record<string, unknown>).memberId as string).length === 0
  ) {
    throw new Error('Invalid token payload');
  }
  return {
    memberId: (decoded as Record<string, unknown>).memberId as string,
    name: (decoded as Record<string, unknown>).name as string,
  };
}

export function signAccessToken(payload: TokenPayload): string {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: '1h' });
}

export function signRefreshToken(payload: TokenPayload): string {
  return jwt.sign(payload, JWT_REFRESH_SECRET, { expiresIn: '30d' });
}

export function verifyAccessToken(token: string): TokenPayload {
  const decoded = jwt.verify(token, JWT_SECRET);
  return validatePayload(decoded);
}

export function verifyRefreshToken(token: string): TokenPayload {
  const decoded = jwt.verify(token, JWT_REFRESH_SECRET);
  return validatePayload(decoded);
}
