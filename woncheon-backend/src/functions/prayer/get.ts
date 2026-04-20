import type { APIGatewayProxyHandler } from 'aws-lambda';
import { GetCommand } from '@aws-sdk/lib-dynamodb';
import { docClient, TABLE_NAME } from '../../libs/dynamo.js';
import { success, error } from '../../libs/response.js';
import { getMemberId, UNAUTHORIZED_RESPONSE } from '../../libs/auth-context.js';
import type { PrayerRequest } from '../../types/prayer.js';

export const handler: APIGatewayProxyHandler = async (event) => {
  const memberId = getMemberId(event);
  if (!memberId) return UNAUTHORIZED_RESPONSE;

  const prayerId = event.pathParameters?.prayerId;
  if (!prayerId) {
    return error('VALIDATION_ERROR', 'prayerId가 필요합니다.', 400);
  }

  const result = await docClient.send(
    new GetCommand({
      TableName: TABLE_NAME,
      Key: { PK: `PRAYER#${prayerId}`, SK: '#META' },
    }),
  );

  const prayer = result.Item as PrayerRequest | undefined;
  if (!prayer?.prayerId) {
    return error('NOT_FOUND', '존재하지 않는 중보기도입니다.', 404);
  }

  return success({
    prayerId: prayer.prayerId,
    // 익명 게시물은 authorMemberId 노출 안 함 (anonymity 유지).
    // 실명 게시물에만 memberId를 포함해서 클라이언트가 차단 가능하게.
    authorMemberId: prayer.isAnonymous ? null : prayer.memberId,
    authorName: prayer.authorName,
    isAnonymous: prayer.isAnonymous,
    content: prayer.content,
    createdAt: prayer.createdAt,
    isMine: prayer.memberId === memberId,
  });
};
