import { NextResponse } from "next/server";
import { getPool } from "@/lib/db/pg";

interface PatchBody {
  /// 이동할 목장 id.
  groupId?: number;
}

// PATCH /api/admin/members/[memberId]/group
//   목원을 다른 목장으로 이동.
//   - Q3 정책 A: 어느 목장의 목자인 사람은 이동 차단 (먼저 목자 교체 필요).
//   - Q2 정책 A: 과거 attendance 기록은 옛 group_id 그대로 둠 (이 쿼리는
//     group_members.group_id만 변경하므로 자동으로 과거 출석은 보존됨).
export async function PATCH(
  request: Request,
  { params }: { params: Promise<{ memberId: string }> }
) {
  try {
    const { memberId } = await params;
    if (!memberId) {
      return NextResponse.json(
        { error: "memberId가 필요합니다." },
        { status: 400 }
      );
    }

    const body = (await request.json()) as PatchBody;
    const newGroupId = body.groupId;
    if (!Number.isInteger(newGroupId)) {
      return NextResponse.json(
        { error: "유효한 groupId가 필요합니다." },
        { status: 400 }
      );
    }

    const pool = getPool();

    // 이동할 목장 존재 확인
    const groupCheck = await pool.query("SELECT id FROM groups WHERE id = $1", [
      newGroupId,
    ]);
    if (groupCheck.rows.length === 0) {
      return NextResponse.json(
        { error: "존재하지 않는 목장입니다." },
        { status: 404 }
      );
    }

    // 멤버십 + 목자 여부 확인
    const memberRow = await pool.query(
      `SELECT gm.group_id, gm.member_name,
              (g.leader_member_id = gm.member_id) AS is_leader
       FROM group_members gm
       JOIN groups g ON g.id = gm.group_id
       WHERE gm.member_id = $1`,
      [memberId]
    );
    if (memberRow.rows.length === 0) {
      return NextResponse.json(
        { error: "목장에 배정된 회원이 아닙니다." },
        { status: 404 }
      );
    }

    const current = memberRow.rows[0];
    if (Number(current.group_id) === newGroupId) {
      return NextResponse.json(
        { error: "이미 해당 목장에 속해 있습니다." },
        { status: 409 }
      );
    }

    // Q3 — 목자는 이동 차단
    if (current.is_leader) {
      return NextResponse.json(
        {
          error:
            "이 회원은 목장의 목자입니다. 먼저 다른 사람으로 목자를 교체한 뒤 이동시켜주세요.",
        },
        { status: 409 }
      );
    }

    // group_members.group_id만 변경 — 과거 attendance(group_id)는 그대로 보존.
    await pool.query(
      "UPDATE group_members SET group_id = $1 WHERE member_id = $2",
      [newGroupId, memberId]
    );

    return NextResponse.json({ success: true });
  } catch (error: unknown) {
    const message =
      error instanceof Error ? error.message : "목장 이동에 실패했습니다.";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
