import type { APIGatewayProxyHandler } from 'aws-lambda';
import { GetCommand, UpdateCommand } from '@aws-sdk/lib-dynamodb';
import bcrypt from 'bcryptjs';
import { docClient, TABLE_NAME } from '../../libs/dynamo.js';
import { success, error } from '../../libs/response.js';
import { parseBody, INVALID_BODY_RESPONSE } from '../../libs/parse-body.js';
import { getMemberId, UNAUTHORIZED_RESPONSE } from '../../libs/auth-context.js';
import type { Member } from '../../types/member.js';

export const handler: APIGatewayProxyHandler = async (event) => {
  const memberId = getMemberId(event);
  if (!memberId) return UNAUTHORIZED_RESPONSE;

  const body = parseBody(event.body);
  if (!body) return INVALID_BODY_RESPONSE;

  const { currentPassword, newPassword } = body as {
    currentPassword?: string;
    newPassword?: string;
  };

  if (!currentPassword || !newPassword) {
    return error('VALIDATION_ERROR', '현재 비밀번호와 새 비밀번호를 입력해주세요.', 400);
  }

  if (newPassword.length < 8) {
    return error('VALIDATION_ERROR', '8자 이상 입력해주세요.', 400);
  }

  const result = await docClient.send(
    new GetCommand({
      TableName: TABLE_NAME,
      Key: { PK: `MEMBER#${memberId}`, SK: '#META' },
    }),
  );

  const member = result.Item as Member | undefined;
  if (!member?.passwordHash) {
    return error('NOT_FOUND', '회원을 찾을 수 없습니다.', 404);
  }

  const isValid = await bcrypt.compare(currentPassword, member.passwordHash);
  if (!isValid) {
    return error('INVALID_CURRENT_PASSWORD', '현재 비밀번호가 올바르지 않습니다.', 400);
  }

  const isSame = await bcrypt.compare(newPassword, member.passwordHash);
  if (isSame) {
    return error('SAME_AS_CURRENT_PASSWORD', '기존 비밀번호와 다르게 설정해주세요.', 400);
  }

  const newHash = await bcrypt.hash(newPassword, 10);

  await docClient.send(
    new UpdateCommand({
      TableName: TABLE_NAME,
      Key: { PK: `MEMBER#${memberId}`, SK: '#META' },
      UpdateExpression:
        'SET passwordHash = :hash, isFirstLogin = :first, updatedAt = :now',
      ExpressionAttributeValues: {
        ':hash': newHash,
        ':first': false,
        ':now': new Date().toISOString(),
      },
    }),
  );

  return success({ message: '비밀번호가 변경되었습니다.' });
};
