/**
 * Integration tests — GET /attendance/stats?period=<period>
 *
 * Verifies:
 *  - Happy path: authenticated user gets group attendance stats
 *  - Available to both leaders AND regular members (no leader guard in handler)
 *  - Defaults to "month" when period param is absent
 *  - Valid periods: week, month, quarter
 *  - Unknown period falls back to "month" silently (VALID_PERIODS fallback in handler)
 *  - Response shape: { period, groups: [...] }
 *  - Each group row has expected numeric fields and a valid rate_percent (0–100)
 *  - 임원 group is excluded from results
 *  - Groups ordered descending by rate_percent
 *  - No token gets 401
 */

import { describe, it, expect, beforeAll } from 'vitest';
import {
  login,
  apiGet,
  parseBody,
  LEADER_ACCOUNT,
  MEMBER_ACCOUNT,
  BASE_URL,
} from './helpers.js';

// ─── Response shapes ──────────────────────────────────────────────────────────

interface StatsRow {
  group_id: number;
  group_name: string;
  present_count: number;
  total_count: number;
  /** ROUND() returns a numeric string from pg driver */
  rate_percent: string | number;
}

interface StatsData {
  period: string;
  groups: StatsRow[];
}

// ─── Assertion helper ─────────────────────────────────────────────────────────

function assertStatsRow(row: StatsRow): void {
  expect(Number.isFinite(Number(row.group_id))).toBe(true);
  expect(typeof row.group_name).toBe('string');
  expect(row.group_name.length).toBeGreaterThan(0);
  expect(Number(row.present_count)).toBeGreaterThanOrEqual(0);
  expect(Number(row.total_count)).toBeGreaterThanOrEqual(0);
  expect(Number(row.present_count)).toBeLessThanOrEqual(Number(row.total_count));
  const rate = Number(row.rate_percent);
  expect(rate).toBeGreaterThanOrEqual(0);
  expect(rate).toBeLessThanOrEqual(100);
}

// ─── Token fixtures ───────────────────────────────────────────────────────────

let leaderToken: string;
let memberToken: string;

beforeAll(async () => {
  [leaderToken, memberToken] = await Promise.all([
    login(LEADER_ACCOUNT.name, LEADER_ACCOUNT.password),
    login(MEMBER_ACCOUNT.name, MEMBER_ACCOUNT.password),
  ]);
}, 15_000);

// ─── Tests ────────────────────────────────────────────────────────────────────

describe('GET /attendance/stats', () => {
  describe('happy path — leader', () => {
    it('returns HTTP 200 with period=month', async () => {
      const res = await apiGet('/attendance/stats?period=month', leaderToken);
      expect(res.status).toBe(200);
    });

    it('returns success: true with period and groups array', async () => {
      const res = await apiGet('/attendance/stats?period=month', leaderToken);
      const body = await parseBody<StatsData>(res);
      if (!body.success) throw new Error('Expected success response');

      expect(body.data.period).toBe('month');
      expect(body.data.groups).toBeInstanceOf(Array);
    });

    it('returns at least one group (DB has 13 groups)', async () => {
      const res = await apiGet('/attendance/stats?period=month', leaderToken);
      const body = await parseBody<StatsData>(res);
      if (!body.success) throw new Error('Expected success response');

      expect(body.data.groups.length).toBeGreaterThan(0);
    });

    it('each group row matches the expected shape', async () => {
      const res = await apiGet('/attendance/stats?period=month', leaderToken);
      const body = await parseBody<StatsData>(res);
      if (!body.success) throw new Error('Expected success response');

      for (const row of body.data.groups) {
        assertStatsRow(row);
      }
    });

    it('groups are ordered by rate_percent descending', async () => {
      const res = await apiGet('/attendance/stats?period=month', leaderToken);
      const body = await parseBody<StatsData>(res);
      if (!body.success) throw new Error('Expected success response');

      const rates = body.data.groups.map((g) => Number(g.rate_percent));
      for (let i = 0; i < rates.length - 1; i++) {
        expect(rates[i]).toBeGreaterThanOrEqual(rates[i + 1]);
      }
    });

    it('excludes the "임원" group', async () => {
      const res = await apiGet('/attendance/stats?period=month', leaderToken);
      const body = await parseBody<StatsData>(res);
      if (!body.success) throw new Error('Expected success response');

      const names = body.data.groups.map((g) => g.group_name);
      expect(names).not.toContain('임원');
    });
  });

  describe('happy path — all valid period values', () => {
    const periods = ['week', 'month', 'quarter'] as const;

    for (const period of periods) {
      it(`returns 200 and echoes period="${period}"`, async () => {
        const res = await apiGet(
          `/attendance/stats?period=${period}`,
          leaderToken,
        );
        expect(res.status).toBe(200);
        const body = await parseBody<StatsData>(res);
        if (!body.success) throw new Error('Expected success response');
        expect(body.data.period).toBe(period);
      });
    }
  });

  describe('happy path — period param absent or unknown', () => {
    it('defaults to "month" when period param is absent', async () => {
      const res = await apiGet('/attendance/stats', leaderToken);
      expect(res.status).toBe(200);
      const body = await parseBody<StatsData>(res);
      if (!body.success) throw new Error('Expected success response');
      // handler: const periodParam = event.queryStringParameters?.period ?? 'month'
      expect(body.data.period).toBe('month');
    });

    it('unknown period falls back gracefully — still returns 200 with valid groups', async () => {
      // Handler defaults unknown periods to "1 month" interval internally.
      // The response echoes the raw period string ("century").
      const res = await apiGet(
        '/attendance/stats?period=century',
        leaderToken,
      );
      expect(res.status).toBe(200);
      const body = await parseBody<StatsData>(res);
      if (!body.success) throw new Error('Expected success response');
      expect(body.data.period).toBe('century');
      expect(body.data.groups).toBeInstanceOf(Array);
    });
  });

  describe('happy path — accessible to non-leader members', () => {
    it('returns 200 for a regular member (no leader guard in handler)', async () => {
      const res = await apiGet('/attendance/stats?period=month', memberToken);
      expect(res.status).toBe(200);
    });

    it('non-leader receives the same group list size as a leader', async () => {
      const [leaderRes, memberRes] = await Promise.all([
        apiGet('/attendance/stats?period=month', leaderToken),
        apiGet('/attendance/stats?period=month', memberToken),
      ]);
      const leaderBody = await parseBody<StatsData>(leaderRes);
      const memberBody = await parseBody<StatsData>(memberRes);
      if (!leaderBody.success || !memberBody.success) {
        throw new Error('Expected both responses to succeed');
      }

      expect(memberBody.data.groups.length).toBe(
        leaderBody.data.groups.length,
      );
    });
  });

  describe('error path — unauthenticated', () => {
    it('returns 401 or 403 with no token', async () => {
      const res = await fetch(
        `${BASE_URL}/attendance/stats?period=month`,
        { method: 'GET' },
      );
      expect([401, 403]).toContain(res.status);
    });

    it('returns 401 or 403 with a garbage token', async () => {
      const res = await apiGet('/attendance/stats?period=month', 'garbage');
      expect([401, 403]).toContain(res.status);
    });
  });
});
