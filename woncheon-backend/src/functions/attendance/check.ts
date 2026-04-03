import type { APIGatewayProxyHandler } from 'aws-lambda';
import { getPool } from '../../libs/pg.js';
import { success, error } from '../../libs/response.js';
import { parseBody, INVALID_BODY_RESPONSE } from '../../libs/parse-body.js';
import { getMemberId, UNAUTHORIZED_RESPONSE } from '../../libs/auth-context.js';

// POST /attendance/check — 출석 체크 (목자가 목원들 체크)
export const handler: APIGatewayProxyHandler = async (event) => {
  const memberId = getMemberId(event);
  if (!memberId) return UNAUTHORIZED_RESPONSE;

  const body = parseBody(event.body);
  if (!body) return INVALID_BODY_RESPONSE;

  const { date, records } = body as {
    date?: string;
    records?: Array<{ memberId: string; isPresent: boolean }>;
  };

  if (!date || !records || !Array.isArray(records)) {
    return error('VALIDATION_ERROR', 'date와 records가 필요합니다.', 400);
  }

  const pool = getPool();

  // 이 사용자가 목자인지 확인
  const groupResult = await pool.query(
    'SELECT id FROM groups WHERE leader_member_id = $1',
    [memberId],
  );

  if (groupResult.rows.length === 0) {
    return error('NOT_LEADER', '목자 권한이 없습니다.', 403);
  }

  const groupId = groupResult.rows[0].id;

  // 해당 목장 멤버인지 확인 후 출석 기록 upsert
  for (const record of records) {
    await pool.query(
      `INSERT INTO attendance (group_id, member_id, attendance_date, is_present, checked_by)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (member_id, attendance_date)
       DO UPDATE SET is_present = $4, checked_by = $5, updated_at = NOW()`,
      [groupId, record.memberId, date, record.isPresent, memberId],
    );
  }

  return success({ message: '출석이 저장되었습니다.', count: records.length });
};
