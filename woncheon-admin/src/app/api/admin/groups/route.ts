import { NextResponse } from "next/server";
import { getPool } from "@/lib/db/pg";

export async function GET() {
  try {
    const pool = getPool();

    const result = await pool.query(
      `SELECT
         g.id,
         g.name,
         g.leader_member_id,
         COUNT(gm.member_id)::int AS member_count,
         COALESCE(
           ROUND(
             COUNT(CASE WHEN a.is_present THEN 1 END)::numeric
             / NULLIF(COUNT(a.id), 0) * 100, 1
           ), 0
         ) AS attendance_rate
       FROM groups g
       LEFT JOIN group_members gm ON g.id = gm.group_id
       LEFT JOIN attendance a
         ON gm.member_id = a.member_id
         AND a.group_id = g.id
         AND a.attendance_date >= CURRENT_DATE - INTERVAL '1 month'
       GROUP BY g.id, g.name, g.leader_member_id
       ORDER BY g.name`
    );

    const groups = result.rows.map((r) => ({
      id: Number(r.id),
      name: r.name,
      leaderMemberId: r.leader_member_id,
      memberCount: r.member_count,
      attendanceRate: Number(r.attendance_rate),
    }));

    return NextResponse.json({ groups });
  } catch (error: unknown) {
    const message =
      error instanceof Error ? error.message : "목장 목록을 불러올 수 없습니다.";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
