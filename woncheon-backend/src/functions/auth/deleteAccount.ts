import type { APIGatewayProxyHandler } from 'aws-lambda';
import { QueryCommand, BatchWriteCommand, DeleteCommand } from '@aws-sdk/lib-dynamodb';
import { docClient, TABLE_NAME } from '../../libs/dynamo.js';
import { success } from '../../libs/response.js';
import { getMemberId, UNAUTHORIZED_RESPONSE } from '../../libs/auth-context.js';

export const handler: APIGatewayProxyHandler = async (event) => {
  const memberId = getMemberId(event);
  if (!memberId) return UNAUTHORIZED_RESPONSE;

  // 1. 회원 메타 삭제
  await docClient.send(
    new DeleteCommand({
      TableName: TABLE_NAME,
      Key: { PK: `MEMBER#${memberId}`, SK: '#META' },
    }),
  );

  // 2. Refresh Token + 디바이스 토큰 삭제
  await deleteByPrefix(`MEMBER#${memberId}`, 'TOKEN#');
  await deleteByPrefix(`MEMBER#${memberId}`, 'DEVICE#');

  // 3. 작성한 신고 삭제
  const reports = await docClient.send(
    new QueryCommand({
      TableName: TABLE_NAME,
      IndexName: 'GSI2',
      KeyConditionExpression: 'GSI2PK = :pk AND begins_with(GSI2SK, :prefix)',
      ExpressionAttributeValues: {
        ':pk': 'REPORT_LIST',
        ':prefix': `${memberId}#`,
      },
      ProjectionExpression: 'PK, SK',
    }),
  );

  await batchDeleteItems(reports.Items ?? []);

  // 4. 작성한 기도 + 관련 댓글/반응 전부 삭제
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
    }),
  );

  for (const prayer of prayers.Items ?? []) {
    await deleteByPrefix(`PRAYER#${prayer.prayerId as string}`, '');
  }

  return success({ message: '계정이 삭제되었습니다.' });
};

async function deleteByPrefix(pk: string, skPrefix: string): Promise<void> {
  const result = await docClient.send(
    new QueryCommand({
      TableName: TABLE_NAME,
      KeyConditionExpression: skPrefix
        ? 'PK = :pk AND begins_with(SK, :prefix)'
        : 'PK = :pk',
      ExpressionAttributeValues: skPrefix
        ? { ':pk': pk, ':prefix': skPrefix }
        : { ':pk': pk },
      ProjectionExpression: 'PK, SK',
    }),
  );

  await batchDeleteItems(result.Items ?? []);
}

async function batchDeleteItems(items: Array<{ PK: string; SK: string }>): Promise<void> {
  if (items.length === 0) return;

  const deleteRequests = items.map((item) => ({
    DeleteRequest: { Key: { PK: item.PK, SK: item.SK } },
  }));

  for (let i = 0; i < deleteRequests.length; i += 25) {
    await docClient.send(
      new BatchWriteCommand({
        RequestItems: { [TABLE_NAME]: deleteRequests.slice(i, i + 25) },
      }),
    );
  }
}
