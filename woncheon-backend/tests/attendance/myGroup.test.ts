/**
 * Integration tests — GET /attendance/my-group
 *
 * Verifies:
 *  - Happy path: leader gets their group + member list
 *  - Non-leader gets 403 NOT_LEADER
 *  - No token gets 401
 *  - Response shape matches contract
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

const ENDPOINT = '/attendance/my-group';

// ─── Response shapes ──────────────────────────────────────────────────────────

interface GroupMember {
  member_id: string;
  member_name: string;
  note: string | null;
}

interface MyGroupData {
  group: { id: number; name: string };
  members: GroupMember[];
}

// ─── Token fixtures (obtained once per suite) ─────────────────────────────────

let leaderToken: string;
let memberToken: string;

beforeAll(async () => {
  [leaderToken, memberToken] = await Promise.all([
    login(LEADER_ACCOUNT.name, LEADER_ACCOUNT.password),
    login(MEMBER_ACCOUNT.name, MEMBER_ACCOUNT.password),
  ]);
}, 15_000);

// ─── Tests ────────────────────────────────────────────────────────────────────

describe('GET /attendance/my-group', () => {
  describe('happy path — leader', () => {
    it('returns HTTP 200', async () => {
      const res = await apiGet(ENDPOINT, leaderToken);
      expect(res.status).toBe(200);
    });

    it('returns success: true with group and members array', async () => {
      const res = await apiGet(ENDPOINT, leaderToken);
      const body = await parseBody<MyGroupData>(res);

      expect(body.success).toBe(true);
      if (!body.success) return; // type narrowing
      expect(body.data.group).toBeDefined();
      expect(body.data.members).toBeInstanceOf(Array);
    });

    it('group shape has id and name fields', async () => {
      const res = await apiGet(ENDPOINT, leaderToken);
      const body = await parseBody<MyGroupData>(res);
      if (!body.success) throw new Error('Expected success response');

      const { group } = body.data;
      expect(Number.isFinite(Number(group.id))).toBe(true);
      expect(typeof group.name).toBe('string');
      expect(group.name.length).toBeGreaterThan(0);
    });

    it('each member has member_id, member_name, and note fields', async () => {
      const res = await apiGet(ENDPOINT, leaderToken);
      const body = await parseBody<MyGroupData>(res);
      if (!body.success) throw new Error('Expected success response');

      const { members } = body.data;
      // The group should have at least one member
      expect(members.length).toBeGreaterThan(0);

      for (const member of members) {
        expect(typeof member.member_id).toBe('string');
        expect(typeof member.member_name).toBe('string');
        // note may be null or a string — never undefined
        expect('note' in member).toBe(true);
      }
    });

    it('members are returned in ascending name order', async () => {
      const res = await apiGet(ENDPOINT, leaderToken);
      const body = await parseBody<MyGroupData>(res);
      if (!body.success) throw new Error('Expected success response');

      const names = body.data.members.map((m) => m.member_name);
      const sorted = [...names].sort((a, b) => a.localeCompare(b, 'ko'));
      expect(names).toEqual(sorted);
    });
  });

  describe('error path — non-leader', () => {
    it('returns HTTP 403 when caller is not a leader', async () => {
      const res = await apiGet(ENDPOINT, memberToken);
      expect(res.status).toBe(403);
    });

    it('returns NOT_LEADER error code', async () => {
      const res = await apiGet(ENDPOINT, memberToken);
      const body = await parseBody<never>(res);

      expect(body.success).toBe(false);
      if (body.success) return;
      expect(body.error.code).toBe('NOT_LEADER');
    });
  });

  describe('error path — unauthenticated', () => {
    it('returns 401 or 403 with no token', async () => {
      const res = await fetch(`${BASE_URL}${ENDPOINT}`, { method: 'GET' });
      // API Gateway Authorizer returns 401 or 403 depending on deny policy
      expect([401, 403]).toContain(res.status);
    });

    it('returns 401 or 403 with a malformed token', async () => {
      const res = await apiGet(ENDPOINT, 'not.a.valid.jwt');
      expect([401, 403]).toContain(res.status);
    });
  });
});
