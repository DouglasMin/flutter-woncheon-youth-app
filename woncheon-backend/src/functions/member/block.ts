import type { APIGatewayProxyHandler } from 'aws-lambda';
import { GetCommand, UpdateCommand } from '@aws-sdk/lib-dynamodb';
import { docClient, TABLE_NAME } from '../../libs/dynamo.js';
import { success, error } from '../../libs/response.js';
import { parseBody, INVALID_BODY_RESPONSE } from '../../libs/parse-body.js';
import { getMemberId, UNAUTHORIZED_RESPONSE } from '../../libs/auth-context.js';
import type { BlockedMember } from '../../types/member.js';

// POST /me/blocks
// body: { memberId: string }
// 반환: { blockedMembers: BlockedMember[] }  (업데이트된 전체 목록)
//
// 차단 대상의 실제 이름은 서버에서 조회해서 저장한다. 클라이언트가 보낸 이름을
// 그대로 신뢰하지 않기 위함.
export const handler: APIGatewayProxyHandler = async (event) => {
  const memberId = getMemberId(event);
  if (!memberId) return UNAUTHORIZED_RESPONSE;

  const body = parseBody(event.body);
  if (!body) return INVALID_BODY_RESPONSE;

  const { memberId: rawTarget } = body as { memberId?: string };
  const targetId = typeof rawTarget === 'string' ? rawTarget.trim() : '';

  if (!targetId) {
    return error('VALIDATION_ERROR', '차단할 사용자 ID가 필요합니다.', 400);
  }
  // ULID 형식(26자 base32)에서 크게 벗어나면 거부 — DDB Key 주입 방지.
  if (targetId.length > 64 || /[^A-Za-z0-9]/.test(targetId)) {
    return error('VALIDATION_ERROR', '잘못된 사용자 ID 형식입니다.', 400);
  }
  if (targetId === memberId) {
    return error('VALIDATION_ERROR', '본인은 차단할 수 없습니다.', 400);
  }

  // 대상 사용자 실존 확인 + 이름 조회
  const target = await docClient.send(
    new GetCommand({
      TableName: TABLE_NAME,
      Key: { PK: `MEMBER#${targetId}`, SK: '#META' },
      ProjectionExpression: '#n, memberId',
      ExpressionAttributeNames: { '#n': 'name' },
    }),
  );
  const targetItem = target.Item as { memberId: string; name: string } | undefined;
  if (!targetItem) {
    return error('NOT_FOUND', '존재하지 않는 사용자입니다.', 404);
  }

  // 현재 blockedMembers 조회해서 중복 방지.
  // NOTE: GET → 계산 → UPDATE 패턴이라 동시 호출 시 last-write-wins로 항목이
  // 유실될 수 있음. 100명 규모에서 동시 차단은 사실상 발생하지 않으므로 MVP는
  // 이대로 유지. 규모 커지면 conditional UpdateExpression + list_append으로 전환.
  const current = await docClient.send(
    new GetCommand({
      TableName: TABLE_NAME,
      Key: { PK: `MEMBER#${memberId}`, SK: '#META' },
      ProjectionExpression: 'blockedMembers',
    }),
  );
  const existing =
    (current.Item?.blockedMembers as BlockedMember[] | undefined) ?? [];

  if (existing.some((b) => b.memberId === targetId)) {
    return success({ blockedMembers: existing });
  }

  const next: BlockedMember[] = [
    ...existing,
    { memberId: targetId, memberName: targetItem.name },
  ];

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
