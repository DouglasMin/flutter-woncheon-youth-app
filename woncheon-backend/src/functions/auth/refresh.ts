import type { APIGatewayProxyHandler } from 'aws-lambda';
import { DeleteCommand, PutCommand } from '@aws-sdk/lib-dynamodb';
import { docClient, TABLE_NAME } from '../../libs/dynamo.js';
import {
  verifyRefreshToken,
  signAccessToken,
  signRefreshToken,
} from '../../libs/jwt.js';
import { success, error } from '../../libs/response.js';
import { parseBody, INVALID_BODY_RESPONSE } from '../../libs/parse-body.js';

export const handler: APIGatewayProxyHandler = async (event) => {
  const body = parseBody(event.body);
  if (!body) return INVALID_BODY_RESPONSE;

  const { refreshToken } = body as { refreshToken?: string };

  if (!refreshToken) {
    return error('VALIDATION_ERROR', 'Refresh Token이 필요합니다.', 400);
  }

  let payload;
  try {
    payload = verifyRefreshToken(refreshToken);
  } catch {
    return error('INVALID_REFRESH_TOKEN', '유효하지 않은 Refresh Token입니다.', 401);
  }

  // Atomic delete with condition — prevents race condition token reuse
  try {
    await docClient.send(
      new DeleteCommand({
        TableName: TABLE_NAME,
        Key: {
          PK: `MEMBER#${payload.memberId}`,
          SK: `TOKEN#${refreshToken}`,
        },
        ConditionExpression: 'attribute_exists(PK)',
      }),
    );
  } catch (err: unknown) {
    const name = (err as { name?: string })?.name;
    if (name === 'ConditionalCheckFailedException') {
      return error('REFRESH_TOKEN_EXPIRED', '만료된 Refresh Token입니다.', 401);
    }
    throw err;
  }

  const tokenPayload = { memberId: payload.memberId, name: payload.name };
  const newAccessToken = signAccessToken(tokenPayload);
  const newRefreshToken = signRefreshToken(tokenPayload);

  const expiresAt = Math.floor(Date.now() / 1000) + 30 * 24 * 60 * 60;
  await docClient.send(
    new PutCommand({
      TableName: TABLE_NAME,
      Item: {
        PK: `MEMBER#${payload.memberId}`,
        SK: `TOKEN#${newRefreshToken}`,
        memberId: payload.memberId,
        token: newRefreshToken,
        expiresAt,
        createdAt: new Date().toISOString(),
      },
    }),
  );

  return success({
    accessToken: newAccessToken,
    refreshToken: newRefreshToken,
  });
};
