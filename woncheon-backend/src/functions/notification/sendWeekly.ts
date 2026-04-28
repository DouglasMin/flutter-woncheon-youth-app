import type { ScheduledHandler } from 'aws-lambda';
import { QueryCommand, PutCommand } from '@aws-sdk/lib-dynamodb';
import { docClient, TABLE_NAME } from '../../libs/dynamo.js';
import { publishToEndpoint } from '../../libs/sns.js';

/** 직전 알림 발송 시각(ISO). 없으면 7일 전을 기본 윈도우로 사용. */
async function getLastNotificationTime(): Promise<string> {
  const result = await docClient.send(
    new QueryCommand({
      TableName: TABLE_NAME,
      KeyConditionExpression: 'PK = :pk',
      ExpressionAttributeValues: { ':pk': 'NOTIF_LOG' },
      ScanIndexForward: false,
      Limit: 1,
    }),
  );
  const last = result.Items?.[0];
  if (last && typeof last.sentAt === 'string') {
    return last.sentAt;
  }
  const fallback = new Date();
  fallback.setUTCDate(fallback.getUTCDate() - 7);
  return fallback.toISOString();
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
  const since = await getLastNotificationTime();

  const countResult = await docClient.send(
    new QueryCommand({
      TableName: TABLE_NAME,
      IndexName: 'GSI2',
      KeyConditionExpression: 'GSI2PK = :pk AND GSI2SK >= :start',
      ExpressionAttributeValues: {
        ':pk': 'PRAYER_LIST',
        ':start': `${since}#`,
      },
      Select: 'COUNT',
    }),
  );

  const count = countResult.Count ?? 0;
  if (count === 0) {
    console.log(`직전 알림(${since}) 이후 새 중보기도 없음. 알림 미발송.`);
    return;
  }

  const devices = await queryAllDevices();
  if (devices.length === 0) {
    console.log('등록된 디바이스 토큰 없음.');
    return;
  }

  const title = '원천청년부';
  const body = `${count}개의 새 중보기도가 올라왔어요 🙏`;
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
        windowSince: since,
        newPrayerCount: count,
        recipientCount: successCount,
        status: successCount === devices.length ? 'success' : 'partial_fail',
      },
    }),
  );

  console.log(
    `알림 발송 완료: ${count}개 기도, ${successCount}/${devices.length}명 (since ${since})`,
  );
};
