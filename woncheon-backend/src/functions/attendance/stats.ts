import type { APIGatewayProxyHandler } from 'aws-lambda';
import { getPool } from '../../libs/pg.js';
import { success } from '../../libs/response.js';
import { getMemberId, UNAUTHORIZED_RESPONSE } from '../../libs/auth-context.js';

const VALID_PERIODS: Record<string, string> = {
  week: '7 days',
  month: '1 month',
  quarter: '3 months',
};

// GET /attendance/stats?period=month — 목장별 출석률 통계
export const handler: APIGatewayProxyHandler = async (event) => {
  const memberId = getMemberId(event);
  if (!memberId) return UNAUTHORIZED_RESPONSE;

  const periodParam = event.queryStringParameters?.period ?? 'month';
  const interval = VALID_PERIODS[periodParam] ?? '1 month';

  const pool = getPool();

  // 목장별 출석률: 분모 = 등록 멤버 수 × 기간 내 일요일 수
  const result = await pool.query(
    `WITH sundays AS (
       SELECT generate_series(
         (CURRENT_DATE - $1::interval)::date,
         CURRENT_DATE,
         '7 days'::interval
       )::date AS sunday
       WHERE EXTRACT(DOW FROM (CURRENT_DATE - $1::interval)::date) = 0
    ),
    adjusted_sundays AS (
       SELECT sunday FROM sundays
       UNION
       SELECT generate_series(
         -- find first sunday on or after start date
         (CURRENT_DATE - $1::interval)::date
           + ((7 - EXTRACT(DOW FROM (CURRENT_DATE - $1::interval)::date)::int) % 7),
         CURRENT_DATE,
         '7 days'::interval
       )::date AS sunday
    ),
    group_stats AS (
       SELECT
         g.id AS group_id,
         g.name AS group_name,
         COUNT(DISTINCT gm.member_id) AS member_count,
         (SELECT COUNT(DISTINCT sunday) FROM adjusted_sundays) AS sunday_count,
         COUNT(CASE WHEN a.is_present THEN 1 END) AS present_count
       FROM groups g
       JOIN group_members gm ON g.id = gm.group_id
       LEFT JOIN attendance a
         ON gm.member_id = a.member_id
         AND a.group_id = g.id
         AND a.attendance_date >= (CURRENT_DATE - $1::interval)::date
       WHERE g.name != '임원'
       GROUP BY g.id, g.name
    )
    SELECT
      group_id,
      group_name,
      present_count::int,
      (member_count * sunday_count)::int AS total_count,
      CASE WHEN member_count * sunday_count > 0
        THEN ROUND(present_count::numeric / (member_count * sunday_count) * 100, 1)
        ELSE 0
      END AS rate_percent
    FROM group_stats
    ORDER BY rate_percent DESC NULLS LAST`,
    [interval],
  );

  return success({
    period: periodParam,
    groups: result.rows,
  });
};
