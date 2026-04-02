import type { APIGatewayProxyHandler } from 'aws-lambda';
import { QueryCommand } from '@aws-sdk/lib-dynamodb';
import { docClient, TABLE_NAME } from '../../libs/dynamo.js';
import { success, error } from '../../libs/response.js';

export const handler: APIGatewayProxyHandler = async (event) => {
  const prayerId = event.pathParameters?.prayerId;
  if (!prayerId) return error('VALIDATION_ERROR', 'prayerId가 필요합니다.', 400);

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

  const items = (result.Items ?? []).map((item) => ({
    commentId: item.commentId as string,
    authorName: item.authorName as string,
    content: item.content as string,
    createdAt: item.createdAt as string,
    memberId: item.memberId as string,
  }));

  return success({ items });
};
