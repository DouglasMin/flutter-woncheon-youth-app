import { NextResponse } from "next/server";
import {
  GetCommand,
  UpdateCommand,
  QueryCommand,
  BatchWriteCommand,
} from "@aws-sdk/lib-dynamodb";
import { docClient, TABLE_NAME } from "@/lib/db/dynamo";

type ReportAction = "dismiss" | "resolve" | "delete-and-resolve";

const VALID_ACTIONS: ReadonlyArray<ReportAction> = [
  "dismiss",
  "resolve",
  "delete-and-resolve",
];

interface PatchBody {
  action?: ReportAction;
  note?: string;
}

interface ReportItem {
  reportId: string;
  reporterMemberId: string;
  targetType: "prayer" | "comment";
  targetId: string;
  status: "pending" | "resolved" | "dismissed";
  createdAt: string;
}

// PATCH /api/admin/reports/[reportId]
//   body: { action: 'dismiss' | 'resolve' | 'delete-and-resolve', note?: string }
//
//   - dismiss: 신고만 닫음 (오신고/문제없음)
//   - resolve: 검토 완료 (별도 조치 없이)
//   - delete-and-resolve: 신고 대상 컨텐츠 삭제 + 신고 closed
//
//   상태 변경 시 GSI4SK도 함께 갱신해야 BeginsWith('pending#') 쿼리에서 빠짐.
export async function PATCH(
  request: Request,
  { params }: { params: Promise<{ reportId: string }> }
) {
  try {
    const { reportId } = await params;
    if (!reportId) {
      return NextResponse.json({ error: "reportId가 필요합니다." }, { status: 400 });
    }

    const body = (await request.json()) as PatchBody;
    const action = body.action;
    const note = (body.note ?? "").trim();

    if (!action || !VALID_ACTIONS.includes(action)) {
      return NextResponse.json(
        { error: `action은 ${VALID_ACTIONS.join(", ")} 중 하나여야 합니다.` },
        { status: 400 }
      );
    }

    // 신고 row 가져오기 (이미 처리된 신고 차단 + targetType/targetId 확인)
    const reportRes = await docClient.send(
      new GetCommand({
        TableName: TABLE_NAME,
        Key: { PK: `REPORT#${reportId}`, SK: "#META" },
      })
    );
    const report = reportRes.Item as ReportItem | undefined;
    if (!report) {
      return NextResponse.json(
        { error: "존재하지 않는 신고입니다." },
        { status: 404 }
      );
    }
    if (report.status !== "pending") {
      return NextResponse.json(
        { error: `이미 처리된 신고입니다 (현재 상태: ${report.status}).` },
        { status: 409 }
      );
    }

    let deletedItemCount = 0;

    // 컨텐츠 삭제 (delete-and-resolve)
    if (action === "delete-and-resolve") {
      if (report.targetType === "prayer") {
        deletedItemCount = await deletePrayerCascade(report.targetId);
      } else {
        // comment 신고는 현재 Flutter UI 미구현이라 백필 데이터 없음.
        // 추후 댓글 신고 추가될 때 parentPrayerId를 report row에 함께 저장하도록
        // 백엔드를 확장한 뒤 여기 구현 예정.
        return NextResponse.json(
          {
            error:
              "댓글 컨텐츠 삭제는 아직 지원되지 않습니다. 'resolve'로 처리하고 별도로 댓글 관리 화면에서 삭제해주세요.",
          },
          { status: 501 }
        );
      }
    }

    // 신고 row 상태 업데이트
    const newStatus: "resolved" | "dismissed" =
      action === "dismiss" ? "dismissed" : "resolved";
    const resolvedAt = new Date().toISOString();

    await docClient.send(
      new UpdateCommand({
        TableName: TABLE_NAME,
        Key: { PK: `REPORT#${reportId}`, SK: "#META" },
        UpdateExpression:
          "SET #s = :status, GSI4SK = :gsi4sk, resolvedAt = :ts, resolutionNote = :note, resolutionAction = :action",
        ConditionExpression: "#s = :pending",
        ExpressionAttributeNames: { "#s": "status" },
        ExpressionAttributeValues: {
          ":status": newStatus,
          ":gsi4sk": `${newStatus}#${report.createdAt}`,
          ":ts": resolvedAt,
          ":note": note,
          ":action": action,
          ":pending": "pending",
        },
      })
    );

    return NextResponse.json({
      success: true,
      reportId,
      newStatus,
      action,
      deletedItemCount,
    });
  } catch (error: unknown) {
    const message =
      error instanceof Error ? error.message : "신고 처리에 실패했습니다.";
    // ConditionalCheckFailed (이미 처리됨)
    if (message.includes("ConditionalCheckFailed")) {
      return NextResponse.json(
        { error: "이미 처리된 신고입니다." },
        { status: 409 }
      );
    }
    return NextResponse.json({ error: message }, { status: 500 });
  }
}

// PRAYER#{id}로 시작하는 모든 row(meta + comments + reactions) 삭제.
// 기존 /api/admin/prayers DELETE 핸들러와 동일한 cascade 패턴.
async function deletePrayerCascade(prayerId: string): Promise<number> {
  const items = await docClient.send(
    new QueryCommand({
      TableName: TABLE_NAME,
      KeyConditionExpression: "PK = :pk",
      ExpressionAttributeValues: { ":pk": `PRAYER#${prayerId}` },
      ProjectionExpression: "PK, SK",
    })
  );

  const allItems = items.Items ?? [];
  if (allItems.length === 0) return 0;

  const deleteRequests = allItems.map((item) => ({
    DeleteRequest: { Key: { PK: item.PK, SK: item.SK } },
  }));

  for (let i = 0; i < deleteRequests.length; i += 25) {
    const batch = deleteRequests.slice(i, i + 25);
    await docClient.send(
      new BatchWriteCommand({
        RequestItems: { [TABLE_NAME]: batch },
      })
    );
  }

  return deleteRequests.length;
}
