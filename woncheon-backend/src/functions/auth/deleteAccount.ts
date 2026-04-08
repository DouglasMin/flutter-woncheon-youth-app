import type { APIGatewayProxyHandler } from 'aws-lambda';
import { QueryCommand, DeleteCommand } from '@aws-sdk/lib-dynamodb';
import { docClient, TABLE_NAME } from '../../libs/dynamo.js';
import { deleteItemsByPK } from '../../libs/batch-delete.js';
import { success, error } from '../../libs/response.js';
import { getMemberId, UNAUTHORIZED_RESPONSE } from '../../libs/auth-context.js';

export const handler: APIGatewayProxyHandler = async (event) => {
  const memberId = getMemberId(event);
  if (!memberId) return UNAUTHORIZED_RESPONSE;

  try {
    // 1. Refresh Token + 디바이스 토큰 삭제
    await deleteItemsByPK(`MEMBER#${memberId}`, 'TOKEN#');
    await deleteItemsByPK(`MEMBER#${memberId}`, 'DEVICE#');

    // 2. 작성한 기도 + 관련 댓글/반응 전부 삭제 (with pagination)
    let lastKey: Record<string, unknown> | undefined;
    do {
      const prayers = await docClient.send(
        new QueryCommand({
          TableName: TABLE_NAME,
          IndexName: 'GSI2',
          KeyConditionExpression: 'GSI2PK = :pk',
          FilterExpression: 'memberId = :mid',
          ExpressionAttributeValues: {
            ':pk': 'PRAYER_LIST',
            ':mid': memberId,
          },
          ProjectionExpression: 'prayerId',
          ExclusiveStartKey: lastKey,
        }),
      );

      // Parallel deletion with concurrency limit
      const items = prayers.Items ?? [];
      const CONCURRENCY = 5;
      for (let i = 0; i < items.length; i += CONCURRENCY) {
        await Promise.all(
          items.slice(i, i + CONCURRENCY).map((p) =>
            deleteItemsByPK(`PRAYER#${p.prayerId as string}`),
          ),
        );
      }

      lastKey = prayers.LastEvaluatedKey;
    } while (lastKey);

    // 3. 회원 메타 삭제 (마지막에 — 위 단계 실패 시 재시도 가능하도록)
    await docClient.send(
      new DeleteCommand({
        TableName: TABLE_NAME,
        Key: { PK: `MEMBER#${memberId}`, SK: '#META' },
      }),
    );
  } catch (err) {
    console.error(`[deleteAccount] Failed for ${memberId}:`, err);
    return error('INTERNAL_ERROR', '계정 삭제 중 오류가 발생했습니다. 다시 시도해주세요.', 500);
  }

  return success({ message: '계정이 삭제되었습니다.' });
};
