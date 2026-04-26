import { NextResponse } from "next/server";
import { QueryCommand, BatchGetCommand } from "@aws-sdk/lib-dynamodb";
import { docClient, TABLE_NAME } from "@/lib/db/dynamo";

type ReportStatus = "pending" | "resolved" | "dismissed";

interface ReportRow {
  reportId: string;
  reporterMemberId: string;
  targetType: "prayer" | "comment";
  targetId: string;
  reason: string;
  status: ReportStatus;
  createdAt: string;
  resolvedAt?: string;
  resolvedBy?: string;
  resolutionNote?: string;
}

interface EnrichedReport extends ReportRow {
  reporterName: string | null;
  target: {
    exists: boolean;
    authorMemberId: string | null;
    authorName: string | null;
    isAnonymous: boolean | null;
    content: string | null;
    createdAt: string | null;
  };
}

const VALID_STATUSES: ReadonlyArray<ReportStatus | "all"> = [
  "pending",
  "resolved",
  "dismissed",
  "all",
];

// GET /api/admin/reports?status=pending|resolved|dismissed|all
//   기본: status=pending. GSI4(REPORT_LIST)로 조회 → 각 행에
//   신고자 이름 + 신고 대상(prayer) 본문을 BatchGet으로 join.
export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const statusParam = (searchParams.get("status") ?? "pending").toLowerCase();
    if (!VALID_STATUSES.includes(statusParam as ReportStatus | "all")) {
      return NextResponse.json(
        { error: `status는 ${VALID_STATUSES.join(", ")} 중 하나여야 합니다.` },
        { status: 400 }
      );
    }

    const queryInput = {
      TableName: TABLE_NAME,
      IndexName: "GSI4",
      KeyConditionExpression:
        statusParam === "all"
          ? "GSI4PK = :pk"
          : "GSI4PK = :pk AND begins_with(GSI4SK, :prefix)",
      ExpressionAttributeValues:
        statusParam === "all"
          ? { ":pk": "REPORT_LIST" }
          : { ":pk": "REPORT_LIST", ":prefix": `${statusParam}#` },
      ScanIndexForward: false, // 최신순
      Limit: 200,
    };

    const result = await docClient.send(new QueryCommand(queryInput));
    const items = (result.Items ?? []) as ReportRow[];

    if (items.length === 0) {
      return NextResponse.json({ reports: [], total: 0 });
    }

    // 신고자 이름과 prayer 본문을 BatchGet으로 한 번에 가져옴
    const memberKeys = new Set<string>();
    const prayerKeys = new Set<string>();
    for (const r of items) {
      memberKeys.add(r.reporterMemberId);
      if (r.targetType === "prayer") prayerKeys.add(r.targetId);
    }

    const batchKeys: { PK: string; SK: string }[] = [];
    for (const id of memberKeys) batchKeys.push({ PK: `MEMBER#${id}`, SK: "#META" });
    for (const id of prayerKeys) batchKeys.push({ PK: `PRAYER#${id}`, SK: "#META" });

    const memberMap = new Map<string, { name: string }>();
    const prayerMap = new Map<
      string,
      {
        memberId: string;
        authorName: string;
        isAnonymous: boolean;
        content: string;
        createdAt: string;
      }
    >();

    // BatchGet 한 번에 100건 제한 — 본 화면은 200건/페이지라 분할 처리
    for (let i = 0; i < batchKeys.length; i += 100) {
      const slice = batchKeys.slice(i, i + 100);
      const batch = await docClient.send(
        new BatchGetCommand({
          RequestItems: { [TABLE_NAME]: { Keys: slice } },
        })
      );
      const got = batch.Responses?.[TABLE_NAME] ?? [];
      for (const item of got) {
        if (typeof item.PK === "string" && item.PK.startsWith("MEMBER#")) {
          memberMap.set(item.PK.slice("MEMBER#".length), {
            name: (item.name as string) ?? "",
          });
        } else if (typeof item.PK === "string" && item.PK.startsWith("PRAYER#")) {
          prayerMap.set(item.PK.slice("PRAYER#".length), {
            memberId: item.memberId as string,
            authorName: (item.authorName as string) ?? "",
            isAnonymous: Boolean(item.isAnonymous),
            content: (item.content as string) ?? "",
            createdAt: (item.createdAt as string) ?? "",
          });
        }
      }
    }

    const reports: EnrichedReport[] = items.map((r) => {
      const reporter = memberMap.get(r.reporterMemberId);
      let target: EnrichedReport["target"];
      if (r.targetType === "prayer") {
        const p = prayerMap.get(r.targetId);
        target = p
          ? {
              exists: true,
              authorMemberId: p.memberId,
              authorName: p.authorName,
              isAnonymous: p.isAnonymous,
              content: p.content,
              createdAt: p.createdAt,
            }
          : {
              exists: false,
              authorMemberId: null,
              authorName: null,
              isAnonymous: null,
              content: null,
              createdAt: null,
            };
      } else {
        // comment 신고는 Flutter UI 미구현 — 본문 fetch 보류
        target = {
          exists: false,
          authorMemberId: null,
          authorName: null,
          isAnonymous: null,
          content: null,
          createdAt: null,
        };
      }
      return {
        ...r,
        reporterName: reporter?.name ?? null,
        target,
      };
    });

    return NextResponse.json({ reports, total: reports.length });
  } catch (error: unknown) {
    const message =
      error instanceof Error ? error.message : "신고 목록을 불러올 수 없습니다.";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
