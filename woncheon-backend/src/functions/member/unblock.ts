import type { APIGatewayProxyHandler } from 'aws-lambda';
import { GetCommand, UpdateCommand } from '@aws-sdk/lib-dynamodb';
import { docClient, TABLE_NAME } from '../../libs/dynamo.js';
import { success, error } from '../../libs/response.js';
import { getMemberId, UNAUTHORIZED_RESPONSE } from '../../libs/auth-context.js';
import type { BlockedMember } from '../../types/member.js';

// DELETE /me/blocks/{memberId}
// 반환: { blockedMembers: BlockedMember[] }
export const handler: APIGatewayProxyHandler = async (event) => {
  const memberId = getMemberId(event);
  if (!memberId) return UNAUTHORIZED_RESPONSE;

  const rawTarget = event.pathParameters?.memberId;
  const targetId = typeof rawTarget === 'string' ? rawTarget.trim() : '';
  if (!targetId) {
    return error('VALIDATION_ERROR', '차단 해제할 사용자 ID가 필요합니다.', 400);
  }
  if (targetId.length > 64 || /[^A-Za-z0-9]/.test(targetId)) {
    return error('VALIDATION_ERROR', '잘못된 사용자 ID 형식입니다.', 400);
  }

  const current = await docClient.send(
    new GetCommand({
      TableName: TABLE_NAME,
      Key: { PK: `MEMBER#${memberId}`, SK: '#META' },
      ProjectionExpression: 'blockedMembers',
    }),
  );
  const existing =
    (current.Item?.blockedMembers as BlockedMember[] | undefined) ?? [];

  const next = existing.filter((b) => b.memberId !== targetId);
  if (next.length === existing.length) {
    // 이미 없는 상태 — idempotent
    return success({ blockedMembers: existing });
  }

  await docClient.send(
    new UpdateCommand({
      TableName: TABLE_NAME,
      Key: { PK: `MEMBER#${memberId}`, SK: '#META' },
      UpdateExpression: 'SET blockedMembers = :bm, updatedAt = :u',
      ExpressionAttributeValues: {
        ':bm': next,
        ':u': new Date().toISOString(),
      },
    }),
  );

  return success({ blockedMembers: next });
};
