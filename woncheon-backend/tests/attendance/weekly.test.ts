/**
 * Integration tests — GET /attendance/weekly?date=<sunday>
 *
 * Verifies:
 *  - Happy path: leader queries a valid Sunday, gets group + members + attendance flags
 *  - Date is the most recent Sunday from helpers.lastSunday()
 *  - Also verifies the known historical Sunday 2026-03-30 (DB has real data)
 *  - Non-Sunday date gets 400 VALIDATION_ERROR
 *  - Missing date param gets 400 VALIDATION_ERROR
 *  - Invalid date string gets 400 VALIDATION_ERROR
 *  - Non-leader gets 403
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
  lastSunday,
  aMonday,
} from './helpers.js';

// ─── Response shapes ──────────────────────────────────────────────────────────

interface WeeklyMember {
  member_id: string;
  member_name: string;
  note: string | null;
  is_present: boolean;
}

interface WeeklyData {
  group: { id: number; name: string };
  date: string;
  members: WeeklyMember[];
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

describe('GET /attendance/weekly', () => {
  describe('happy path — valid Sunday', () => {
    it('returns HTTP 200 for the most recent Sunday', async () => {
      const res = await apiGet(
        `/attendance/weekly?date=${lastSunday()}`,
        leaderToken,
      );
      expect(res.status).toBe(200);
    });

    it('returns success: true with group, date, and members', async () => {
      const res = await apiGet(
        `/attendance/weekly?date=${lastSunday()}`,
        leaderToken,
      );
      const body = await parseBody<WeeklyData>(res);
      if (!body.success) throw new Error('Expected success response');

      expect(body.data.group).toBeDefined();
      expect(body.data.date).toBe(lastSunday());
      expect(body.data.members).toBeInstanceOf(Array);
    });

    it('each member entry has member_id, member_name, note, and is_present', async () => {
      const res = await apiGet(
        `/attendance/weekly?date=${lastSunday()}`,
        leaderToken,
      );
      const body = await parseBody<WeeklyData>(res);
      if (!body.success) throw new Error('Expected success response');

      const { members } = body.data;
      expect(members.length).toBeGreaterThan(0);

      for (const m of members) {
        expect(typeof m.member_id).toBe('string');
        expect(typeof m.member_name).toBe('string');
        expect('note' in m).toBe(true);
        expect(typeof m.is_present).toBe('boolean');
      }
    });

    it('is_present defaults to false for members with no attendance record', async () => {
      // Query a Sunday far in the past — no records should exist
      const pastSunday = '2000-01-02'; // a known Sunday with no data
      const res = await apiGet(
        `/attendance/weekly?date=${pastSunday}`,
        leaderToken,
      );
      const body = await parseBody<WeeklyData>(res);
      if (!body.success) throw new Error('Expected success response');

      const allAbsent = body.data.members.every((m) => m.is_present === false);
      expect(allAbsent).toBe(true);
    });

    it('returns correct data for the known historical date 2026-03-29', async () => {
      // DB has 557 attendance records — 2026-03-29 is a Sunday with real data
      const res = await apiGet(
        '/attendance/weekly?date=2026-03-29',
        leaderToken,
      );
      expect(res.status).toBe(200);

      const body = await parseBody<WeeklyData>(res);
      if (!body.success) throw new Error('Expected success response');

      expect(body.data.date).toBe('2026-03-29');
      // At least some members should be present given real DB data
      const presentCount = body.data.members.filter((m) => m.is_present).length;
      expect(presentCount).toBeGreaterThan(0);
    });

    it('members are returned in ascending name order', async () => {
      const res = await apiGet(
        `/attendance/weekly?date=${lastSunday()}`,
        leaderToken,
      );
      const body = await parseBody<WeeklyData>(res);
      if (!body.success) throw new Error('Expected success response');

      const names = body.data.members.map((m) => m.member_name);
      const sorted = [...names].sort((a, b) => a.localeCompare(b, 'ko'));
      expect(names).toEqual(sorted);
    });
  });

  describe('error path — invalid date', () => {
    it('returns 400 VALIDATION_ERROR for a non-Sunday (Monday)', async () => {
      const res = await apiGet(
        `/attendance/weekly?date=${aMonday()}`,
        leaderToken,
      );
      expect(res.status).toBe(400);
      const body = await parseBody<never>(res);
      if (body.success) throw new Error('Expected error response');
      expect(body.error.code).toBe('VALIDATION_ERROR');
    });

    it('returns 400 VALIDATION_ERROR for a Saturday (2026-03-28)', async () => {
      const res = await apiGet(
        '/attendance/weekly?date=2026-03-28',
        leaderToken,
      );
      expect(res.status).toBe(400);
      const body = await parseBody<never>(res);
      if (body.success) throw new Error('Expected error response');
      expect(body.error.code).toBe('VALIDATION_ERROR');
    });

    it('returns 400 for a completely invalid date string', async () => {
      const res = await apiGet(
        '/attendance/weekly?date=not-a-date',
        leaderToken,
      );
      expect(res.status).toBe(400);
    });

    it('returns 400 when date param is missing entirely', async () => {
      const res = await apiGet('/attendance/weekly', leaderToken);
      expect(res.status).toBe(400);
      const body = await parseBody<never>(res);
      if (body.success) throw new Error('Expected error response');
      expect(body.error.code).toBe('VALIDATION_ERROR');
    });
  });

  describe('error path — non-leader', () => {
    it('returns 403 NOT_LEADER for a regular member', async () => {
      const res = await apiGet(
        `/attendance/weekly?date=${lastSunday()}`,
        memberToken,
      );
      expect(res.status).toBe(403);
      const body = await parseBody<never>(res);
      if (body.success) throw new Error('Expected error response');
      expect(body.error.code).toBe('NOT_LEADER');
    });
  });

  describe('error path — unauthenticated', () => {
    it('returns 401 or 403 with no token', async () => {
      const res = await fetch(
        `${BASE_URL}/attendance/weekly?date=${lastSunday()}`,
        { method: 'GET' },
      );
      expect([401, 403]).toContain(res.status);
    });
  });
});
