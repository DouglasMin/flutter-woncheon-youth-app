import type { APIGatewayProxyHandler } from 'aws-lambda';
import { getPool } from '../../libs/pg.js';
import { success, error } from '../../libs/response.js';
import { getMemberId, UNAUTHORIZED_RESPONSE } from '../../libs/auth-context.js';

// GET /attendance/weekly?date=2026-03-29 — 내 목장 주간 출석 현황
export const handler: APIGatewayProxyHandler = async (event) => {
  const memberId = getMemberId(event);
  if (!memberId) return UNAUTHORIZED_RESPONSE;

  const date = event.queryStringParameters?.date;
  if (!date) {
    return error('VALIDATION_ERROR', 'date 파라미터가 필요합니다.', 400);
  }

  // 일요일 검증
  const parsed = new Date(date);
  if (isNaN(parsed.getTime()) || parsed.getUTCDay() !== 0) {
    return error('VALIDATION_ERROR', '일요일 날짜만 가능합니다.', 400);
  }

  const pool = getPool();

  // 내 목장 조회
  const groupResult = await pool.query(
    'SELECT id, name FROM groups WHERE leader_member_id = $1',
    [memberId],
  );

  if (groupResult.rows.length === 0) {
    return error('NOT_LEADER', '목자 권한이 없습니다.', 403);
  }

  const group = groupResult.rows[0];

  // 해당 날짜의 출석 현황 (모든 멤버 표시, 미체크는 false)
  const result = await pool.query(
    `SELECT
       gm.member_id,
       gm.member_name,
       gm.note,
       COALESCE(a.is_present, FALSE) AS is_present
     FROM group_members gm
     LEFT JOIN attendance a
       ON gm.member_id = a.member_id
       AND a.group_id = gm.group_id
       AND a.attendance_date = $2
     WHERE gm.group_id = $1
     ORDER BY gm.member_name`,
    [group.id, date],
  );

  return success({
    group: { id: group.id, name: group.name },
    date,
    members: result.rows,
  });
};
