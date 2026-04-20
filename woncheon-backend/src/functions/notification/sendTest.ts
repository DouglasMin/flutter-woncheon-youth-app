import type { APIGatewayProxyHandler } from 'aws-lambda';
import { QueryCommand } from '@aws-sdk/lib-dynamodb';
import { docClient, TABLE_NAME } from '../../libs/dynamo.js';
import { publishToEndpoint } from '../../libs/sns.js';
import { success, error } from '../../libs/response.js';
import { getMemberId, UNAUTHORIZED_RESPONSE } from '../../libs/auth-context.js';
import { parseBody } from '../../libs/parse-body.js';

// POST /notifications/test
// body(optional): { title?: string, body?: string }
// 로그인한 본인의 등록된 기기에 즉시 테스트 푸시 발송.
// 실기기 테스트 시 "바로 받아보기" 용도 + App Store 심사관도 사용 가능.
export const handler: APIGatewayProxyHandler = async (event) => {
  const memberId = getMemberId(event);
  if (!memberId) return UNAUTHORIZED_RESPONSE;

  const body = parseBody(event.body) ?? {};
  const { title: rawTitle, body: rawBody } = body as {
    title?: string;
    body?: string;
  };

  const title =
    typeof rawTitle === 'string' && rawTitle.trim().length > 0
      ? rawTitle.trim()
      : '원천청년부';
  const messageBody =
    typeof rawBody === 'string' && rawBody.trim().length > 0
      ? rawBody.trim()
      : '테스트 알림입니다 🙏';

  // 본인 등록 디바이스만 조회 (PK=MEMBER#{id}, SK begins_with DEVICE#)
  const result = await docClient.send(
    new QueryCommand({
      TableName: TABLE_NAME,
      KeyConditionExpression: 'PK = :pk AND begins_with(SK, :prefix)',
      ExpressionAttributeValues: {
        ':pk': `MEMBER#${memberId}`,
        ':prefix': 'DEVICE#',
      },
    }),
  );

  const devices = result.Items ?? [];
  if (devices.length === 0) {
    return error(
      'NO_DEVICES',
      '등록된 디바이스가 없습니다. 알림 권한을 허용하고 앱을 재실행해주세요.',
      404,
    );
  }

  let successCount = 0;
  const failures: string[] = [];

  for (const device of devices) {
    const endpoint = device.snsEndpoint as string | undefined;
    if (!endpoint) {
      failures.push('endpoint missing');
      continue;
    }
    try {
      await publishToEndpoint(endpoint, title, messageBody, {
        screen: 'prayer_list',
      });
      successCount++;
    } catch (err) {
      failures.push(err instanceof Error ? err.message : String(err));
    }
  }

  return success({
    sent: successCount,
    total: devices.length,
    failures,
  });
};
