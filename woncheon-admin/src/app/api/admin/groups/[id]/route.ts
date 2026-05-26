import { NextResponse } from "next/server";
import { getPool } from "@/lib/db/pg";

interface PatchBody {
  /// 새 목자 memberId. 그 목장의 멤버여야 함.
  leaderMemberId?: string;
  /// 목장명 변경 (목자명과 독립).
  name?: string;
}

// PATCH /api/admin/groups/[id]
//   - leaderMemberId: 같은 목장 멤버로만 목자 변경 가능
//   - name: 목장명 자유 편집 (목자명과 독립 — Q1 정책 C)
export async function PATCH(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const groupId = Number(id);
    if (!Number.isInteger(groupId)) {
      return NextResponse.json(
        { error: "유효하지 않은 목장 ID입니다." },
        { status: 400 }
      );
    }

    const body = (await request.json()) as PatchBody;
    const newLeaderId = body.leaderMemberId?.trim();
    const newName = body.name?.trim();

    if (!newLeaderId && !newName) {
      return NextResponse.json(
        { error: "변경할 항목(leaderMemberId 또는 name)이 필요합니다." },
        { status: 400 }
      );
    }

    const pool = getPool();

    // 목장 존재 확인
    const groupCheck = await pool.query(
      "SELECT id FROM groups WHERE id = $1",
      [groupId]
    );
    if (groupCheck.rows.length === 0) {
      return NextResponse.json(
        { error: "존재하지 않는 목장입니다." },
        { status: 404 }
      );
    }

    // 목자 변경 — 새 목자가 그 목장의 멤버인지 검증
    if (newLeaderId) {
      const memberCheck = await pool.query(
        `SELECT member_id FROM group_members
         WHERE group_id = $1 AND member_id = $2`,
        [groupId, newLeaderId]
      );
      if (memberCheck.rows.length === 0) {
        return NextResponse.json(
          { error: "새 목자는 해당 목장의 멤버여야 합니다." },
          { status: 400 }
        );
      }
      await pool.query(
        "UPDATE groups SET leader_member_id = $1, updated_at = NOW() WHERE id = $2",
        [newLeaderId, groupId]
      );
    }

    // 목장명 변경
    if (newName) {
      await pool.query(
        "UPDATE groups SET name = $1, updated_at = NOW() WHERE id = $2",
        [newName, groupId]
      );
    }

    return NextResponse.json({ success: true });
  } catch (error: unknown) {
    const message =
      error instanceof Error ? error.message : "목장 정보 변경에 실패했습니다.";
    // 목장명 unique 제약 위반
    if (message.includes("groups_name_key")) {
      return NextResponse.json(
        { error: "이미 같은 이름의 목장이 있습니다." },
        { status: 409 }
      );
    }
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
