import { BatchGetCommand, QueryCommand } from '@aws-sdk/lib-dynamodb';
import { docClient, TABLE_NAME } from './dynamo.js';
import { publishToEndpoint } from './sns.js';

export interface NotificationFanoutResult {
  total: number;
  successCount: number;
  failureCount: number;
}

export async function queryAllDeviceEndpoints(): Promise<string[]> {
  const keys: Array<{ PK: string; SK: string }> = [];
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

    for (const item of result.Items ?? []) {
      if (typeof item.PK === 'string' && typeof item.SK === 'string') {
        keys.push({ PK: item.PK, SK: item.SK });
      }
    }
    lastKey = result.LastEvaluatedKey;
  } while (lastKey);

  const endpoints: string[] = [];
  for (let i = 0; i < keys.length; i += 100) {
    const batch = await docClient.send(
      new BatchGetCommand({
        RequestItems: { [TABLE_NAME]: { Keys: keys.slice(i, i + 100) } },
      }),
    );

    for (const device of batch.Responses?.[TABLE_NAME] ?? []) {
      if (typeof device.snsEndpoint === 'string' && device.snsEndpoint.length > 0) {
        endpoints.push(device.snsEndpoint);
      }
    }
  }

  return endpoints;
}

export async function publishNoticeToAllDevices(params: {
  noticeId: string;
  title: string;
  body: string;
}): Promise<NotificationFanoutResult> {
  const endpoints = await queryAllDeviceEndpoints();
  const alertBody = params.body
    ? `${params.title}\n${params.body}`
    : params.title;

  const results = await Promise.allSettled(
    endpoints.map((endpoint) =>
      publishToEndpoint(endpoint, '원천청년부 공지', alertBody, {
        screen: 'notice_detail',
        noticeId: params.noticeId,
      }),
    ),
  );

  const successCount = results.filter((result) => result.status === 'fulfilled').length;
  return {
    total: endpoints.length,
    successCount,
    failureCount: endpoints.length - successCount,
  };
}
