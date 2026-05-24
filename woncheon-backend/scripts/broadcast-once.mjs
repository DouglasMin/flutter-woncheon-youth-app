#!/usr/bin/env node
// 일회성 broadcast 스크립트.
// sendWeekly.ts의 GSI3 + BatchGet 패턴이 실제로 14대 디바이스에 푸시를 보내는지 검증.
// 환경: AWS_PROFILE=dongik2 node scripts/broadcast-once.mjs
//
// 1. GSI3에서 ALL_DEVICES 키 수집
// 2. BatchGet으로 base table에서 snsEndpoint 등 full row 조회
// 3. iOS/Android 각각 SNS publish
// 4. 결과 리포트

import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import {
  DynamoDBDocumentClient,
  QueryCommand,
  BatchGetCommand,
} from '@aws-sdk/lib-dynamodb';
import { SNSClient, PublishCommand } from '@aws-sdk/client-sns';

const REGION = 'ap-northeast-2';
const TABLE_NAME = 'woncheon-dev';

const TITLE = '원천청년부';
const BODY =
  '원천 청년부 여러분, 오늘은 주일입니다. 예배 가운데 은혜로운 시간 보내시기를 축복합니다.';
const DATA = { screen: 'prayer_list' };

const dynamo = DynamoDBDocumentClient.from(
  new DynamoDBClient({ region: REGION }),
);
const sns = new SNSClient({ region: REGION });

async function queryAllDevices() {
  // 1. GSI3에서 키만 수집
  const keys = [];
  let lastKey;
  do {
    const result = await dynamo.send(
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

  if (keys.length === 0) return [];

  // 2. BatchGet으로 base table full row
  const devices = [];
  for (let i = 0; i < keys.length; i += 100) {
    const slice = keys.slice(i, i + 100);
    const batch = await dynamo.send(
      new BatchGetCommand({
        RequestItems: { [TABLE_NAME]: { Keys: slice } },
      }),
    );
    devices.push(...(batch.Responses?.[TABLE_NAME] ?? []));
  }
  return devices;
}

async function publishToEndpoint(endpointArn, title, body, data) {
  const message = {
    default: body,
    GCM: JSON.stringify({
      priority: 'high',
      notification: {
        title,
        body,
        android_channel_id: 'prayer_high',
      },
      data: data ?? {},
    }),
    APNS: JSON.stringify({
      aps: { alert: { title, body }, sound: 'default' },
      ...data,
    }),
    APNS_SANDBOX: JSON.stringify({
      aps: { alert: { title, body }, sound: 'default' },
      ...data,
    }),
  };

  await sns.send(
    new PublishCommand({
      TargetArn: endpointArn,
      Message: JSON.stringify(message),
      MessageStructure: 'json',
    }),
  );
}

async function main() {
  console.log(`[broadcast] querying devices...`);
  const devices = await queryAllDevices();
  console.log(`[broadcast] total device rows: ${devices.length}`);

  const endpoints = devices
    .map((d) => ({
      ep: d.snsEndpoint,
      platform: d.platform,
      memberId: d.memberId,
    }))
    .filter((e) => typeof e.ep === 'string' && e.ep.length > 0);

  console.log(
    `[broadcast] valid snsEndpoint rows: ${endpoints.length} ` +
      `(missing: ${devices.length - endpoints.length})`,
  );

  if (endpoints.length === 0) {
    console.error('[broadcast] no valid endpoints — abort');
    process.exit(1);
  }

  console.log(`[broadcast] title: "${TITLE}"`);
  console.log(`[broadcast] body:  "${BODY}"`);
  console.log(`[broadcast] sending to ${endpoints.length} endpoints...`);

  const results = await Promise.allSettled(
    endpoints.map((e) => publishToEndpoint(e.ep, TITLE, BODY, DATA)),
  );

  let ok = 0;
  let fail = 0;
  const failures = [];
  results.forEach((r, i) => {
    if (r.status === 'fulfilled') {
      ok++;
    } else {
      fail++;
      const e = endpoints[i];
      failures.push({
        platform: e.platform,
        memberId: e.memberId,
        reason: r.reason?.message ?? String(r.reason),
      });
    }
  });

  console.log(`\n[broadcast] result: ${ok} success, ${fail} failed`);
  if (failures.length > 0) {
    console.log('[broadcast] failures:');
    for (const f of failures) {
      console.log(
        `  platform=${f.platform} memberId=${f.memberId} reason=${f.reason}`,
      );
    }
  }
}

main().catch((e) => {
  console.error('[broadcast] fatal:', e);
  process.exit(1);
});
