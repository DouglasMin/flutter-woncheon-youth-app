import type { APIGatewayProxyHandler } from 'aws-lambda';
import { QueryCommand } from '@aws-sdk/lib-dynamodb';
import { docClient, TABLE_NAME } from '../../libs/dynamo.js';
import { success } from '../../libs/response.js';
import type { NoticeRecord } from '../../types/notice.js';
import { toNoticeListItem } from '../../types/notice.js';

const VALID_CURSOR_KEYS = new Set(['PK', 'SK', 'GSI2PK', 'GSI2SK']);

function encodeCursor(key: Record<string, unknown>): string {
  return Buffer.from(JSON.stringify(key)).toString('base64');
}

function cursorKeyFromNotice(
  notice: NoticeRecord | undefined,
): Record<string, string> | undefined {
  if (!notice) return undefined;
  const { PK, SK, GSI2PK, GSI2SK } = notice;
  if (
    typeof PK !== 'string' ||
    typeof SK !== 'string' ||
    typeof GSI2PK !== 'string' ||
    typeof GSI2SK !== 'string'
  ) {
    return undefined;
  }
  return { PK, SK, GSI2PK, GSI2SK };
}

function parseCursor(
  cursorParam: string | undefined,
): Record<string, unknown> | undefined {
  if (!cursorParam) return undefined;

  try {
    const parsed = JSON.parse(
      Buffer.from(cursorParam, 'base64').toString('utf-8'),
    ) as unknown;

    if (typeof parsed !== 'object' || parsed === null || Array.isArray(parsed)) {
      return undefined;
    }

    const obj = parsed as Record<string, unknown>;
    const keys = Object.keys(obj);
    if (keys.length !== VALID_CURSOR_KEYS.size) return undefined;

    for (const key of keys) {
      if (!VALID_CURSOR_KEYS.has(key)) return undefined;
      if (typeof obj[key] !== 'string') return undefined;
    }

    return obj;
  } catch {
    return undefined;
  }
}

function parseLimit(limitParam: string | undefined): number {
  const parsed = Number(limitParam ?? 20);
  if (!Number.isFinite(parsed) || parsed < 1) return 20;
  return Math.min(Math.floor(parsed), 50);
}

export const handler: APIGatewayProxyHandler = async (event) => {
  const limit = parseLimit(event.queryStringParameters?.limit);
  const queryLimit = Math.min(limit * 3, 100);
  const exclusiveStartKey = parseCursor(
    event.queryStringParameters?.cursor ?? undefined,
  );

  const result = await docClient.send(
    new QueryCommand({
      TableName: TABLE_NAME,
      IndexName: 'GSI2',
      KeyConditionExpression: 'GSI2PK = :pk',
      FilterExpression: '#status = :published',
      ExpressionAttributeNames: { '#status': 'status' },
      ExpressionAttributeValues: {
        ':pk': 'NOTICE_LIST',
        ':published': 'published',
      },
      ScanIndexForward: false,
      Limit: queryLimit,
      ExclusiveStartKey: exclusiveStartKey,
    }),
  );

  const publishedRecords = ((result.Items ?? []) as NoticeRecord[]).filter(
    (item) => item.status === 'published',
  );
  const pageRecords = publishedRecords.slice(0, limit);
  const items = pageRecords.map(toNoticeListItem);
  const overflowCursorKey =
    publishedRecords.length > limit
      ? cursorKeyFromNotice(pageRecords[pageRecords.length - 1])
      : undefined;
  const nextCursorKey = overflowCursorKey ?? result.LastEvaluatedKey;
  const nextCursor = nextCursorKey ? encodeCursor(nextCursorKey) : null;

  return success({
    items,
    nextCursor,
    hasMore: Boolean(nextCursor),
  });
};
