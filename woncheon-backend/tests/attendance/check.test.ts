/**
 * Integration tests — POST /attendance/check
 *
 * Verifies:
 *  - Happy path: leader bulk-upserts attendance for own group members
 *  - Idempotency: calling twice with same data succeeds (upsert semantic)
 *  - Non-leader gets 403
 *  - Member ID from a different group gets 400 VALIDATION_ERROR
 *  - Missing body fields get 400 VALIDATION_ERROR
 *  - No token gets 401
 */

import { describe, it, expect, beforeAll } from 'vitest';
import {
  login,
  apiGet,
  apiPost,
  parseBody,
  LEADER_ACCOUNT,
  MEMBER_ACCOUNT,
  BASE_URL,
  lastSunday,
} from './helpers.js';

const ENDPOINT = '/attendance/check';
const MY_GROUP_ENDPOINT = '/attendance/my-group';

// ─── Response shapes ──────────────────────────────────────────────────────────

interface CheckData {
  message: string;
  count: number;
}

interface MyGroupData {
  group: { id: number; name: string };
  members: Array<{ member_id: string; member_name: string; note: string | null }>;
}

// ─── Token fixtures ───────────────────────────────────────────────────────────

let leaderToken: string;
let memberToken: string;

/** Real member IDs that belong to the leader's group (fetched once). */
let groupMemberIds: string[];

beforeAll(async () => {
  [leaderToken, memberToken] = await Promise.all([
    login(LEADER_ACCOUNT.name, LEADER_ACCOUNT.password),
    login(MEMBER_ACCOUNT.name, MEMBER_ACCOUNT.password),
  ]);

  // Fetch the leader's group members so we have valid IDs for POST body
  const groupRes = await apiGet(MY_GROUP_ENDPOINT, leaderToken);
  const groupBody = await parseBody<MyGroupData>(groupRes);
  if (!groupBody.success) {
    throw new Error(`Failed to fetch leader group: ${JSON.stringify(groupBody)}`);
  }
  groupMemberIds = groupBody.data.members.map((m) => m.member_id);
}, 20_000);

// ─── Tests ────────────────────────────────────────────────────────────────────

describe('POST /attendance/check', () => {
  describe('happy path — leader submits valid attendance', () => {
    it('returns HTTP 200 with count equal to submitted records', async () => {
      // Use the first two members to keep the write small
      const records = groupMemberIds.slice(0, 2).map((id, i) => ({
        memberId: id,
        isPresent: i === 0, // first present, second absent
      }));

      const res = await apiPost(
        ENDPOINT,
        { date: lastSunday(), records },
        leaderToken,
      );

      expect(res.status).toBe(200);
      const body = await parseBody<CheckData>(res);
      if (!body.success) throw new Error('Expected success response');
      expect(body.data.count).toBe(records.length);
    });

    it('returns a confirmation message string', async () => {
      const records = groupMemberIds.slice(0, 1).map((id) => ({
        memberId: id,
        isPresent: true,
      }));

      const res = await apiPost(
        ENDPOINT,
        { date: lastSunday(), records },
        leaderToken,
      );
      const body = await parseBody<CheckData>(res);
      if (!body.success) throw new Error('Expected success response');

      expect(typeof body.data.message).toBe('string');
      expect(body.data.message.length).toBeGreaterThan(0);
    });

    it('is idempotent — submitting the same records twice both succeed', async () => {
      const records = groupMemberIds.slice(0, 1).map((id) => ({
        memberId: id,
        isPresent: false,
      }));
      const payload = { date: lastSunday(), records };

      const res1 = await apiPost(ENDPOINT, payload, leaderToken);
      const res2 = await apiPost(ENDPOINT, payload, leaderToken);

      expect(res1.status).toBe(200);
      expect(res2.status).toBe(200);
    });

    it('accepts all members of the group in a single request', async () => {
      const records = groupMemberIds.map((id) => ({
        memberId: id,
        isPresent: true,
      }));

      const res = await apiPost(
        ENDPOINT,
        { date: lastSunday(), records },
        leaderToken,
      );

      expect(res.status).toBe(200);
      const body = await parseBody<CheckData>(res);
      if (!body.success) throw new Error('Expected success response');
      expect(body.data.count).toBe(groupMemberIds.length);
    });
  });

  describe('error path — member from a different group', () => {
    it('returns HTTP 400 VALIDATION_ERROR for a foreign memberId', async () => {
      // A clearly fabricated member ID that cannot belong to the leader's group
      const fakeId = 'MEMBER#DOES_NOT_EXIST_IN_THIS_GROUP';
      const res = await apiPost(
        ENDPOINT,
        {
          date: lastSunday(),
          records: [{ memberId: fakeId, isPresent: true }],
        },
        leaderToken,
      );

      expect(res.status).toBe(400);
      const body = await parseBody<never>(res);
      if (body.success) throw new Error('Expected error response');
      expect(body.error.code).toBe('VALIDATION_ERROR');
      // Error message should mention the offending ID
      expect(body.error.message).toContain(fakeId);
    });
  });

  describe('error path — missing or malformed body', () => {
    it('returns 400 when "date" is omitted', async () => {
      const records = groupMemberIds.slice(0, 1).map((id) => ({
        memberId: id,
        isPresent: true,
      }));

      const res = await apiPost(ENDPOINT, { records }, leaderToken);
      expect(res.status).toBe(400);
    });

    it('returns 400 when "records" is omitted', async () => {
      const res = await apiPost(
        ENDPOINT,
        { date: lastSunday() },
        leaderToken,
      );
      expect(res.status).toBe(400);
    });

    it('returns 400 when "records" is an empty array', async () => {
      const res = await apiPost(
        ENDPOINT,
        { date: lastSunday(), records: [] },
        leaderToken,
      );
      expect(res.status).toBe(400);
    });

    it('returns 400 when body is not JSON', async () => {
      const res = await fetch(`${BASE_URL}${ENDPOINT}`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${leaderToken}`,
          'Content-Type': 'application/json',
        },
        body: 'this is not json{{{',
      });
      expect(res.status).toBe(400);
    });
  });

  describe('error path — non-leader', () => {
    it('returns HTTP 403 NOT_LEADER', async () => {
      const res = await apiPost(
        ENDPOINT,
        {
          date: lastSunday(),
          records: [{ memberId: 'anything', isPresent: true }],
        },
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
      const res = await fetch(`${BASE_URL}${ENDPOINT}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ date: lastSunday(), records: [] }),
      });
      expect([401, 403]).toContain(res.status);
    });
  });
});
