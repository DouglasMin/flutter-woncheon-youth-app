import type { APIGatewayProxyHandler } from 'aws-lambda';
import { QueryCommand } from '@aws-sdk/lib-dynamodb';
import { docClient, TABLE_NAME } from '../../libs/dynamo.js';
import { success } from '../../libs/response.js';

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

  const result = await docClient.send(
    new QueryCommand({
      TableName: TABLE_NAME,
      IndexName: 'GSI2',
      KeyConditionExpression: keyCondition,
      ExpressionAttributeValues: expressionValues,
      ScanIndexForward: false,
      Limit: limit,
      ExclusiveStartKey: exclusiveStartKey,
    }),
  );

  const items = (result.Items ?? []).map((item) => ({
    prayerId: item.prayerId as string,
    authorName: item.authorName as string,
    isAnonymous: item.isAnonymous as boolean,
    contentPreview:
      (item.content as string).length > 200
        ? (item.content as string).substring(0, 200) + '...'
        : item.content as string,
    createdAt: item.createdAt as string,
  }));

  const nextCursor = result.LastEvaluatedKey
    ? Buffer.from(JSON.stringify(result.LastEvaluatedKey)).toString('base64')
    : null;

  return success({
    items,
    nextCursor,
    hasMore: !!result.LastEvaluatedKey,
  });
};
