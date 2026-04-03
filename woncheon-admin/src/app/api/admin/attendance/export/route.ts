import { NextResponse } from "next/server";
import { getPool } from "@/lib/db/pg";

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const startDate = searchParams.get("startDate") ?? "2026-01-01";
    const endDate = searchParams.get("endDate") ?? "2026-12-31";

    const pool = getPool();

    // Get distinct dates
    const datesResult = await pool.query(
      `SELECT DISTINCT attendance_date
       FROM attendance
       WHERE attendance_date BETWEEN $1::date AND $2::date
       ORDER BY attendance_date`,
      [startDate, endDate]
    );
    const dates = datesResult.rows.map((r) =>
      new Date(r.attendance_date).toISOString().split("T")[0]
    );

    // Get all attendance data
    const result = await pool.query(
      `SELECT
         g.name AS group_name,
         gm.member_name,
         a.attendance_date,
         COALESCE(a.is_present, FALSE) AS is_present
       FROM groups g
       JOIN group_members gm ON g.id = gm.group_id
       LEFT JOIN attendance a
         ON gm.member_id = a.member_id
         AND a.group_id = g.id
         AND a.attendance_date BETWEEN $1::date AND $2::date
       ORDER BY g.name, gm.member_name, a.attendance_date`,
      [startDate, endDate]
    );

    // Pivot to CSV
    interface MemberRow {
      group: string;
      name: string;
      dates: Record<string, boolean>;
    }

    const memberMap = new Map<string, MemberRow>();

    for (const row of result.rows) {
      const key = `${row.group_name}|${row.member_name}`;
      if (!memberMap.has(key)) {
        memberMap.set(key, {
          group: row.group_name,
          name: row.member_name,
          dates: {},
        });
      }
      if (row.attendance_date) {
        const dateStr = new Date(row.attendance_date).toISOString().split("T")[0];
        memberMap.get(key)!.dates[dateStr] = row.is_present;
      }
    }

    // Build CSV
    const header = ["목장", "이름", ...dates].join(",");
    const rows = Array.from(memberMap.values()).map((m) => {
      const cells = dates.map((d) =>
        m.dates[d] === true ? "O" : m.dates[d] === false ? "X" : ""
      );
      return [m.group, m.name, ...cells].join(",");
    });

    const csv = "\uFEFF" + [header, ...rows].join("\n"); // BOM for Excel Korean

    return new NextResponse(csv, {
      headers: {
        "Content-Type": "text/csv; charset=utf-8",
        "Content-Disposition": `attachment; filename=attendance-${startDate}-${endDate}.csv`,
      },
    });
  } catch (error: unknown) {
    const message =
      error instanceof Error ? error.message : "내보내기에 실패했습니다.";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
