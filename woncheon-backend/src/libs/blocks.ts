import { GetCommand } from '@aws-sdk/lib-dynamodb';
import { docClient, TABLE_NAME } from './dynamo.js';
import type { BlockedMember } from '../types/member.js';

/**
 * 요청자의 차단 멤버 ID 집합을 조회.
 * prayer/comment 리스트 조회 시 서버 측 필터링에 사용.
 * 결과는 Set<memberId> — O(1) 조회.
 */
export async function getBlockedMemberIds(
  memberId: string,
): Promise<Set<string>> {
  const result = await docClient.send(
    new GetCommand({
      TableName: TABLE_NAME,
      Key: { PK: `MEMBER#${memberId}`, SK: '#META' },
      ProjectionExpression: 'blockedMembers',
    }),
  );
  const list =
    (result.Item?.blockedMembers as BlockedMember[] | undefined) ?? [];
  return new Set(list.map((b) => b.memberId));
}
