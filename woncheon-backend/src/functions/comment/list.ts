import type { APIGatewayProxyHandler } from 'aws-lambda';
import { QueryCommand } from '@aws-sdk/lib-dynamodb';
import { docClient, TABLE_NAME } from '../../libs/dynamo.js';
import { success, error } from '../../libs/response.js';
import { getMemberId } from '../../libs/auth-context.js';
import { getBlockedMemberIds } from '../../libs/blocks.js';

export const handler: APIGatewayProxyHandler = async (event) => {
  const prayerId = event.pathParameters?.prayerId;
  if (!prayerId) return error('VALIDATION_ERROR', 'prayerId가 필요합니다.', 400);

  const requesterId = getMemberId(event);
  const blockedIds = requesterId
    ? await getBlockedMemberIds(requesterId)
    : new Set<string>();

  const result = await docClient.send(
    new QueryCommand({
      TableName: TABLE_NAME,
      KeyConditionExpression: 'PK = :pk AND begins_with(SK, :prefix)',
      ExpressionAttributeValues: {
        ':pk': `PRAYER#${prayerId}`,
        ':prefix': 'COMMENT#',
      },
      ScanIndexForward: true, // oldest first
    }),
  );

  const rows = result.Items ?? [];
  const filtered =
    blockedIds.size > 0
      ? rows.filter((it) => !blockedIds.has(it.memberId as string))
      : rows;

  const items = filtered.map((item) => ({
    commentId: item.commentId as string,
    authorName: item.authorName as string,
    content: item.content as string,
    createdAt: item.createdAt as string,
    memberId: item.memberId as string,
  }));

  return success({ items });
};
