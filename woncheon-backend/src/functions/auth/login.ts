import type { APIGatewayProxyHandler } from 'aws-lambda';
import { QueryCommand, PutCommand } from '@aws-sdk/lib-dynamodb';
import bcrypt from 'bcryptjs';
import { docClient, TABLE_NAME } from '../../libs/dynamo.js';
import { signAccessToken, signRefreshToken } from '../../libs/jwt.js';
import { success, error } from '../../libs/response.js';
import { parseBody, INVALID_BODY_RESPONSE } from '../../libs/parse-body.js';
import type { Member } from '../../types/member.js';

export const handler: APIGatewayProxyHandler = async (event) => {
  const body = parseBody(event.body);
  if (!body) return INVALID_BODY_RESPONSE;

  const { name, password } = body as { name?: string; password?: string };

  if (!name || !password) {
    return error('VALIDATION_ERROR', '이름과 비밀번호를 입력해주세요.', 400);
  }

  const result = await docClient.send(
    new QueryCommand({
      TableName: TABLE_NAME,
      IndexName: 'GSI1',
      KeyConditionExpression: 'GSI1PK = :pk AND GSI1SK = :sk',
      ExpressionAttributeValues: {
        ':pk': `NAME#${name}`,
        ':sk': '#META',
      },
    }),
  );

  const member = result.Items?.[0] as Member | undefined;
  if (!member?.passwordHash) {
    return error('MEMBER_NOT_FOUND', '등록된 청년부원이 아닙니다.', 401);
  }

  const isValidPassword = await bcrypt.compare(password, member.passwordHash);
  if (!isValidPassword) {
    return error('INVALID_PASSWORD', '비밀번호를 확인해주세요.', 401);
  }

  const tokenPayload = { memberId: member.memberId, name: member.name };
  const accessToken = signAccessToken(tokenPayload);
  const refreshToken = signRefreshToken(tokenPayload);

  const expiresAt = Math.floor(Date.now() / 1000) + 30 * 24 * 60 * 60;
  await docClient.send(
    new PutCommand({
      TableName: TABLE_NAME,
      Item: {
        PK: `MEMBER#${member.memberId}`,
        SK: `TOKEN#${refreshToken}`,
        memberId: member.memberId,
        token: refreshToken,
        expiresAt,
        createdAt: new Date().toISOString(),
      },
    }),
  );

  return success({
    accessToken,
    refreshToken,
    isFirstLogin: member.isFirstLogin,
    member: {
      memberId: member.memberId,
      name: member.name,
      blockedMembers: member.blockedMembers ?? [],
    },
  });
};
