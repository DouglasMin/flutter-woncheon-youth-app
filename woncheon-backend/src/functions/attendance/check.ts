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

  if (!date || !records || !Array.isArray(records) || records.length === 0) {
    return error('VALIDATION_ERROR', 'date와 records가 필요합니다.', 400);
  }

  const pool = getPool();

  // 서버에서 KST 기준 날짜 검증
  const validationResult = await pool.query(
    `SELECT
       EXTRACT(DOW FROM $1::date)::int AS date_dow,
       $1::date > CURRENT_DATE AS is_future,
       $1::date < (CURRENT_DATE - INTERVAL '28 days')::date AS is_too_old`,
    [date],
  );

  const { date_dow, is_future, is_too_old } = validationResult.rows[0];

  if (Number(date_dow) !== 0) {
    return error('VALIDATION_ERROR', '일요일 날짜만 가능합니다.', 400);
  }
  if (is_future) {
    return error('VALIDATION_ERROR', '미래 날짜에는 출석을 기록할 수 없습니다.', 400);
  }
  if (is_too_old) {
    return error('VALIDATION_ERROR', '4주 이전의 출석은 수정할 수 없습니다.', 400);
  }

  // 이 사용자가 목자인지 확인
  const groupResult = await pool.query(
    'SELECT id FROM groups WHERE leader_member_id = $1',
    [memberId],
  );

  if (groupResult.rows.length === 0) {
    return error('NOT_LEADER', '목자 권한이 없습니다.', 403);
  }

  const groupId = groupResult.rows[0].id;

  // 제출된 memberId가 이 목장 소속인지 검증
  const submittedIds = records.map((r) => r.memberId);
  const memberCheck = await pool.query(
    `SELECT member_id FROM group_members
     WHERE group_id = $1 AND member_id = ANY($2::text[])`,
    [groupId, submittedIds],
  );
  const validIds = new Set(memberCheck.rows.map((r) => r.member_id as string));
  const invalidIds = submittedIds.filter((id) => !validIds.has(id));

  if (invalidIds.length > 0) {
    return error(
      'VALIDATION_ERROR',
      `이 목장에 속하지 않는 멤버가 포함되어 있습니다: ${invalidIds.join(', ')}`,
      400,
    );
  }

  // 트랜잭션으로 배치 upsert
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const memberIds = records.map((r) => r.memberId);
    const presents = records.map((r) => r.isPresent);

    await client.query(
      `INSERT INTO attendance (group_id, member_id, attendance_date, is_present, checked_by)
       SELECT $1, unnest($2::text[]), $3::date, unnest($4::boolean[]), $5
       ON CONFLICT (group_id, member_id, attendance_date)
       DO UPDATE SET is_present = EXCLUDED.is_present,
                     checked_by = EXCLUDED.checked_by`,
      [groupId, memberIds, date, presents, memberId],
    );

    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }

  return success({ message: '출석이 저장되었습니다.', count: records.length, date });
};
