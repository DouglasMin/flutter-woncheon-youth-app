import { NextResponse } from "next/server";
import { QueryCommand, DeleteCommand, BatchWriteCommand } from "@aws-sdk/lib-dynamodb";
import { docClient, TABLE_NAME } from "@/lib/db/dynamo";

export async function GET() {
  try {
    const result = await docClient.send(
      new QueryCommand({
        TableName: TABLE_NAME,
        IndexName: "GSI2",
        KeyConditionExpression: "GSI2PK = :pk",
        ExpressionAttributeValues: { ":pk": "PRAYER_LIST" },
        ScanIndexForward: false,
        Limit: 100,
      })
    );

    const prayers = (result.Items ?? []).map((item) => ({
      prayerId: item.prayerId,
      authorName: item.authorName,
      isAnonymous: item.isAnonymous,
      memberId: item.memberId, // Admin can see real author
      content: item.content,
      createdAt: item.createdAt,
    }));

    return NextResponse.json({ prayers });
  } catch (error: unknown) {
    const message =
      error instanceof Error ? error.message : "기도 목록을 불러올 수 없습니다.";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}

// Admin delete prayer (with comments/reactions cleanup)
export async function DELETE(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const prayerId = searchParams.get("prayerId");

    if (!prayerId) {
      return NextResponse.json(
        { error: "prayerId가 필요합니다." },
        { status: 400 }
      );
    }

    // Find all items with this prayer PK (meta + comments + reactions)
    const items = await docClient.send(
      new QueryCommand({
        TableName: TABLE_NAME,
        KeyConditionExpression: "PK = :pk",
        ExpressionAttributeValues: { ":pk": `PRAYER#${prayerId}` },
        ProjectionExpression: "PK, SK",
      })
    );

    if (!items.Items || items.Items.length === 0) {
      return NextResponse.json(
        { error: "존재하지 않는 기도입니다." },
        { status: 404 }
      );
    }

    // Batch delete all related items
    const deleteRequests = items.Items.map((item) => ({
      DeleteRequest: {
        Key: { PK: item.PK, SK: item.SK },
      },
    }));

    // DynamoDB batch write limit is 25
    for (let i = 0; i < deleteRequests.length; i += 25) {
      const batch = deleteRequests.slice(i, i + 25);
      await docClient.send(
        new BatchWriteCommand({
          RequestItems: { [TABLE_NAME]: batch },
        })
      );
    }

    return NextResponse.json({
      success: true,
      deletedCount: deleteRequests.length,
    });
  } catch (error: unknown) {
    const message =
      error instanceof Error ? error.message : "삭제에 실패했습니다.";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
