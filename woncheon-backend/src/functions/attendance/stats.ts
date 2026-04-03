import type { APIGatewayProxyHandler } from 'aws-lambda';
import { getPool } from '../../libs/pg.js';
import { success, error } from '../../libs/response.js';
import { getMemberId, UNAUTHORIZED_RESPONSE } from '../../libs/auth-context.js';

// GET /attendance/stats?period=month — 목장별 출석률 통계
export const handler: APIGatewayProxyHandler = async (event) => {
  const memberId = getMemberId(event);
  if (!memberId) return UNAUTHORIZED_RESPONSE;

  const period = event.queryStringParameters?.period ?? 'month';

  const pool = getPool();

  let dateFilter: string;
  if (period === 'week') {
    dateFilter = "a.attendance_date >= CURRENT_DATE - INTERVAL '7 days'";
  } else if (period === 'quarter') {
    dateFilter = "a.attendance_date >= CURRENT_DATE - INTERVAL '3 months'";
  } else {
    // default: month
    dateFilter = "a.attendance_date >= CURRENT_DATE - INTERVAL '1 month'";
  }

  const result = await pool.query(
    `SELECT
       g.id AS group_id,
       g.name AS group_name,
       COUNT(CASE WHEN a.is_present THEN 1 END) AS present_count,
       COUNT(a.id) AS total_count,
       ROUND(
         COUNT(CASE WHEN a.is_present THEN 1 END)::NUMERIC
         / NULLIF(COUNT(a.id), 0) * 100, 1
       ) AS rate_percent
     FROM groups g
     JOIN group_members gm ON g.id = gm.group_id
     LEFT JOIN attendance a ON gm.member_id = a.member_id AND ${dateFilter}
     WHERE g.name != '임원'
     GROUP BY g.id, g.name
     ORDER BY rate_percent DESC NULLS LAST`,
  );

  return success({
    period,
    groups: result.rows,
  });
};
