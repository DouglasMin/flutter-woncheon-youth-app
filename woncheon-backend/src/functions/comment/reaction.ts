import type { APIGatewayProxyHandler } from 'aws-lambda';
import { GetCommand, PutCommand, DeleteCommand, QueryCommand } from '@aws-sdk/lib-dynamodb';
import { docClient, TABLE_NAME } from '../../libs/dynamo.js';
import { success, error } from '../../libs/response.js';
import { getMemberId, UNAUTHORIZED_RESPONSE } from '../../libs/auth-context.js';

export const handler: APIGatewayProxyHandler = async (event) => {
  const memberId = getMemberId(event);
  if (!memberId) return UNAUTHORIZED_RESPONSE;

  const prayerId = event.pathParameters?.prayerId;
  if (!prayerId) return error('VALIDATION_ERROR', 'prayerId가 필요합니다.', 400);

  const key = {
    PK: `PRAYER#${prayerId}`,
    SK: `REACTION#${memberId}`,
  };

  // Check if already reacted
  const existing = await docClient.send(
    new GetCommand({ TableName: TABLE_NAME, Key: key }),
  );

  if (existing.Item) {
    // Remove reaction (toggle off)
    await docClient.send(
      new DeleteCommand({ TableName: TABLE_NAME, Key: key }),
    );
  } else {
    // Add reaction (toggle on)
    await docClient.send(
      new PutCommand({
        TableName: TABLE_NAME,
        Item: {
          ...key,
          prayerId,
          memberId,
          createdAt: new Date().toISOString(),
        },
      }),
    );
  }

  // Return current count
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
    reacted: !existing.Item,
    count: countResult.Count ?? 0,
  });
};
