import type { APIGatewayProxyHandler } from 'aws-lambda';
import { GetCommand, QueryCommand } from '@aws-sdk/lib-dynamodb';
import { docClient, TABLE_NAME } from '../../libs/dynamo.js';
import { success, error } from '../../libs/response.js';
import { getMemberId, UNAUTHORIZED_RESPONSE } from '../../libs/auth-context.js';

export const handler: APIGatewayProxyHandler = async (event) => {
  const memberId = getMemberId(event);
  if (!memberId) return UNAUTHORIZED_RESPONSE;

  const prayerId = event.pathParameters?.prayerId;
  if (!prayerId) return error('VALIDATION_ERROR', 'prayerId가 필요합니다.', 400);

  // Check if this user reacted
  const existing = await docClient.send(
    new GetCommand({
      TableName: TABLE_NAME,
      Key: {
        PK: `PRAYER#${prayerId}`,
        SK: `REACTION#${memberId}`,
      },
    }),
  );

  // Get total count
  const countResult = await docClient.send(
    new QueryCommand({
      TableName: TABLE_NAME,
      KeyConditionExpression: 'PK = :pk AND begins_with(SK, :prefix)',
      ExpressionAttributeValues: {
        ':pk': `PRAYER#${prayerId}`,
        ':prefix': 'REACTION#',
      },
      Select: 'COUNT',
    }),
  );

  return success({
    reacted: !!existing.Item,
    count: countResult.Count ?? 0,
  });
};
