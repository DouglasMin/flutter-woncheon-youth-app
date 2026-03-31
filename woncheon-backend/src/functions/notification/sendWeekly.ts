import type { ScheduledHandler } from 'aws-lambda';
import { QueryCommand, PutCommand } from '@aws-sdk/lib-dynamodb';
import { docClient, TABLE_NAME } from '../../libs/dynamo.js';
import { publishToEndpoint } from '../../libs/sns.js';

function getStartOfWeekKST(): string {
  const now = new Date();
  const kstOffset = 9 * 60 * 60 * 1000;
  const kstNow = new Date(now.getTime() + kstOffset);
  const day = kstNow.getUTCDay();
  const diff = day === 0 ? 6 : day - 1;
  const monday = new Date(kstNow);
  monday.setUTCDate(kstNow.getUTCDate() - diff);
  monday.setUTCHours(0, 0, 0, 0);
  const utcMonday = new Date(monday.getTime() - kstOffset);
  return utcMonday.toISOString();
}

async function queryAllDevices(): Promise<Array<Record<string, unknown>>> {
  const devices: Array<Record<string, unknown>> = [];
  let lastKey: Record<string, unknown> | undefined;

  do {
    const result = await docClient.send(
      new QueryCommand({
        TableName: TABLE_NAME,
        IndexName: 'GSI3',
        KeyConditionExpression: 'GSI3PK = :pk',
        ExpressionAttributeValues: { ':pk': 'ALL_DEVICES' },
        ExclusiveStartKey: lastKey,
      }),
    );
    devices.push(...(result.Items ?? []));
    lastKey = result.LastEvaluatedKey;
  } while (lastKey);

  return devices;
}

export const handler: ScheduledHandler = async () => {
  const startOfWeek = getStartOfWeekKST();

  const countResult = await docClient.send(
    new QueryCommand({
      TableName: TABLE_NAME,
      IndexName: 'GSI2',
      KeyConditionExpression: 'GSI2PK = :pk AND GSI2SK >= :start',
      ExpressionAttributeValues: {
        ':pk': 'PRAYER_LIST',
        ':start': `${startOfWeek}#`,
      },
      Select: 'COUNT',
    }),
  );

  const count = countResult.Count ?? 0;
  if (count === 0) {
    console.log('이번 주 새 중보기도 없음. 알림 미발송.');
    return;
  }

  const devices = await queryAllDevices();
  if (devices.length === 0) {
    console.log('등록된 디바이스 토큰 없음.');
    return;
  }

  const title = '원천청년부';
  const body = `이번 주 ${count}개의 중보기도가 올라왔어요 🙏`;
  const data = { screen: 'prayer_list' };

  let successCount = 0;
  for (const device of devices) {
    const endpoint = device.snsEndpoint as string | undefined;
    if (!endpoint) continue;

    try {
      await publishToEndpoint(endpoint, title, body, data);
      successCount++;
    } catch (err) {
      console.error(`Failed to send to ${endpoint}:`, err);
    }
  }

  await docClient.send(
    new PutCommand({
      TableName: TABLE_NAME,
      Item: {
        PK: 'NOTIF_LOG',
        SK: new Date().toISOString(),
        sentAt: new Date().toISOString(),
        newPrayerCount: count,
        recipientCount: successCount,
        status: successCount === devices.length ? 'success' : 'partial_fail',
      },
    }),
  );

  console.log(`알림 발송 완료: ${successCount}/${devices.length}명`);
};
