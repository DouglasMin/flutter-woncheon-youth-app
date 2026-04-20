import type { APIGatewayProxyHandler } from 'aws-lambda';
import { QueryCommand } from '@aws-sdk/lib-dynamodb';
import { docClient, TABLE_NAME } from '../../libs/dynamo.js';
import { success } from '../../libs/response.js';
import { getMemberId } from '../../libs/auth-context.js';
import { getBlockedMemberIds } from '../../libs/blocks.js';

const VALID_CURSOR_KEYS = new Set(['PK', 'SK', 'GSI2PK', 'GSI2SK']);

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

function isValidISODate(str: string): boolean {
  const d = new Date(str);
  return !isNaN(d.getTime()) && str.length >= 10;
}

export const handler: APIGatewayProxyHandler = async (event) => {
  const limit = Math.min(
    Number(event.queryStringParameters?.limit ?? 20),
    50,
  );
  const exclusiveStartKey = parseCursor(
    event.queryStringParameters?.cursor ?? undefined,
  );

  // Date filter parameters
  const startDate = event.queryStringParameters?.startDate;
  const endDate = event.queryStringParameters?.endDate;

  // Optional memberIds filter (comma-separated).
  // Applied server-side after the GSI2 query so we can preserve anonymity
  // (clients never receive author memberId; the filter matches the DB field
  // even for isAnonymous:true items).
  const memberIdsRaw = event.queryStringParameters?.memberIds;
  const memberIdsSet = memberIdsRaw
    ? new Set(memberIdsRaw.split(',').map((s) => s.trim()).filter(Boolean))
    : null;

  // Build key condition
  let keyCondition = 'GSI2PK = :pk';
  const expressionValues: Record<string, unknown> = { ':pk': 'PRAYER_LIST' };

  if (startDate && isValidISODate(startDate) && endDate && isValidISODate(endDate)) {
    // Range: between startDate and endDate
    keyCondition += ' AND GSI2SK BETWEEN :start AND :end';
    expressionValues[':start'] = `${startDate}#`;
    expressionValues[':end'] = `${endDate}~`; // ~ sorts after all alphanumeric
  } else if (startDate && isValidISODate(startDate)) {
    // From startDate onwards
    keyCondition += ' AND GSI2SK >= :start';
    expressionValues[':start'] = `${startDate}#`;
  }

  // 요청자의 차단 목록 조회 (App Store Guideline 1.2 준수).
  // 익명 게시물이라도 DB 쪽 memberId는 알고 있으므로 서버가 선제적으로 필터.
  const requesterId = getMemberId(event);
  const blockedIds = requesterId
    ? await getBlockedMemberIds(requesterId)
    : new Set<string>();

  // When memberIds filter or block filter is active, fetch a wider page so we
  // don't return empty results just because the top-N by date contains no matches.
  const needsServerFilter = memberIdsSet || blockedIds.size > 0;
  const queryLimit = needsServerFilter ? Math.min(limit * 5, 100) : limit;

  const result = await docClient.send(
    new QueryCommand({
      TableName: TABLE_NAME,
      IndexName: 'GSI2',
      KeyConditionExpression: keyCondition,
      ExpressionAttributeValues: expressionValues,
      ScanIndexForward: false,
      Limit: queryLimit,
      ExclusiveStartKey: exclusiveStartKey,
    }),
  );

  let rawItems = result.Items ?? [];
  if (memberIdsSet) {
    rawItems = rawItems.filter((it) =>
      memberIdsSet.has(it.memberId as string),
    );
  }
  if (blockedIds.size > 0) {
    rawItems = rawItems.filter(
      (it) => !blockedIds.has(it.memberId as string),
    );
  }
  rawItems = rawItems.slice(0, limit);

  const items = rawItems.map((item) => ({
    prayerId: item.prayerId as string,
    authorName: item.authorName as string,
    isAnonymous: item.isAnonymous as boolean,
    contentPreview:
      (item.content as string).length > 200
        ? (item.content as string).substring(0, 200) + '...'
        : item.content as string,
    createdAt: item.createdAt as string,
  }));

  // 서버 필터 적용 후 결과가 limit보다 적으면 "더 없음"으로 간주.
  // (DDB에는 더 있을 수 있으나 대부분 차단/필터로 걸러질 가능성이 높고,
  //  그대로 hasMore:true를 반환하면 클라이언트가 빈 페이지를 무한 요청할 수 있음.)
  const hasMore = !!result.LastEvaluatedKey && items.length >= limit;
  const nextCursor =
    hasMore && result.LastEvaluatedKey
      ? Buffer.from(JSON.stringify(result.LastEvaluatedKey)).toString('base64')
      : null;

  return success({
    items,
    nextCursor,
    hasMore,
  });
};
