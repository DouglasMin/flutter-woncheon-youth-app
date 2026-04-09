import { NextResponse } from "next/server";
import { getPool } from "@/lib/db/pg";

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const groupId = searchParams.get("groupId");
    const startDate = searchParams.get("startDate") ?? "2026-01-01";
    const endDate = searchParams.get("endDate") ?? "2026-12-31";

    const pool = getPool();

    let groupFilter = "";
    const params: (string | number)[] = [startDate, endDate];

    if (groupId) {
      groupFilter = "AND g.id = $3";
      params.push(Number(groupId));
    }

    const result = await pool.query(
      `SELECT
         g.id AS group_id,
         g.name AS group_name,
         gm.member_id,
         gm.member_name,
         a.attendance_date,
         COALESCE(a.is_present, FALSE) AS is_present
       FROM groups g
       JOIN group_members gm ON g.id = gm.group_id
       LEFT JOIN attendance a
         ON gm.member_id = a.member_id
         AND a.group_id = g.id
         AND a.attendance_date BETWEEN $1::date AND $2::date
       WHERE 1=1 ${groupFilter}
       ORDER BY g.name, gm.member_name, a.attendance_date`,
      params
    );

    // Get distinct dates
    const dates = await pool.query(
      `SELECT DISTINCT attendance_date
       FROM attendance
       WHERE attendance_date BETWEEN $1::date AND $2::date
       ORDER BY attendance_date`,
      [startDate, endDate]
    );

    // Get groups list
    const groups = await pool.query(
      "SELECT id, name FROM groups ORDER BY name"
    );

    // Pivot: group → members → dates → is_present
    interface PivotGroup {
      id: number;
      name: string;
      members: Array<{
        memberId: string;
        name: string;
        dates: Record<string, boolean>;
      }>;
    }

    const pivotMap = new Map<number, PivotGroup>();

    for (const row of result.rows) {
      const gid = Number(row.group_id);
      if (!pivotMap.has(gid)) {
        pivotMap.set(gid, {
          id: gid,
          name: row.group_name,
          members: [],
        });
      }

      const group = pivotMap.get(gid)!;
      let member = group.members.find((m) => m.memberId === row.member_id);
      if (!member) {
        member = { memberId: row.member_id, name: row.member_name, dates: {} };
        group.members.push(member);
      }

      if (row.attendance_date) {
        // pg returns DATE as JS Date object — convert safely without timezone shift
        const raw = row.attendance_date;
        const dateStr = raw instanceof Date
          ? `${raw.getFullYear()}-${String(raw.getMonth() + 1).padStart(2, '0')}-${String(raw.getDate()).padStart(2, '0')}`
          : String(raw).split('T')[0];
        member.dates[dateStr] = row.is_present;
      }
    }

    return NextResponse.json({
      groups: Array.from(pivotMap.values()),
      dates: dates.rows.map((r) => {
        const raw = r.attendance_date;
        if (raw instanceof Date) {
          return `${raw.getFullYear()}-${String(raw.getMonth() + 1).padStart(2, '0')}-${String(raw.getDate()).padStart(2, '0')}`;
        }
        return String(raw).split('T')[0];
      }),
      allGroups: groups.rows.map((r) => ({
        id: Number(r.id),
        name: r.name,
      })),
    });
  } catch (error: unknown) {
    const message =
      error instanceof Error ? error.message : "출결 데이터를 불러올 수 없습니다.";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
