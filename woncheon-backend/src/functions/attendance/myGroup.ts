import type { APIGatewayProxyHandler } from 'aws-lambda';
import { getPool } from '../../libs/pg.js';
import { success, error } from '../../libs/response.js';
import { getMemberId, UNAUTHORIZED_RESPONSE } from '../../libs/auth-context.js';

// GET /attendance/my-group — 내 목장 멤버 목록 (목자 전용)
export const handler: APIGatewayProxyHandler = async (event) => {
  const memberId = getMemberId(event);
  if (!memberId) return UNAUTHORIZED_RESPONSE;

  const pool = getPool();

  // 이 사용자가 목자인 목장 조회
  const groupResult = await pool.query(
    'SELECT id, name FROM groups WHERE leader_member_id = $1',
    [memberId],
  );

  if (groupResult.rows.length === 0) {
    return error('NOT_LEADER', '목자 권한이 없습니다.', 403);
  }

  const group = groupResult.rows[0];

  // 목원 목록
  const membersResult = await pool.query(
    `SELECT member_id, member_name, note
     FROM group_members
     WHERE group_id = $1
     ORDER BY member_name`,
    [group.id],
  );

  return success({
    group: { id: group.id, name: group.name },
    members: membersResult.rows,
  });
};
