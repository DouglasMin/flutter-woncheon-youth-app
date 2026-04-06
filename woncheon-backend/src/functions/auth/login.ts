import type { APIGatewayProxyHandler } from 'aws-lambda';
import { QueryCommand, PutCommand } from '@aws-sdk/lib-dynamodb';
import bcrypt from 'bcryptjs';
import { docClient, TABLE_NAME } from '../../libs/dynamo.js';
import { signAccessToken, signRefreshToken } from '../../libs/jwt.js';
import { success, error } from '../../libs/response.js';
import { parseBody, INVALID_BODY_RESPONSE } from '../../libs/parse-body.js';
import type { Member } from '../../types/member.js';

const RATE_LIMIT_WINDOW_MS = 60 * 1000;
const RATE_LIMIT_MAX_ATTEMPTS = 5;
const loginAttempts = new Map<string, number[]>();

function getClientIp(event: Parameters<APIGatewayProxyHandler>[0]): string {
  return (
    event.requestContext.identity?.sourceIp ??
    event.headers['x-forwarded-for']?.split(',')[0]?.trim() ??
    'unknown'
  );
}

function isRateLimited(ip: string): boolean {
  const now = Date.now();
  const attempts = (loginAttempts.get(ip) ?? []).filter(
    (timestamp) => now - timestamp < RATE_LIMIT_WINDOW_MS,
  );

  if (attempts.length >= RATE_LIMIT_MAX_ATTEMPTS) {
    loginAttempts.set(ip, attempts);
    return true;
  }

  attempts.push(now);
  loginAttempts.set(ip, attempts);
  return false;
}

export const handler: APIGatewayProxyHandler = async (event) => {
  const clientIp = getClientIp(event);
  if (isRateLimited(clientIp)) {
    return error('RATE_LIMITED', '잠시 후 다시 시도해주세요.', 429);
  }

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
    },
  });
};
