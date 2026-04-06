import type { APIGatewayProxyHandler } from 'aws-lambda';
import { PutCommand } from '@aws-sdk/lib-dynamodb';
import { ulid } from 'ulid';
import { docClient, TABLE_NAME } from '../../libs/dynamo.js';
import { success, error } from '../../libs/response.js';
import { parseBody, INVALID_BODY_RESPONSE } from '../../libs/parse-body.js';
import { getMemberId, UNAUTHORIZED_RESPONSE } from '../../libs/auth-context.js';

// POST /report — 기도/댓글 신고
export const handler: APIGatewayProxyHandler = async (event) => {
  const memberId = getMemberId(event);
  if (!memberId) return UNAUTHORIZED_RESPONSE;

  const body = parseBody(event.body);
  if (!body) return INVALID_BODY_RESPONSE;

  const { targetType, targetId, reason } = body as {
    targetType?: string; // 'prayer' | 'comment'
    targetId?: string;
    reason?: string;
  };

  if (!targetType || !targetId) {
    return error('VALIDATION_ERROR', 'targetType과 targetId가 필요합니다.', 400);
  }

  if (!['prayer', 'comment'].includes(targetType)) {
    return error('VALIDATION_ERROR', 'targetType은 prayer 또는 comment만 가능합니다.', 400);
  }

  const reportId = ulid();
  const createdAt = new Date().toISOString();

  await docClient.send(
    new PutCommand({
      TableName: TABLE_NAME,
      Item: {
        PK: `REPORT#${reportId}`,
        SK: '#META',
        GSI2PK: 'REPORT_LIST',
        GSI2SK: `${memberId}#${createdAt}#${reportId}`,
        reportId,
        reporterMemberId: memberId,
        targetType,
        targetId,
        reason: reason ?? '',
        status: 'pending',
        createdAt,
      },
    }),
  );

  return success({ reportId, message: '신고가 접수되었습니다.' }, 201);
};
