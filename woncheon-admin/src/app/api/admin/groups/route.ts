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
         lead.member_name AS leader_name,
         (SELECT COUNT(*)::int FROM group_members WHERE group_id = g.id) AS member_count,
         COALESCE(
           (SELECT ROUND(
             COUNT(CASE WHEN a.is_present THEN 1 END)::numeric
             / NULLIF(COUNT(*)::numeric, 0) * 100, 1
           )
           FROM attendance a
           JOIN group_members gm ON a.member_id = gm.member_id AND a.group_id = gm.group_id
           WHERE a.group_id = g.id
             AND a.attendance_date >= CURRENT_DATE - INTERVAL '1 month'
           ), 0
         ) AS attendance_rate
       FROM groups g
       LEFT JOIN group_members lead
         ON lead.group_id = g.id AND lead.member_id = g.leader_member_id
       ORDER BY g.name`
    );

    // 각 목장의 멤버 목록 (목자 변경 dropdown용)
    const membersResult = await pool.query(
      `SELECT group_id, member_id, member_name
       FROM group_members
       ORDER BY member_name`
    );
    const membersByGroup = new Map<
      number,
      Array<{ memberId: string; name: string }>
    >();
    for (const row of membersResult.rows) {
      const gid = Number(row.group_id);
      if (!membersByGroup.has(gid)) membersByGroup.set(gid, []);
      membersByGroup.get(gid)!.push({
        memberId: row.member_id,
        name: row.member_name,
      });
    }

    const groups = result.rows.map((r) => {
      const id = Number(r.id);
      return {
        id,
        name: r.name,
        leaderMemberId: r.leader_member_id,
        leaderName: r.leader_name ?? null,
        memberCount: r.member_count,
        attendanceRate: Number(r.attendance_rate),
        members: membersByGroup.get(id) ?? [],
      };
    });

    return NextResponse.json({ groups });
  } catch (error: unknown) {
    const message =
      error instanceof Error ? error.message : "목장 목록을 불러올 수 없습니다.";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
