import type { APIGatewayProxyHandler } from 'aws-lambda';
import { getPool } from '../../libs/pg.js';
import { success, error } from '../../libs/response.js';
import { getMemberId, UNAUTHORIZED_RESPONSE } from '../../libs/auth-context.js';

// GET /attendance/weekly?date=YYYY-MM-DD
// 본인 중심의 주간 출결 종합 데이터. 리더면 목장 roster도 포함.
export const handler: APIGatewayProxyHandler = async (event) => {
  const memberId = getMemberId(event);
  if (!memberId) return UNAUTHORIZED_RESPONSE;

  const date = event.queryStringParameters?.date;
  if (!date) {
    return error('VALIDATION_ERROR', 'date 파라미터가 필요합니다.', 400);
  }

  const parsed = new Date(date);
  if (isNaN(parsed.getTime()) || parsed.getUTCDay() !== 0) {
    return error('VALIDATION_ERROR', '일요일 날짜만 가능합니다.', 400);
  }

  const pool = getPool();

  // 1. 본인의 소속 목장 조회 (리더거나 일반 멤버거나 둘 다 cover)
  const membershipResult = await pool.query<{
    group_id: string;
    group_name: string;
    leader_member_id: string;
  }>(
    `SELECT g.id AS group_id, g.name AS group_name, g.leader_member_id
     FROM group_members gm
     JOIN groups g ON gm.group_id = g.id
     WHERE gm.member_id = $1
     LIMIT 1`,
    [memberId],
  );

  if (membershipResult.rows.length === 0) {
    return error('NOT_IN_GROUP', '소속된 목장이 없습니다.', 404);
  }

  const { group_id, group_name, leader_member_id } = membershipResult.rows[0];
  const isLeader = leader_member_id === memberId;

  // 2. 본인의 오늘(해당 주일) 출결 상태 + 체크한 리더 이름 조회
  const todayResult = await pool.query<{
    is_present: boolean;
    updated_at: string;
    checked_by: string;
    checked_by_name: string | null;
  }>(
    `SELECT a.is_present, a.updated_at, a.checked_by,
            cb.member_name AS checked_by_name
     FROM attendance a
     LEFT JOIN group_members cb
       ON cb.group_id = a.group_id AND cb.member_id = a.checked_by
     WHERE a.member_id = $1 AND a.attendance_date = $2
     LIMIT 1`,
    [memberId, date],
  );
  const todayRow = todayResult.rows[0];

  // 3. 본인의 최근 4주 히스토리 (현재 주일 포함 과거 방향)
  const historyResult = await pool.query<{
    date: string;
    is_present: boolean;
  }>(
    `WITH weeks AS (
       SELECT ($1::date - (n * INTERVAL '7 days'))::date AS week_date
       FROM generate_series(0, 3) AS n
     )
     SELECT w.week_date::text AS date,
            COALESCE(a.is_present, FALSE) AS is_present
     FROM weeks w
     LEFT JOIN attendance a
       ON a.member_id = $2 AND a.attendance_date = w.week_date
     ORDER BY w.week_date ASC`,
    [date, memberId],
  );

  // 4. 본인의 최근 12주 출석률 (분기 stat)
  const statsResult = await pool.query<{ present: string }>(
    `SELECT COUNT(*) FILTER (WHERE is_present = TRUE) AS present
     FROM attendance
     WHERE member_id = $1
       AND attendance_date > ($2::date - INTERVAL '84 days')
       AND attendance_date <= $2::date`,
    [memberId, date],
  );
  const presentWeeks = Number(statsResult.rows[0]?.present ?? 0);
  const totalWeeks = 12;
  const rate = Math.round((presentWeeks / totalWeeks) * 1000) / 10;

  // 5. 목장 전체 roster — 리더/멤버 공통.
  // 리더일 때만 각 멤버의 최근 12주 출석률도 함께 반환해서
  // "목원별 출석률 한눈에" UI를 만들 수 있게 한다.
  let members: Array<{
    member_id: string;
    member_name: string;
    note: string | null;
    is_present: boolean;
    present_weeks?: number;
    total_weeks?: number;
    rate?: number;
  }>;

  if (isLeader) {
    const membersResult = await pool.query<{
      member_id: string;
      member_name: string;
      note: string | null;
      is_present: boolean;
      present_weeks: string;
    }>(
      `SELECT gm.member_id,
              gm.member_name,
              gm.note,
              COALESCE(a.is_present, FALSE) AS is_present,
              (
                SELECT COUNT(*) FILTER (WHERE a2.is_present = TRUE)
                FROM attendance a2
                WHERE a2.member_id = gm.member_id
                  AND a2.attendance_date > ($2::date - INTERVAL '84 days')
                  AND a2.attendance_date <= $2::date
              ) AS present_weeks
       FROM group_members gm
       LEFT JOIN attendance a
         ON gm.member_id = a.member_id
         AND a.group_id = gm.group_id
         AND a.attendance_date = $2
       WHERE gm.group_id = $1
       ORDER BY gm.member_name`,
      [group_id, date],
    );
    members = membersResult.rows.map((r) => {
      const pw = Number(r.present_weeks);
      return {
        member_id: r.member_id,
        member_name: r.member_name,
        note: r.note,
        is_present: r.is_present,
        present_weeks: pw,
        total_weeks: 12,
        rate: Math.round((pw / 12) * 1000) / 10,
      };
    });
  } else {
    const membersResult = await pool.query<{
      member_id: string;
      member_name: string;
      note: string | null;
      is_present: boolean;
    }>(
      `SELECT gm.member_id,
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
      [group_id, date],
    );
    members = membersResult.rows;
  }

  return success({
    isLeader,
    group: { id: group_id, name: group_name },
    date,
    today: {
      isPresent: todayRow?.is_present ?? false,
      hasRecord: !!todayRow,
      markedBy: todayRow?.checked_by_name ?? null,
      markedAt: todayRow?.updated_at ?? null,
    },
    history: historyResult.rows.map((r) => ({
      date: r.date,
      isPresent: r.is_present,
    })),
    stats: {
      totalWeeks,
      presentWeeks,
      rate,
    },
    members,
  });
};
