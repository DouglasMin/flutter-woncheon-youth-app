import type { APIGatewayProxyHandler } from 'aws-lambda';
import { PutCommand, QueryCommand } from '@aws-sdk/lib-dynamodb';
import { ulid } from 'ulid';
import { docClient, TABLE_NAME } from '../../libs/dynamo.js';
import { success, error } from '../../libs/response.js';
import { parseBody, INVALID_BODY_RESPONSE } from '../../libs/parse-body.js';

// POST /auth/register-request — 새신자 가입 요청 (인증 불필요)
export const handler: APIGatewayProxyHandler = async (event) => {
  const body = parseBody(event.body);
  if (!body) return INVALID_BODY_RESPONSE;

  const { name, phone, note } = body as {
    name?: string;
    phone?: string;
    note?: string;
  };

  if (!name || name.trim().length === 0) {
    return error('VALIDATION_ERROR', '이름을 입력해주세요.', 400);
  }

  if (!phone || phone.trim().length === 0) {
    return error('VALIDATION_ERROR', '연락처를 입력해주세요.', 400);
  }

  // 이미 등록된 이름인지 확인
  const existing = await docClient.send(
    new QueryCommand({
      TableName: TABLE_NAME,
      IndexName: 'GSI1',
      KeyConditionExpression: 'GSI1PK = :pk AND GSI1SK = :sk',
      ExpressionAttributeValues: {
        ':pk': `NAME#${name.trim()}`,
        ':sk': '#META',
      },
    }),
  );

  if ((existing.Count ?? 0) > 0) {
    return error(
      'ALREADY_REGISTERED',
      '이미 등록된 이름입니다. 비밀번호를 잊으셨다면 관리자에게 문의해주세요.',
      409,
    );
  }

  const requestId = ulid();
  const createdAt = new Date().toISOString();

  await docClient.send(
    new PutCommand({
      TableName: TABLE_NAME,
      Item: {
        PK: `REGISTER_REQUEST#${requestId}`,
        SK: '#META',
        requestId,
        name: name.trim(),
        phone: phone.trim(),
        note: note?.trim() ?? '',
        status: 'pending',
        createdAt,
      },
    }),
  );

  return success(
    { requestId, message: '가입 요청이 접수되었습니다. 관리자 승인 후 이용 가능합니다.' },
    201,
  );
};
