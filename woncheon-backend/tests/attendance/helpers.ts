/**
 * Shared helpers for attendance integration tests.
 *
 * All tests hit the LIVE deployed API — no mocking.
 * Tokens are obtained once per suite via /auth/login to avoid
 * repeated login round-trips inside each test.
 */

export const BASE_URL =
  'https://ul7b1ft3di.execute-api.ap-northeast-2.amazonaws.com/dev';

// ─── Account definitions ──────────────────────────────────────────────────────

/** 김지현: 목자 — owns a group in PostgreSQL */
export const LEADER_ACCOUNT = { name: '김지현', password: '11111111' };

/** 민동익: 목원 — not a leader */
export const MEMBER_ACCOUNT = { name: '민동익', password: '11111111' };

// ─── Generic API response types ───────────────────────────────────────────────

export interface ApiSuccess<T> {
  success: true;
  data: T;
}

export interface ApiError {
  success: false;
  error: { code: string; message: string };
}

export type ApiBody<T> = ApiSuccess<T> | ApiError;

/** Cast res.json() to a typed response body. */
export async function parseBody<T>(res: Response): Promise<ApiBody<T>> {
  return (await res.json()) as ApiBody<T>;
}

export interface LoginData {
  accessToken: string;
  refreshToken: string;
  isFirstLogin: boolean;
  member: { memberId: string; name: string };
}

// ─── HTTP helpers ─────────────────────────────────────────────────────────────

export async function apiGet(path: string, token: string): Promise<Response> {
  return fetch(`${BASE_URL}${path}`, {
    method: 'GET',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
  });
}

export async function apiPost(
  path: string,
  body: unknown,
  token?: string,
): Promise<Response> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  };
  if (token) headers['Authorization'] = `Bearer ${token}`;
  return fetch(`${BASE_URL}${path}`, {
    method: 'POST',
    headers,
    body: JSON.stringify(body),
  });
}

// ─── Auth helper ──────────────────────────────────────────────────────────────

/**
 * Login and return a valid access token.
 * Throws if login fails so the test suite fails fast and clearly.
 */
export async function login(name: string, password: string): Promise<string> {
  const res = await apiPost('/auth/login', { name, password });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Login failed for "${name}" (${res.status}): ${text}`);
  }
  const json = (await res.json()) as ApiSuccess<LoginData>;
  return json.data.accessToken;
}

// ─── Date helpers ─────────────────────────────────────────────────────────────

/**
 * Returns the most recent Sunday (or today if today is Sunday) in
 * YYYY-MM-DD format — used to build a valid weekly query date.
 */
export function lastSunday(): string {
  const d = new Date();
  d.setUTCDate(d.getUTCDate() - d.getUTCDay()); // rewind to Sunday
  return d.toISOString().slice(0, 10);
}

/**
 * Returns a Monday date string (never a valid Sunday for the weekly endpoint).
 */
export function aMonday(): string {
  const d = new Date();
  // walk forward until we land on a Monday (DOW = 1)
  while (d.getUTCDay() !== 1) d.setUTCDate(d.getUTCDate() + 1);
  return d.toISOString().slice(0, 10);
}
