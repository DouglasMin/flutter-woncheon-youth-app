import type { APIGatewayProxyHandler } from 'aws-lambda';
import { PutCommand } from '@aws-sdk/lib-dynamodb';
import { docClient, TABLE_NAME } from '../../libs/dynamo.js';
import { createEndpoint } from '../../libs/sns.js';
import { success, error } from '../../libs/response.js';
import { parseBody, INVALID_BODY_RESPONSE } from '../../libs/parse-body.js';
import { getMemberId, UNAUTHORIZED_RESPONSE } from '../../libs/auth-context.js';

export const handler: APIGatewayProxyHandler = async (event) => {
  const memberId = getMemberId(event);
  if (!memberId) return UNAUTHORIZED_RESPONSE;

  const body = parseBody(event.body);
  if (!body) return INVALID_BODY_RESPONSE;

  const { token, platform } = body as { token?: string; platform?: string };

  if (!token || !platform || !['ios', 'android'].includes(platform)) {
    return error('VALIDATION_ERROR', '유효한 토큰과 플랫폼(ios/android)을 입력해주세요.', 400);
  }

  const platformArn =
    platform === 'ios'
      ? process.env.SNS_IOS_PLATFORM_ARN
      : process.env.SNS_ANDROID_PLATFORM_ARN;

  let snsEndpoint = '';
  if (platformArn) {
    snsEndpoint = await createEndpoint(platformArn, token);
  }

  await docClient.send(
    new PutCommand({
      TableName: TABLE_NAME,
      Item: {
        PK: `MEMBER#${memberId}`,
        SK: `DEVICE#${platform}#${token}`,
        GSI3PK: 'ALL_DEVICES',
        memberId,
        token,
        platform,
        snsEndpoint,
        createdAt: new Date().toISOString(),
      },
    }),
  );

  return success({ message: '토큰이 등록되었습니다.' });
};
